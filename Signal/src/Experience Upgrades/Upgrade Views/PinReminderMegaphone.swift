

import Foundation

class PinReminderMegaphone: MegaphoneView {
    init(experienceUpgrade: ExperienceUpgrade, fromViewController: UIViewController) {
        super.init(experienceUpgrade: experienceUpgrade)

        titleText = NSLocalizedString("XXGJUSTHHANQP49", comment: "Title for PIN reminder megaphone")
        bodyText = NSLocalizedString("XXGJUSTHHANQP47", comment: "Body for PIN reminder megaphone")
        imageName = "PIN_megaphone"

        let primaryButtonTitle = NSLocalizedString("XXGJUSTHHANQP46", comment: "Action text for PIN reminder megaphone")

        let primaryButton = MegaphoneView.Button(title: primaryButtonTitle) { [weak self] in
            let vc = PinReminderViewController {
                self?.dismiss(animated: false)
                self?.presentToastForNewRepetitionInterval(fromViewController: fromViewController)
            }

            fromViewController.present(vc, animated: true)
        }

        setButtons(primary: primaryButton)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func presentToastForNewRepetitionInterval(fromViewController: UIViewController) {
        let toastText: String
        switch OWS2FAManager.shared().repetitionInterval {
        case (1 * kDayInterval):
            toastText = NSLocalizedString("XXGJUSTHHANQP50",
                                          comment: "Toast indicating that we'll ask you for your PIN again tomorrow.")
        case (3 * kDayInterval):
            toastText = NSLocalizedString("XXGJUSTHHANQP48",
                                          comment: "Toast indicating that we'll ask you for your PIN again in 3 days.")
        case (7 * kDayInterval):
            toastText = NSLocalizedString("XXGJUSTHHANQP52",
                                          comment: "Toast indicating that we'll ask you for your PIN again in a week.")
        case (14 * kDayInterval):
            toastText = NSLocalizedString("XXGJUSTHHANQP51",
                                          comment: "Toast indicating that we'll ask you for your PIN again in 2 weeks.")
        default:
            toastText = MegaphoneStrings.weWillRemindYouLater
        }

        presentToast(text: toastText, fromViewController: fromViewController)
    }
}
