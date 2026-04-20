package com.zoontek.rnbootsplash

import android.app.Activity
import android.app.Dialog
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.WindowManager
import android.widget.FrameLayout
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
    mainHandler.post {
      statusTextView?.let { textView ->
        val isDarkMode = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
        val colorToUse = if (isDarkMode && darkColor.isNotEmpty()) darkColor else lightColor

        if (colorToUse.isNotEmpty()) {
          try {
            textView.setTextColor(Color.parseColor(colorToUse))
          } catch (e: IllegalArgumentException) {
            // Invalid color format, ignore
          }
        }
      }
    }
  }

  override fun onCreate(savedInstanceState: Bundle?) {
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

    super.onCreate(savedInstanceState)

    // Add a TextView on top of the existing theme-rendered content (no setContentView!)
    val density = context.resources.displayMetrics.density
    val bottomMargin = (120 * density).toInt()

    val textView = TextView(context).apply {
      gravity = Gravity.CENTER
      textAlignment = TextView.TEXT_ALIGNMENT_CENTER
      setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
      typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
      visibility = android.view.View.GONE
    }

    val params = FrameLayout.LayoutParams(
      FrameLayout.LayoutParams.MATCH_PARENT,
      FrameLayout.LayoutParams.WRAP_CONTENT
    ).apply {
      gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
      setMargins(
        (20 * density).toInt(),
        0,
        (20 * density).toInt(),
        bottomMargin
      )
    }

    // Add to the Dialog's decor view content — floats on top of the splash theme
    val decorView = window?.decorView as? FrameLayout
    decorView?.addView(textView, params)
    statusTextView = textView

    // Initialize with current state
    val currentText = RNBootSplashModuleImpl.getCurrentText()
    val lightColor = RNBootSplashModuleImpl.getLightTextColor()
    val darkColor = RNBootSplashModuleImpl.getDarkTextColor()

    if (currentText.isNotEmpty()) {
      textView.text = currentText
      textView.visibility = android.view.View.VISIBLE
    }

    if (lightColor.isNotEmpty() || darkColor.isNotEmpty()) {
      val isDarkMode = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
      val colorToUse = if (isDarkMode && darkColor.isNotEmpty()) darkColor else lightColor

      if (colorToUse.isNotEmpty()) {
        try {
          textView.setTextColor(Color.parseColor(colorToUse))
        } catch (e: IllegalArgumentException) {
          // Invalid color format, use default
        }
      }
    }
  }
}
