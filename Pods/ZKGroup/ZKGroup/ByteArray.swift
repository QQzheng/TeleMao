
import Foundation

public class ByteArray {
    let contents: [UInt8]

    init(newContents: [UInt8], expectedLength: Int, unrecoverable: Bool = false) throws {
        if newContents.count != expectedLength {
            throw ZkGroupException.IllegalArgument
        }
        contents = newContents
    }
}
