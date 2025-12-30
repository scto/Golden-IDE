/*
 * This file is part of Golden IDE.
 * Golden IDE is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 * Golden IDE is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with Golden IDE. If not, see <https://www.gnu.org/licenses/>.
 */

package com.github.scto.goldenide.extension

import android.graphics.Typeface
import androidx.core.content.res.ResourcesCompat
import io.github.rosemoe.sora.widget.CodeEditor
import io.github.rosemoe.sora.widget.component.EditorAutoCompletion
import com.github.scto.goldenide.R
import com.github.scto.goldenide.editor.completion.CustomCompletionItemAdapter
import com.github.scto.goldenide.editor.completion.CustomCompletionLayout
import com.github.scto.goldenide.common.Prefs

/**
 * Sets the font and enables highlighting of the current line for the code editor.
 */
fun CodeEditor.setFont() {
    typefaceText = if (Prefs.editorFont.isNotEmpty()) {
        Typeface.createFromFile(Prefs.editorFont)
    } else {
        ResourcesCompat.getFont(context, R.font.noto_sans_mono)
    }
    isHighlightCurrentLine = true
}

fun CodeEditor.setCompletionLayout() {
    getComponent(EditorAutoCompletion::class.java).apply {
        setAdapter(CustomCompletionItemAdapter())
        setLayout(CustomCompletionLayout())
    }
}
