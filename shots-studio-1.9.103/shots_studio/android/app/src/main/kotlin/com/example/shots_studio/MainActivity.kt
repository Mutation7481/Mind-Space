package com.ansah.shots_studio

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentUris
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.content.FileProvider
import android.content.BroadcastReceiver
import android.content.Context
import android.content.IntentFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import java.io.File

class MainActivity : FlutterActivity() {
    private val UPDATE_CHANNEL = "update_installer"
    private val MEDIA_DELETE_CHANNEL = "media_delete"
    private val CAPTURE_CHANNEL = "mind_space_capture"
    private val INSTALL_REQUEST_CODE = 1001
    private val DELETE_REQUEST_CODE = 1002
    
    // Pending result for async delete operations
    private var pendingDeleteResult: MethodChannel.Result? = null
    private var pendingDeletePaths: List<String>? = null
    private var captureChannel: MethodChannel? = null

    private val privateMemoryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val path = intent?.getStringExtra("path")
            if (path != null) {
                captureChannel?.invokeMethod("onPrivateMemoryCaptured", path)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Mind Space Capture Channel
        captureChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CAPTURE_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPendingMemories" -> {
                        val prefs = getSharedPreferences("mind_space_capture", Context.MODE_PRIVATE)
                        val listJson = prefs.getString("pending_memories", "[]") ?: "[]"
                        val jsonArray = JSONArray(listJson)
                        val paths = mutableListOf<String>()
                        for (i in 0 until jsonArray.length()) {
                            paths.add(jsonArray.getString(i))
                        }
                        // Clear pending queue
                        prefs.edit().remove("pending_memories").apply()
                        result.success(paths)
                    }
                    "showCaptureNotification" -> {
                        QuickCaptureNotification.show(this@MainActivity)
                        result.success(true)
                    }
                    "dismissCaptureNotification" -> {
                        QuickCaptureNotification.dismiss(this@MainActivity)
                        result.success(true)
                    }
                    "triggerCapture" -> {
                        val intent = Intent(this@MainActivity, CaptureActivity::class.java).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }

        // Show persistent capture notification by default
        QuickCaptureNotification.show(this)

        val filter = IntentFilter("com.ansah.shots_studio.NEW_PRIVATE_MEMORY")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(privateMemoryReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(privateMemoryReceiver, filter)
        }
        
        // Update installer channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "canRequestPackageInstalls" -> {
                    result.success(canRequestPackageInstalls())
                }
                "requestInstallPermission" -> {
                    requestInstallPermission()
                    result.success(true)
                }
                "installApk" -> {
                    val apkPath = call.argument<String>("apkPath")
                    if (apkPath != null) {
                        try {
                            installApk(apkPath)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INSTALL_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "APK path is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Media delete channel - for batch deleting media files with single confirmation
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_DELETE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "deleteMediaFiles" -> {
                    val filePaths = call.argument<List<String>>("filePaths")
                    if (filePaths != null && filePaths.isNotEmpty()) {
                        deleteMediaFiles(filePaths, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "File paths list is required and cannot be empty", null)
                    }
                }
                "isSupported" -> {
                    // Batch delete with single dialog is supported on Android 11+
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.R)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun deleteMediaFiles(filePaths: List<String>, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ - Use MediaStore.createDeleteRequest for batch delete with single dialog
            try {
                val uris = mutableListOf<Uri>()
                
                for (path in filePaths) {
                    val uri = getMediaUriFromPath(path)
                    if (uri != null) {
                        uris.add(uri)
                    }
                }
                
                if (uris.isEmpty()) {
                    result.success(mapOf(
                        "success" to false,
                        "deletedCount" to 0,
                        "error" to "No valid media URIs found for the given paths"
                    ))
                    return
                }
                
                // Store pending result for onActivityResult callback
                pendingDeleteResult = result
                pendingDeletePaths = filePaths
                
                // Create delete request with all URIs - shows single confirmation dialog
                val pendingIntent = MediaStore.createDeleteRequest(contentResolver, uris)
                startIntentSenderForResult(
                    pendingIntent.intentSender,
                    DELETE_REQUEST_CODE,
                    null,
                    0,
                    0,
                    0
                )
                
            } catch (e: Exception) {
                result.success(mapOf(
                    "success" to false,
                    "deletedCount" to 0,
                    "error" to "Error creating delete request: ${e.message}"
                ))
            }
        } else {
            // Android 10 and below - Use direct file deletion
            var deletedCount = 0
            var errorMessage: String? = null
            
            for (path in filePaths) {
                try {
                    val file = File(path)
                    if (file.exists() && file.delete()) {
                        deletedCount++
                        // Also remove from MediaStore
                        contentResolver.delete(
                            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                            "${MediaStore.Images.Media.DATA}=?",
                            arrayOf(path)
                        )
                    }
                } catch (e: Exception) {
                    errorMessage = e.message
                }
            }
            
            val allDeleted = deletedCount == filePaths.size
            result.success(mapOf(
                "success" to allDeleted,
                "deletedCount" to deletedCount,
                "totalRequested" to filePaths.size,
                "error" to errorMessage
            ))
        }
    }
    
    private fun getMediaUriFromPath(path: String): Uri? {
        // Query MediaStore to get the URI for a file path
        val projection = arrayOf(MediaStore.Images.Media._ID)
        val selection = "${MediaStore.Images.Media.DATA}=?"
        val selectionArgs = arrayOf(path)
        
        contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
                val id = cursor.getLong(idColumn)
                return ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
            }
        }
        
        return null
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == DELETE_REQUEST_CODE) {
            val result = pendingDeleteResult
            val paths = pendingDeletePaths
            pendingDeleteResult = null
            pendingDeletePaths = null
            
            if (result != null) {
                if (resultCode == Activity.RESULT_OK) {
                    // User approved deletion
                    result.success(mapOf(
                        "success" to true,
                        "deletedCount" to (paths?.size ?: 0),
                        "totalRequested" to (paths?.size ?: 0),
                        "userApproved" to true
                    ))
                } else {
                    // User denied deletion
                    result.success(mapOf(
                        "success" to false,
                        "deletedCount" to 0,
                        "totalRequested" to (paths?.size ?: 0),
                        "userApproved" to false,
                        "error" to "User denied deletion request"
                    ))
                }
            }
        }
    }

    private fun canRequestPackageInstalls(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true // On older versions, this permission is granted by default
        }
    }

    private fun requestInstallPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (!packageManager.canRequestPackageInstalls()) {
                val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                    data = Uri.parse("package:$packageName")
                }
                startActivityForResult(intent, INSTALL_REQUEST_CODE)
            }
        }
    }

    private fun installApk(apkPath: String) {
        val apkFile = File(apkPath)
        if (!apkFile.exists()) {
            throw Exception("APK file not found: $apkPath")
        }

        val intent = Intent(Intent.ACTION_VIEW).apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // Use FileProvider for Android N and above
                val apkUri = FileProvider.getUriForFile(
                    this@MainActivity,
                    "$packageName.fileprovider",
                    apkFile
                )
                setDataAndType(apkUri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } else {
                // Direct file access for older versions
                setDataAndType(Uri.fromFile(apkFile), "application/vnd.android.package-archive")
            }
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        startActivity(intent)
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(privateMemoryReceiver)
        } catch (e: Exception) {
            // Receiver might not be registered
        }
        super.onDestroy()
    }
}
