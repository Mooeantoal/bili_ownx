package com.example.bili_ownx

import io.flutter.app.FlutterApplication
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class FlutterApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
    }

    override fun registerFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}