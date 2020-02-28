

import Foundation

/**
 * Strings re-used in multiple places should be added here.
 */

@objc public class CommonStrings: NSObject {
    @objc
    static public let backButton = NSLocalizedString("XXGJUSTHHANQB1", comment: "return to the previous screen")

    @objc
    static public let continueButton = NSLocalizedString("XXGJUSTHHANQB42", comment: "Label for 'continue' button.")

    @objc
    static public let dismissButton = NSLocalizedString("XXGJUSTHHANQD32", comment: "Short text to dismiss current modal / actionsheet / screen")

    @objc
    static public let cancelButton = NSLocalizedString("XXGJUSTHHANQT19", comment: "Label for the cancel button in an alert or action sheet.")

    @objc
    static public let doneButton = NSLocalizedString("XXGJUSTHHANQB43", comment: "Label for generic done button.")

    @objc
    static public let nextButton = NSLocalizedString("XXGJUSTHHANQB44", comment: "Label for the 'next' button.")

    @objc
    static public let retryButton = NSLocalizedString("XXGJUSTHHANQL7", comment: "Generic text for button that retries whatever the last action was.")

    @objc
    static public let openSettingsButton = NSLocalizedString("XXGJUSTHHANQK13", comment: "Button text which opens the settings app")

    @objc
    static public let errorAlertTitle = NSLocalizedString("XXGJUSTHHANQA19", comment: "")

    @objc
    static public let searchPlaceholder = NSLocalizedString("XXGJUSTHHANQH3", comment: "placeholder text in an empty search field")

    @objc
    static public let mainPhoneNumberLabel = NSLocalizedString("XXGJUSTHHANQP16", comment: "Label for 'Main' phone numbers.")
}

@objc
public class CommonFormats: NSObject {
    @objc
    static public func formatUsername(_ username: String) -> String? {
        guard let username = username.filterForDisplay else { return nil }
        return NSLocalizedString("XXGJUSTHHANQU40",
                                 comment: "A prefix appeneded to all usernames when displayed") + username
    }
}

@objc
public class MessageStrings: NSObject {

    @objc
    static public let conversationIsBlocked = NSLocalizedString("XXGJUSTHHANQC55", comment: "An indicator that a contact or group has been blocked.")

    @objc
    static public let newGroupDefaultTitle = NSLocalizedString("XXGJUSTHHANQN15", comment: "Used in place of the group name when a group has not yet been named.")

    @objc
    static public let replyNotificationAction = NSLocalizedString("XXGJUSTHHANQP106", comment: "Notification action button title")

    @objc
    static public let markAsReadNotificationAction = NSLocalizedString("XXGJUSTHHANQP105", comment: "Notification action button title")

    @objc
    static public let sendButton =  NSLocalizedString("XXGJUSTHHANQS40", comment: "Label for the button to send a message")

    @objc
    static public let noteToSelf = NSLocalizedString("XXGJUSTHHANQN28", comment: "Label for 1:1 conversation with yourself.")

    @objc
    static public let viewOnceViewPhoto = NSLocalizedString("XXGJUSTHHANQP8", comment: "Label for view-once messages indicating that user can tap to view the message's contents.")

    @objc
    static public let viewOnceViewVideo = NSLocalizedString("XXGJUSTHHANQP9", comment: "Label for view-once messages indicating that user can tap to view the message's contents.")
}

@objc
public class NotificationStrings: NSObject {
    @objc
    static public let incomingCallBody = NSLocalizedString("XXGJUSTHHANQC0", comment: "notification body")

    @objc
    static public let missedCallBody = NSLocalizedString("XXGJUSTHHANQC3", comment: "notification body")

    @objc
    static public let missedCallBecauseOfIdentityChangeBody = NSLocalizedString("XXGJUSTHHANQC2", comment: "notification body")

    @objc
    static public let incomingMessageBody = NSLocalizedString("XXGJUSTHHANQA22", comment: "notification body")

    @objc
    static public let incomingGroupMessageTitleFormat = NSLocalizedString("XXGJUSTHHANQN17", comment: "notification title. Embeds {{author name}} and {{group name}}")

    @objc
    static public let failedToSendBody = NSLocalizedString("XXGJUSTHHANQS41", comment: "notification body")

    @objc
    static public let incomingReactionFormat = NSLocalizedString("XXGJUSTHHANQR2",
                                                                 comment: "notification body. Embeds {{reaction emoji}}")

    @objc
    static public let incomingReactionTextMessageFormat = NSLocalizedString("XXGJUSTHHANQR10",
                                                                            comment: "notification body. Embeds {{reaction emoji}} and {{body text}}")

    @objc
    static public let incomingReactionViewOnceMessageFormat = NSLocalizedString("XXGJUSTHHANQR12",
                                                                                comment: "notification body. Embeds {{reaction emoji}}")

    @objc
    static public let incomingReactionStickerMessageFormat = NSLocalizedString("XXGJUSTHHANQR9",
                                                                               comment: "notification body. Embeds {{reaction emoji}}")

    @objc
    static public let incomingReactionContactShareMessageFormat = NSLocalizedString("XXGJUSTHHANQR5",
                                                                                    comment: "notification body. Embeds {{reaction emoji}}")

    @objc
    static public let incomingReactionAlbumMessageFormat = NSLocalizedString("XXGJUSTHHANQR3",
                                                                             comment: "notification body. Embeds {{reaction emoji}}")

    @objc
    static public let incomingReactionPhotoMessageFormat = NSLocalizedString("XXGJUSTHHANQR8",
                                                                             comment: "notification body. Embeds {{reaction emoji}}")

    @objc
    static public let incomingReactionVideoMessageFormat = NSLocalizedString("XXGJUSTHHANQR11",
                                                                             comment: "notification body. Embeds {{reaction emoji}}")

    @objc
    static public let incomingReactionVoiceMessageFormat = NSLocalizedString("XXGJUSTHHANQR13",
                                                                             comment: "notification body. Embeds {{reaction emoji}}")

    @objc
    static public let incomingReactionAudioMessageFormat = NSLocalizedString("XXGJUSTHHANQR4",
                                                                             comment: "notification body. Embeds {{reaction emoji}}")

    @objc
    static public let incomingReactionGifMessageFormat = NSLocalizedString("XXGJUSTHHANQR7",
                                                                            comment: "notification body. Embeds {{reaction emoji}}")

    @objc
    static public let incomingReactionFileMessageFormat = NSLocalizedString("XXGJUSTHHANQR6",
                                                                            comment: "notification body. Embeds {{reaction emoji}}")
}

@objc public class CallStrings: NSObject {
    @objc
    static public let callStatusFormat = NSLocalizedString("XXGJUSTHHANQC5", comment: "embeds {{Call Status}} in call screen label. For ongoing calls, {{Call Status}} is a seconds timer like 01:23, otherwise {{Call Status}} is a short text like 'Ringing', 'Busy', or 'Failed Call'")

    @objc
    static public let confirmAndCallButtonTitle = NSLocalizedString("XXGJUSTHHANQS2", comment: "alert button text to confirm placing an outgoing call after the recipients Safety Number has changed.")

    @objc
    static public let callBackAlertTitle = NSLocalizedString("XXGJUSTHHANQC8", comment: "Title for alert offering to call a user.")
    @objc
    static public let callBackAlertMessageFormat = NSLocalizedString("XXGJUSTHHANQC7", comment: "Message format for alert offering to call a user. Embeds {{the user's display name or phone number}}.")
    @objc
    static public let callBackAlertCallButton = NSLocalizedString("XXGJUSTHHANQC1", comment: "Label for call button for alert offering to call a user.")

    // MARK: Notification actions
    @objc
    static public let callBackButtonTitle = NSLocalizedString("XXGJUSTHHANQC23", comment: "notification action")
    @objc
    static public let showThreadButtonTitle = NSLocalizedString("XXGJUSTHHANQS156", comment: "notification action")
    @objc
    static public let answerCallButtonTitle = NSLocalizedString("XXGJUSTHHANQA21", comment: "notification action")
    @objc
    static public let declineCallButtonTitle = NSLocalizedString("XXGJUSTHHANQR41", comment: "notification action")
}

@objc public class MediaStrings: NSObject {
    @objc
    static public let allMedia = NSLocalizedString("XXGJUSTHHANQM1", comment: "nav bar button item")
}

@objc public class SafetyNumberStrings: NSObject {
    @objc
    static public let confirmSendButton = NSLocalizedString("XXGJUSTHHANQS3",
                                                      comment: "button title to confirm sending to a recipient whose safety number recently changed")
}

@objc public class MegaphoneStrings: NSObject {
    @objc
    static public let remindMeLater = NSLocalizedString("XXGJUSTHHANQM8", comment: "button title to snooze a megaphone")

    @objc
    static public let weWillRemindYouLater = NSLocalizedString("XXGJUSTHHANQM9", comment: "toast indicating that we will remind the user later")
}
