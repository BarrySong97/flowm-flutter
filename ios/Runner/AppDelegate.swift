import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let appGroupChannel = FlutterMethodChannel(
      name: "com.flowm.app_group",
      binaryMessenger: controller.binaryMessenger)

    appGroupChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in

      guard call.method == "saveToAppGroup" else {
        result(FlutterMethodNotImplemented)
        return
      }

      if let args = call.arguments as? [String: Any],
        let groupId = args["groupId"] as? String,
        let data = args["data"] as? [String: Any]
      {

        self?.saveToAppGroup(groupId: groupId, data: data, result: result)
      } else {
        result(
          FlutterError(
            code: "INVALID_ARGUMENTS",
            message: "Invalid arguments",
            details: nil))
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveToAppGroup(groupId: String, data: [String: Any], result: @escaping FlutterResult)
  {
    print("[AppDelegate] ===== saveToAppGroup called =====")
    print("[AppDelegate] Group ID: \(groupId)")
    print("[AppDelegate] Data keys: \(Array(data.keys))")
    print("[AppDelegate] Data values: \(data)")

    guard let userDefaults = UserDefaults(suiteName: groupId) else {
      print("[AppDelegate] ERROR: Failed to create UserDefaults for \(groupId)")
      result(
        FlutterError(
          code: "APP_GROUP_ERROR",
          message: "Failed to access App Group: \(groupId)",
          details: nil))
      return
    }

    print("[AppDelegate] Successfully created UserDefaults for \(groupId)")

    for (key, value) in data {
      print("[AppDelegate] Processing key: \(key), value: \(value), type: \(type(of: value))")

      if let stringValue = value as? String {
        userDefaults.set(stringValue, forKey: key)
        print("[AppDelegate] Set string value for key \(key): \(stringValue)")
      } else if let intValue = value as? Int {
        userDefaults.set(intValue, forKey: key)
        print("[AppDelegate] Set int value for key \(key): \(intValue)")
      } else if let doubleValue = value as? Double {
        userDefaults.set(doubleValue, forKey: key)
        print("[AppDelegate] Set double value for key \(key): \(doubleValue)")
      } else if let boolValue = value as? Bool {
        userDefaults.set(boolValue, forKey: key)
        print("[AppDelegate] Set bool value for key \(key): \(boolValue)")
      } else {
        print("[AppDelegate] WARNING: Unsupported value type for key \(key): \(type(of: value))")
      }
    }

    // 同步到磁盘
    let syncResult = userDefaults.synchronize()
    print("[AppDelegate] Synchronize result: \(syncResult)")

    // 验证数据是否真的写入了
    print("[AppDelegate] Verifying written data:")
    for (key, _) in data {
      let storedValue = userDefaults.object(forKey: key)
      print("[AppDelegate] Key \(key): \(String(describing: storedValue))")
    }

    // 列出所有键
    let allKeys = userDefaults.dictionaryRepresentation().keys
    print("[AppDelegate] All keys in App Group after write: \(Array(allKeys))")

    print("[AppDelegate] Data saved to \(groupId): \(data.keys)")
    result(true)
  }
}
