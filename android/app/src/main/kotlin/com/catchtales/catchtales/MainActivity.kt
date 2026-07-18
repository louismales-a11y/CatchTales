package com.catchtales.catchtales

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        const val CHAT_CHANNEL = "com.catchtales.catchtales/chat"
        const val INSTALL_CHANNEL = "com.catchtales.catchtales/install"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Channel: open chat in separate window
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHAT_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openChat" -> {
                        val code = call.argument<String>("code") ?: ""
                        if (code.isNotEmpty()) {
                            val intent = Intent(this, ChatActivity::class.java).apply {
                                putExtra(ChatActivity.EXTRA_SESSION_CODE, code)
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NEW_DOCUMENT
                                addFlags(Intent.FLAG_ACTIVITY_MULTIPLE_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.error("NO_CODE", "No session code provided", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // Channel: install downloaded APK
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTALL_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installApk" -> {
                        val filePath = call.argument<String>("path") ?: ""
                        if (filePath.isNotEmpty()) {
                            try {
                                val file = File(filePath)
                                val uri = FileProvider.getUriForFile(
                                    this,
                                    "${packageName}.fileprovider",
                                    file
                                )
                                val intent = Intent(Intent.ACTION_INSTALL_PACKAGE).apply {
                                    data = uri
                                    flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("INSTALL_FAILED", e.message, null)
                            }
                        } else {
                            result.error("NO_PATH", "No file path provided", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
