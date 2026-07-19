package com.chatrizz.chatrizz

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    companion object {
        var flutterEngineRef: FlutterEngine? = null
    }

    private val CHANNEL = "com.chatrizz/overlay"
    private val REQUEST_CODE_OVERLAY = 1001

    private var mediaProjectionManager: MediaProjectionManager? = null
    private var savedResultCode: Int = 0
    private var savedResultData: Intent? = null
    private var pendingScreenshotPath: String? = null
    private var pendingProjectionCallback: ((Boolean) -> Unit)? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        WindowCompat.setDecorFitsSystemWindows(window, false)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val controller = WindowInsetsControllerCompat(window, window.decorView)
            controller.isAppearanceLightStatusBars = !isNightMode()
            controller.isAppearanceLightNavigationBars = !isNightMode()
        } else {
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        }

        mediaProjectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

        handleOverlayIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleOverlayIntent(intent)
    }

    private fun handleOverlayIntent(intent: Intent?) {
        if (intent?.getStringExtra("overlay_action") == "capture") {
            if (savedResultData != null) {
                val path = captureScreenshotSync()
                if (path != null) {
                    pendingScreenshotPath = path
                    notifyFlutterScreenshot(path)
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MainActivity.flutterEngineRef = flutterEngine

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startOverlay" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                        !android.provider.Settings.canDrawOverlays(this)) {
                        result.error("PERMISSION_DENIED", "Overlay permission not granted", null)
                        return@setMethodCallHandler
                    }
                    if (savedResultData == null) {
                        requestMediaProjection { success ->
                            if (success) {
                                startOverlayService()
                                result.success(true)
                            } else {
                                result.error("PERMISSION_DENIED", "Screen capture permission denied", null)
                            }
                        }
                    } else {
                        startOverlayService()
                        result.success(true)
                    }
                }
                "stopOverlay" -> {
                    stopOverlayService()
                    result.success(true)
                }
                "checkOverlayPermission" -> {
                    val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        android.provider.Settings.canDrawOverlays(this)
                    } else true
                    result.success(granted)
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            android.net.Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "isOverlayRunning" -> {
                    result.success(OverlayService.isRunning)
                }
                "getPendingScreenshot" -> {
                    result.success(pendingScreenshotPath)
                    pendingScreenshotPath = null
                }
                "setCategories" -> {
                    val cats = call.argument<List<String>>("categories")
                    if (cats != null) OverlayConfig.categories = cats
                    result.success(true)
                }
                "setGroqApiKey" -> {
                    val key = call.argument<String>("apiKey")
                    if (key != null) OverlayConfig.groqApiKey = key
                    result.success(true)
                }
                "getPendingCreditDeductions" -> {
                    val prefs = getSharedPreferences("chatrizz_credits", MODE_PRIVATE)
                    result.success(prefs.getInt("pending_credits", 0))
                }
                "clearPendingCreditDeductions" -> {
                    val prefs = getSharedPreferences("chatrizz_credits", MODE_PRIVATE)
                    prefs.edit().putInt("pending_credits", 0).apply()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Check if we have a pending screenshot to send
        if (pendingScreenshotPath != null) {
            notifyFlutterScreenshot(pendingScreenshotPath!!)
        }
    }

    private fun requestMediaProjection(onResult: (Boolean) -> Unit) {
        pendingProjectionCallback = onResult
        val intent = mediaProjectionManager?.createScreenCaptureIntent()
        startActivityForResult(intent, REQUEST_CODE_OVERLAY)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_OVERLAY) {
            if (resultCode == RESULT_OK && data != null) {
                savedResultCode = resultCode
                savedResultData = data
                ProjectionHolder.resultCode = resultCode
                ProjectionHolder.resultData = data
                startOverlayService()
                pendingProjectionCallback?.invoke(true)
            } else {
                pendingProjectionCallback?.invoke(false)
                stopOverlayService()
            }
            pendingProjectionCallback = null
        }
    }

    private fun startOverlayService() {
        val intent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_START
        }
        ContextCompat.startForegroundService(this, intent)
    }

    private fun stopOverlayService() {
        val intent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_STOP
        }
        startService(intent)
    }

    private fun captureScreenshotSync(): String? {
        if (savedResultData == null) return null

        val projection = mediaProjectionManager?.getMediaProjection(savedResultCode, savedResultData!!) ?: return null

        val metrics = DisplayMetrics()
        windowManager.defaultDisplay.getMetrics(metrics)
        val width = metrics.widthPixels
        val height = metrics.heightPixels
        val densityDpi = metrics.densityDpi

        var imageReader: ImageReader? = null
        var virtualDisplay: VirtualDisplay? = null
        var resultPath: String? = null
        val lock = Object()

        try {
            imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
            virtualDisplay = projection.createVirtualDisplay(
                "OverlayCapture",
                width, height, densityDpi,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader?.surface, null, null
            )

            imageReader?.setOnImageAvailableListener({ r ->
                val image = r.acquireLatestImage()
                if (image != null) {
                    val planes = image.planes
                    val buffer = planes[0].buffer
                    val pixelStride = planes[0].pixelStride
                    val rowStride = planes[0].rowStride

                    buffer.rewind()
                    val data = ByteArray(buffer.remaining())
                    buffer.get(data)
                    image.close()

                    val pixels = IntArray(width * height)
                    for (y in 0 until height) {
                        var rowOffset = y * rowStride
                        var pixelIdx = y * width
                        for (x in 0 until width) {
                            val pos = rowOffset + x * pixelStride
                            val r = data[pos].toInt() and 0xff
                            val g = data[pos + 1].toInt() and 0xff
                            val b = data[pos + 2].toInt() and 0xff
                            val a = data[pos + 3].toInt() and 0xff
                            pixels[pixelIdx + x] = (a shl 24) or (r shl 16) or (g shl 8) or b
                        }
                    }

                    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    bitmap.setPixels(pixels, 0, width, 0, 0, width, height)

                    val file = File(cacheDir, "overlay_screenshot.png")
                    FileOutputStream(file).use { out ->
                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                    }

                    bitmap.recycle()
                    resultPath = file.absolutePath
                }
                synchronized(lock) { lock.notify() }
            }, Handler(Looper.getMainLooper()))

            // Wait up to 2 seconds for the image
            synchronized(lock) {
                lock.wait(2000)
            }

        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            virtualDisplay?.release()
            imageReader?.close()
            projection.stop()
        }

        return resultPath
    }

    private fun notifyFlutterScreenshot(path: String) {
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            try {
                MethodChannel(messenger, CHANNEL).invokeMethod("onScreenshotCaptured", path)
            } catch (_: Exception) {}
        }
    }

    private fun isNightMode(): Boolean {
        val nightModeFlags = resources.configuration.uiMode and
            android.content.res.Configuration.UI_MODE_NIGHT_MASK
        return nightModeFlags == android.content.res.Configuration.UI_MODE_NIGHT_YES
    }
}
