#!/bin/bash

# ==============================================================================
# EINSTELLUNGEN & VARIABLEN
# ==============================================================================

# Namen
OLD_NAME="Golden IDE"
NEW_NAME="Golden IDE"

# Package Namen
OLD_PKG="com.github.scto.goldenide"
NEW_PKG="com.github.scto.goldenide"

# Pfade (für Ordnerstruktur und Strings im Code)
OLD_PATH="com.github.scto.goldenide"
NEW_PATH="com/github/scto/goldenide"

# API Keys
OLD_API_KEY="AIzaSyBNIS3j9bvplRJ9oeImDLDrcb2SUL3YdUM"
NEW_API_KEY="AIzaSyBNIS3j9bvplRJ9oeImDLDrcb2SUL3YdUM"

# Zusätzliche Namensvariationen (Case-Sensitive)
# Für Fälle wie "Theme.GoldenIde" -> "Theme.GoldenIde"
OLD_NAME_CAMEL="GoldenIde"
NEW_NAME_CAMEL="GoldenIde"

# Für Fälle wie Ressourcen "goldenide_icon" -> "goldenide_icon"
OLD_NAME_LOWER="goldenide"
NEW_NAME_LOWER="goldenide"

# Zielordner
TARGET_DIR_NAME="Golden-IDE"

# Module, die bearbeitet werden sollen (Features werden separat gesucht)
MODULES=("app" "build-tools" "common" "datadir" "jgit" "util")

# Build-Varianten / Source Sets
VARIANTS=("main" "test" "androidTest" "debug" "dev" "prod")

# Programmiersprachen-Ordner
LANGUAGES=("kotlin" "java" "aidl")

# ==============================================================================
# START
# ==============================================================================

echo "========================================================"
echo "Starte Migration: $OLD_NAME -> $NEW_NAME"
echo "========================================================"

SOURCE_DIR=$(pwd)
TARGET_DIR="$SOURCE_DIR/$TARGET_DIR_NAME"

# ==============================================================================
# 1. SETUP: Ordner erstellen, Git Init & Kopieren
# ==============================================================================
echo "1. Vorbereitung der Umgebung..."

if [ -d "$TARGET_DIR" ]; then
    echo "   ACHTUNG: Der Ordner '$TARGET_DIR_NAME' existiert bereits."
    read -p "   Soll der Ordner gelöscht und neu erstellt werden? (j/n) " choice
    case "$choice" in 
      j|J ) echo "   Lösche alten Ordner..."; rm -rf "$TARGET_DIR";;
      * ) echo "   Abbruch."; exit 1;;
    esac
fi

echo "   Erstelle Zielordner: $TARGET_DIR"
mkdir -p "$TARGET_DIR"

echo "   Initialisiere Git Repository..."
# Wir wechseln kurz rein für git init
cd "$TARGET_DIR" || exit
git init -b main
cd "$SOURCE_DIR" || exit

echo "   Kopiere Projektdateien..."
# Kopiere alles außer Git, Gradle Caches, Build-Ordner und den Zielordner selbst
if command -v rsync &> /dev/null; then
    rsync -av --progress . "$TARGET_DIR/" \
        --exclude "$TARGET_DIR_NAME" \
        --exclude ".git" \
        --exclude ".gradle" \
        --exclude "build" \
        --exclude "*/build" \
        --exclude "*.iml" \
        --exclude "local.properties" > /dev/null
else
    echo "   Warnung: 'rsync' nicht gefunden. Verwende 'cp' (langsamer/weniger präzise)."
    # Einfacher Kopier-Loop als Fallback
    for file in ./* ./.??*; do
        if [[ "$file" != "./$TARGET_DIR_NAME" && "$file" != "./.git" && "$file" != "./.gradle" && "$file" != "." && "$file" != ".." ]]; then
            cp -R "$file" "$TARGET_DIR/" 2>/dev/null || true
        fi
    done
fi

echo "   Wechsle in den neuen Projektordner..."
cd "$TARGET_DIR" || exit

# ==============================================================================
# 2. TEXT-ERSETZUNG (Inhalten in Dateien)
# ==============================================================================
echo "2. Führe Text-Ersetzungen in allen Dateien durch..."

# Findet alle Dateien (keine Ordner), schließt .git aus
# Wir nutzen grep -I um Binärdateien zu ignorieren
grep -rIl "." . | grep -v "\.git" | while read -r file; do
    
    # 1. API Key tauschen (höchste Priorität, spezifisch)
    if grep -q "$OLD_API_KEY" "$file"; then
        sed -i "s/$OLD_API_KEY/$NEW_API_KEY/g" "$file"
        echo "   [Key] API Key ersetzt in: $file"
    fi

    # 2. Package Name (com.github.scto.goldenide -> com.github.scto.goldenide)
    # Wichtig: Zuerst das Package ersetzen, bevor "goldenide" einzeln ersetzt wird
    if grep -q "$OLD_PKG" "$file"; then
        sed -i "s/$OLD_PKG/$NEW_PKG/g" "$file"
    fi

    # 3. Pfad im String-Format (com.github.scto.goldenide -> com/github/scto/goldenide)
    if grep -q "$OLD_PATH" "$file"; then
        sed -i "s|$OLD_PATH|$NEW_PATH|g" "$file"
    fi

    # 4. Projekt Name (Golden IDE -> Golden IDE)
    if grep -q "$OLD_NAME" "$file"; then
        sed -i "s/$OLD_NAME/$NEW_NAME/g" "$file"
    fi

    # 5. CamelCase Varianten (GoldenIde -> GoldenIde)
    # Z.B. für Themes, Klassenreferenzen in XML
    if grep -q "$OLD_NAME_CAMEL" "$file"; then
        sed -i "s/$OLD_NAME_CAMEL/$NEW_NAME_CAMEL/g" "$file"
    fi

    # 6. Kleinschreibung (goldenide -> goldenide)
    # Ersetzt alles was übrig ist (z.B. datei_namen, resources, ids)
    # Da com.github.scto.goldenide schon in Schritt 2 ersetzt wurde, wird hier nichts kaputt gemacht
    if grep -q "$OLD_NAME_LOWER" "$file"; then
        sed -i "s/$OLD_NAME_LOWER/$NEW_NAME_LOWER/g" "$file"
    fi

done
echo "   Text-Ersetzungen abgeschlossen."

# ==============================================================================
# 3. DATEI-UMBENENNUNG (Wenn Dateinamen goldenide enthalten)
# ==============================================================================
echo "3. Suche nach Dateien, die umbenannt werden müssen..."
# Suche Dateien die "goldenide" oder "GoldenIde" im Namen haben und benenne sie um
find . -name "*$OLD_NAME_LOWER*" -o -name "*$OLD_NAME_CAMEL*" | while read -r filepath; do
    dir=$(dirname "$filepath")
    filename=$(basename "$filepath")
    
    # Ersetze im Dateinamen (sowohl lower als auch Camel)
    new_filename=$(echo "$filename" | sed "s/$OLD_NAME_LOWER/$NEW_NAME_LOWER/g" | sed "s/$OLD_NAME_CAMEL/$NEW_NAME_CAMEL/g")
    
    if [ "$filename" != "$new_filename" ]; then
        mv "$filepath" "$dir/$new_filename"
        echo "   [Rename] $filename -> $new_filename"
    fi
done

# ==============================================================================
# 4. ORDNER-STRUKTUR REFACTORING
# ==============================================================================
echo "4. Strukturiere Java/Kotlin Paket-Ordner um..."

move_source_files() {
    local module_path=$1
    local variant=$2
    local lang=$3
    
    # Quell-Pfad (alt): z.B. app/src/main/java/com.github.scto.goldenide
    local src_dir="$module_path/src/$variant/$lang/$OLD_PATH"
    
    # Ziel-Pfad (neu): Standardmäßig com/github/scto/goldenide
    local dest_rel_path="$NEW_PATH"
    local base_dest_dir="$module_path/src/$variant/$lang"

    # SPEZIALFALL: src/test/java -> verschieben nach src/test/kotlin
    if [[ "$variant" == "test" && "$lang" == "java" ]]; then
        base_dest_dir="$module_path/src/$variant/kotlin"
        echo "   [Move] Spezialfall erkannt: Verschiebe $module_path test/java -> test/kotlin"
    fi

    local dest_dir="$base_dest_dir/$dest_rel_path"

    if [ -d "$src_dir" ]; then
        # Zielordner erstellen
        mkdir -p "$dest_dir"
        
        # Inhalt verschieben
        if [ "$(ls -A "$src_dir")" ]; then
            echo "   [Move] $src_dir -> $dest_dir"
            mv "$src_dir"/* "$dest_dir"/ 2>/dev/null || true
        fi
        
        # Alte leere Ordner aufräumen (com.github.scto.goldenide und org)
        rmdir -p "$src_dir" 2>/dev/null || true
        
        # Falls es der Spezialfall (test/java) war, den nun leeren java-Ordner löschen
        if [[ "$variant" == "test" && "$lang" == "java" ]]; then
             rmdir "$module_path/src/$variant/java" 2>/dev/null || true
        fi
    fi
}

# 4a. Standard-Module durchlaufen
for mod in "${MODULES[@]}"; do
    for var in "${VARIANTS[@]}"; do
        for lang in "${LANGUAGES[@]}"; do
            move_source_files "$mod" "$var" "$lang"
        done
    done
done

# 4b. Feature-Module durchlaufen
if [ -d "feature" ]; then
    echo "   Verarbeite Feature-Submodule..."
    find feature -mindepth 1 -maxdepth 1 -type d | while read -r feature_mod; do
        for var in "${VARIANTS[@]}"; do
            for lang in "${LANGUAGES[@]}"; do
                move_source_files "$feature_mod" "$var" "$lang"
            done
        done
    done
fi

echo "========================================================"
echo "MIGRATION ERFOLGREICH ABGESCHLOSSEN"
echo "========================================================"
echo "Neues Projekt liegt in: $TARGET_DIR"
echo "1. Öffne das Projekt in Android Studio / Fleet."
echo "2. Führe 'Sync Project with Gradle Files' aus."
echo "3. Überprüfe die 'git status' Änderungen."
echo "========================================================"