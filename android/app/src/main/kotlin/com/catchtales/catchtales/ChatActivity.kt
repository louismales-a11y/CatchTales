package com.catchtales.catchtales

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Second FlutterActivity for the fishing room chat.
/// Opens as a separate task so it appears as its own card in the recent apps switcher.
class ChatActivity : FlutterActivity() {
    companion object {
        const val EXTRA_SESSION_CODE = "session_code"
        const val CHANNEL = "com.catchtales.catchtales/chat"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Pass the session code from the intent to Flutter via MethodChannel
        val sessionCode = intent.getStringExtra(EXTRA_SESSION_CODE) ?: ""
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSessionCode") {
                result.success(sessionCode)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
