
import Foundation

public enum SMKError: Error {
    case assertionError(description: String)
    case invalidInput(_ description: String)
}
