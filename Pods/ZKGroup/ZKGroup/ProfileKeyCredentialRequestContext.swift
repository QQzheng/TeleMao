
import Foundation

public class ProfileKeyCredentialRequestContext: ByteArray {

  public init(contents: [UInt8]) throws {
    fatalError("Not implemented.")
  }

  public func getRequest() throws  -> ProfileKeyCredentialRequest {
    fatalError("Not implemented.")
  }

  public func serialize() -> [UInt8] {
    return contents
  }
}
