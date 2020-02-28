

import UIKit

@objc
public class Onboarding2FAViewController: OnboardingBaseViewController {
    private let attemptsAlertThreshold = 4
    private let pinTextField = UITextField()
    private let pinTypeToggle = UIButton()

    private lazy var pinStrokeNormal = pinTextField.addBottomStroke()
    private lazy var pinStrokeError = pinTextField.addBottomStroke(color: .ows_accentRed, strokeWidth: 2)
    private let validationWarningLabel = UILabel()

    enum PinAttemptState {
        case unattempted
        case invalid(remainingAttempts: UInt32?)
        case exhausted
        case valid

        var isInvalid: Bool {
            switch self {
            case .unattempted, .valid:
                return false
            case .invalid, .exhausted:
                return true
            }
        }
    }
    private var attemptState: PinAttemptState = .unattempted {
        didSet {
            updateValidationWarnings()
        }
    }

    private let isUsingKBS: Bool
    private var pinType: KeyBackupService.PinType = .numeric {
        didSet {
            updatePinType()
        }
    }

    public init(onboardingController: OnboardingController, isUsingKBS: Bool) {
        self.isUsingKBS = isUsingKBS
        super.init(onboardingController: onboardingController)
    }

    override public func loadView() {
        view = UIView()
        view.addSubview(primaryView)
        primaryView.autoPinEdgesToSuperviewEdges()

        view.backgroundColor = Theme.backgroundColor

        let titleText = NSLocalizedString("XXGJUSTHHANQO29", comment: "Title of the 'onboarding PIN' view.")
        let explanationText = NSLocalizedString("XXGJUSTHHANQO28", comment: "Title of the 'onboarding PIN' view.")

        let titleLabel = self.titleLabel(text: titleText)
        let ROHSREFOEUUYZhuceThirdHonzy = self.ROHSREFOEUUYZhuceThirdHonzy(explanationText: explanationText)
        ROHSREFOEUUYZhuceThirdHonzy.font = UIFont.ows_dynamicTypeSubheadlineClamped
        ROHSREFOEUUYZhuceThirdHonzy.accessibilityIdentifier = "onboarding.2fa." + "ROHSREFOEUUYZhuceThirdHonzy"

        pinTextField.delegate = self
        pinTextField.isSecureTextEntry = true
        pinTextField.textColor = Theme.primaryTextColor
        pinTextField.font = .ows_dynamicTypeBodyClamped
        pinTextField.isSecureTextEntry = true
        pinTextField.defaultTextAttributes.updateValue(5, forKey: .kern)
        pinTextField.keyboardAppearance = Theme.keyboardAppearance
        pinTextField.setContentHuggingHorizontalLow()
        pinTextField.setCompressionResistanceHorizontalLow()
        pinTextField.autoSetDimension(.height, toSize: 40)
        pinTextField.accessibilityIdentifier = "onboarding.2fa.pinTextField"

        validationWarningLabel.textColor = .ows_accentRed
        validationWarningLabel.font = UIFont.ows_dynamicTypeCaption1Clamped
        validationWarningLabel.accessibilityIdentifier = "onboarding.2fa.validationWarningLabel"
        validationWarningLabel.numberOfLines = 0
        validationWarningLabel.setCompressionResistanceHigh()

        let forgotPinLink = self.linkButton(title: NSLocalizedString("XXGJUSTHHANQO6",
                                                                     comment: "Label for the 'forgot 2FA PIN' link in the 'onboarding 2FA' view."),
                                            selector: #selector(forgotPinLinkTapped))
        forgotPinLink.accessibilityIdentifier = "onboarding.2fa." + "forgotPinLink"

        let pinStack = UIStackView(arrangedSubviews: [
            pinTextField,
            UIView.spacer(withHeight: 10),
            validationWarningLabel,
            UIView.spacer(withHeight: 10),
            forgotPinLink
        ])
        pinStack.axis = .vertical
        pinStack.alignment = .fill

        let pinStackRow = UIView()
        pinStackRow.addSubview(pinStack)
        pinStack.autoHCenterInSuperview()
        pinStack.autoPinHeightToSuperview()
        pinStack.autoSetDimension(.width, toSize: 227)
        pinStackRow.setContentHuggingVerticalHigh()

        pinTypeToggle.setTitleColor(.ows_signalBlue, for: .normal)
        pinTypeToggle.titleLabel?.font = .ows_dynamicTypeSubheadlineClamped
        pinTypeToggle.addTarget(self, action: #selector(togglePinType), for: .touchUpInside)
        pinTypeToggle.accessibilityIdentifier = "pinCreation.pinTypeToggle"

        let nextButton = self.button(title: CommonStrings.nextButton,
                                     selector: #selector(nextPressed))
        nextButton.accessibilityIdentifier = "onboarding.2fa." + "nextButton"
        let primaryButtonView = OnboardingBaseViewController.horizontallyWrap(primaryButton: nextButton)

        let topSpacer = UIView.vStretchingSpacer()
        let bottomSpacer = UIView.vStretchingSpacer()
        let compressableBottomMargin = UIView.vStretchingSpacer(minHeight: 16, maxHeight: primaryLayoutMargins.bottom)

        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            UIView.spacer(withHeight: 10),
            ROHSREFOEUUYZhuceThirdHonzy,
            topSpacer,
            pinStackRow,
            bottomSpacer,
            pinTypeToggle,
            UIView.spacer(withHeight: 10),
            primaryButtonView,
            compressableBottomMargin
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        primaryView.addSubview(stackView)

        // Because of the keyboard, vertical spacing can get pretty cramped,
        // so we have custom spacer logic.
        stackView.autoPinEdges(toSuperviewMarginsExcludingEdge: .bottom)
        autoPinView(toBottomOfViewControllerOrKeyboard: stackView, avoidNotch: true)

        // Ensure whitespace is balanced, so inputs are vertically centered.
        topSpacer.autoMatch(.height, to: .height, of: bottomSpacer)

        updateValidationWarnings()
        updatePinType()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        _ = pinTextField.becomeFirstResponder()
    }

    // MARK: - Events

    @objc func forgotPinLinkTapped() {
        Logger.info("")

        OWSActionSheets.showActionSheet(
            title: NSLocalizedString("XXGJUSTHHANQR18",
                                     comment: "Alert title explaining what happens if you forget your 'two-factor auth pin'."),
            message: NSLocalizedString("XXGJUSTHHANQR17",
                                       comment: "Alert message explaining what happens if you forget your 'two-factor auth pin'.")
        )
    }

    @objc func nextPressed() {
        Logger.info("")

        tryToVerify()
    }

    private func tryToVerify(testTruncatedPin: Bool = false) {
        Logger.info("")

        var pinToUse = pinTextField.text

        // If true, we're doing a fallback verification to test if this is a
        // legacy pin that was created with >16 characters and then truncated.
        if testTruncatedPin {
            assert((pinToUse?.count ?? 0) > kLegacyTruncated2FAv1PinLength)
            pinToUse = pinToUse?.substring(to: Int(kLegacyTruncated2FAv1PinLength))
        }

        guard let pin = pinToUse?.ows_stripped(), pin.count >= kMin2FAPinLength else {
            // Check if we're already in an invalid state, if so we can do nothing
            guard !attemptState.isInvalid else { return }
            attemptState = .invalid(remainingAttempts: nil)
            return
        }

        // v1 pins also have a max length, but we'll rely on the server to verify that
        // since we do not know if this is a v1 or a v2 pin at registration time.

        onboardingController.update(twoFAPin: pin)

        onboardingController.submitVerification(fromViewController: self, completion: { (outcome) in
            switch outcome {
            case .invalid2FAPin:
                // In the past, we used to truncate pins. To support legacy users,
                // also attempt the truncated version of the pin if the original
                // did not match. This error only occurs for v1 registration locks,
                // the variant that includes remaining attempts is used for v2 locks
                // which should not have this problem.
                guard pin.count <= kLegacyTruncated2FAv1PinLength || testTruncatedPin else {
                    return self.tryToVerify(testTruncatedPin: true)
                }

                self.attemptState = .invalid(remainingAttempts: nil)
            case .invalidV2RegistrationLockPin(let remainingAttempts):
                self.attemptState = .invalid(remainingAttempts: remainingAttempts)
            case .exhaustedV2RegistrationLockAttempts:
                self.attemptState = .exhausted
                self.showAccountLocked()
            case .success:
                self.attemptState = .valid
            case .invalidVerificationCode:
                owsFailDebug("Invalid verification code in 2FA view.")
            }
        })
    }

    private func showAccountLocked() {
        guard let navigationController = navigationController else {
            owsFailDebug("Missing navigationController")
            return
        }

        let vc = OnboardingAccountLockedViewController(onboardingController: onboardingController)
        navigationController.pushViewController(vc, animated: true)
    }

    private func updateValidationWarnings() {
        AssertIsOnMainThread()

        pinStrokeNormal.isHidden = attemptState.isInvalid
        pinStrokeError.isHidden = !attemptState.isInvalid
        validationWarningLabel.isHidden = !attemptState.isInvalid

        switch attemptState {
        case .exhausted:
            validationWarningLabel.text = NSLocalizedString("XXGJUSTHHANQO1",
                                                            comment: "Label indicating that the 2fa pin is exhausted in the 'onboarding 2fa' view.")
        case .invalid(let remainingAttempts):
            guard let remaining = remainingAttempts else {
                validationWarningLabel.text = NSLocalizedString("XXGJUSTHHANQO7",
                                                                comment: "Label indicating that the 2fa pin is invalid in the 'onboarding 2fa' view.")
                break
            }

            // If there are less than the threshold attempts remaining, also show an alert with more detail.
            if remaining < attemptsAlertThreshold {
                let formatMessage: String
                if remaining == 1 {
                    formatMessage = NSLocalizedString("XXGJUSTHHANQR20",
                                                      comment: "Alert message explaining what happens if you get your pin wrong and have one attempt remaining 'two-factor auth pin'.")
                } else {
                    formatMessage = NSLocalizedString("XXGJUSTHHANQR19",
                                                      comment: "Alert message explaining what happens if you get your pin wrong and have multiple attempts remaining 'two-factor auth pin'.")
                }

                OWSActionSheets.showActionSheet(
                    title: NSLocalizedString("XXGJUSTHHANQR21",
                                             comment: "Alert title explaining what happens if you forget your 'two-factor auth pin'."),
                    message: String(format: formatMessage, remaining)
                )
            }

            let formatMessage: String
            if remaining == 1 {
                formatMessage = NSLocalizedString("XXGJUSTHHANQO9",
                                                  comment: "Label indicating that the 2fa pin is invalid with a retry count of one in the 'onboarding 2fa' view.")
            } else {
                formatMessage = NSLocalizedString("XXGJUSTHHANQO8",
                                                  comment: "Label indicating that the 2fa pin is invalid with a retry count other than one in the 'onboarding 2fa' view.")
            }

            validationWarningLabel.text = String(format: formatMessage, remaining)

        default:
            break
        }
    }

    private func updatePinType() {
        AssertIsOnMainThread()

        pinTextField.text = nil
        attemptState = .unattempted

        pinTypeToggle.isHidden = !isUsingKBS

        switch pinType {
        case .numeric:
            pinTypeToggle.setTitle(NSLocalizedString("XXGJUSTHHANQO2",
                                                     comment: "Button asking if the user would like to enter an alphanumeric PIN"), for: .normal)
            pinTextField.keyboardType = .asciiCapableNumberPad
        case .alphanumeric:
            pinTypeToggle.setTitle(NSLocalizedString("XXGJUSTHHANQO3",
                                                     comment: "Button asking if the user would like to enter an numeric PIN"), for: .normal)
            pinTextField.keyboardType = .default
        }

        pinTextField.reloadInputViews()
    }

    @objc func togglePinType() {
        guard isUsingKBS else {
            return owsFailDebug("unexpectedly tried to toggle PIN type when not using KBS")
        }

        switch pinType {
        case .numeric:
            pinType = .alphanumeric
        case .alphanumeric:
            pinType = .numeric
        }
    }
}

// MARK: -

extension Onboarding2FAViewController: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let hasPendingChanges: Bool
        if pinType == .numeric {
            ViewControllerUtils.ows2FAPINTextField(textField, shouldChangeCharactersIn: range, replacementString: string)
            hasPendingChanges = false
        } else {
            hasPendingChanges = true
        }

        // Reset the attempt state to clear errors, since the user is trying again
        attemptState = .unattempted

        return hasPendingChanges
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        tryToVerify()
        return false
    }
}
