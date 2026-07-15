package com.catchtales.catchtales

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        const val CHAT_CHANNEL = "com.catchtales.catchtales/chat"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Handle requests to open the chat in a separate window
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHAT_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openChat" -> {
                        val code = call.argument<String>("code") ?: ""
                        if (code.isNotEmpty()) {
                            val intent = Intent(this, ChatActivity::class.java).apply {
                                putExtra(ChatActivity.EXTRA_SESSION_CODE, code)
                                // Start as a new document so it appears as a separate entry in recent apps
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
    }
}
