

import Foundation
import Lottie

class ProfileNameReminderMegaphone: MegaphoneView {
    init(experienceUpgrade: ExperienceUpgrade, fromViewController: UIViewController) {
        super.init(experienceUpgrade: experienceUpgrade)

        let hasProfileNameAlready = OWSProfileManager.shared().localFullName()?.isEmpty == false

        titleText = hasProfileNameAlready
            ? NSLocalizedString("XXGJUSTHHANQP85",
                                comment: "Title for profile name reminder megaphone when user already has a profile name")
            : NSLocalizedString("XXGJUSTHHANQP87",
                                comment: "Title for profile name reminder megaphone when user doesn't have a profile name")
        bodyText = hasProfileNameAlready
            ? NSLocalizedString("XXGJUSTHHANQP84",
                                comment: "Body for profile name reminder megaphone when user already has a profile name")
            : NSLocalizedString("XXGJUSTHHANQP86",
                                comment: "Body for profile name reminder megaphone when user doesn't have a profile name")
        imageName = "profileMegaphone"

        let primaryButton = MegaphoneView.Button(
            title: NSLocalizedString("XXGJUSTHHANQP83",
                                     comment: "Action text for profile name reminder megaphone")
        ) { [weak self] in
            let vc = ProfileViewController.forExperienceUpgrade {
                self?.markAsComplete()
                fromViewController.navigationController?.popToViewController(fromViewController, animated: true) {
                    fromViewController.navigationController?.setNavigationBarHidden(false, animated: false)
                    self?.dismiss(animated: false)
                    self?.presentToast(
                        text: NSLocalizedString("XXGJUSTHHANQP88",
                                                comment: "Toast indicating that a PIN has been created."),
                        fromViewController: fromViewController
                    )
                }
            }

            fromViewController.navigationController?.pushViewController(vc, animated: true)
        }

        let secondaryButton = snoozeButton(fromViewController: fromViewController)
        setButtons(primary: primaryButton, secondary: secondaryButton)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
