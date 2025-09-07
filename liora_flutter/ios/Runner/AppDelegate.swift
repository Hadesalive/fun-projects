import Flutter
import UIKit
import FirebaseAuth

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    print("[AppDelegate] open url: \(url.absoluteString)")
    let handled = Auth.auth().canHandle(url)
    print("[AppDelegate] FirebaseAuth handled: \(handled)")
    if handled {
      return true
    }
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if let url = userActivity.webpageURL {
      print("[AppDelegate] continue userActivity url: \(url.absoluteString)")
      let handled = Auth.auth().canHandle(url)
      print("[AppDelegate] FirebaseAuth handled (userActivity): \(handled)")
      if handled {
        return true
      }
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }

  override func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    print("[AppDelegate] legacy openURL: \(url.absoluteString)")
    let handled = Auth.auth().canHandle(url)
    print("[AppDelegate] FirebaseAuth handled (legacy): \(handled)")
    if handled {
      return true
    }
    return super.application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
  }
}
