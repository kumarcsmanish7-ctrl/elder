package com.example.elderlyee

import android.content.Intent
import android.os.Bundle
import android.speech.RecognizerIntent
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.elderlyee.ui.theme.ElderlyeeTheme
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.WritableMap
import java.util.*

class MainActivity : ComponentActivity() {

    private var voiceAIModule: VoiceAIModule? = null
    
    // UI State for feedback
    var statusText by mutableStateOf("Ready to chat")

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Initialize the module
        val reactContext = ReactApplicationContext(this)
        voiceAIModule = VoiceAIModule(reactContext)
        
        // MANUALLY SET THE ACTIVITY FOR TESTING
        voiceAIModule?.setActivity(this)

        val testPromise = object : Promise {
            override fun resolve(value: Any?) { 
                android.util.Log.d("VoiceAI", "Result: $value")
                statusText = "AI Response: $value"
            }
            override fun reject(code: String?, message: String?) { 
                android.util.Log.e("VoiceAI", "Error: $message")
                statusText = "Error: $message"
            }
            override fun reject(code: String?, throwable: Throwable?) { }
            override fun reject(code: String?, message: String?, throwable: Throwable?) { }
            override fun reject(throwable: Throwable?) { }
            override fun reject(throwable: Throwable?, userInfo: WritableMap?) { }
            override fun reject(code: String?, userInfo: WritableMap) { }
            override fun reject(code: String?, throwable: Throwable?, userInfo: WritableMap?) { }
            override fun reject(code: String?, message: String?, userInfo: WritableMap) { }
            override fun reject(code: String?, message: String?, throwable: Throwable?, userInfo: WritableMap?) { }
            @Deprecated("Deprecated") override fun reject(message: String?) { }
        }

        setContent {
            ElderlyeeTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    Column(
                        modifier = Modifier.padding(innerPadding).fillMaxSize(),
                        verticalArrangement = Arrangement.Center,
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(text = "Elderlyee AI Chatbot", style = MaterialTheme.typography.headlineMedium)
                        Spacer(modifier = Modifier.height(20.dp))
                        Text(text = statusText, modifier = Modifier.padding(16.dp))
                        Spacer(modifier = Modifier.height(20.dp))
                        Button(onClick = {
                            statusText = "Listening..."
                            voiceAIModule?.startVoiceAI(testPromise)
                        }) {
                            Text("Start Voice AI")
                        }
                    }
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 101) { // SPEECH_REQUEST_CODE
            statusText = "Processing with Gemini AI..."
            voiceAIModule?.handleSpeechResult(resultCode, data)
        }
    }
}
