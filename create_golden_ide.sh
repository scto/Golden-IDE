#!/bin/bash

# ==============================================================================
# EINSTELLUNGEN
# ==============================================================================
# Haupt-Namen
OLD_NAME="Golden IDE"
NEW_NAME="Golden IDE"

# Package Namen
OLD_PKG="com.github.scto.goldenide"
NEW_PKG="com.github.scto.goldenide"

# Pfad-Fragmente
SEARCH_PATH="com.github.scto.goldenide"
TARGET_PATH_SUFFIX="com/github/scto/goldenide"

# API Keys
OLD_API_KEY="AIzaSyBNIS3j9bvplRJ9oeImDLDrcb2SUL3YdUM"
NEW_API_KEY="AIzaSyBNIS3j9bvplRJ9oeImDLDrcb2SUL3YdUM"

# Variationen (Case-Sensitive - SEHR WICHTIG)
# 1. GoldenIde (z.B. in Styles/Themes)
OLD_NAME_CAMEL="GoldenIde"
NEW_NAME_CAMEL="GoldenIde"

# 2. GoldenIDE (z.B. rootProject.name in settings.gradle)
OLD_NAME_SIMPLE="GoldenIDE"
NEW_NAME_SIMPLE="GoldenIDE"

# 3. goldenide (alles klein, z.B. resources)
OLD_NAME_LOWER="goldenide"
NEW_NAME_LOWER="goldenide"

# 4. Golden-IDE (Github/Jitpack/Repo-Name)
OLD_ORG_HYPHEN="Golden-IDE"
# Hinweis: NEW_ORG_HYPHEN wird hier als "Golden-IDE" verwendet für Text-Ersetzungen,
# aber Dependencies werden explizit ausgeschlossen.

TARGET_DIR_NAME="Golden-IDE"

# ==============================================================================
# 1. SETUP: Umgebung vorbereiten
# ==============================================================================
SOURCE_DIR=$(pwd)
TARGET_DIR="$SOURCE_DIR/$TARGET_DIR_NAME"

echo "========================================================"
echo "Starte Migration: $OLD_NAME -> $NEW_NAME"
echo "========================================================"

if [ -d "$TARGET_DIR" ]; then
    echo "ACHTUNG: Ordner '$TARGET_DIR_NAME' existiert bereits."
    echo "Lösche alten Ordner..."
    rm -rf "$TARGET_DIR"
fi

echo "1. Erstelle Zielordner $TARGET_DIR_NAME..."
mkdir -p "$TARGET_DIR"

echo "2. Initialisiere Git..."
cd "$TARGET_DIR" || exit
git init -b main > /dev/null
cd "$SOURCE_DIR" || exit

echo "3. Kopiere Dateien..."
if command -v rsync &> /dev/null; then
    rsync -a --exclude "$TARGET_DIR_NAME" \
             --exclude ".git" \
             --exclude ".gradle" \
             --exclude "/build" \
             --exclude "/*/build" \
             --exclude "feature/*/build" \
             --exclude "*.iml" \
             --exclude "local.properties" . "$TARGET_DIR/"
else
    # Fallback cp
    for file in ./* ./.??*; do
        if [[ "$file" != "./$TARGET_DIR_NAME" && "$file" != "./.git" && "$file" != "./.gradle" && "$file" != "." && "$file" != ".." ]]; then
            cp -R "$file" "$TARGET_DIR/" 2>/dev/null || true
        fi
    done
fi

# Ab jetzt arbeiten wir NUR im neuen Ordner
cd "$TARGET_DIR" || exit

# ==============================================================================
# 4. ORDNER-STRUKTUR ÄNDERN (DYNAMISCH)
# ==============================================================================
echo "4. Strukturiere Ordner um ($SEARCH_PATH -> $TARGET_PATH_SUFFIX)..."

# Findet alle 'com.github.scto.goldenide' Ordner und verschiebt sie
find . -type d -path "*/$SEARCH_PATH" -prune | while read -r src_dir; do
    
    # Basis-Verzeichnis ermitteln
    base_dir=$(dirname "$(dirname "$src_dir")")
    dest_dir="$base_dir/$TARGET_PATH_SUFFIX"
    
    # Spezialfall Check: src/test/java -> src/test/kotlin
    is_test_java=false
    if [[ "$base_dir" == *"/src/test/java" ]]; then
        base_dir_kotlin="${base_dir%java}kotlin"
        dest_dir="$base_dir_kotlin/$TARGET_PATH_SUFFIX"
        is_test_java=true
        echo "   [Move] Spezialfall test/java -> test/kotlin: $src_dir"
    else
        echo "   [Move] $src_dir -> $dest_dir"
    fi

    # Verschieben
    mkdir -p "$dest_dir"
    cp -R "$src_dir/." "$dest_dir/"
    rm -rf "$src_dir"
    
    # Aufräumen: Leeres 'org' Verzeichnis löschen
    rmdir "$(dirname "$src_dir")" 2>/dev/null || true
    
    if [ "$is_test_java" = true ]; then
        rmdir "$base_dir" 2>/dev/null || true
    fi
done

# ==============================================================================
# 5. TEXT-ERSETZUNG (Dateiinhalte)
# ==============================================================================
echo "5. Ersetze Texte, Packages und Imports in Dateien..."

grep -rIl "." . | grep -v "\.git" | while read -r file; do
    
    # 5.1 API Key
    if grep -q "$OLD_API_KEY" "$file"; then
        sed -i "s/$OLD_API_KEY/$NEW_API_KEY/g" "$file"
        echo "   [Edit] API Key ersetzt in: $file"
    fi

    # 5.2 Package Name (com.github.scto.goldenide)
    if grep -q "$OLD_PKG" "$file"; then
        sed -i "s/$OLD_PKG/$NEW_PKG/g" "$file"
    fi

    # 5.3 Pfade in Strings
    if grep -q "$SEARCH_PATH" "$file"; then
        sed -i "s|$SEARCH_PATH|$TARGET_PATH_SUFFIX|g" "$file"
    fi

    # 5.4 GoldenIDE -> GoldenIDE (Wichtig für rootProject.name in settings.gradle)
    if grep -q "$OLD_NAME_SIMPLE" "$file"; then
        sed -i "s/$OLD_NAME_SIMPLE/$NEW_NAME_SIMPLE/g" "$file"
    fi

    # 5.5 App Name "Golden IDE" -> "Golden IDE"
    if grep -q "$OLD_NAME" "$file"; then
        sed -i "s/$OLD_NAME/$NEW_NAME/g" "$file"
    fi

    # 5.6 CamelCase "GoldenIde" -> "GoldenIde"
    if grep -q "$OLD_NAME_CAMEL" "$file"; then
        sed -i "s/$OLD_NAME_CAMEL/$NEW_NAME_CAMEL/g" "$file"
    fi

    # 5.7 Kleinschreibung "goldenide" -> "goldenide"
    if grep -q "$OLD_NAME_LOWER" "$file"; then
        sed -i "s/$OLD_NAME_LOWER/$NEW_NAME_LOWER/g" "$file"
    fi

    # 5.8 Bindestrich-Variante "Golden-IDE" -> "Golden-IDE"
    # WICHTIG: Ignoriert Zeilen mit "com.github", um Dependencies nicht zu zerstören!
    if grep -q "$OLD_ORG_HYPHEN" "$file"; then
        sed -i "/com\.github/!s/$OLD_ORG_HYPHEN/Golden-IDE/g" "$file"
    fi
done

# ==============================================================================
# 6. SPEZIAL-FIX FÜR settings.gradle.kts
# ==============================================================================
# Zur Sicherheit: Erzwinge korrekten Projektnamen, falls generische Ersetzung fehlschlug
if [ -f "settings.gradle.kts" ]; then
    echo "6. Überprüfe settings.gradle.kts..."
    sed -i "s/rootProject.name = \"GoldenIDE\"/rootProject.name = \"GoldenIDE\"/g" settings.gradle.kts
    sed -i "s/rootProject.name = \"Cosmic-IDE\"/rootProject.name = \"Golden-IDE\"/g" settings.gradle.kts
fi

# ==============================================================================
# 7. DATEINAMEN UMBENENNEN
# ==============================================================================
echo "7. Benenne Dateien um..."
find . -name "*$OLD_NAME_LOWER*" -o -name "*$OLD_NAME_CAMEL*" -o -name "*$OLD_NAME_SIMPLE*" | while read -r filepath; do
    dir=$(dirname "$filepath")
    filename=$(basename "$filepath")
    
    # Ersetze alle Varianten im Dateinamen
    new_filename=$(echo "$filename" \
        | sed "s/$OLD_NAME_LOWER/$NEW_NAME_LOWER/g" \
        | sed "s/$OLD_NAME_CAMEL/$NEW_NAME_CAMEL/g" \
        | sed "s/$OLD_NAME_SIMPLE/$NEW_NAME_SIMPLE/g")
    
    if [ "$filename" != "$new_filename" ]; then
        mv "$filepath" "$dir/$new_filename"
        echo "   [Rename] $filename -> $new_filename"
    fi
done

# ==============================================================================
# 8. CLEANUP
# ==============================================================================
echo "8. bash ./gradlew clean..."
bash ./gradlew clean... 
echo "9. Bereinige Caches..."
rm -rf .gradle build */build feature/*/build

echo "========================================================"
echo "FERTIG! Das Projekt befindet sich in: $TARGET_DIR"
echo "========================================================"
echo "Nächste Schritte:"
echo "1. cd Golden-IDE"
echo "2. git add . && git commit -m 'Migration to Golden IDE'"
echo "3. bash ./gradlew assembleDebug"
echo "========================================================"