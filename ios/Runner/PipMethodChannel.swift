import Flutter
import AVFoundation
import AVKit

@available(iOS 9.0, *)
class PipMethodChannel: NSObject, FlutterPlugin {
    private var eventSink: FlutterEventSink?
    private var isInPiPMode = false
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "bili_ownx/pip", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "bili_ownx/pip_events", binaryMessenger: registrar.messenger())
        
        let instance = PipMethodChannel()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }
    
    // FlutterPlugin 协议方法
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enterPiP":
            guard let args = call.arguments as? [String: Any],
                  let aspectRatio = args["aspectRatio"] as? Double,
                  let title = args["title"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "无效的参数", details: nil))
                return
            }
            enterPiPMode(aspectRatio: aspectRatio, title: title, result: result)
            
        case "exitPiP":
            exitPiPMode(result: result)
            
        case "updatePiPConfig":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "无效的参数", details: nil))
                return
            }
            let aspectRatio = args["aspectRatio"] as? Double
            let title = args["title"] as? String?
            updatePiPConfig(aspectRatio: aspectRatio, title: title, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func enterPiPMode(aspectRatio: Double, title: String, result: @escaping FlutterResult) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            result(FlutterError(code: "PIP_NOT_SUPPORTED", message: "设备不支持画中画功能", details: nil))
            return
        }
        
        // 获取根视图控制器
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            result(FlutterError(code: "NO_ROOT_VIEW", message: "无法找到根视图控制器", details: nil))
            return
        }
        
        // 创建或获取现有的播放器视图
        let playerViewController = rootViewController.children.first as? AVPlayerViewController ?? AVPlayerViewController()
        
        if playerViewController.parent == nil {
            // 如果还没有添加到视图层级，则添加
            rootViewController.addChild(playerViewController)
            rootViewController.view.insertSubview(playerViewController.view, at: 0)
            playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                playerViewController.view.leadingAnchor.constraint(equalTo: rootViewController.view.leadingAnchor),
                playerViewController.view.trailingAnchor.constraint(equalTo: rootViewController.view.trailingAnchor),
                playerViewController.view.topAnchor.constraint(equalTo: rootViewController.view.topAnchor),
                playerViewController.view.bottomAnchor.constraint(equalTo: rootViewController.view.bottomAnchor)
            ])
            playerViewController.didMove(toParent: rootViewController)
        }
        
        // 设置画中画控制器
        if let pipController = playerViewController.pictureInPictureController {
            pipController.delegate = self
            
            // 设置宽高比
            let aspectRatioFloat = CGFloat(aspectRatio)
            
            // 启动画中画
            DispatchQueue.main.async {
                if pipController.isPictureInPictureActive {
                    // 如果已经在画中画模式，返回成功
                    self.isInPiPMode = true
                    self.notifyPiPModeChange()
                    result(true)
                } else {
                    pipController.startPictureInPicture()
                    self.isInPiPMode = true
                    self.notifyPiPModeChange()
                    result(true)
                }
            }
        } else {
            result(FlutterError(code: "PIP_CONTROLLER_UNAVAILABLE", message: "画中画控制器不可用", details: nil))
        }
    }
    
    private func exitPiPMode(result: @escaping FlutterResult) {
        // 获取根视图控制器
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            result(FlutterError(code: "NO_ROOT_VIEW", message: "无法找到根视图控制器", details: nil))
            return
        }
        
        // 查找现有的播放器视图
        if let playerViewController = rootViewController.children.first as? AVPlayerViewController,
           let pipController = playerViewController.pictureInPictureController,
           pipController.isPictureInPictureActive {
            
            DispatchQueue.main.async {
                pipController.stopPictureInPicture()
                self.isInPiPMode = false
                self.notifyPiPModeChange()
                result(true)
            }
        } else {
            // 如果不在画中画模式，直接返回成功
            self.isInPiPMode = false
            self.notifyPiPModeChange()
            result(true)
        }
    }
    
    private func updatePiPConfig(aspectRatio: Double?, title: String?, result: @escaping FlutterResult) {
        // iOS PIP 配置更新相对有限，这里返回成功
        result(true)
    }
    
    private func notifyPiPModeChange() {
        eventSink?(["isInPiP": isInPiPMode])
    }
}

// MARK: - AVPictureInPictureControllerDelegate
extension PipMethodChannel: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isInPiPMode = true
        notifyPiPModeChange()
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isInPiPMode = true
        notifyPiPModeChange()
    }
    
    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isInPiPMode = false
        notifyPiPModeChange()
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isInPiPMode = false
        notifyPiPModeChange()
    }
}

// MARK: - FlutterStreamHandler
extension PipMethodChannel: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        // 发送当前状态
        eventSink(["isInPiP": isInPiPMode])
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}