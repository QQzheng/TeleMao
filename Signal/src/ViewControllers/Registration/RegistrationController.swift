
import UIKit

@objc
public class RegistrationController: NSObject {

    // MARK: - Dependencies

    private static var tsAccountManager: TSAccountManager {
        return TSAccountManager.sharedInstance()
    }

    private static var backup: OWSBackup {
        return AppEnvironment.shared.backup
    }

    // MARK: -

    private override init() {}

    // MARK: -

    private class func showBackupRestoreView(fromView view: UIViewController) {
        AssertIsOnMainThread()

        Logger.info("")

        guard let navigationController = view.navigationController else {
            owsFailDebug("Missing navigationController")
            return
        }

        let restoreView = BackupRestoreViewController()
        navigationController.setViewControllers([restoreView], animated: true)
    }

    // TODO: OnboardingController will eventually need to do something like this.
//    private class func checkCanImportBackup(fromView view: UIViewController) {
//        AssertIsOnMainThread()
//
//        Logger.info("")
//
//        self.backup.checkCanImport({ (canImport) in
//            Logger.info("canImport: \(canImport)")
//
//            if (canImport) {
//                self.backup.setHasPendingRestoreDecision(true)
//
//                self.showBackupRestoreView(fromView: view)
//            } else {
//                self.showProfileView(fromView: view)
//            }
//        }) { (_) in
//            self.showBackupCheckFailedAlert(fromView: view)
//        }
//    }
//
//    private class func showBackupCheckFailedAlert(fromView view: UIViewController) {
//        AssertIsOnMainThread()
//
//        Logger.info("")
//
//        let alert = UIAlertController(title: NSLocalizedString("XXGJUSTHHANQA19",
//                                                               comment: "Title for alert shown when the app failed to check for an existing backup."),
//                                      message: NSLocalizedString("XXGJUSTHHANQC31",
//                                                                  comment: "Message for alert shown when the app failed to check for an existing backup."),
//                                      preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: NSLocalizedString("XXGJUSTHHANQR23", comment: ""),
//                                      style: .default) { (_) in
//                                        self.checkCanImportBackup(fromView: view)
//        })
//        alert.addAction(UIAlertAction(title: NSLocalizedString("XXGJUSTHHANQC30", comment: "The label for the 'do not restore backup' button."),
//                                      style: .destructive) { (_) in
//                                        self.showProfileView(fromView: view)
//        })
//        view.presentAlert(alert)
//    }
}
