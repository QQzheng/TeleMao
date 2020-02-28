
import Foundation

public struct OWSAssertionError: Error {
    public let errorCode: Int = SCKError.Code.assertionError.rawValue
    public let description: String
    public init(_ description: String) {
        owsFailDebug("assertionError: \(description)")
        self.description = description
    }
}
