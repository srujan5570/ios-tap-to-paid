import Flutter
import UIKit

#if !targetEnvironment(simulator)
import CastarSDK
#endif

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    CastarBridge.register(with: self.registrar(forPlugin: "CastarBridge")!)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
