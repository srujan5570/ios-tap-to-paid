#if targetEnvironment(simulator)
import Flutter

@objc public class CastarBridge: NSObject {
    @objc public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "castar_sdk", binaryMessenger: registrar.messenger())
        let instance = CastarBridge()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
}

extension CastarBridge: FlutterPlugin {
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            if let args = call.arguments as? [String: Any],
               let clientId = args["clientId"] as? String {
                print("[CastarSDK Mock] Initialized with client ID: \(clientId)")
                result(true)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS",
                                  message: "Client ID is required",
                                  details: nil))
            }
        case "showAd":
            print("[CastarSDK Mock] Showing mock ad")
            // Simulate ad success after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                result(true)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
#endif 