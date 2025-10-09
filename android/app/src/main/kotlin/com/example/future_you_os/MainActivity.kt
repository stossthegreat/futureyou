package com.example.future_you_os

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import dev.fluttercommunity.plus.androidalarmmanager.AndroidAlarmManagerPlugin

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Register alarm manager plugin
        AndroidAlarmManagerPlugin.registerWith(
            flutterEngine.plugins.get(AndroidAlarmManagerPlugin::class.java) ?: 
            AndroidAlarmManagerPlugin()
        )
    }
}
