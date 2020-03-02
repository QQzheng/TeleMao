
import Foundation

@objc
class ComposeViewController: OWSViewController {
    let recipientPicker = RecipientPickerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        // lcy 20200302 通讯录标题修改
        title = "通讯录"

        recipientPicker.allowsSelectingUnregisteredPhoneNumbers = false
        recipientPicker.shouldShowInvites = true
        recipientPicker.delegate = self
        addChild(recipientPicker)
        view.addSubview(recipientPicker.view)

        // lcy 20200302 导航栏按钮UI修改
//        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismissPressed))

//        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "btnGroup--white"), style: .plain, target: self, action: #selector(newGroupPressed))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "plus"), style: .plain, target: self, action: #selector(newGroupPressed))

        navigationItem.rightBarButtonItem?.accessibilityLabel = NSLocalizedString("XXGJUSTHHANQN12", comment: "Accessibility label for the new group button")
    }

    @objc func dismissPressed() {
        dismiss(animated: true)
    }

    @objc func newGroupPressed() {
        navigationController?.pushViewController(NewGroupViewController(), animated: true)
    }

    func newConversation(address: SignalServiceAddress) {
        assert(address.isValid)
        let thread = TSContactThread.getOrCreateThread(contactAddress: address)
        newConversation(thread: thread)
    }

    func newConversation(thread: TSThread) {
        /**
         lcy 20200302 通讯录点击跳转到对话页面跳转修改
         */
        DispatchQueue.main.async {
            let vc = ConversationViewController()
            vc.configure(for: thread, action: .compose, focusMessageId: nil)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
//        SignalApp.shared().presentConversation(for: thread, action: .compose, animated: false)
//        presentingViewController?.dismiss(animated: true)
    }
}

extension ComposeViewController: RecipientPickerDelegate {
    func recipientPicker(
        _ recipientPickerViewController: RecipientPickerViewController,
        canSelectRecipient recipient: PickedRecipient
    ) -> Bool {
        return true
    }

    func recipientPicker(
        _ recipientPickerViewController: RecipientPickerViewController,
        didSelectRecipient recipient: PickedRecipient
    ) {
        switch recipient.identifier {
        case .address(let address):
            newConversation(address: address)
        case .group(let groupThread):
            newConversation(thread: groupThread)
        }
    }

    func recipientPicker(
        _ recipientPickerViewController: RecipientPickerViewController,
        didDeselectRecipient recipient: PickedRecipient
    ) {}

    func recipientPicker(
        _ recipientPickerViewController: RecipientPickerViewController,
        accessoryMessageForRecipient recipient: PickedRecipient
    ) -> String? {
        switch recipient.identifier {
        case .address(let address):
            guard recipientPicker.contactsViewHelper.isSignalServiceAddressBlocked(address) else { return nil }
            return MessageStrings.conversationIsBlocked
        case .group(let thread):
            guard recipientPicker.contactsViewHelper.isThreadBlocked(thread) else { return nil }
            return MessageStrings.conversationIsBlocked
        }
    }

    func recipientPickerTableViewWillBeginDragging(_ recipientPickerViewController: RecipientPickerViewController) {}
}
