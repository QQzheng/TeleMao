
import Foundation

public class ProfileKeyCommitment: ByteArray {

  public init(contents: [UInt8]) throws {
    fatalError("Not implemented.")
  }

  public func getProfileKeyVersion() throws  -> ProfileKeyVersion {
    fatalError("Not implemented.")
  }

  public func serialize() -> [UInt8] {
    return contents
  }
}
