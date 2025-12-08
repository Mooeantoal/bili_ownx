import Flutter
import UIKit
import AVKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // 注册画中画插件
    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not type FlutterViewController")
    }
    
    let registrar = self.registrar(forPlugin: "PipMethodChannel")!
    PipMethodChannel.register(with: registrar)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    // 画中画模式下支持所有方向
    return .all
  }
  
  override func applicationDidEnterBackground(_ application: UIApplication) {
    // 应用进入后台时的处理
    super.applicationDidEnterBackground(application)
  }
  
  override func applicationWillEnterForeground(_ application: UIApplication) {
    // 应用即将进入前台时的处理
    super.applicationWillEnterForeground(application)
  }
}
