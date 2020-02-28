

import Foundation
import PromiseKit

class FakeAccountServiceClient: AccountServiceClient {
    override init() {}

    // MARK: - Public
//版本1.0 缺少v1/accounts/apn/preauth 接口
//    public override func requestPreauthChallenge(recipientId: String, pushToken: String) -> Promise<Void> {
//        return Promise { $0.fulfill(()) }
//    }

    public override func requestVerificationCode(recipientId: String, preauthChallenge: String?, captchaToken: String?, transport: TSVerificationTransport) -> Promise<Void> {
        return Promise { $0.fulfill(()) }
    }

    public override func getPreKeysCount() -> Promise<Int> {
        return Promise { $0.fulfill(0) }
    }

    public override func setPreKeys(identityKey: IdentityKey, signedPreKeyRecord: SignedPreKeyRecord, preKeyRecords: [PreKeyRecord]) -> Promise<Void> {
        return Promise { $0.fulfill(()) }
    }

    public override func setSignedPreKey(_ signedPreKey: SignedPreKeyRecord) -> Promise<Void> {
        return Promise { $0.fulfill(()) }
    }

    public override func updatePrimaryDeviceAccountAttributes() -> Promise<Void> {
        return Promise { $0.fulfill(()) }
    }

    public override func getUuid() -> Promise<UUID> {
        return Promise { $0.fulfill(UUID()) }
    }
}
