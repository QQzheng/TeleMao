
import UIKit
import SafariServices

@objc
public class OnboardingAccountLockedViewController: OnboardingBaseViewController {
    override public func loadView() {
        view = UIView()
        view.addSubview(primaryView)
        primaryView.autoPinEdgesToSuperviewEdges()

        view.backgroundColor = Theme.backgroundColor

        let titleLabel = self.titleLabel(text:
            NSLocalizedString("XXGJUSTHHANQO13",
                              comment: "Title of the 'onboarding account locked' view."))
        titleLabel.accessibilityIdentifier = "onboarding.accountLocked." + "titleLabel"

        let ROHSREFOEUUYZhuceThirdHonzy = self.ROHSREFOEUUYZhuceThirdHonzy(explanationText:
            NSLocalizedString("XXGJUSTHHANQO11",
                              comment: "Explanation of the 'onboarding account locked' view."))
        ROHSREFOEUUYZhuceThirdHonzy.font = UIFont.ows_dynamicTypeBodyClamped
        ROHSREFOEUUYZhuceThirdHonzy.textColor = Theme.primaryTextColor
        ROHSREFOEUUYZhuceThirdHonzy.accessibilityIdentifier = "onboarding.accountLocked." + "ROHSREFOEUUYZhuceThirdHonzy"

        let okayButton = self.button(
            title: NSLocalizedString("XXGJUSTHHANQB45",
                                     comment: "Label for the 'okay' button."),
            selector: #selector(okayPressed)
        )
        okayButton.accessibilityIdentifier = "onboarding.accountLocked." + "okayButton"
        let primaryButtonView = OnboardingBaseViewController.horizontallyWrap(primaryButton: okayButton)

        let learnMoreLink = self.linkButton(
            title: NSLocalizedString("XXGJUSTHHANQO12",
                                     comment: "Label for the 'learn more' link in the 'onboarding account locked' view."),
            selector: #selector(learnMoreLinkTapped)
        )
        learnMoreLink.accessibilityIdentifier = "onboarding.accountLocked." + "learnMoreLink"

        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            UIView.spacer(withHeight: 10),
            ROHSREFOEUUYZhuceThirdHonzy,
            UIView.vStretchingSpacer(),
            primaryButtonView,
            learnMoreLink
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        primaryView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewMargins()
    }

    // MARK: - Events

    @objc func learnMoreLinkTapped() {
        Logger.info("")

        // TODO PINs: Open the right support center URL
        let vc = SFSafariViewController(url: URL(string: "https://support.signal.org/hc/en-us/articles/360007059792")!)
        present(vc, animated: true, completion: nil)
    }

    @objc func okayPressed() {
        Logger.info("")

        navigationController?.popToRootViewController(animated: true)
    }
}
