
import Foundation

public class ProfileKeyCredentialRequest: ByteArray {

  public init(contents: [UInt8]) throws {
    fatalError("Not implemented.")
  }

  public func serialize() -> [UInt8] {
    return contents
  }
}