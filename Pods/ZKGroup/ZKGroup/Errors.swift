
import Foundation

public enum ZkGroupException: Error {
    case InvalidInput
    case VerificationFailed
    case ZkGroupError
    case AssertionError
    case IllegalArgument
}
