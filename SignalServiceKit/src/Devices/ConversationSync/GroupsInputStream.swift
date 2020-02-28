

import Foundation

public struct GroupDetails {
    public let groupId: Data
    public let name: String?
    public let memberAddresses: [SignalServiceAddress]
    public let conversationColorName: String?
    public let isBlocked: Bool
    public let expireTimer: UInt32
    public let avatarData: Data?
    public let isArchived: Bool?
    public let inboxSortOrder: UInt32?
    public let groupsVersion: GroupsVersion?
    public let groupSecretParamsData: Data?
}

public class GroupsInputStream {
    var inputStream: ChunkedInputStream

    public init(inputStream: ChunkedInputStream) {
        self.inputStream = inputStream
    }

    public func decodeGroup() throws -> GroupDetails? {
        guard !inputStream.isEmpty else {
            return nil
        }

        var groupDataLength: UInt32 = 0
        try inputStream.decodeSingularUInt32Field(value: &groupDataLength)

        var groupData: Data = Data()
        try inputStream.decodeData(value: &groupData, count: Int(groupDataLength))

        let groupDetails = try SSKProtoGroupDetails.parseData(groupData)

        var avatarData: Data?
        if let avatar = groupDetails.avatar {
            var decodedData = Data()
            try inputStream.decodeData(value: &decodedData, count: Int(avatar.length))
            if decodedData.count > 0 {
                avatarData = decodedData
            }
        }

        // GroupsV2 TODO: Send and receive these values.
        let groupsVersion: GroupsVersion? = GroupsVersion.V1
        let groupSecretParamsData: Data? = nil

        return GroupDetails(groupId: groupDetails.id,
                            name: groupDetails.name,
                            memberAddresses: groupDetails.memberAddresses,
                            conversationColorName: groupDetails.color,
                            isBlocked: groupDetails.blocked,
                            expireTimer: groupDetails.expireTimer,
                            avatarData: avatarData,
                            isArchived: groupDetails.hasArchived ? groupDetails.archived : nil,
                            inboxSortOrder: groupDetails.hasInboxPosition ? groupDetails.inboxPosition : nil,
                            groupsVersion: groupsVersion,
                            groupSecretParamsData: groupSecretParamsData)
    }
}