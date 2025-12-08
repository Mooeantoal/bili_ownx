package com.example.bili_ownx

import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private var pipMethodChannel: PipMethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 初始化画中画通道
        pipMethodChannel = PipMethodChannel()
        pipMethodChannel?.initialize(flutterEngine, this)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 启用画中画功能（API 26+）
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // 在 AndroidManifest.xml 中配置会更好
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: android.content.res.Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        
        // 通知画中画状态变化
        pipMethodChannel?.onPictureInPictureModeChanged(isInPictureInPictureMode)
    }
}
