

#import "OWSUploadV2.h"
#import <PromiseKit/AnyPromise.h>
#import <SignalCoreKit/Cryptography.h>
#import <SignalCoreKit/NSData+OWS.h>
#import <SignalServiceKit/MIMETypeUtil.h>
#import <SignalServiceKit/OWSError.h>
#import <SignalServiceKit/OWSRequestFactory.h>
#import <SignalServiceKit/OWSSignalService.h>
#import <SignalServiceKit/SSKEnvironment.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>
#import <SignalServiceKit/TSAttachmentStream.h>
#import <SignalServiceKit/TSNetworkManager.h>
#import <SignalServiceKit/TSSocketManager.h>

NS_ASSUME_NONNULL_BEGIN

void AppendMultipartFormPath(id<AFMultipartFormData> formData, NSString *name, NSString *dataString)
{
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];

    [formData appendPartWithFormData:data name:name];
}

#pragma mark -
//版本1.0  网络请求修改OSS
// See: https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-UsingHTTPPOST.html
@implementation OWSUploadForm

+ (nullable OWSUploadForm *)parse:(nullable NSDictionary *)formResponseObject
{
    if (![formResponseObject isKindOfClass:[NSDictionary class]]) {
        OWSFailDebug(@"Invalid upload form.");
        return nil;
    }
    NSDictionary *responseMap = formResponseObject;

//    NSString *_Nullable formAcl = responseMap[@"acl"];
//    if (![formAcl isKindOfClass:[NSString class]] || formAcl.length < 1) {
//        OWSFailDebug(@"Invalid upload form: acl.");
//        return nil;
//    }
    NSDictionary *ossDic = responseMap[@"param"];
    
    NSString *_Nullable formKey = ossDic[@"key"];
    if (![formKey isKindOfClass:[NSString class]] || formKey.length < 1) {
        OWSFailDebug(@"Invalid upload form: key.");
        return nil;
    }
    NSString *_Nullable formPolicy = ossDic[@"policy"];
    if (![formPolicy isKindOfClass:[NSString class]] || formPolicy.length < 1) {
        OWSFailDebug(@"Invalid upload form: policy.");
        return nil;
    }
//    NSString *_Nullable formAlgorithm = responseMap[@"algorithm"];
//    if (![formAlgorithm isKindOfClass:[NSString class]] || formAlgorithm.length < 1) {
//        OWSFailDebug(@"Invalid upload form: algorithm.");
//        return nil;
//    }
//    NSString *_Nullable formCredential = responseMap[@"credential"];
//    if (![formCredential isKindOfClass:[NSString class]] || formCredential.length < 1) {
//        OWSFailDebug(@"Invalid upload form: credential.");
//        return nil;
//    }
//    NSString *_Nullable formDate = responseMap[@"date"];
//    if (![formDate isKindOfClass:[NSString class]] || formDate.length < 1) {
//        OWSFailDebug(@"Invalid upload form: date.");
//        return nil;
//    }
    NSString *_Nullable formSignature = ossDic[@"Signature"];
    if (![formSignature isKindOfClass:[NSString class]] || formSignature.length < 1) {
        OWSFailDebug(@"Invalid upload form: signature.");
        return nil;
    }

    NSString *_Nullable formOSSAccessKeyId = ossDic[@"OSSAccessKeyId"];
    if (![formOSSAccessKeyId isKindOfClass:[NSString class]] || formOSSAccessKeyId.length < 1) {
        OWSFailDebug(@"Invalid upload form: OSSAccessKeyId.");
        return nil;
    }
    
//    NSNumber *_Nullable attachmentId = responseMap[@"attachmentId"];
//    if (attachmentId == nil) {
//        // This value is optional.
//    } else if (![attachmentId isKindOfClass:[NSNumber class]]) {
//        OWSFailDebug(@"Invalid upload form: attachmentId.");
//        return nil;
//    }
//    NSString *_Nullable attachmentIdString = responseMap[@"attachmentIdString"];
//    if (attachmentIdString == nil) {
//        // This value is optional.
//    } else if (![attachmentIdString isKindOfClass:[NSString class]] || attachmentIdString.length < 1) {
//        OWSFailDebug(@"Invalid upload form: attachmentIdString.");
//        return nil;
//    }

    OWSUploadForm *form = [OWSUploadForm new];
    
    // Required properties.
    //form.formAcl = formAcl;
    form.formKey = formKey;
    form.formPolicy = formPolicy;
//    form.formAlgorithm = formAlgorithm;
//    form.formCredential = formCredential;
//    form.formDate = formDate;
    form.formSignature = formSignature;
    form.formOSSAccessKeyId = formOSSAccessKeyId;

    // Optional properties.
//    form.attachmentId = attachmentId;
//    form.attachmentIdString = attachmentIdString;

    return form;
}

- (void)appendToForm:(id<AFMultipartFormData>)formData
{
    // We have to build up the form manually vs. simply passing in a paramaters dict
    // because AWS is sensitive to the order of the form params (at least the "key"
    // field must occur early on).
    //
    // For consistency, all fields are ordered here in a known working order.
    AppendMultipartFormPath(formData, @"key", self.formKey);
//    AppendMultipartFormPath(formData, @"acl", self.formAcl);
//    AppendMultipartFormPath(formData, @"x-amz-algorithm", self.formAlgorithm);
//    AppendMultipartFormPath(formData, @"x-amz-credential", self.formCredential);
//    AppendMultipartFormPath(formData, @"x-amz-date", self.formDate);
    AppendMultipartFormPath(formData, @"policy", self.formPolicy);
    AppendMultipartFormPath(formData, @"Signature", self.formSignature);
    AppendMultipartFormPath(formData, @"OSSAccessKeyId", self.formOSSAccessKeyId);
}

@end

#pragma mark -

@interface OWSAvatarUploadV2 ()

@property (nonatomic, nullable) NSData *avatarData;

@end

#pragma mark -

@implementation OWSAvatarUploadV2

#pragma mark - Dependencies

- (AFHTTPSessionManager *)uploadHTTPManager
{
    return [OWSSignalService sharedInstance].CDNSessionManager;
}

- (TSNetworkManager *)networkManager
{
    return SSKEnvironment.shared.networkManager;
}

#pragma mark - Avatars

// If avatarData is nil, we are clearing the avatar.
- (AnyPromise *)uploadAvatarToService:(nullable NSData *)avatarData
                        progressBlock:(UploadProgressBlock)progressBlock
{
    OWSAssertDebug(avatarData == nil || avatarData.length > 0);
    self.avatarData = avatarData;

    __weak OWSAvatarUploadV2 *weakSelf = self;
    AnyPromise *promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            TSRequest *formRequest = [OWSRequestFactory profileAvatarUploadFormRequest];
            [self.networkManager makeRequest:formRequest
                success:^(NSURLSessionDataTask *task, id _Nullable formResponseObject) {
                    OWSAvatarUploadV2 *_Nullable strongSelf = weakSelf;
                    if (!strongSelf) {
                        return resolve(OWSErrorWithCodeDescription(OWSErrorCodeUploadFailed, @"Upload deallocated"));
                    }

                    if (avatarData == nil) {
                        OWSLogDebug(@"successfully cleared avatar");
                        return resolve(@(1));
                    }

                    // TODO: Should we use a non-empty urlPath?
                    [[strongSelf parseFormAndUpload:formResponseObject urlPath:@"" progressBlock:progressBlock]
                            .thenInBackground(^{
                                return resolve(@(1));
                            })
                            .catchInBackground(^(NSError *error) {

                                resolve(error);
                            }) retainUntilComplete];
                }
                failure:^(NSURLSessionDataTask *task, NSError *error) {
                    OWSLogError(@"Failed to get profile avatar upload form: %@", error);
                    resolve(error);
                }];
        });
    }];
    return promise;
}

- (AnyPromise *)parseFormAndUpload:(nullable id)formResponseObject
                           urlPath:(NSString *)urlPath
                     progressBlock:(UploadProgressBlock)progressBlock
{
    OWSUploadForm *_Nullable form = [OWSUploadForm parse:formResponseObject];
    if (!form) {
        return [AnyPromise
            promiseWithValue:OWSErrorWithCodeDescription(OWSErrorCodeUploadFailed, @"Invalid upload form.")];
    }

    self.urlPath = form.formKey;

    __weak OWSAvatarUploadV2 *weakSelf = self;
    AnyPromise *promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self.uploadHTTPManager POST:urlPath
            parameters:nil
            constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                OWSAvatarUploadV2 *_Nullable strongSelf = weakSelf;
                if (!strongSelf) {
                    return resolve(OWSErrorWithCodeDescription(OWSErrorCodeUploadFailed, @"Upload deallocated"));
                }

                // We have to build up the form manually vs. simply passing in a paramaters dict
                // because AWS is sensitive to the order of the form params (at least the "key"
                // field must occur early on).
                //
                // For consistency, all fields are ordered here in a known working order.
                [form appendToForm:formData];
                AppendMultipartFormPath(formData, @"Content-Type", OWSMimeTypeApplicationOctetStream);

                NSData *_Nullable uploadData = strongSelf.avatarData;
                if (uploadData.length < 1) {
                    OWSCFailDebug(@"Could not load upload data.");
                    return resolve(
                        OWSErrorWithCodeDescription(OWSErrorCodeUploadFailed, @"Could not load upload data."));
                }
                OWSCAssertDebug(uploadData.length > 0);
                [formData appendPartWithFormData:uploadData name:@"file"];

                OWSLogVerbose(@"constructed body");
            }
            progress:^(NSProgress *progress) {
                OWSLogVerbose(@"Upload progress: %.2f%%", progress.fractionCompleted * 100);

                progressBlock(progress);
            }
            success:^(NSURLSessionDataTask *uploadTask, id _Nullable responseObject) {
                OWSLogInfo(@"Upload succeeded with key: %@", form.formKey);
                return resolve(@(1));
            }
            failure:^(NSURLSessionDataTask *_Nullable uploadTask, NSError *error) {
                OWSLogError(@"Upload failed with error: %@", error);
                resolve(error);
            }];
    }];
    return promise;
}

@end

#pragma mark - Attachments

@interface OWSAttachmentUploadV2 ()

@property (nonatomic) TSAttachmentStream *attachmentStream;

@end

#pragma mark -

@implementation OWSAttachmentUploadV2

#pragma mark - Dependencies

- (AFHTTPSessionManager *)uploadHTTPManager
{
    return [OWSSignalService sharedInstance].CDNSessionManager;
}

- (TSNetworkManager *)networkManager
{
    return SSKEnvironment.shared.networkManager;
}

- (TSSocketManager *)socketManager
{
    return SSKEnvironment.shared.socketManager;
}

#pragma mark -

- (nullable NSData *)attachmentData
{
    OWSAssertDebug(self.attachmentStream);

    NSData *encryptionKey;
    NSData *digest;
    NSError *error;
    NSData *attachmentData = [self.attachmentStream readDataFromFileWithError:&error];
    if (error) {
        OWSLogError(@"Failed to read attachment data with error: %@", error);
        return nil;
    }

    NSData *_Nullable encryptedAttachmentData = [Cryptography encryptAttachmentData:attachmentData
                                                                          shouldPad:YES
                                                                             outKey:&encryptionKey
                                                                          outDigest:&digest];
    if (!encryptedAttachmentData) {
        OWSFailDebug(@"could not encrypt attachment data.");
        return nil;
    }

    self.encryptionKey = encryptionKey;
    self.digest = digest;

    return encryptedAttachmentData;
}

// On success, yields an instance of OWSUploadV2.
- (AnyPromise *)uploadAttachmentToService:(TSAttachmentStream *)attachmentStream
                            progressBlock:(UploadProgressBlock)progressBlock
{
    OWSAssertDebug(attachmentStream);

    self.attachmentStream = attachmentStream;

    AnyPromise *promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self uploadAttachmentToService:resolve progressBlock:progressBlock skipWebsocket:NO];
        });
    }];
    return promise;
}

- (void)uploadAttachmentToService:(PMKResolver)resolve
                    progressBlock:(UploadProgressBlock)progressBlock
                    skipWebsocket:(BOOL)skipWebsocket
{
    TSRequest *formRequest = [OWSRequestFactory allocAttachmentRequest];

    BOOL shouldUseWebsocket = (self.socketManager.canMakeRequests && !skipWebsocket);

    __weak OWSAttachmentUploadV2 *weakSelf = self;
    void (^formSuccess)(id _Nullable) = ^(id _Nullable formResponseObject) {
        OWSAttachmentUploadV2 *_Nullable strongSelf = weakSelf;
        if (!strongSelf) {
            return resolve(OWSErrorWithCodeDescription(OWSErrorCodeUploadFailed, @"Upload deallocated"));
        }
//版本1.0 去掉@“attachments/”
        [[strongSelf parseFormAndUpload:formResponseObject urlPath:@"" progressBlock:progressBlock]
                .thenInBackground(^{
                    resolve(@(1));
                })
                .catchInBackground(^(NSError *error) {
                    resolve(error);
                }) retainUntilComplete];
    };
    void (^formFailure)(NSError *) = ^(NSError *error) {
        OWSLogError(@"Failed to get profile avatar upload form: %@", error);
        resolve(error);
    };

    if (shouldUseWebsocket) {
        [self.socketManager makeRequest:formRequest
            success:^(id _Nullable responseObject) {
                formSuccess(responseObject);
            }
            failure:^(NSInteger statusCode, NSData *_Nullable responseData, NSError *_Nullable error) {
                OWSLogError(@"Websocket request failed: %d, %@", (int)statusCode, error);

                // Try again without websocket.
                [weakSelf uploadAttachmentToService:resolve progressBlock:progressBlock skipWebsocket:YES];
            }];
    } else {
        [self.networkManager makeRequest:formRequest
            success:^(NSURLSessionDataTask *task, id _Nullable formResponseObject) {
                formSuccess(formResponseObject);
            }
            failure:^(NSURLSessionDataTask *task, NSError *error) {
                formFailure(error);
            }];
    }
}

#pragma mark -

- (AnyPromise *)parseFormAndUpload:(nullable id)formResponseObject
                           urlPath:(NSString *)urlPath
                     progressBlock:(UploadProgressBlock)progressBlock
{
    OWSUploadForm *_Nullable form = [OWSUploadForm parse:formResponseObject];
    if (!form) {
        return [AnyPromise
            promiseWithValue:OWSErrorWithCodeDescription(OWSErrorCodeUploadFailed, @"Invalid upload form.")];
    }
    
    //版本1.0  网络请求修改 attachmentId 改成 formKey
    //UInt64 serverId = form.attachmentId.unsignedLongLongValue;
    UInt64 serverId = form.formKey.longLongValue;
    if (serverId < 1) {
        return [AnyPromise
            promiseWithValue:OWSErrorWithCodeDescription(OWSErrorCodeUploadFailed, @"Invalid upload form.")];
    }

    self.serverId = serverId;

    __weak OWSAttachmentUploadV2 *weakSelf = self;
    AnyPromise *promise = [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self.uploadHTTPManager POST:urlPath
            parameters:nil
            constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                OWSAttachmentUploadV2 *_Nullable strongSelf = weakSelf;
                if (!strongSelf) {
                    return resolve(OWSErrorWithCodeDescription(OWSErrorCodeUploadFailed, @"Upload deallocated"));
                }

                // We have to build up the form manually vs. simply passing in a paramaters dict
                // because AWS is sensitive to the order of the form params (at least the "key"
                // field must occur early on).
                //
                // For consistency, all fields are ordered here in a known working order.
                [form appendToForm:formData];
                AppendMultipartFormPath(formData, @"Content-Type", OWSMimeTypeApplicationOctetStream);

                NSData *_Nullable uploadData = [strongSelf attachmentData];
                if (uploadData.length < 1) {
                    OWSCFailDebug(@"Could not load upload data.");
                    return resolve(
                        OWSErrorWithCodeDescription(OWSErrorCodeUploadFailed, @"Could not load upload data."));
                }
                OWSAssertDebug(uploadData.length > 0);
                [formData appendPartWithFormData:uploadData name:@"file"];

                OWSLogVerbose(@"constructed %@ body", [NSByteCountFormatter stringFromByteCount:uploadData.length countStyle:NSByteCountFormatterCountStyleFile]);
            }
            progress:^(NSProgress *progress) {
                OWSLogVerbose(@"Upload progress: %.2f%%", progress.fractionCompleted * 100);

                progressBlock(progress);
            }
            success:^(NSURLSessionDataTask *uploadTask, id _Nullable responseObject) {
                OWSAttachmentUploadV2 *_Nullable strongSelf = weakSelf;
                if (!strongSelf) {
                    return resolve(OWSErrorWithCodeDescription(OWSErrorCodeUploadFailed, @"Upload deallocated"));
                }

                OWSLogInfo(@"Upload succeeded with key: %@", form.formKey);
                return resolve(@(1));
            }
            failure:^(NSURLSessionDataTask *_Nullable uploadTask, NSError *error) {
                OWSLogError(@"Upload failed with error: %@", error);
                resolve(error);
            }];
    }];
    return promise;
}

@end

NS_ASSUME_NONNULL_END
