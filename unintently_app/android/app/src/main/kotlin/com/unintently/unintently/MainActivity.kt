package com.unintently.unintently

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.unintently.app/deeplink"
    private var pendingLink: String? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val action = intent?.action
        val data = intent?.dataString
        if (Intent.ACTION_VIEW == action && data != null) {
            pendingLink = data
            methodChannel?.invokeMethod("onDeepLink", data)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> {
                    val link = pendingLink
                    pendingLink = null
                    result.success(link)
                }
                "clearPendingLink" -> {
                    pendingLink = null
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        pendingLink?.let {
            methodChannel?.invokeMethod("onDeepLink", it)
        }
    }
}
