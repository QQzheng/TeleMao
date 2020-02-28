
import Foundation
// All Observer methods will be invoked from the main thread.
@objc
public protocol ShareViewDelegate: class {
    func shareViewWasUnlocked()
    func shareViewWasCompleted()
    func shareViewWasCancelled()
    func shareViewFailed(error: Error)
}
