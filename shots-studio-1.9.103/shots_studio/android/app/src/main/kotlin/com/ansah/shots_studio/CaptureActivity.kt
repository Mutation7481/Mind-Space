package com.ansah.shots_studio

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import android.view.WindowManager
import android.widget.Toast
import org.json.JSONArray
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer

class CaptureActivity : Activity() {

    private val REQUEST_SCREEN_CAPTURE = 1010
    private var mediaProjectionManager: MediaProjectionManager? = null
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Make activity transparent and non-focusable
        window.addFlags(WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE)

        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        if (mediaProjectionManager != null) {
            val captureIntent = mediaProjectionManager!!.createScreenCaptureIntent()
            startActivityForResult(captureIntent, REQUEST_SCREEN_CAPTURE)
        } else {
            Toast.makeText(this, "Screen capture service not available", Toast.LENGTH_SHORT).show()
            finish()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_SCREEN_CAPTURE) {
            if (resultCode == RESULT_OK && data != null) {
                startCapture(resultCode, data)
            } else {
                Toast.makeText(this, "Capture cancelled", Toast.LENGTH_SHORT).show()
                finish()
            }
        }
    }

    private fun startCapture(resultCode: Int, data: Intent) {
        val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val metrics = DisplayMetrics()
        
        val width: Int
        val height: Int
        val density: Int

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val windowMetrics = windowManager.currentWindowMetrics
            val bounds = windowMetrics.bounds
            width = bounds.width()
            height = bounds.height()
            density = resources.configuration.densityDpi
        } else {
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay.getRealMetrics(metrics)
            width = metrics.widthPixels
            height = metrics.heightPixels
            density = metrics.densityDpi
        }

        // Android 14+ requires starting foreground service before mediaProjection
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val serviceIntent = Intent(this, MediaProjectionService::class.java).apply {
                action = MediaProjectionService.ACTION_START
            }
            startForegroundService(serviceIntent)
        }

        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)

        mainHandler.postDelayed({
            try {
                mediaProjection = mediaProjectionManager?.getMediaProjection(resultCode, data)

                if (mediaProjection == null) {
                    cleanup()
                    finish()
                    return@postDelayed
                }

                virtualDisplay = mediaProjection?.createVirtualDisplay(
                    "MindSpaceScreenCapture",
                    width,
                    height,
                    density,
                    DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                    imageReader?.surface,
                    null,
                    mainHandler
                )

                // Wait a moment for frame to be rendered
                mainHandler.postDelayed({
                    acquireAndSaveImage(width, height)
                }, 400)

            } catch (e: Exception) {
                e.printStackTrace()
                Toast.makeText(this, "Error during capture: ${e.message}", Toast.LENGTH_SHORT).show()
                cleanup()
                finish()
            }
        }, 150)
    }

    private fun acquireAndSaveImage(width: Int, height: Int) {
        var image: Image? = null
        try {
            image = imageReader?.acquireLatestImage()
            if (image != null) {
                val planes = image.planes
                val buffer: ByteBuffer = planes[0].buffer
                val pixelStride = planes[0].pixelStride
                val rowStride = planes[0].rowStride
                val rowPadding = rowStride - pixelStride * width

                val bitmap = Bitmap.createBitmap(
                    width + rowPadding / pixelStride,
                    height,
                    Bitmap.Config.ARGB_8888
                )
                bitmap.copyPixelsFromBuffer(buffer)

                // Crop to exact width if padding exists
                val finalBitmap = if (rowPadding > 0) {
                    Bitmap.createBitmap(bitmap, 0, 0, width, height)
                } else {
                    bitmap
                }

                // Save strictly to app-private storage so it NEVER enters the user's gallery
                val privateDir = File(filesDir, "private_memories")
                if (!privateDir.exists()) {
                    privateDir.mkdirs()
                }
                // Write .nomedia file as extra assurance against any media scanner
                val noMedia = File(privateDir, ".nomedia")
                if (!noMedia.exists()) {
                    noMedia.createNewFile()
                }

                val timestamp = System.currentTimeMillis()
                val outputFile = File(privateDir, "memory_$timestamp.png")
                FileOutputStream(outputFile).use { out ->
                    finalBitmap.compress(Bitmap.CompressFormat.PNG, 95, out)
                }

                // Store in SharedPreferences pending queue so Flutter receives it
                val prefs = getSharedPreferences("mind_space_capture", Context.MODE_PRIVATE)
                val existingListJson = prefs.getString("pending_memories", "[]") ?: "[]"
                val jsonArray = JSONArray(existingListJson)
                jsonArray.put(outputFile.absolutePath)
                prefs.edit().putString("pending_memories", jsonArray.toString()).apply()

                // Broadcast intent to MainActivity if running
                val broadcast = Intent("com.ansah.shots_studio.NEW_PRIVATE_MEMORY").apply {
                    putExtra("path", outputFile.absolutePath)
                    setPackage(packageName)
                }
                sendBroadcast(broadcast)

                Toast.makeText(this, "✨ Memory saved to Mind Space! Processing...", Toast.LENGTH_LONG).show()
            } else {
                Toast.makeText(this, "Failed to acquire screen frame", Toast.LENGTH_SHORT).show()
            }
        } catch (e: Exception) {
            e.printStackTrace()
            Toast.makeText(this, "Error saving memory: ${e.message}", Toast.LENGTH_SHORT).show()
        } finally {
            image?.close()
            cleanup()
            finish()
        }
    }

    private fun cleanup() {
        try {
            virtualDisplay?.release()
            virtualDisplay = null
            imageReader?.close()
            imageReader = null
            mediaProjection?.stop()
            mediaProjection = null

            val stopServiceIntent = Intent(this, MediaProjectionService::class.java).apply {
                action = MediaProjectionService.ACTION_STOP
            }
            startService(stopServiceIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        cleanup()
        super.onDestroy()
    }
}
