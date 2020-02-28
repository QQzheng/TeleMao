
import Foundation

@objc
protocol AddToBlockListDelegate: class {
    func addToBlockListComplete()
}

@objc
class AddToBlockListViewController: OWSViewController {
    @objc weak var delegate: AddToBlockListDelegate?
    let recipientPicker = RecipientPickerViewController()

    var blockingManager: OWSBlockingManager {
        return .shared()
    }

    var contactsManager: OWSContactsManager {
        return Environment.shared.contactsManager
    }

    var messageSender: MessageSender {
        return SSKEnvironment.shared.messageSender
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("XXGJUSTHHANQB22",
                                  comment: "Title for the 'add to block list' view.")

        recipientPicker.delegate = self
        addChild(recipientPicker)
        view.addSubview(recipientPicker.view)

        recipientPicker.findByPhoneNumberButtonTitle = NSLocalizedString(
            "XXGJUSTHHANQB22",
            comment: "A label for the block button in the block list view"
        )
    }

    func block(address: SignalServiceAddress) {
        BlockListUIUtils.showBlockAddressActionSheet(
            address,
            from: self,
            blockingManager: blockingManager,
            contactsManager: contactsManager,
            completionBlock: { [weak self] isBlocked in
                guard isBlocked else { return }
                self?.delegate?.addToBlockListComplete()
            }
        )
    }

    func block(thread: TSThread) {
        BlockListUIUtils.showBlockThreadActionSheet(
            thread,
            from: self,
            blockingManager: blockingManager,
            contactsManager: contactsManager,
            messageSender: messageSender,
            completionBlock: { [weak self] isBlocked in
                guard isBlocked else { return }
                self?.delegate?.addToBlockListComplete()
            }
        )
    }
}

extension AddToBlockListViewController: RecipientPickerDelegate {
    func recipientPicker(
        _ recipientPickerViewController: RecipientPickerViewController,
        canSelectRecipient recipient: PickedRecipient
    ) -> Bool {
        switch recipient.identifier {
        case .address(let address):
            guard !recipientPicker.contactsViewHelper.isSignalServiceAddressBlocked(address) else { return false }
            return true
        case .group(let thread):
            guard !recipientPicker.contactsViewHelper.isThreadBlocked(thread) else { return false }
            return true
        }
    }

    func recipientPicker(
        _ recipientPickerViewController: RecipientPickerViewController,
        didSelectRecipient recipient: PickedRecipient
    ) {
        switch recipient.identifier {
        case .address(let address):
            block(address: address)
        case .group(let groupThread):
            block(thread: groupThread)
        }
    }

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
