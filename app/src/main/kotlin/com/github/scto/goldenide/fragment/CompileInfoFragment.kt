/*
 * This file is part of Golden IDE.
 * Golden IDE is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 * Golden IDE is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with Golden IDE. If not, see <https://www.gnu.org/licenses/>.
 */

package com.github.scto.goldenide.fragment

import android.os.Bundle
import android.view.View
import androidx.fragment.app.commit
import androidx.lifecycle.lifecycleScope
import io.github.rosemoe.sora.langs.textmate.TextMateLanguage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import com.github.scto.goldenide.R
import com.github.scto.goldenide.build.BuildReporter
import com.github.scto.goldenide.common.BaseBindingFragment
import com.github.scto.goldenide.compile.Compiler
import com.github.scto.goldenide.databinding.FragmentCompileInfoBinding
import com.github.scto.goldenide.project.Project
import com.github.scto.goldenide.util.ProjectHandler

/**
 * A fragment for displaying information about the compilation process.
 */
class CompileInfoFragment : BaseBindingFragment<FragmentCompileInfoBinding>() {
    val project: Project = ProjectHandler.getProject()
        ?: throw IllegalStateException("No project set")
    val reporter by lazy {
        BuildReporter { report ->
            if (report.message.isEmpty()) return@BuildReporter
            // Update the info editor with the build output
            val text = binding.infoEditor.text
            lifecycleScope.launch {
                text.insert(
                    text.lineCount - 1,
                    0,
                    "${report.kind}: ${report.message}\n"
                )
            }
        }
    }
    val compiler: Compiler = Compiler(project, reporter)

    override fun getViewBinding() = FragmentCompileInfoBinding.inflate(layoutInflater)

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.infoEditor.apply {
            setEditorLanguage(TextMateLanguage.create("source.build", false))
            editable = false
            isLineNumberEnabled = false
        }

        binding.toolbar.apply {
            title = "Compiling ${project.name}"
            setNavigationOnClickListener {
                parentFragmentManager.popBackStack()
            }
        }

        lifecycleScope.launch(Dispatchers.IO) {
            try {
                compiler.compile()
                if (reporter.buildSuccess) {
                    withContext(Dispatchers.Main) {
                        navigateToProjectOutputFragment()
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    binding.infoEditor.text.insert(
                        binding.infoEditor.text.lineCount - 1,
                        0,
                        "Build failed: ${e.message}\n"
                    )
                }
            }
        }
    }

    override fun onDestroyView() {
        binding.infoEditor.release()
        super.onDestroyView()
    }

    private fun navigateToProjectOutputFragment() {
        parentFragmentManager.commit {
            add(R.id.fragment_container, ProjectOutputFragment())
            addToBackStack(null)
        }
    }
}
