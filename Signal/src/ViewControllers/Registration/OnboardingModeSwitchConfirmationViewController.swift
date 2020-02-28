
import Foundation

class OnboardingModeSwitchConfirmationViewController: OnboardingBaseViewController {
    var warningText: String?

    override func loadView() {
        view = UIView()
        view.addSubview(primaryView)
        primaryView.autoPinEdgesToSuperviewEdges()

        view.backgroundColor = Theme.backgroundColor

        let titleText: String
        let explanationText: String
        let nextButtonText: String
        let image: UIImage?

        switch onboardingController.defaultOnboardingMode {
        case .registering:
            titleText = NSLocalizedString("XXGJUSTHHANQO20",
                                          comment: "header text indicating to the user they're switching from registering to linking flow")
            explanationText = NSLocalizedString("XXGJUSTHHANQO18",
                                                comment: "explanation to the user they're switching from registering to linking flow")

            nextButtonText = NSLocalizedString("XXGJUSTHHANQO16",
                                               comment: "button indicating that the user will link their phone")

            warningText = NSLocalizedString("XXGJUSTHHANQO22",
                                            comment: "warning to the user that linking a phone is not recommended")
            image = nil
        case .provisioning:
            titleText = NSLocalizedString("XXGJUSTHHANQO19",
                                          comment: "header text indicating to the user they're switching from linking to registering flow")
            explanationText = NSLocalizedString("XXGJUSTHHANQO17",
                                                comment: "explanation to the user they're switching from linking to registering flow")
            nextButtonText = NSLocalizedString("XXGJUSTHHANQO15",
                                               comment: "button indicating that the user will register their ipad")
            warningText = NSLocalizedString("XXGJUSTHHANQO21",
                                            comment: "warning to the user that registering an ipad is not recommended")
            image = #imageLiteral(resourceName: "ipad-primary")
        }

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingHigh()

        let titleLabel = self.titleLabel(text: titleText)

        let ROHSREFOEUUYZhuceThirdHonzy = self.ROHSREFOEUUYZhuceThirdHonzy(explanationText: explanationText)

        let nextButton = self.button(title: nextButtonText,
                                            selector: #selector(didPressNext))
        nextButton.accessibilityIdentifier = "onboarding.modeSwitch.nextButton"
        let primaryButtonView = OnboardingBaseViewController.horizontallyWrap(primaryButton: nextButton)

        let topSpacer = UIView.vStretchingSpacer(minHeight: 12)
        let bottomSpacer = UIView.vStretchingSpacer(minHeight: 12)

        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            UIView.spacer(withHeight: 12),
            ROHSREFOEUUYZhuceThirdHonzy,
            topSpacer,
            imageView,
            bottomSpacer,
            primaryButtonView
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 12
        primaryView.addSubview(stackView)

        topSpacer.autoMatch(.height, to: .height, of: bottomSpacer)

        stackView.autoPinEdgesToSuperviewMargins()
    }

    override func shouldShowBackButton() -> Bool {
        return true
    }

    @objc func didPressNext() {
        let actionSheet = ActionSheetController(message: warningText)

        let continueAction = ActionSheetAction(title: CommonStrings.continueButton,
                                               accessibilityIdentifier: "onboarding.modeSwitch.continue") { _ in
            self.onboardingController.toggleModeSwitch(viewController: self)
        }
        actionSheet.addAction(continueAction)
        actionSheet.addAction(OWSActionSheets.cancelAction)

        presentActionSheet(actionSheet)
    }
}
