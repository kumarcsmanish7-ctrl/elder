package com.example.elderlyapp

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import android.os.*
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.telephony.SmsManager
import android.view.View
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import java.util.*
import kotlin.math.sqrt

class MainActivity : AppCompatActivity(), SensorEventListener {

    private lateinit var statusText: TextView
    private lateinit var sosButton: Button

    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null

    private lateinit var tts: TextToSpeech
    private lateinit var speechRecognizer: SpeechRecognizer

    // 🔧 Logic parameters
    private val FALL_THRESHOLD = 158.0
    private val RESPONSE_TIMEOUT = 8000L
    private val COOLDOWN = 6000L

    private var lastFallTime = 0L
    private var waitingForResponse = false

    private val EMERGENCY_NUMBER = "9886711909" // CHANGE

    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        statusText = findViewById(R.id.statusText)
        sosButton = findViewById(R.id.sosButton)

        statusText.text = "Monitoring active ✅"
        sosButton.visibility = View.GONE

        createForegroundNotification()
        requestPermissions()

        // SOS button click
        sosButton.setOnClickListener {
            triggerSOS("SOS button pressed")
        }

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        sensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_NORMAL)

        tts = TextToSpeech(this) {
            if (it == TextToSpeech.SUCCESS) {
                tts.language = Locale.US
            }
        }

        setupSpeechRecognizer()
    }

    // ================= FALL DETECTION =================

    override fun onSensorChanged(event: SensorEvent) {
        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]

        val magnitude = sqrt(x * x + y * y + z * z)

        if (magnitude > FALL_THRESHOLD && !waitingForResponse) {
            val now = System.currentTimeMillis()
            if (now - lastFallTime > COOLDOWN) {
                lastFallTime = now
                onFallDetected()
            }
        }
    }

    private fun onFallDetected() {
        waitingForResponse = true
        statusText.text = "⚠️ Fall detected"
        sosButton.visibility = View.VISIBLE

        tts.speak(
            "Are you okay? Please say okay or help.",
            TextToSpeech.QUEUE_FLUSH,
            null,
            "FALL"
        )

        handler.postDelayed({ startListening() }, 3000)

        // ⏱️ No response → SOS
        handler.postDelayed({
            if (waitingForResponse) {
                triggerSOS("No response")
            }
        }, RESPONSE_TIMEOUT)
    }

    // ================= SPEECH =================

    private fun setupSpeechRecognizer() {
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer.setRecognitionListener(object : RecognitionListener {

            override fun onResults(results: Bundle?) {
                val spoken = results
                    ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    ?.firstOrNull()
                    ?.lowercase()
                    ?.trim()

                if (spoken != null) {
                    handleSpeech(spoken)
                }
            }

            override fun onError(error: Int) {
                if (waitingForResponse) startListening()
            }

            override fun onReadyForSpeech(params: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {}
            override fun onPartialResults(partialResults: Bundle?) {}
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
    }

    private fun startListening() {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
        intent.putExtra(
            RecognizerIntent.EXTRA_LANGUAGE_MODEL,
            RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
        )
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.US)
        speechRecognizer.startListening(intent)
    }

    private fun handleSpeech(text: String) {
        when {
            text.contains("okay") || text.contains("fine") -> {
                waitingForResponse = false
                sosButton.visibility = View.GONE
                statusText.text = "User is safe ✅"
                tts.speak("Okay. Stay safe.", TextToSpeech.QUEUE_FLUSH, null, "SAFE")
            }

            text.contains("help") || text.contains("emergency") -> {
                triggerSOS("Voice help request")
            }

            else -> startListening()
        }
    }

    // ================= SOS =================

    private fun triggerSOS(reason: String) {
        waitingForResponse = false
        sosButton.visibility = View.GONE
        statusText.text = "🚨 Emergency triggered"

        tts.speak("Emergency alert sent.", TextToSpeech.QUEUE_FLUSH, null, "SOS")

        sendSmsWithLocation()
        makeEmergencyCall()
    }

    private fun sendSmsWithLocation() {
        try {
            val smsManager = SmsManager.getDefault()

            val location = getLastLocation()

            val message = if (location != null) {
                "EMERGENCY! Fall detected. Help needed. Location: https://maps.google.com/?q=${location.latitude},${location.longitude}"
            } else {
                "EMERGENCY! Fall detected. Help needed. Location unavailable."
            }

            smsManager.sendTextMessage(
                EMERGENCY_NUMBER,
                null,
                message,
                null,
                null
            )

            statusText.text = "Emergency SMS sent"

        } catch (e: Exception) {
            statusText.text = "SMS failed"
            e.printStackTrace()
        }
    }



    private fun makeEmergencyCall() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
            != PackageManager.PERMISSION_GRANTED
        ) return

        val intent = Intent(Intent.ACTION_CALL)
        intent.data = Uri.parse("tel:$EMERGENCY_NUMBER")
        startActivity(intent)
    }

    private fun getLastLocation(): Location? {

        val fineGranted = ContextCompat.checkSelfPermission(
            this, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        val coarseGranted = ContextCompat.checkSelfPermission(
            this, Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        if (!fineGranted && !coarseGranted) return null

        val lm = getSystemService(Context.LOCATION_SERVICE) as LocationManager

        // MOST RELIABLE on Samsung / indoors
        val networkLocation =
            lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)

        if (networkLocation != null) return networkLocation

        // GPS fallback
        return lm.getLastKnownLocation(LocationManager.GPS_PROVIDER)
    }


    private fun requestPermissions() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(
                Manifest.permission.RECORD_AUDIO,
                Manifest.permission.SEND_SMS,
                Manifest.permission.CALL_PHONE,
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ),
            100
        )
    }
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == 100) {
            for (i in permissions.indices) {
                if (permissions[i].contains("LOCATION") &&
                    grantResults[i] != PackageManager.PERMISSION_GRANTED
                ) {
                    statusText.text = "⚠️ Location permission denied"
                }
            }
        }
    }


    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onDestroy() {
        super.onDestroy()
        sensorManager.unregisterListener(this)
        speechRecognizer.destroy()
        tts.shutdown()
    }

    private fun createForegroundNotification() {
        val channelId = "elderly_channel"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "ElderlyEase",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("ElderlyEase Active")
            .setContentText("Fall monitoring running")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .build()

        getSystemService(NotificationManager::class.java).notify(1, notification)
    }
}
