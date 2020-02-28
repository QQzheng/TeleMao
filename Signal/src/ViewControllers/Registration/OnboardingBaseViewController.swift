
import UIKit
import PromiseKit

@objc
public class OnboardingBaseViewController: OWSViewController {
    let onboardingController: OnboardingController

    @objc
    public init(onboardingController: OnboardingController) {
        self.onboardingController = onboardingController
        super.init(nibName: nil, bundle: nil)
        self.shouldUseTheme = false
    }

    @available(*, unavailable, message: "use other init() instead.")
    required public init?(coder aDecoder: NSCoder) {
        notImplemented()
    }

    // MARK: - 版本1.0 UI
    func  xxgjusthBgView() -> UIView {
        var gao : CGFloat = 199
        if UIDevice.current.hasIPhoneXNotch {
            gao =  219
        }
        let ww = UIScreen.main.bounds.size.width
        
        let xxgjusthBgView = UIView()
        let xxgjusthDa = UIImageView(image: UIImage(named: "bg"))
        xxgjusthDa.frame = CGRect(x: 0, y: 0, width: ww, height: gao)
        xxgjusthBgView.addSubview(xxgjusthDa)
        
        let xxgjusthXi = UIImageView(image: UIImage(named: "bgXiao"))
        xxgjusthXi.frame = CGRect(x: ww*3/8, y: gao - ww/8, width: ww/4, height: ww/4)
        xxgjusthBgView.addSubview(xxgjusthXi)
       
        return xxgjusthBgView
    }

    func titleLabel(text: String) -> UILabel {
        let titleLabel = UILabel()
        titleLabel.text = text
        titleLabel.textColor = Theme.primaryTextColor
        titleLabel.font = UIFont.ows_dynamicTypeTitle1Clamped.ows_semibold()
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.textAlignment = .center
        return titleLabel
    }
    
    func ROHSREFOEUUYZhuceThirdHonzy(explanationText: String) -> UILabel {
        let ROHSREFOEUUYZhuceThirdHonzy = UILabel()
        ROHSREFOEUUYZhuceThirdHonzy.textColor = Theme.secondaryTextAndIconColor
        ROHSREFOEUUYZhuceThirdHonzy.font = UIFont.ows_dynamicTypeSubheadlineClamped
        ROHSREFOEUUYZhuceThirdHonzy.text = explanationText
        ROHSREFOEUUYZhuceThirdHonzy.numberOfLines = 0
        ROHSREFOEUUYZhuceThirdHonzy.textAlignment = .center
        ROHSREFOEUUYZhuceThirdHonzy.lineBreakMode = .byWordWrapping
        return ROHSREFOEUUYZhuceThirdHonzy
    }
    func button(title: String, selector: Selector) -> OWSFlatButton {
        return button(title: title, selector: selector, titleColor: .white, backgroundColor: .ows_signalBlue)
    }
    func linkButton(title: String, selector: Selector) -> OWSFlatButton {
        return button(title: title, selector: selector, titleColor: .ows_signalBlue, backgroundColor: .clear)
    }
   
    private func button(title: String, selector: Selector, titleColor: UIColor, backgroundColor: UIColor) -> OWSFlatButton {
        let font = UIFont.ows_dynamicTypeBodyClamped.ows_semibold()
        let buttonHeight = OWSFlatButton.heightForFont(font)
        let button = OWSFlatButton.button(title: title,
                                          font: font,
                                          titleColor: titleColor,
                                          backgroundColor: backgroundColor,
                                          target: self,
                                          selector: selector)
        button.autoSetDimension(.height, toSize: buttonHeight)
        button.layer.cornerRadius = buttonHeight/2
        button.clipsToBounds = true
        return button
    }
    // 版本1.0 UI --------------
    var primaryLayoutMargins: UIEdgeInsets {
        switch traitCollection.horizontalSizeClass {
        case .unspecified, .compact:
            return UIEdgeInsets(top: 32, leading: 32, bottom: 32, trailing: 32)
        case .regular:
            return UIEdgeInsets(top: 112, leading: 112, bottom: 112, trailing: 112)
        @unknown default:
            return UIEdgeInsets(top: 32, leading: 32, bottom: 32, trailing: 32)
        }
    }
    func shouldShowBackButton() -> Bool {
        return onboardingController.isOnboardingModeOverriden
    }

    public class func horizontallyWrap(primaryButton: UIView) -> UIView {
        primaryButton.autoSetDimension(.width, toSize: 280)

        let buttonWrapper = UIView()
        buttonWrapper.addSubview(primaryButton)

        primaryButton.autoPinEdge(toSuperviewEdge: .top)
        primaryButton.autoPinEdge(toSuperviewEdge: .bottom)
        primaryButton.autoHCenterInSuperview()
        NSLayoutConstraint.autoSetPriority(.defaultLow) {
            primaryButton.autoPinEdge(toSuperviewEdge: .leading)
            primaryButton.autoPinEdge(toSuperviewEdge: .trailing)
        }

        return buttonWrapper
    }

    // MARK: - View Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.shouldBottomViewReserveSpaceForKeyboard = true

        if (shouldShowBackButton()) {
            let backButton = UIButton()
            let backButtonImage = CurrentAppContext().isRTL ? #imageLiteral(resourceName: "NavBarBackRTL") : #imageLiteral(resourceName: "NavBarBack")
            backButton.setTemplateImage(backButtonImage, tintColor: Theme.secondaryTextAndIconColor)
            backButton.addTarget(self, action: #selector(navigateBack), for: .touchUpInside)

            view.addSubview(backButton)
            backButton.autoSetDimensions(to: CGSize(width: 40, height: 40))
            backButton.autoPinEdge(toSuperviewMargin: .leading)
            backButton.autoPinEdge(toSuperviewMargin: .top)
        }
    }

    @objc func navigateBack() {
        navigationController?.popViewController(animated: true)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.isNavigationBarHidden = true
        // Disable "back" gesture.
        self.navigationController?.navigationItem.backBarButtonItem?.isEnabled = false
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.navigationController?.isNavigationBarHidden = true
        // Disable "back" gesture.
        self.navigationController?.navigationItem.backBarButtonItem?.isEnabled = false
    }

    // The margins for `primaryView` will update to reflect the current traitCollection.
    // This includes handling changes to traits - e.g. when splitting an iPad or rotating
    // some iPhones.
    //
    // Subclasses should add primaryView as the single child of self.view and add any further
    // subviews to primaryView.
    //
    // If not for iOS10, we could get rid of primaryView, and manipulate the layoutMargins on
    // self.view directly, however on iOS10, UIKit VC presentation machinery resets the
    // layoutMargins *after* this method is called.
    let primaryView = UIView()
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        primaryView.layoutMargins = primaryLayoutMargins
    }

    // MARK: - Orientation

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.isIPad ? .all : .portrait
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
