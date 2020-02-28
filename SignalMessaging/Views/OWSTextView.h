
NS_ASSUME_NONNULL_BEGIN

extern const UIDataDetectorTypes kOWSAllowedDataDetectorTypes;

@interface OWSTextView : UITextView

- (void)ensureShouldLinkifyText:(BOOL)shouldLinkifyText;

@end

NS_ASSUME_NONNULL_END
