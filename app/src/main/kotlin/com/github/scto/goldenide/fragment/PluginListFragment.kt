/*
 * This file is part of Golden IDE.
 * Golden IDE is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 * Golden IDE is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with Golden IDE. If not, see <https://www.gnu.org/licenses/>.
 */

package com.github.scto.goldenide.fragment

import android.os.Bundle
import android.util.Log
import android.view.View
import androidx.lifecycle.lifecycleScope
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.snackbar.Snackbar
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import com.github.scto.goldenide.adapter.AvailablePluginAdapter
import com.github.scto.goldenide.adapter.PluginAdapter
import com.github.scto.goldenide.common.BaseBindingFragment
import com.github.scto.goldenide.common.Prefs
import com.github.scto.goldenide.databinding.FragmentPluginListBinding
import com.github.scto.goldenide.databinding.PluginInfoBinding
import com.github.scto.goldenide.rewrite.plugin.api.Plugin
import com.github.scto.goldenide.rewrite.util.FileUtil
import com.github.scto.goldenide.util.CommonUtils
import com.github.scto.goldenide.util.CommonUtils.showSnackbarError
import java.net.URL

class PluginListFragment : BaseBindingFragment<FragmentPluginListBinding>() {

    override fun getViewBinding() = FragmentPluginListBinding.inflate(layoutInflater)

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.toolbar.setNavigationOnClickListener {
            parentFragmentManager.popBackStack()
        }

        binding.pluginsList.apply {
            adapter = AvailablePluginAdapter(object : AvailablePluginAdapter.OnPluginEventListener {
                override fun onPluginClicked(plugin: Plugin) {
                    val dialog = BottomSheetDialog(requireActivity())
                    val binding = PluginInfoBinding.inflate(layoutInflater)
                    val bottomSheetView = binding.root
                    binding.apply {
                        val title = "${plugin.name} v${plugin.version}"
                        pluginName.text = title
                        val desc = plugin.description
                            .ifEmpty { "No description" } + "\n\n" + plugin.source
                        CommonUtils.getMarkwon().setMarkdown(pluginDescription, desc)
                    }
                    dialog.setContentView(bottomSheetView)
                    dialog.show()
                }

                override fun onPluginLongClicked(plugin: Plugin) {
                    MaterialAlertDialogBuilder(requireContext())
                        .setTitle("Delete plugin")
                        .setMessage("Are you sure you want to delete ${plugin.name}?")
                        .setPositiveButton("Yes") { _, _ ->
                            lifecycleScope.launch {
                                FileUtil.pluginDir.resolve(plugin.name).deleteRecursively()
                                val plugins = getPlugins()
                                (adapter as PluginAdapter).submitList(plugins)
                            }
                        }
                        .setNegativeButton("No") { _, _ -> }
                        .show()
                }

                override fun onPluginInstall(plugin: Plugin) {
                    binding.progressBar.visibility = View.VISIBLE
                    Snackbar.make(
                        binding.root,
                        "Installing ${plugin.name}...",
                        Snackbar.LENGTH_SHORT
                    ).show()
                    lifecycleScope.launch(Dispatchers.IO) {
                        val pluginFolder = FileUtil.pluginDir.resolve(plugin.name)
                        pluginFolder.mkdirs()
                        pluginFolder.resolve("config.json").apply {
                            Log.d("PluginListFragment", "Writing ${plugin.raw} to $this")
                            writeText(plugin.raw)
                        }
                        pluginFolder.resolve("classes.dex").apply {
                            runCatching {
                                writeBytes(URL("${plugin.source}/releases/download/${plugin.version}/classes.dex").readBytes())
                            }.onFailure {
                                Log.e(
                                    "PluginListFragment",
                                    "Failed to download ${plugin.name}", it
                                )
                                showSnackbarError(
                                    binding.root,
                                    "Failed to get plugins",
                                    it
                                )
                            }
                        }
                        lifecycleScope.launch(Dispatchers.Main) {
                            Snackbar.make(
                                binding.root,
                                "${plugin.name} installed",
                                Snackbar.LENGTH_SHORT
                            ).show()
                            binding.progressBar.visibility = View.INVISIBLE
                        }
                    }
                }
            })
            lifecycleScope.launch {
                (adapter as AvailablePluginAdapter).submitList(getPlugins())
            }
        }
    }

    suspend fun getPlugins(): List<Plugin> {
        return withContext(Dispatchers.IO) {
            try {
                val pluginsJson = URL(Prefs.pluginRepository).readText()
                val pluginsType = object : TypeToken<List<Plugin>>() {}.type
                Gson().fromJson(pluginsJson, pluginsType) as List<Plugin>
            } catch (e: Exception) {
                Log.e(
                    "PluginListFragment",
                    "Failed to get plugins", e
                )
                showSnackbarError(
                    binding.root,
                    "Failed to get plugins",
                    e
                )
                emptyList()
            }
        }
    }
}
