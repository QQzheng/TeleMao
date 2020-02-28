

import Foundation

class ReactionsMegaphone: MegaphoneView {
    init(experienceUpgrade: ExperienceUpgrade, fromViewController: UIViewController) {
        super.init(experienceUpgrade: experienceUpgrade)

        titleText = NSLocalizedString("XXGJUSTHHANQR15", comment: "Title for the megaphone introducing reactions")
        bodyText = NSLocalizedString("XXGJUSTHHANQR14", comment: "Body for the megaphone introducing reactions")

        imageSize = .large
        animation = Animation(
            name: "reactionsMegaphone",
            backgroundImageName: "reactions-megaphone-bg",
            backgroundImageInset: 12,
            loopMode: .repeat(3),
            backgroundBehavior: .forceFinish,
            contentMode: .center
        )
    }

    override func tappedDismiss() {
        dismiss { self.markAsComplete() }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
