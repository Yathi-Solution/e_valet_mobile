package com.yathi.evalet

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.speech.tts.TextToSpeech
import android.util.Log
import androidx.annotation.NonNull
import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService
import java.util.Locale
import java.util.UUID

/**
 * Custom FCM service that plays the retrieval-alert sound, speaks the
 * notification body aloud, and starts a repeating vibration alert when the
 * app is in background or terminated.
 * Extends Flutter's service so the Dart background handler and notification
 * display still work normally.
 */
class ValetFirebaseMessagingService : FlutterFirebaseMessagingService() {

    override fun onMessageReceived(@NonNull remoteMessage: RemoteMessage) {
        Log.d(TAG, "onMessageReceived called — type=${remoteMessage.data["type"]} " +
                "hasNotification=${remoteMessage.notification != null}")

        if (remoteMessage.data["type"] == "retrieval_request") {
            // Play the custom level-up alert sound
            playRetrievalSound()
            // Also start the repeating vibration pattern
            startRepeatingVibration()
        }

        // Speak notification body aloud (loud, hearable) when app is in background/terminated
        val body = remoteMessage.notification?.body
        val title = remoteMessage.notification?.title
        val textToSpeak = when {
            !body.isNullOrBlank() -> body
            !title.isNullOrBlank() -> title
            else -> null
        }
        if (!textToSpeak.isNullOrBlank()) {
            speakWithTts(textToSpeak)
        }
        super.onMessageReceived(remoteMessage)
    }

    /**
     * Play retrieval_alert.mp3 from res/raw once using MediaPlayer at full volume.
     * We fire-and-forget (no loop) — the repeating vibration + the foreground
     * AudioPlayer loop (started in Dart when the sheet opens) cover the rest.
     */
    private fun playRetrievalSound() {
        try {
            val resId = resources.getIdentifier("retrieval_alert", "raw", packageName)
            if (resId == 0) {
                Log.w(TAG, "retrieval_alert raw resource not found")
                return
            }
            val player = MediaPlayer()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                player.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            val afd = resources.openRawResourceFd(resId)
            player.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
            afd.close()
            player.setVolume(1.0f, 1.0f)
            player.prepare()
            player.setOnCompletionListener { it.release() }
            player.start()
            Log.d(TAG, "Retrieval alert sound started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to play retrieval alert sound: ${e.message}")
        }
    }

    /**
     * Vibrate with a repeating pattern (700 ms on / 500 ms off) until cancelled.
     * The Flutter VibrationController.stop() → Vibration.cancel() call from Dart
     * will cancel this when the driver accepts or passes the request, because
     * both use the same system Vibrator for the app's UID.
     */
    private fun startRepeatingVibration() {
        try {
            // pattern: [delay, vibrate, pause, vibrate, ...] in milliseconds
            val pattern = longArrayOf(0L, 700L, 500L, 700L)
            val repeatIndex = 0 // repeat the whole waveform from the start

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Android 12+ — VibratorManager is the recommended API
                val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vm.defaultVibrator.vibrate(
                    VibrationEffect.createWaveform(pattern, repeatIndex)
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Android 8–11
                @Suppress("DEPRECATION")
                val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, repeatIndex))
            } else {
                // Android < 8 — deprecated API, still works
                @Suppress("DEPRECATION")
                val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                @Suppress("DEPRECATION")
                vibrator.vibrate(pattern, repeatIndex)
            }
            Log.d(TAG, "Repeating vibration started for retrieval_request")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start vibration: ${e.message}")
        }
    }

    private fun speakWithTts(text: String) {
        val utteranceId = "valet_tts_${UUID.randomUUID()}"
        var ttsRef: TextToSpeech? = null
        ttsRef = TextToSpeech(applicationContext) { status ->
            val tts = ttsRef ?: return@TextToSpeech
            if (status != TextToSpeech.SUCCESS) {
                Log.e(TAG, "TTS init failed: $status")
                tts.shutdown()
                return@TextToSpeech
            }
            if (tts.setLanguage(Locale.getDefault()) >= 0) {
                tts.setSpeechRate(0.45f)
                tts.setOnUtteranceProgressListener(object : android.speech.tts.UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) {}
                    override fun onDone(utteranceId: String?) {
                        tts.stop()
                        tts.shutdown()
                    }
                    override fun onError(utteranceId: String?) {
                        tts.shutdown()
                    }
                    override fun onError(utteranceId: String?, errorCode: Int) {
                        tts.shutdown()
                    }
                })
                val params = Bundle().apply { putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, utteranceId) }
                tts.speak(text, TextToSpeech.QUEUE_FLUSH, params, utteranceId)
                Log.d(TAG, "TTS speaking (background): $text")
            } else {
                Log.e(TAG, "TTS setLanguage failed")
                tts.shutdown()
            }
        }
    }

    companion object {
        private const val TAG = "ValetFCM"
    }
}
