package com.chatrizz.chatrizz

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.DisplayMetrics
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextView
import androidx.core.app.NotificationCompat
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import com.google.android.gms.tasks.Tasks
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class OverlayService : Service() {

    private lateinit var windowManager: WindowManager
    private var bubbleView: View? = null
    private var bubbleParams: WindowManager.LayoutParams? = null
    private var resultPanel: View? = null
    private var mediaProjection: MediaProjection? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        const val ACTION_START = "com.chatrizz.overlay.START"
        const val ACTION_STOP = "com.chatrizz.overlay.STOP"
        var isRunning = false
            private set
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startOverlay()
            ACTION_STOP -> stopOverlay()
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopOverlay()
        super.onDestroy()
    }

    private fun startOverlay() {
        if (isRunning) return
        isRunning = true
        createNotificationChannel()
        startForeground(1001, createNotification())
        showBubble()
        initMediaProjection()
    }

    private fun initMediaProjection() {
        val data = ProjectionHolder.resultData ?: return
        val mgr = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        try {
            mediaProjection = mgr.getMediaProjection(ProjectionHolder.resultCode, data)
        } catch (_: Exception) {}
    }

    private fun hideBubble() {
        bubbleView?.let {
            try { windowManager.removeView(it) } catch (_: Exception) {}
        }
        bubbleView = null
    }

    private fun showBubble() {
        if (bubbleView != null) return
        val density = resources.displayMetrics.density
        val size = (56 * density).toInt()

        val bubble = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_menu_edit)
            layoutParams = FrameLayout.LayoutParams(size, size)
            scaleType = ImageView.ScaleType.FIT_CENTER
            setPadding((14 * density).toInt(), (14 * density).toInt(),
                (14 * density).toInt(), (14 * density).toInt())
            setColorFilter(Color.WHITE)
            setBackgroundResource(R.drawable.overlay_bubble_bg)
        }

        val prev = bubbleParams
        val params = WindowManager.LayoutParams(
            size, size,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = prev?.x ?: 0
            y = prev?.y ?: (200 * density).toInt()
        }
        bubbleParams = params

        bubble.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0; private var initialY = 0
            private var initialTouchX = 0f; private var initialTouchY = 0f
            private var isDragging = false
            private var longPressTriggered = false
            private val longPressHandler = Handler(Looper.getMainLooper())
            private val dismissThreshold = (150 * density).toInt()
            private val screenHeight = resources.displayMetrics.heightPixels
            private val longPressRunnable = Runnable {
                longPressTriggered = true
                notifyOverlayDismissed()
            }

            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = params.x; initialY = params.y
                        initialTouchX = event.rawX; initialTouchY = event.rawY
                        isDragging = false; longPressTriggered = false
                        longPressHandler.postDelayed(longPressRunnable, 600)
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dx = (event.rawX - initialTouchX).toInt()
                        val dy = (event.rawY - initialTouchY).toInt()
                        if (Math.abs(dx) > 15 || Math.abs(dy) > 15) {
                            isDragging = true
                            longPressHandler.removeCallbacks(longPressRunnable)
                        }
                        params.x = initialX + dx; params.y = initialY + dy
                        windowManager.updateViewLayout(v, params)

                        // Visual feedback when near bottom
                        val nearBottom = params.y + size + dismissThreshold > screenHeight
                        v.alpha = if (nearBottom) 0.4f else 1.0f
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        longPressHandler.removeCallbacks(longPressRunnable)
                        v.alpha = 1.0f
                        if (longPressTriggered) return true
                        if (isDragging) {
                            if (params.y + size + dismissThreshold > screenHeight) {
                                notifyOverlayDismissed()
                            }
                        } else {
                            onBubbleTap(params.x, params.y)
                        }
                        return true
                    }
                    MotionEvent.ACTION_CANCEL -> {
                        longPressHandler.removeCallbacks(longPressRunnable)
                        v.alpha = 1.0f
                        return true
                    }
                }
                return false
            }

            private fun notifyOverlayDismissed() {
                stopOverlay()
                try {
                    val engine = com.chatrizz.chatrizz.MainActivity.Companion.flutterEngineRef
                    if (engine != null) {
                        MethodChannel(engine.dartExecutor.binaryMessenger, "com.chatrizz/overlay")
                            .invokeMethod("onOverlayDismissed", null)
                    }
                } catch (_: Exception) {}
            }
        })

        bubbleView = bubble
        windowManager.addView(bubble, params)
    }

    private fun onBubbleTap(bubbleX: Int, bubbleY: Int) {
        hideResultPanel()
        hideBubble()
        captureAndProcess(bubbleX, bubbleY)
    }

    private fun showProcessingPanel(x: Int, y: Int) {
        hideResultPanel()
        val density = resources.displayMetrics.density
        val widthPx = (280 * density).toInt()

        val panel = FrameLayout(this).apply {
            setBackgroundColor(Color.BLACK)
        }

        val progressBar = ProgressBar(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                (48 * density).toInt(), (48 * density).toInt(), Gravity.CENTER
            )
        }

        val loadingText = TextView(this).apply {
            text = "Analyzing chat..."
            setTextColor(Color.WHITE)
            textSize = 14f
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT, Gravity.CENTER
            )
            translationY = 48f * density
        }

        panel.addView(progressBar)
        panel.addView(loadingText)

        val panelParams = WindowManager.LayoutParams(
            widthPx, (160 * density).toInt(),
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            this.x = if (x + widthPx > resources.displayMetrics.widthPixels) x - widthPx else x + (56 * density).toInt()
            this.y = y
        }

        resultPanel = panel
        try { windowManager.addView(panel, panelParams) } catch (_: Exception) {}
    }

    private fun hideResultPanel() {
        resultPanel?.let {
            try { windowManager.removeView(it) } catch (_: Exception) {}
        }
        resultPanel = null
    }

    private fun captureAndProcess(bubbleX: Int, bubbleY: Int) {
        executor.execute {
            try {
                mainHandler.post {
                    showProcessingPanel(bubbleX, bubbleY)
                    showBubble()
                }

                val screenshotPath = captureScreenshot()
                if (screenshotPath == null) {
                    showError("Failed to capture screen")
                    return@execute
                }

                val text = doOcr(screenshotPath)
                if (text.isNullOrBlank()) {
                    showError("No text found in screenshot")
                    return@execute
                }

                val suggestions = getAiSuggestions(text)
                if (suggestions.isNullOrBlank()) {
                    showError("Failed to get AI suggestions")
                    return@execute
                }

                notifyCreditUsed()
                showSuggestions(suggestions, bubbleX, bubbleY)
            } catch (e: Exception) {
                showError("Error: ${e.message}")
            }
        }
    }

    private fun captureScreenshot(): String? {
        val proj = mediaProjection ?: return null
        val metrics = DisplayMetrics()
        windowManager.defaultDisplay.getMetrics(metrics)
        val width = metrics.widthPixels; val height = metrics.heightPixels
        val densityDpi = metrics.densityDpi

        var imageReader: ImageReader? = null
        var virtualDisplay: VirtualDisplay? = null
        var resultPath: String? = null
        val latch = CountDownLatch(1)

        try {
            imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 3)
            virtualDisplay = proj.createVirtualDisplay(
                "OverlayCapture", width, height, densityDpi,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader?.surface, null, null
            )

            var frameCount = 0
            imageReader?.setOnImageAvailableListener({ r ->
                frameCount++
                if (frameCount < 3) {
                    r.acquireLatestImage()?.close()
                    return@setOnImageAvailableListener
                }
                try {
                    val image = r.acquireLatestImage() ?: return@setOnImageAvailableListener
                    try {
                        val planes = image.planes
                        if (planes.size < 1) return@setOnImageAvailableListener
                        val buffer = planes[0].buffer
                        val pixelStride = planes[0].pixelStride
                        val rowStride = planes[0].rowStride

                        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                        val pixels = IntArray(width * height)
                        buffer.rewind()

                        var idx = 0
                        for (y in 0 until height) {
                            var rowPos = y * rowStride
                            for (x in 0 until width) {
                                val pos = rowPos + x * pixelStride
                                val r = buffer.get(pos).toInt() and 0xff
                                val g = buffer.get(pos + 1).toInt() and 0xff
                                val b = buffer.get(pos + 2).toInt() and 0xff
                                val a = buffer.get(pos + 3).toInt() and 0xff
                                pixels[idx++] = (a shl 24) or (r shl 16) or (g shl 8) or b
                            }
                        }

                        bitmap.setPixels(pixels, 0, width, 0, 0, width, height)

                        val file = File(cacheDir, "overlay_screenshot.png")
                        FileOutputStream(file).use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
                        bitmap.recycle()
                        resultPath = file.absolutePath
                        latch.countDown()
                    } catch (e: Exception) {
                        e.printStackTrace()
                        latch.countDown()
                    } finally {
                        image.close()
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                    latch.countDown()
                }
            }, Handler(Looper.getMainLooper()))

            latch.await(5, TimeUnit.SECONDS)
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            virtualDisplay?.release()
            imageReader?.close()
        }
        return resultPath
    }

    private fun doOcr(imagePath: String): String? {
        return try {
            val file = File(imagePath)
            if (!file.exists()) return null
            val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
            val inputImage = InputImage.fromFilePath(this, Uri.fromFile(file))
            val result = Tasks.await(recognizer.process(inputImage))
            recognizer.close()
            result.text
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun getAiSuggestions(text: String): String? {
        return try {
            val apiKey = com.chatrizz.chatrizz.OverlayConfig.groqApiKey
            if (apiKey.isBlank()) return "Error: Groq API key not configured"
            val url = URL("https://api.groq.com/openai/v1/chat/completions")
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "application/json")
            conn.setRequestProperty("Authorization", "Bearer $apiKey")
            conn.doOutput = true
            conn.connectTimeout = 30000
            conn.readTimeout = 30000

            val cats = OverlayConfig.categories
            val catList = cats.joinToString(", ")
            val catFormat = cats.mapIndexed { i, c -> "${i + 1}. [$c] <text>" }.joinToString("\n")

            val prompt = """Analyze this chat screenshot text and suggest ${cats.size} reply options ($catList). Keep each under 15 words. Format as:
=== Reply Options ===
$catFormat

Chat text: $text"""

            val body = """{"model":"llama-3.1-8b-instant","messages":[{"role":"system","content":"You are ChatRizz, an AI dating assistant."},{"role":"user","content":"${prompt.replace("\"", "\\\"").replace("\n", "\\n")}"}],"temperature":0.8,"max_tokens":500}"""

            OutputStreamWriter(conn.outputStream).use { it.write(body) }

            val response = conn.inputStream.bufferedReader().readText()
            conn.disconnect()

            // Parse JSON response
            val json = org.json.JSONObject(response)
            val choices = json.getJSONArray("choices")
            if (choices.length() > 0) {
                val message = choices.getJSONObject(0).getJSONObject("message")
                message.getString("content")
            } else null
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun showSuggestions(suggestions: String, bubbleX: Int, bubbleY: Int) {
        mainHandler.post {
            hideResultPanel()
            val density = resources.displayMetrics.density
            val panelWidth = (300 * density).toInt()

            // Parse suggestions into lines
            val lines = suggestions.split("\n").filter { it.isNotBlank() }
            val suggestionItems = mutableListOf<String>()
            for (line in lines) {
                val trimmed = line.trim()
                if (trimmed.matches(Regex("^[\\d.]*\\s*\\[.*\\].*"))) {
                    suggestionItems.add(trimmed)
                }
            }

            // If no parsed items, just show raw text
            if (suggestionItems.isEmpty()) {
                for (line in lines) {
                    if (line.trim().isNotBlank()) suggestionItems.add(line.trim())
                }
            }

            val container = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setPadding((12 * density).toInt(), (12 * density).toInt(),
                    (12 * density).toInt(), (12 * density).toInt())
            }

            // Title
            container.addView(TextView(this).apply {
                text = "AI Suggestions"
                setTextColor(Color.WHITE)
                textSize = 16f
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                setPadding(0, 0, 0, (8 * density).toInt())
            })

            // Close button
            val closeBtn = TextView(this).apply {
                text = "✕"
                setTextColor(Color.argb(180, 255, 255, 255))
                textSize = 18f
                gravity = Gravity.END
                setOnClickListener { hideResultPanel() }
            }
            val closeContainer = FrameLayout(this)
            closeContainer.addView(closeBtn, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ))
            container.addView(closeContainer)

            // Suggestion items
            for (item in suggestionItems) {
                val itemContainer = LinearLayout(this).apply {
                    orientation = LinearLayout.HORIZONTAL
                    setPadding((10 * density).toInt(), (10 * density).toInt(),
                        (10 * density).toInt(), (10 * density).toInt())
                    setBackgroundColor(Color.argb(200, 0, 0, 0))
                }

                val itemParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.WRAP_CONTENT
                )
                itemParams.setMargins(0, 0, 0, (6 * density).toInt())
                itemContainer.layoutParams = itemParams

                val suggestionText = item.replace(Regex("^[\\d.]*\\s*"), "").trim()
                val copyText = suggestionText.replace(Regex("^\\[.*?\\]\\s*"), "").trim()
                val textView = TextView(this).apply {
                    text = suggestionText
                    setTextColor(Color.WHITE)
                    textSize = 14f
                    typeface = Typeface.DEFAULT_BOLD
                    layoutParams = LinearLayout.LayoutParams(0, FrameLayout.LayoutParams.WRAP_CONTENT, 1f)
                }

                val copyBtn = Button(this).apply {
                    text = "Copy"
                    setTextColor(Color.WHITE)
                    textSize = 12f
                    setBackgroundColor(Color.argb(255, 60, 60, 60))
                    setPadding((12 * density).toInt(), (4 * density).toInt(),
                        (12 * density).toInt(), (4 * density).toInt())
                    layoutParams = LinearLayout.LayoutParams(
                        FrameLayout.LayoutParams.WRAP_CONTENT,
                        FrameLayout.LayoutParams.WRAP_CONTENT
                    )
                    setOnClickListener {
                        val clipboard = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
                        clipboard.setPrimaryClip(ClipData.newPlainText("ChatRizz", copyText))
                        this.text = "Copied!"
                        mainHandler.postDelayed({ this.text = "Copy" }, 1500)
                    }
                }

                itemContainer.addView(textView)
                itemContainer.addView(copyBtn)
                container.addView(itemContainer)
            }

            val scrollView = ScrollView(this).apply {
                addView(container)
            }

            val panelParams = WindowManager.LayoutParams(
                panelWidth, FrameLayout.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                else WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                this.x = if (bubbleX + panelWidth > resources.displayMetrics.widthPixels) bubbleX - panelWidth else bubbleX + (70 * density).toInt()
                this.y = bubbleY
            }

            // Add touch outside to dismiss
            scrollView.setOnTouchListener { _, event ->
                if (event.action == MotionEvent.ACTION_OUTSIDE) {
                    hideResultPanel()
                    return@setOnTouchListener true
                }
                false
            }

            resultPanel = scrollView
            try { windowManager.addView(scrollView, panelParams) } catch (_: Exception) {}
        }
    }

    private fun showError(message: String) {
        mainHandler.post {
            hideResultPanel()
            val density = resources.displayMetrics.density

            val text = TextView(this).apply {
                this.text = message
                setTextColor(Color.argb(255, 255, 100, 100))
                textSize = 14f
                gravity = Gravity.CENTER
                setPadding((16 * density).toInt(), (16 * density).toInt(),
                    (16 * density).toInt(), (16 * density).toInt())
                setBackgroundColor(Color.BLACK)
                setOnClickListener { hideResultPanel() }
            }

            val params = WindowManager.LayoutParams(
                (250 * density).toInt(), FrameLayout.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                else WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.CENTER
            }

            resultPanel = text
            try { windowManager.addView(text, params) } catch (_: Exception) {}
        }
    }

    private fun notifyCreditUsed() {
        try {
            val prefs = getSharedPreferences("chatrizz_credits", MODE_PRIVATE)
            val total = prefs.getInt("pending_credits", 0) + 2
            prefs.edit().putInt("pending_credits", total).apply()
        } catch (_: Exception) {}

        try {
            val engine = com.chatrizz.chatrizz.MainActivity.Companion.flutterEngineRef
            if (engine != null) {
                MethodChannel(engine.dartExecutor.binaryMessenger, "com.chatrizz/overlay")
                    .invokeMethod("onCreditUsed", null)
            }
        } catch (_: Exception) {}
    }

    private fun stopOverlay() {
        isRunning = false
        hideResultPanel()
        bubbleView?.let {
            try { windowManager.removeView(it) } catch (_: Exception) {}
        }
        bubbleView = null
        mediaProjection?.stop()
        mediaProjection = null
        try {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        } catch (_: Exception) {}
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel("chatrizz_overlay", "ChatRizz Overlay", NotificationManager.IMPORTANCE_LOW)
        (getSystemService(NotificationManager::class.java)).createNotificationChannel(channel)
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, "chatrizz_overlay")
            .setContentTitle("ChatRizz Overlay")
            .setContentText("Tap for AI chat suggestions")
            .setSmallIcon(android.R.drawable.ic_menu_edit)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
