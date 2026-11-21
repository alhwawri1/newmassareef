import Foundation
import WebKit
import WidgetKit

final class MasareefAppGroupBridge: NSObject, WKScriptMessageHandler {
    static let suiteName = "group.com.alhawari.masareef"
    static let snapshotKey = "masareef_widget_snapshot_v1"

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "masareefWidgetSync",
              let dict = message.body as? [String: Any],
              let payload = dict["payload"] as? String else { return }

        let suite = (dict["suite"] as? String) ?? Self.suiteName
        if let defaults = UserDefaults(suiteName: suite) {
            defaults.set(payload, forKey: Self.snapshotKey)
            defaults.synchronize()
            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}
