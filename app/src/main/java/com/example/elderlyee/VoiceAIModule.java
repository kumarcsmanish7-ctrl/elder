package com.example.elderlyee;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.speech.RecognizerIntent;
import android.speech.tts.TextToSpeech;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.google.ai.client.generativeai.GenerativeModel;
import com.google.ai.client.generativeai.java.GenerativeModelFutures;
import com.google.ai.client.generativeai.type.Content;
import com.google.ai.client.generativeai.type.GenerateContentResponse;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;

import java.util.ArrayList;
import java.util.Locale;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

public class VoiceAIModule extends ReactContextBaseJavaModule implements LifecycleEventListener {

    private static final String TAG = "VoiceAIModule";
    private static final int SPEECH_REQUEST_CODE = 101;
    private static final int PERMISSION_REQUEST_CODE = 201;

    private TextToSpeech textToSpeech;
    private Promise pendingPromise;
    private final Executor executor = Executors.newSingleThreadExecutor();
    private boolean isTtsInitialized = false;
    private Activity manualActivity; 

    private final ActivityEventListener mActivityEventListener = new BaseActivityEventListener() {
        @Override
        public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
            if (requestCode == SPEECH_REQUEST_CODE) {
                handleSpeechResult(resultCode, data);
            }
        }
    };

    public VoiceAIModule(ReactApplicationContext reactContext) {
        super(reactContext);
        if (reactContext != null) {
            reactContext.addLifecycleEventListener(this);
            reactContext.addActivityEventListener(mActivityEventListener);
            initializeTextToSpeech(reactContext);
        }
    }

    public void setActivity(Activity activity) {
        this.manualActivity = activity;
    }

    @NonNull
    @Override
    public String getName() {
        return "VoiceAIModule";
    }

    private void initializeTextToSpeech(ReactApplicationContext context) {
        textToSpeech = new TextToSpeech(context, status -> {
            if (status == TextToSpeech.SUCCESS) {
                textToSpeech.setLanguage(Locale.US);
                isTtsInitialized = true;
                Log.d(TAG, "TTS Initialized Successfully");
            } else {
                Log.e(TAG, "TTS Initialization Failed");
            }
        });
    }

    @ReactMethod
    public void startVoiceAI(Promise promise) {
        this.pendingPromise = promise;
        
        Activity activity = getCurrentActivity();
        if (activity == null) {
            activity = manualActivity;
        }
        if (activity == null) {
            activity = findActivity(getReactApplicationContext());
        }

        if (activity == null) {
            Log.e(TAG, "Activity is null.");
            if (pendingPromise != null) pendingPromise.reject("ERR", "Activity context not found.");
            return;
        }

        if (ContextCompat.checkSelfPermission(getReactApplicationContext(), Manifest.permission.RECORD_AUDIO)
                != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.RECORD_AUDIO}, PERMISSION_REQUEST_CODE);
            return;
        }

        Intent intent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
        intent.putExtra(RecognizerIntent.EXTRA_PROMPT, "Listening...");
        try {
            activity.startActivityForResult(intent, SPEECH_REQUEST_CODE);
        } catch (Exception e) {
            if (pendingPromise != null) pendingPromise.reject("ERR", "Failed to start voice intent: " + e.getMessage());
        }
    }

    private Activity findActivity(Context context) {
        if (context == null) return null;
        if (context instanceof Activity) return (Activity) context;
        if (context instanceof ContextWrapper) {
            return findActivity(((ContextWrapper) context).getBaseContext());
        }
        return null;
    }

    public void handleSpeechResult(int resultCode, Intent data) {
        if (resultCode == Activity.RESULT_OK && data != null) {
            ArrayList<String> result = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS);
            if (result != null && !result.isEmpty()) {
                processSpeechWithGemini(result.get(0));
            }
        }
    }

    private void processSpeechWithGemini(String userSpeech) {
        String apiKey = BuildConfig.GEMINI_API_KEY;
        try {
            // Using the requested model name
            GenerativeModel gm = new GenerativeModel("gemini-3-flash-preview", apiKey);
            GenerativeModelFutures model = GenerativeModelFutures.from(gm);
            
            Content content = new Content.Builder().addText(userSpeech).build();
            ListenableFuture<GenerateContentResponse> response = model.generateContent(content);

            Futures.addCallback(response, new FutureCallback<GenerateContentResponse>() {
                @Override
                public void onSuccess(GenerateContentResponse result) {
                    String aiResponse = result.getText();
                    if (isTtsInitialized && aiResponse != null) {
                        textToSpeech.speak(aiResponse, TextToSpeech.QUEUE_FLUSH, null, "voiceai");
                    }
                    if (pendingPromise != null) {
                        pendingPromise.resolve(aiResponse);
                    }
                }
                @Override
                public void onFailure(Throwable t) {
                    Log.e(TAG, "Gemini Failure: " + t.getMessage());
                    if (pendingPromise != null) pendingPromise.reject("GEMINI_ERROR", t.getMessage());
                }
            }, executor);
        } catch (Exception e) {
            Log.e(TAG, "Exception: " + e.getMessage());
            if (pendingPromise != null) pendingPromise.reject("EXCEPTION", e.getMessage());
        }
    }

    @Override public void onHostResume() {}
    @Override public void onHostPause() { if (textToSpeech != null) textToSpeech.stop(); }
    @Override public void onHostDestroy() { if (textToSpeech != null) textToSpeech.shutdown(); }
}
