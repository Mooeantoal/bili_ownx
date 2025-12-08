package com.example.bili_ownx

import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.os.Build
import android.util.Rational
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PipMethodChannel : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private var activity: FlutterActivity? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isInPiPMode = false

    companion object {
        private const val CHANNEL = "bili_ownx/pip"
        private const val EVENT_CHANNEL = "bili_ownx/pip_events"
        private const val PERMISSION_CODE = 1001
    }

    fun initialize(flutterEngine: FlutterEngine, activity: FlutterActivity) {
        this.activity = activity

        // 设置方法通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler(this)

        // 设置事件通道
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "enterPiP" -> {
                val aspectRatio = call.argument<Double>("aspectRatio") ?: (16.0 / 9.0)
                val title = call.argument<String>("title") ?: "Bili Flutter"
                enterPiPMode(aspectRatio, title, result)
            }
            "exitPiP" -> {
                exitPiPMode(result)
            }
            "updatePiPConfig" -> {
                val aspectRatio = call.argument<Double>("aspectRatio")
                val title = call.argument<String>("title")
                updatePiPConfig(aspectRatio, title, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun enterPiPMode(aspectRatio: Double, title: String, result: MethodChannel.Result) {
        if (!supportsPiP()) {
            result.error("PIP_NOT_SUPPORTED", "设备不支持画中画功能", null)
            return
        }

        try {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(aspectRatio.toInt(), 1))
                .setTitle(title)
                .build()

            val success = activity?.enterPictureInPictureMode(params) ?: false
            if (success) {
                isInPiPMode = true
                notifyPiPModeChange()
                result.success(true)
            } else {
                result.error("PIP_FAILED", "进入画中画模式失败", null)
            }
        } catch (e: Exception) {
            result.error("PIP_ERROR", "画中画错误: ${e.message}", e)
        }
    }

    private fun exitPiPMode(result: MethodChannel.Result) {
        try {
            activity?.moveTaskToBack(true)
            isInPiPMode = false
            notifyPiPModeChange()
            result.success(true)
        } catch (e: Exception) {
            result.error("PIP_ERROR", "退出画中画模式失败: ${e.message}", e)
        }
    }

    private fun updatePiPConfig(aspectRatio: Double?, title: String?, result: MethodChannel.Result) {
        // Android PIP 在运行时不能直接更新配置，这里只返回成功
        result.success(true)
    }

    private fun supportsPiP(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && 
               activity?.packageManager?.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE) == true
    }

    private fun notifyPiPModeChange() {
        eventSink?.success(mapOf("isInPiP" to isInPiPMode))
    }

    // EventChannel.StreamHandler 实现
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        // 发送当前状态
        eventSink?.success(mapOf("isInPiP" to isInPiPMode))
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // 处理画中画模式变化
    fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean) {
        isInPiPMode = isInPictureInPictureMode
        notifyPiPModeChange()
    }
}