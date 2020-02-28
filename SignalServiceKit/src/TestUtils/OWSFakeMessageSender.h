
#import "OWSMessageSender.h"

NS_ASSUME_NONNULL_BEGIN

#ifdef TESTABLE_BUILD

typedef void (^messageBlock)(TSOutgoingMessage *);

@interface OWSFakeMessageSender : OWSMessageSender

@property (nonatomic, nullable) NSError *stubbedFailingError;

@property (nonatomic, nullable) messageBlock sendMessageWasCalledBlock;
@property (nonatomic, nullable) messageBlock sendAttachmentWasCalledBlock;
@property (nonatomic, nullable) messageBlock sendTemporaryAttachmentWasCalledBlock;

@end

#endif

NS_ASSUME_NONNULL_END
