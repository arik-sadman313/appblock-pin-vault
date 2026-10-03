package com.example.appblock_pin_vault

import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class SecurityService(private val context: Context) {

    companion object {
        private const val KEY_ALIAS = "AppBlockPinVaultKey"
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val PREFS_NAME = "secure_prefs"
        private const val KEY_CIPHERTEXT = "pin_ciphertext"
        private const val KEY_IV = "pin_iv"
        private const val GCM_TAG_LENGTH = 128
    }

    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private fun getSecretKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        
        if (!keyStore.containsAlias(KEY_ALIAS)) {
            val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
            val keyGenParameterSpec = KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true)
                .build()
            
            keyGenerator.init(keyGenParameterSpec)
            return keyGenerator.generateKey()
        }

        return keyStore.getKey(KEY_ALIAS, null) as SecretKey
    }

    fun encryptAndStorePin(pin: String): Boolean {
        return try {
            val secretKey = getSecretKey()
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.ENCRYPT_MODE, secretKey)
            
            val ciphertext = cipher.doFinal(pin.toByteArray(Charsets.UTF_8))
            val iv = cipher.iv

            prefs.edit()
                .putString(KEY_CIPHERTEXT, Base64.encodeToString(ciphertext, Base64.DEFAULT))
                .putString(KEY_IV, Base64.encodeToString(iv, Base64.DEFAULT))
                .apply()
                
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    fun decryptPin(): String? {
        return try {
            val ciphertext64 = prefs.getString(KEY_CIPHERTEXT, null)
            val iv64 = prefs.getString(KEY_IV, null)
            
            if (ciphertext64 == null || iv64 == null) return null

            val ciphertext = Base64.decode(ciphertext64, Base64.DEFAULT)
            val iv = Base64.decode(iv64, Base64.DEFAULT)

            val secretKey = getSecretKey()
            val cipher = Cipher.getInstance(TRANSFORMATION)
            val spec = GCMParameterSpec(GCM_TAG_LENGTH, iv)
            cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)

            val plaintext = cipher.doFinal(ciphertext)
            String(plaintext, Charsets.UTF_8)
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    fun deletePin(): Boolean {
        return try {
            val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
            if (keyStore.containsAlias(KEY_ALIAS)) {
                keyStore.deleteEntry(KEY_ALIAS)
            }
            prefs.edit().clear().apply()
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
