package org.lichess.mobileV2

import android.app.ActivityManager
import android.content.Context
import android.graphics.Rect
import androidx.core.view.ViewCompat
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
  private val exclusionChannel = "mobile.lichess.org/gestures_exclusion"
  private val storageChannel = "mobile.lichess.org/storage"

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, exclusionChannel).setMethodCallHandler {
      call, result ->
      if (call.method == "setSystemGestureExclusionRects") {
        val arguments = call.arguments as List<Map<String, Int>>
        val decodedRects = decodeExclusionRects(arguments)
        ViewCompat.setSystemGestureExclusionRects(activity.window.decorView, decodedRects)
        result.success(null)
      } else {
        result.notImplemented()
      }
    }

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, storageChannel).setMethodCallHandler {
      call, result ->
      if (call.method == "clearApplicationUserData") {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        result.success(activityManager.clearApplicationUserData())
      } else {
        result.notImplemented()
      }
    }
  }

  private fun decodeExclusionRects(inputRects: List<Map<String, Int>>): List<Rect> =
    inputRects.mapIndexed { index, item ->
      Rect(
        item["left"] ?: error("rect at index $index doesn't contain 'left' property"),
        item["top"] ?: error("rect at index $index doesn't contain 'top' property"),
        item["right"] ?: error("rect at index $index doesn't contain 'right' property"),
        item["bottom"] ?: error("rect at index $index doesn't contain 'bottom' property")
      )
    }
}
