

import Foundation

@objc
public extension TSInfoMessage {

    // MARK: - Dependencies

    var contactsManager: ContactsManagerProtocol {
        return SSKEnvironment.shared.contactsManager
    }

    func groupUpdateDescription(transaction: SDSAnyReadTransaction) -> String {
        // for legacy group updates we persisted a pre-rendered string, rather than the details
        // to generate that string
        if let customMessage = self.customMessage {
            return customMessage
        }

        let genericDescription = NSLocalizedString("XXGJUSTHHANQG26", comment: "conversation history entry")

        guard let newGroupModel = self.newGroupModel else {
            return genericDescription
        }

        guard let groupUpdater = self.groupUpdateSourceAddress else {
            if self.previousGroupModel == nil {
                return NSLocalizedString("XXGJUSTHHANQG14", comment: "conversation history entry")
            } else {
                return genericDescription
            }
        }

        return groupUpdateDescription(fromGroupState: self.previousGroupModel,
                                      toGroupState: newGroupModel,
                                      groupUpdater: groupUpdater,
                                      transaction: transaction)
    }

    func groupUpdateDescription(fromGroupState: TSGroupModel?,
                                toGroupState: TSGroupModel,
                                groupUpdater: SignalServiceAddress,
                                transaction: SDSAnyReadTransaction) -> String {
        let updaterName = self.contactsManager.displayName(for: groupUpdater, transaction: transaction)

        guard let fromGroupState = fromGroupState else {
            // New Group was created
            if groupUpdater.isLocalAddress {
                return NSLocalizedString("XXGJUSTHHANQG15",
                                         comment: "conversation history entry when the local user created a group")
            } else {
                let format = NSLocalizedString("XXGJUSTHHANQG16",
                                               comment: "conversation history entry after a remote user added you to a group. Embeds {{remote user name}}")
                return String(format: format, updaterName)
            }
        }

        // Existing Group was updated

        var lines: [String] = []
        if groupUpdater.isLocalAddress {
            lines.append(NSLocalizedString("XXGJUSTHHANQG31",
                                           comment: "conversation history entry."))
        } else {
            let format = NSLocalizedString("XXGJUSTHHANQG32",
                                           comment: "conversation history entry. Embeds {{remote user's name}}")
            let text = String(format: format, updaterName)
            lines.append(text)
        }

        if toGroupState.groupName != fromGroupState.groupName {
            if let toGroupName = toGroupState.groupName, toGroupName.count > 0 {
                let format = NSLocalizedString("XXGJUSTHHANQG34",
                                               comment: "conversation history entry. Embeds {{group name}}")
                let text = String(format: format, toGroupName)
                lines.append(text)
            } else {
                let text = NSLocalizedString("XXGJUSTHHANQG33",
                                             comment: "conversation history entry")
                lines.append(text)
            }
        }

        if fromGroupState.groupAvatarData != toGroupState.groupAvatarData {
            if let toGroupAvatarData = toGroupState.groupAvatarData, toGroupAvatarData.count > 0 {
                let text = NSLocalizedString("XXGJUSTHHANQG30",
                                             comment: "conversation history entry")
                lines.append(text)
            } else {
                let text = NSLocalizedString("XXGJUSTHHANQG29",
                                             comment: "conversation history entry")
                lines.append(text)
            }
        }

        let addedMembers = toGroupState.groupMembers.filter { !fromGroupState.groupMembers.contains($0) }
        let localUserAddedToGroup = (addedMembers.first { $0 == TSAccountManager.localAddress } != nil)
        if localUserAddedToGroup {
            let text = NSLocalizedString("XXGJUSTHHANQG35",
                                         comment: "conversation history entry")
            lines.append(text)
        } else if addedMembers.count == 1 {
            let format = NSLocalizedString("XXGJUSTHHANQG28",
                                           comment: "conversation history entry. Embeds the {{added user's name}}")

            let userName = contactsManager.displayName(for: addedMembers[0], transaction: transaction)
            let text = String(format: format, userName)
            lines.append(text)
        } else if addedMembers.count >= 2 {
            let firstMembers = addedMembers[0..<addedMembers.count - 1]
            let firstMembersText = firstMembers.map {
                contactsManager.displayName(for: $0, transaction: transaction)
            }.joined(separator: ", ")

            let finalMember = addedMembers[addedMembers.count - 1]
            let finalMemberText = contactsManager.displayName(for: finalMember, transaction: transaction)

            let format = NSLocalizedString("XXGJUSTHHANQG27",
                                           comment: "conversation history entry.  embeds {0: all but the final member} and {1: the final member}")

            let text = String(format: format, firstMembersText, finalMemberText)
            lines.append(text)
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    private var previousGroupModel: TSGroupModel? {
        guard let infoMessageUserInfo = self.infoMessageUserInfo else {
            return nil
        }

        guard let groupModel = infoMessageUserInfo[.oldGroupModel] as? TSGroupModel else {
            assert(infoMessageUserInfo[.oldGroupModel] == nil)
            return nil
        }

        return groupModel
    }

    private var newGroupModel: TSGroupModel? {
        guard let infoMessageUserInfo = self.infoMessageUserInfo else {
            return nil
        }

        guard let groupModel = infoMessageUserInfo[.newGroupModel] as? TSGroupModel else {
            assert(infoMessageUserInfo[.newGroupModel] == nil)
            return nil
        }

        return groupModel
    }

    private var groupUpdateSourceAddress: SignalServiceAddress? {
        guard let infoMessageUserInfo = self.infoMessageUserInfo else {
            return nil
        }

        guard let address = infoMessageUserInfo[.groupUpdateSourceAddress] as? SignalServiceAddress else {
            assert(infoMessageUserInfo[.groupUpdateSourceAddress] == nil)
            return nil
        }

        return address
    }
}
