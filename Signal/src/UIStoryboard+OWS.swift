
import Foundation

extension UIStoryboard {
    private enum StoryboardName: String {
        case main = "Main"
    }

    @objc
    class var main: UIStoryboard {
        return UIStoryboard(name: StoryboardName.main.rawValue, bundle: Bundle.main)
    }
}
