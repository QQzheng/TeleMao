
import UIKit
import PromiseKit
import Contacts
import Lottie

@objc
public class OnboardingPermissionsViewController: OnboardingBaseViewController {

//    private let animationView = AnimationView(name: "notificationPermission")
//版本1.0 UI
    override public func loadView() {
        view = UIView()
        view.addSubview(primaryView)
        primaryView.autoPinEdgesToSuperviewEdges()

        view.backgroundColor = Theme.backgroundColor
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("XXGJUSTHHANQN1", comment: "A button to skip a view."),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(skipWasPressed))
        
        //版本1.1 UI 修改
        var gao : CGFloat = 199 + UIScreen.main.bounds.size.width/8
        var statusH : CGFloat  = 20
        if UIDevice.current.hasIPhoneXNotch {
            gao = 219 + UIScreen.main.bounds.size.width/8
            statusH = 40
        }
        let bgview = self.xxgjusthBgView()
        bgview.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: gao)
        primaryView.addSubview(bgview)
        
        
        let titleLabel = self.titleLabel(text: NSLocalizedString("XXGJUSTHHANQO25", comment: "标题"))
        titleLabel.accessibilityIdentifier = "onboarding.permissions." + "titleLabel"
        
        let ROHSREFOEUUYZhuceThirdHonzy = self.ROHSREFOEUUYZhuceThirdHonzy(explanationText: NSLocalizedString("XXGJUSTHHANQO24",
                                                                                  comment: "备注"))
        ROHSREFOEUUYZhuceThirdHonzy.accessibilityIdentifier = "onboarding.permissions." + "ROHSREFOEUUYZhuceThirdHonzy"

        let giveAccessButton = self.button(title: NSLocalizedString("XXGJUSTHHANQO23",
                                                                    comment: "允许权限"),
                                           selector: #selector(giveAccessPressed))
        giveAccessButton.accessibilityIdentifier = "onboarding.permissions." + "giveAccessButton"
        let primaryButtonView = OnboardingBaseViewController.horizontallyWrap(primaryButton: giveAccessButton)
        
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            UIView.spacer(withHeight: 20),
            ROHSREFOEUUYZhuceThirdHonzy,
            UIView.vStretchingSpacer(),
            primaryButtonView
            ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.layoutMargins = UIEdgeInsets(top: 32, left: 32, bottom: 32, right: 32)
        stackView.isLayoutMarginsRelativeArrangement = true
        primaryView.addSubview(stackView)
        stackView.autoPinWidthToSuperview()
        stackView.autoPin(toTopLayoutGuideOf: self, withInset: gao - statusH)
        stackView.autoPin(toBottomLayoutGuideOf: self, withInset: 0)



//
//        let stackView = UIStackView(arrangedSubviews: [
//            titleLabel,
//            UIView.spacer(withHeight: 20),
//            explanationLabel,
//            UIView.spacer(withHeight: 60),
////            animationView,
////            UIView.vStretchingSpacer(minHeight: 80),
//            primaryButtonView
//        ])
//        stackView.axis = .vertical
//        stackView.alignment = .fill
//        stackView.spacing = 0
//        primaryView.addSubview(stackView)
//
//        stackView.autoPinEdgesToSuperviewMargins()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
      //  self.animationView.play()
    }

    // MARK: Request Access

    private func requestAccess() {
        Logger.info("")

        requestContactsAccess().then { _ in
            return PushRegistrationManager.shared.registerUserNotificationSettings()
        }.done { [weak self] in
            guard let self = self else {
                return
            }
            self.onboardingController.onboardingPermissionsDidComplete(viewController: self)
            }.retainUntilComplete()
    }

    private func requestContactsAccess() -> Promise<Void> {
        Logger.info("")

        let (promise, resolver) = Promise<Void>.pending()
        CNContactStore().requestAccess(for: CNEntityType.contacts) { (granted, error) -> Void in
            if granted {
                Logger.info("Granted.")
            } else {
                Logger.error("Error: \(String(describing: error)).")
            }
            // Always fulfill.
            resolver.fulfill(())
        }
        return promise
    }

     // MARK: - Events

    @objc func skipWasPressed() {
        Logger.info("")

        onboardingController.onboardingPermissionsWasSkipped(viewController: self)
    }

    @objc func giveAccessPressed() {
        Logger.info("")

        requestAccess()
    }

    @objc func notNowPressed() {
        Logger.info("")

        onboardingController.onboardingPermissionsWasSkipped(viewController: self)
    }
}
