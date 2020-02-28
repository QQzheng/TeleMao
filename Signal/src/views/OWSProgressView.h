
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OWSProgressView : UIView

@property (nonatomic) UIColor *color;
@property (nonatomic) CGFloat progress;

+ (CGSize)defaultSize;

@end

NS_ASSUME_NONNULL_END
