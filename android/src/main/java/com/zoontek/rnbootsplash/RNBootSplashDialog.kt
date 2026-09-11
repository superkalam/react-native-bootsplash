package com.zoontek.rnbootsplash

import android.app.Activity
import android.app.Dialog
import android.content.res.Configuration
import android.graphics.Color
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.WindowManager
import android.widget.TextView

import androidx.annotation.StyleRes

class RNBootSplashDialog(
  activity: Activity,
  @StyleRes themeResId: Int,
  private val fade: Boolean
) : Dialog(activity, themeResId) {

  private var statusTextView: TextView? = null
  private val mainHandler = Handler(Looper.getMainLooper())

  init {
    setOwnerActivity(activity)
    setCancelable(false)
    setCanceledOnTouchOutside(false)
  }

  @Deprecated("Deprecated in favor of OnBackPressedCallback")
  override fun onBackPressed() {
    val activity = ownerActivity
    activity?.moveTaskToBack(true)
  }

  override fun dismiss() {
    if (isShowing) {
      runCatching { super.dismiss() }
    }
  }

  fun dismiss(callback: () -> Unit) {
    if (isShowing) {
      setOnDismissListener { callback() }
      runCatching { super.dismiss() }.onFailure { callback() }
    } else {
      callback()
    }
  }

  override fun show() {
    if (!isShowing) {
      runCatching { super.show() }
    }
  }

  fun show(callback: () -> Unit) {
    if (!isShowing) {
      setOnShowListener { callback() }
      runCatching { super.show() }.onFailure { callback() }
    } else {
      callback()
    }
  }

  fun setStatusText(text: String) {
    mainHandler.post {
      statusTextView?.let { textView ->
        if (text.isEmpty()) {
          textView.text = text
          textView.visibility = android.view.View.GONE
        } else {
          textView.text = text
          textView.visibility = android.view.View.VISIBLE
        }
      }
    }
  }

  fun setTextColor(lightColor: String, darkColor: String) {
    mainHandler.post { applyTextColor(lightColor, darkColor) }
  }

  private fun applyTextColor(lightColor: String, darkColor: String) {
    val textView = statusTextView ?: return

    val isDarkMode = (context.resources.configuration.uiMode and
      Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
    val colorToUse = if (isDarkMode && darkColor.isNotEmpty()) darkColor else lightColor

    if (colorToUse.isEmpty()) {
      return
    }

    try {
      textView.setTextColor(Color.parseColor(colorToUse))
    } catch (e: IllegalArgumentException) {
      // Invalid color format, keep the layout default
    }
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    // Set the custom layout
    setContentView(R.layout.bootsplash_layout)

    // Get reference to status TextView
    statusTextView = findViewById(R.id.bootsplash_status)

    // Initialize with current state from RNBootSplashModuleImpl
    // (onCreate is already on main thread)
    val currentText = RNBootSplashModuleImpl.getCurrentText()

    statusTextView?.text = currentText
    statusTextView?.visibility = when {
      currentText.isEmpty() -> android.view.View.GONE
      else -> android.view.View.VISIBLE
    }

    applyTextColor(
      RNBootSplashModuleImpl.getLightTextColor(),
      RNBootSplashModuleImpl.getDarkTextColor()
    )

    window?.apply {
      setLayout(
        WindowManager.LayoutParams.MATCH_PARENT,
        WindowManager.LayoutParams.MATCH_PARENT
      )

      setWindowAnimations(
        when {
          fade -> R.style.BootSplashFadeOutAnimation
          else -> R.style.BootSplashNoAnimation
        }
      )

      if (RNBootSplashModuleImpl.isSamsungOneUI4()) {
        setBackgroundDrawableResource(R.drawable.compat_splash_screen_oneui_4)
      }
    }
  }
}
