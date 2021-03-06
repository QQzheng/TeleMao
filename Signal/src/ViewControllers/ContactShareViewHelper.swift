
import Foundation
import SignalServiceKit
import ContactsUI
import MessageUI

@objc
public protocol ContactShareViewHelperDelegate: class {
    func didCreateOrEditContact()
    func sendFailMessage()
}

@objc
public class ContactShareViewHelper: NSObject, CNContactViewControllerDelegate,MFMessageComposeViewControllerDelegate {

    @objc
    weak var delegate: ContactShareViewHelperDelegate?

    let contactsManager: OWSContactsManager
    private let installUrl = "https://signal.org/install/"

    @objc
    public required init(contactsManager: OWSContactsManager) {
        AssertIsOnMainThread()

        self.contactsManager = contactsManager

        super.init()
    }

    // MARK: Actions

    @objc
    public func sendMessage(contactShare: ContactShareViewModel, fromViewController: UIViewController) {
        Logger.info("")

        presentThreadAndPeform(action: .compose, contactShare: contactShare, fromViewController: fromViewController)
    }

    @objc
    public func audioCall(contactShare: ContactShareViewModel, fromViewController: UIViewController) {
        Logger.info("")

        presentThreadAndPeform(action: .audioCall, contactShare: contactShare, fromViewController: fromViewController)
    }

    @objc
    public func videoCall(contactShare: ContactShareViewModel, fromViewController: UIViewController) {
        Logger.info("")

        presentThreadAndPeform(action: .videoCall, contactShare: contactShare, fromViewController: fromViewController)
    }

    private func presentThreadAndPeform(action: ConversationViewAction, contactShare: ContactShareViewModel, fromViewController: UIViewController) {
        let phoneNumbers = contactShare.systemContactsWithSignalAccountPhoneNumbers(contactsManager)
        guard phoneNumbers.count > 0 else {
            return
        }
        guard phoneNumbers.count > 1 else {
            let address = SignalServiceAddress(phoneNumber: phoneNumbers.first!)
            SignalApp.shared().presentConversation(for: address, action: action, animated: true)
            return
        }

        showPhoneNumberPicker(phoneNumbers: phoneNumbers, fromViewController: fromViewController, completion: { phoneNumber in
            SignalApp.shared().presentConversation(for: SignalServiceAddress(phoneNumber: phoneNumber), action: action, animated: true)
        })
    }

    @objc
    public func showInviteContact(contactShare: ContactShareViewModel, fromViewController: UIViewController) {
        Logger.info("")

        guard MFMessageComposeViewController.canSendText() else {
            Logger.info("Device cannot send text")
            OWSActionSheets.showErrorAlert(message: NSLocalizedString("XXGJUSTHHANQU21", comment: ""))
            return
        }
        let phoneNumbers = contactShare.e164PhoneNumbers()
        guard phoneNumbers.count > 0 else {
            owsFailDebug("no phone numbers.")
            return
        }

        //版本1.1 修改名片分享闪退
//       let inviteFlow = InviteFlow(presentingViewController: fromViewController)
//        inviteFlow.sendSMSTo(phoneNumbers: phoneNumbers)
        
        let messageComposeViewController = MFMessageComposeViewController()
        messageComposeViewController.messageComposeDelegate = self
        messageComposeViewController.recipients = phoneNumbers

        let inviteText = NSLocalizedString("XXGJUSTHHANQS157", comment: "body sent to contacts when inviting to Install Tmao")
        messageComposeViewController.body = inviteText.appending(" \(self.installUrl)")
        
        fromViewController.present(messageComposeViewController, animated: true)
    }

    @objc
    func showAddToContacts(contactShare: ContactShareViewModel, fromViewController: UIViewController) {
        Logger.info("")

        let actionSheet = ActionSheetController(title: nil, message: nil)

        actionSheet.addAction(ActionSheetAction(title: NSLocalizedString("XXGJUSTHHANQC110",
                                                                     comment: "Label for 'new contact' button in conversation settings view."),
                                            style: .default) { _ in
                                                self.didPressCreateNewContact(contactShare: contactShare, fromViewController: fromViewController)
        })
        actionSheet.addAction(ActionSheetAction(title: NSLocalizedString("XXGJUSTHHANQC95",
                                                                     comment: "Label for 'new contact' button in conversation settings view."),
                                            style: .default) { _ in
                                                self.didPressAddToExistingContact(contactShare: contactShare, fromViewController: fromViewController)
        })
        actionSheet.addAction(OWSActionSheets.cancelAction)

        fromViewController.presentActionSheet(actionSheet)
    }

    private func showPhoneNumberPicker(phoneNumbers: [String], fromViewController: UIViewController, completion :@escaping ((String) -> Void)) {

        let actionSheet = ActionSheetController(title: nil, message: nil)

        for phoneNumber in phoneNumbers {
            actionSheet.addAction(ActionSheetAction(title: PhoneNumber.bestEffortLocalizedPhoneNumber(withE164: phoneNumber),
                                                          style: .default) { _ in
                                                            completion(phoneNumber)
            })
        }
        actionSheet.addAction(OWSActionSheets.cancelAction)

        fromViewController.presentActionSheet(actionSheet)
    }

    func didPressCreateNewContact(contactShare: ContactShareViewModel, fromViewController: UIViewController) {
        Logger.info("")

        presentNewContactView(contactShare: contactShare, fromViewController: fromViewController)
    }

    func didPressAddToExistingContact(contactShare: ContactShareViewModel, fromViewController: UIViewController) {
        Logger.info("")

        presentSelectAddToExistingContactView(contactShare: contactShare, fromViewController: fromViewController)
    }

    // MARK: -

    private func presentNewContactView(contactShare: ContactShareViewModel, fromViewController: UIViewController) {
        guard contactsManager.supportsContactEditing else {
            owsFailDebug("Contact editing not supported")
            return
        }

        guard let systemContact = OWSContacts.systemContact(for: contactShare.dbRecord, imageData: contactShare.avatarImageData) else {
            owsFailDebug("Could not derive system contact.")
            return
        }

        guard contactsManager.isSystemContactsAuthorized else {
            ContactsViewHelper.presentMissingContactAccessAlertController(from: fromViewController)
            return
        }

        let contactViewController = CNContactViewController(forNewContact: systemContact)
        contactViewController.delegate = self
        contactViewController.allowsActions = false
        contactViewController.allowsEditing = true
        contactViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(title: CommonStrings.cancelButton,
                                                                                 style: .plain,
                                                                                 target: self,
                                                                                 action: #selector(didFinishEditingContact))

        let modal = OWSNavigationController(rootViewController: contactViewController)
        fromViewController.present(modal, animated: true)
    }

    private func presentSelectAddToExistingContactView(contactShare: ContactShareViewModel, fromViewController: UIViewController) {
        guard contactsManager.supportsContactEditing else {
            owsFailDebug("Contact editing not supported")
            return
        }

        guard contactsManager.isSystemContactsAuthorized else {
            ContactsViewHelper.presentMissingContactAccessAlertController(from: fromViewController)
            return
        }

        guard let navigationController = fromViewController.navigationController else {
            owsFailDebug("missing navigationController")
            return
        }

        let viewController = AddContactShareToExistingContactViewController(contactShare: contactShare)
        navigationController.pushViewController(viewController, animated: true)
    }

    // MARK: - CNContactViewControllerDelegate

    @objc public func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        Logger.info("")

        guard let delegate = delegate else {
            owsFailDebug("missing delegate")
            return
        }

        delegate.didCreateOrEditContact()
    }

    @objc public func didFinishEditingContact() {
        Logger.info("")

        guard let delegate = delegate else {
            owsFailDebug("missing delegate")
            return
        }

        delegate.didCreateOrEditContact()
    }
    
    //MARK: - MFMessageComposeViewControllerDelegate,版本1.1新增
    @objc public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        guard let delegate = delegate else {
            owsFailDebug("missing delegate")
            return
        }
        
        switch result {
        case .failed:
            delegate.sendFailMessage() //邀请失败
        case .sent:
            Logger.debug("user successfully invited their friends via SMS.")
        case .cancelled:
            Logger.debug("user cancelled message invite")
        @unknown default:
            owsFailDebug("unknown MessageComposeResult: \(result)")
        }
        
        delegate.didCreateOrEditContact()
    }
}
