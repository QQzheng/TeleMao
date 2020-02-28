
import UIKit

class ExpirationNagView: ReminderView {
    private static let updateLink = URL(string: "itms-apps://itunes.apple.com/app/id874139669")!

    @objc convenience init() {
        self.init(mode: .nag, text: "") {
            UIApplication.shared.openURL(ExpirationNagView.updateLink)
        }
    }

    @objc func updateText() {
        if AppExpiry.isExpired {
            text = NSLocalizedString("XXGJUSTHHANQE58", comment: "Label notifying the user that the app has expired.")
        } else if AppExpiry.daysUntilBuildExpiry == 1 {
            text = NSLocalizedString("XXGJUSTHHANQE60", comment: "Label warning the user that the app will expire today.")
        } else {
            let soonWarning = NSLocalizedString("XXGJUSTHHANQE59", comment: "Label warning the user that the app will expire soon.")
            text = String(format: soonWarning, AppExpiry.daysUntilBuildExpiry)
        }
    }
}
