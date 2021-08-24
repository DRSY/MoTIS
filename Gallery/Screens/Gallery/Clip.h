//
//  Clip.h
//  Gallery
//
//  Created by 任宇宇 on 2021/8/3.
//

#ifndef Clip_h
#define Clip_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface SampleClass:NSObject
/* method declaration */
- (double)availableMemory;
- (double)usedMemory;
@end


@interface TorchModule : NSObject

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath
    NS_SWIFT_NAME(init(fileAtPath:))NS_DESIGNATED_INITIALIZER;

- (nullable instancetype)init NS_SWIFT_NAME(init())NS_DESIGNATED_INITIALIZER;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface IndexingModule : TorchModule
- (nullable NSArray<NSNumber*>*)search:(NSArray<NSNumber*>*)query NS_SWIFT_NAME(search(query:));
- (nullable NSArray<NSNumber*>*)buildIndex:(NSArray<NSArray<NSNumber*>*>*)datas NS_SWIFT_NAME(buildIndex(datas:));
- (nullable NSArray<NSNumber*>*)buildIndexOne:(NSArray<NSNumber*>*)data NS_SWIFT_NAME(buildIndexOne(data:));
- (nullable NSArray<NSNumber*>*)save;

@end

@interface CLIPNLPTorchModule : TorchModule
- (nullable NSArray<NSNumber*>*)test;
- (nullable NSArray<NSNumber*>*)encode:(NSArray*)ids NS_SWIFT_NAME(encode(text:));
@end


@interface CLIPImageTorchModule : TorchModule
- (nullable NSArray<NSNumber*>*)test_uiimagetomat:(UIImage*)image NS_SWIFT_NAME(test_uiimagetomat(image:));
- (nullable NSArray<NSArray<NSNumber*>*>*)encode_images:(NSArray<UIImage*>*)images NS_SWIFT_NAME(encode_images(images:));
- (nullable NSArray<NSNumber*>*)test:(NSString*)filePath NS_SWIFT_NAME(test(path:));
- (nullable NSArray<NSNumber*>*)encode:(void*)imageBuffer NS_SWIFT_NAME(encode(image:));
@end
NS_ASSUME_NONNULL_END


#endif /* Clip_h */
