import Foundation
import CastarSDK
import Flutter

class CastarBridge: NSObject, FlutterPlugin {
    private var castarInstance: Castar?
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.castar.sdk/bridge", binaryMessenger: registrar.messenger())
        let instance = CastarBridge()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initializeCastar":
            let key = "cskKFkzBSlmLUF"
            let initResult = Castar.createInstance(devKey: key)
            
            switch initResult {
            case .success(let instance):
                self.castarInstance = instance
                instance.start()
                result(true)
            case .failure(let error):
                result(FlutterError(code: "INIT_ERROR",
                                  message: error.localizedDescription,
                                  details: nil))
            }
            
        case "startCastar":
            if let instance = castarInstance {
                instance.start()
                result(true)
            } else {
                result(FlutterError(code: "NOT_INITIALIZED",
                                  message: "Castar SDK not initialized",
                                  details: nil))
            }
            
        case "stopCastar":
            if let instance = castarInstance {
                instance.stop()
                result(true)
            } else {
                result(FlutterError(code: "NOT_INITIALIZED",
                                  message: "Castar SDK not initialized",
                                  details: nil))
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
} 