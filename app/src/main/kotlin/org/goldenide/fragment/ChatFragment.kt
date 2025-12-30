/*
 * This file is part of Golden IDE.
 * Golden IDE is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 * Golden IDE is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with Golden IDE. If not, see <https://www.gnu.org/licenses/>.
 */

package com.github.scto.goldenide.fragment

import android.content.Context
import android.content.res.ColorStateList
import android.content.res.Resources
import android.graphics.Rect
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updatePadding
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.color.MaterialColors
import com.google.android.material.shape.MaterialShapeDrawable
import com.google.android.material.shape.ShapeAppearanceModel
import com.google.genai.errors.ServerException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import com.github.scto.goldenide.R
import com.github.scto.goldenide.adapter.ConversationAdapter
import com.github.scto.goldenide.chat.ChatProvider
import com.github.scto.goldenide.common.BaseBindingFragment
import com.github.scto.goldenide.databinding.FragmentChatBinding
import com.github.scto.goldenide.extension.getDip

class ChatFragment : BaseBindingFragment<FragmentChatBinding>() {

    private val conversationAdapter = ConversationAdapter()

    override fun getViewBinding() = FragmentChatBinding.inflate(layoutInflater)

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        setupUI(view.context)
        setOnClickListeners()
        setupRecyclerView()
        setupKeyboardVisibility(view)
        binding.messageText.requestFocus()
    }

    private fun setupUI(context: Context) {
        initToolbar()
        binding.toolbar.title = "Gemini Pro"
    }

    private fun initToolbar() {
        binding.toolbar.setNavigationOnClickListener {
            parentFragmentManager.popBackStack()
        }
        binding.toolbar.setOnMenuItemClickListener {

            if (it.itemId == R.id.clear) {
                conversationAdapter.clear()
                binding.recyclerview.invalidate()
                return@setOnMenuItemClickListener false
            }

            true
        }
    }

    private fun setOnClickListeners() {
        binding.sendMessageButtonIcon.setOnClickListener {
            val message = binding.messageText.text.toString().trim()
            if (message.isEmpty()) {
                return@setOnClickListener
            }
            val conversation = ConversationAdapter.Conversation(message, "user")
            conversationAdapter.add(conversation)
            binding.messageText.setText("")
            lifecycleScope.launch(Dispatchers.IO) {
                try {
                    val reply = ChatProvider.generate(
                        conversationAdapter.getConversations()
                    )

                    val response = ConversationAdapter.Conversation(stream = reply)
                    withContext(Dispatchers.Main) {
                        conversationAdapter.add(response)
                        binding.recyclerview.scrollToPosition(conversationAdapter.itemCount - 1)
                    }
                } catch (e: ServerException) {
                    Toast.makeText(requireContext(), e.message, Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    private fun setupRecyclerView() {
        binding.recyclerview.apply {
            adapter = conversationAdapter
            layoutManager = LinearLayoutManager(requireContext()).apply {
                stackFromEnd = true
            }
            addItemDecoration(object : RecyclerView.ItemDecoration() {
                override fun getItemOffsets(
                    outRect: Rect,
                    view: View,
                    parent: RecyclerView,
                    state: RecyclerView.State
                ) {
                    val verticalOffset = 8.dp
                    outRect.top = verticalOffset
                    outRect.bottom = verticalOffset
                }
            })
        }
    }

    private fun setupKeyboardVisibility(view: View) {
        view.viewTreeObserver.addOnGlobalLayoutListener {
            val r = Rect()
            view.getWindowVisibleDisplayFrame(r)

            // Screen height minus visible area = keyboard height
            val keyboardHeight = view.rootView.height - r.bottom

            if (keyboardHeight > 300) { // Keyboard is visible
                // Scroll to bottom of conversation when keyboard appears
                if (conversationAdapter.itemCount > 0) {
                    binding.recyclerview.post {
                        binding.recyclerview.scrollToPosition(conversationAdapter.itemCount - 1)
                    }
                }

                // Add padding to make sure input field is above keyboard
                binding.chatLayout.translationY = -keyboardHeight.toFloat()
            } else {
                // Reset position when keyboard is hidden
                binding.chatLayout.translationY = 0f
            }
        }
    }
}

private val Int.dp: Int
    get() = (Resources.getSystem().displayMetrics.density * this + 0.5f).toInt()
