
import Foundation

extension UIGestureRecognizer {
    @objc
    public var stateString: String {
        return NSStringForUIGestureRecognizerState(state)
    }
}
