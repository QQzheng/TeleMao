
import Foundation
import SignalServiceKit

@objc
public protocol ContactNameFieldViewDelegate: class {
    func nameFieldDidChange()
}

// MARK: -

class ContactNameFieldView: UIView {
    weak var delegate: ContactNameFieldViewDelegate?

    let name: String
    let initialValue: String?

    var valueView: UITextField!

    var hasUnsavedChanges = false

    // MARK: - Initializers

    @available(*, unavailable, message: "use other constructor instead.")
    required init?(coder aDecoder: NSCoder) {
        notImplemented()
    }

    required init(name: String, value: String?, delegate: ContactNameFieldViewDelegate) {
        self.name = name
        self.initialValue = value
        self.delegate = delegate

        super.init(frame: CGRect.zero)

        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(wasTapped)))

        createContents()
    }

    private let hMargin = CGFloat(16)
    private let vMargin = CGFloat(10)

    func createContents() {
        self.layoutMargins = UIEdgeInsets(top: vMargin, left: hMargin, bottom: vMargin, right: hMargin)

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.layoutMargins = .zero
        stackView.spacing = 10
        self.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewMargins()

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = UIFont.ows_dynamicTypeBody
        nameLabel.textColor = UIColor.ows_signalBlue
        nameLabel.lineBreakMode = .byTruncatingTail
        stackView.addArrangedSubview(nameLabel)
        nameLabel.setContentHuggingHigh()
        nameLabel.setCompressionResistanceHigh()

        valueView = UITextField()
        if let initialValue = initialValue {
            valueView.text = initialValue
        }
        valueView.font = UIFont.ows_dynamicTypeBody
        valueView.textColor = Theme.primaryTextColor
        stackView.addArrangedSubview(valueView)

        valueView.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    @objc func wasTapped(sender: UIGestureRecognizer) {
        Logger.info("")

        guard sender.state == .recognized else {
            return
        }

        valueView.becomeFirstResponder()
    }

    @objc func textFieldDidChange(sender: UITextField) {
        Logger.info("")

        hasUnsavedChanges = true

        guard let delegate = self.delegate else {
            owsFailDebug("missing delegate.")
            return
        }

        delegate.nameFieldDidChange()
    }

    public func value() -> String {
        guard let value = valueView.text else {
            return ""
        }
        return value
    }
}

// MARK: -

@objc
public protocol EditContactShareNameViewControllerDelegate: class {
    func editContactShareNameView(_ editContactShareNameView: EditContactShareNameViewController,
                                  didEditContactShare contactShare: ContactShareViewModel)
}

// MARK: -

@objc
public class EditContactShareNameViewController: OWSViewController, ContactNameFieldViewDelegate {
    weak var delegate: EditContactShareNameViewControllerDelegate?

    let contactShare: ContactShareViewModel

    var namePrefixView: ContactNameFieldView!
    var givenNameView: ContactNameFieldView!
    var middleNameView: ContactNameFieldView!
    var familyNameView: ContactNameFieldView!
    var nameSuffixView: ContactNameFieldView!
    var organizationNameView: ContactNameFieldView!

    var fieldViews = [ContactNameFieldView]()

    // MARK: Initializers

    @available(*, unavailable, message:"use other constructor instead.")
    required public init?(coder aDecoder: NSCoder) {
        notImplemented()
    }

    @objc
    required public init(contactShare: ContactShareViewModel, delegate: EditContactShareNameViewControllerDelegate) {
        self.contactShare = contactShare
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        buildFields()
    }

    func buildFields() {
        namePrefixView = ContactNameFieldView(name: NSLocalizedString("XXGJUSTHHANQC70",
                                                                      comment: "Label for the 'name prefix' field of a contact."),
                                              value: contactShare.name.namePrefix, delegate: self)
        givenNameView = ContactNameFieldView(name: NSLocalizedString("XXGJUSTHHANQC68",
                                                                     comment: "Label for the 'given name' field of a contact."),
                                             value: contactShare.name.givenName, delegate: self)
        middleNameView = ContactNameFieldView(name: NSLocalizedString("XXGJUSTHHANQC69",
                                                                      comment: "Label for the 'middle name' field of a contact."),
                                              value: contactShare.name.middleName, delegate: self)
        familyNameView = ContactNameFieldView(name: NSLocalizedString("XXGJUSTHHANQC67",
                                                                      comment: "Label for the 'family name' field of a contact."),
                                              value: contactShare.name.familyName, delegate: self)
        nameSuffixView = ContactNameFieldView(name: NSLocalizedString("XXGJUSTHHANQC71",
                                                                      comment: "Label for the 'name suffix' field of a contact."),
                                              value: contactShare.name.nameSuffix, delegate: self)
        organizationNameView = ContactNameFieldView(name: NSLocalizedString("XXGJUSTHHANQC72",
                                                                            comment: "Label for the 'organization' field of a contact."),
                                              value: contactShare.name.organizationName, delegate: self)
        fieldViews = [
            namePrefixView ,
            givenNameView ,
            middleNameView ,
            familyNameView ,
            nameSuffixView,
            organizationNameView
        ]
    }

    // MARK: - View Lifecycle

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateNavigationBar()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override public func loadView() {
        super.loadView()

        self.navigationItem.title = NSLocalizedString("XXGJUSTHHANQC78",
                                                      comment: "Title for the 'edit contact share name' view.")

        self.view.preservesSuperviewLayoutMargins = false
        self.view.backgroundColor = Theme.backgroundColor

        updateContent()

        updateNavigationBar()
    }

    func hasUnsavedChanges() -> Bool {
        for fieldView in fieldViews {
            if fieldView.hasUnsavedChanges {
                return true
            }
        }
        return false
    }

    func updateNavigationBar() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                target: self,
                                                                action: #selector(didPressCancel))

        if hasUnsavedChanges() {
            self.navigationItem.rightBarButtonItem =
                UIBarButtonItem(barButtonSystemItem: .save,
                                target: self,
                                action: #selector(didPressSave))
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }

    private func updateContent() {
        AssertIsOnMainThread()

        guard let rootView = self.view else {
            owsFailDebug("missing root view.")
            return
        }

        for subview in rootView.subviews {
            subview.removeFromSuperview()
        }

        let scrollView = UIScrollView()
        scrollView.preservesSuperviewLayoutMargins = false
        self.view.addSubview(scrollView)
        scrollView.layoutMargins = .zero
        scrollView.autoPinWidthToSuperview()
        scrollView.autoPin(toTopLayoutGuideOf: self, withInset: 0)
        scrollView.autoPinEdge(toSuperviewEdge: .bottom)

        let fieldsView = createFieldsView()

        scrollView.addSubview(fieldsView)
        fieldsView.autoPinLeadingToSuperviewMargin()
        fieldsView.autoPinTrailingToSuperviewMargin()
        fieldsView.autoPinEdge(toSuperviewEdge: .top)
        fieldsView.autoPinEdge(toSuperviewEdge: .bottom)
    }

    private func createFieldsView() -> UIView {
        AssertIsOnMainThread()

        var rows = [UIView]()

        for fieldView in fieldViews {
            rows.append(fieldView)
        }

        return ContactFieldView(rows: rows, hMargin: hMargin)
    }

    private let hMargin = CGFloat(16)

    // MARK: -

    @objc func didPressSave() {
        Logger.info("")

        guard let newName = OWSContactName() else {
            owsFailDebug("could not create a new name.")
            return
        }
        newName.namePrefix = namePrefixView.value().ows_stripped()
        newName.givenName = givenNameView.value().ows_stripped()
        newName.middleName = middleNameView.value().ows_stripped()
        newName.familyName = familyNameView.value().ows_stripped()
        newName.nameSuffix = nameSuffixView.value().ows_stripped()
        newName.organizationName = organizationNameView.value().ows_stripped()

        let modifiedContactShare = contactShare.copy(withName: newName)

        guard let delegate = self.delegate else {
            owsFailDebug("missing delegate.")
            return
        }

        delegate.editContactShareNameView(self, didEditContactShare: modifiedContactShare)

        guard let navigationController = self.navigationController else {
            owsFailDebug("Missing navigationController.")
            return
        }
        navigationController.popViewController(animated: true)
    }

    @objc func didPressCancel() {
        Logger.info("")

        guard let navigationController = self.navigationController else {
            owsFailDebug("Missing navigationController.")
            return
        }
        navigationController.popViewController(animated: true)
    }

    // MARK: - ContactNameFieldViewDelegate

    public func nameFieldDidChange() {
        updateNavigationBar()
    }
}
