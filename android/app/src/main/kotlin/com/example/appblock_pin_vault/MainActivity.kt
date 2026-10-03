package com.example.appblock_pin_vault

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.appblock_pin_vault/security"
    private lateinit var securityService: SecurityService

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        securityService = SecurityService(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "encryptAndStorePin" -> {
                    val pin = call.argument<String>("pin")
                    if (pin != null) {
                        val success = securityService.encryptAndStorePin(pin)
                        if (success) {
                            result.success(true)
                        } else {
                            result.error("ENCRYPTION_FAILED", "Failed to encrypt and store PIN", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "PIN cannot be null", null)
                    }
                }
                "decryptPin" -> {
                    val pin = securityService.decryptPin()
                    if (pin != null) {
                        result.success(pin)
                    } else {
                        result.error("DECRYPTION_FAILED", "Failed to decrypt PIN or PIN not found", null)
                    }
                }
                "deletePin" -> {
                    val success = securityService.deletePin()
                    if (success) {
                        result.success(true)
                    } else {
                        result.error("DELETION_FAILED", "Failed to delete PIN", null)
                    }
                }
                "setSecureMode" -> {
                    val secure = call.argument<Boolean>("secure") ?: false
                    if (secure) {
                        window.addFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(true)
                }
                "getElapsedRealtime" -> {
                    result.success(android.os.SystemClock.elapsedRealtime())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
