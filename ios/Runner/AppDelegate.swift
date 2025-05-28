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
    
    #if !targetEnvironment(simulator)
    // Use real CastarSDK in device builds
    CastarBridge.register(with: self.registrar(forPlugin: "CastarBridge")!)
    #else
    // Use mock implementation in simulator builds
    CastarBridge.register(with: self.registrar(forPlugin: "CastarBridge")!)
    #endif
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
