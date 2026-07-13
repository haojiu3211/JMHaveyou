//
//  V2NIMMessageAttachmentBuilder.h
//  NIMSDK
//
//  Created by 陈吉力 on 2025/10/14.
//  Copyright © 2025 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "V2NIMMessageEnum.h"
#import "V2NIMMessageAttachment.h"

@class V2NIMUpdatedTeamInfo;
@class V2NIMMessageCallDuration;

NS_ASSUME_NONNULL_BEGIN

@interface V2NIMMessageAttachmentBuilder : NSObject

@property(nonnull,nonatomic,strong) NSString *raw;

+ (instancetype)builder;

- (nullable V2NIMMessageAttachment *)build;

@end

@interface V2NIMMessageFileAttachmentBuilder : NSObject
@property(nullable,nonatomic,strong) NSString *path;
@property(nonatomic,assign) NSUInteger size;
@property(nonnull,nonatomic,strong) NSString *md5;
@property(nullable,nonatomic,strong) NSString *url;
@property(nullable,nonatomic,strong) NSString *ext;
@property(nonnull,nonatomic,copy) NSString *name;
@property(nullable,nonatomic,strong) NSString *sceneName;
@property(nonatomic,assign) V2NIMMessageAttachmentUploadState uploadState;

+ (instancetype)builder:(NSString *)path;

- (nullable V2NIMMessageFileAttachment *)build;
@end

@interface V2NIMMessageImageAttachmentBuilder : NSObject
@property(nullable,nonatomic,strong) NSString *path;
@property(nonatomic,assign) NSUInteger size;
@property(nonnull,nonatomic,strong) NSString *md5;
@property(nullable,nonatomic,strong) NSString *url;
@property(nullable,nonatomic,strong) NSString *ext;
@property(nonnull,nonatomic,copy) NSString *name;
@property(nullable,nonatomic,strong) NSString *sceneName;
@property(nonatomic,assign) V2NIMMessageAttachmentUploadState uploadState;

@property(nonatomic,assign,readonly) int width;
@property(nonatomic,assign,readonly) int height;

+ (instancetype)builder:(NSString *)path width:(int)width height:(int)height;

- (nullable V2NIMMessageImageAttachment *)build;
@end

@interface V2NIMMessageAudioAttachmentBuilder : NSObject
@property(nullable,nonatomic,strong) NSString *path;
@property(nonatomic,assign) NSUInteger size;
@property(nonnull,nonatomic,strong) NSString *md5;
@property(nullable,nonatomic,strong) NSString *url;
@property(nullable,nonatomic,strong) NSString *ext;
@property(nonnull,nonatomic,copy) NSString *name;
@property(nullable,nonatomic,strong) NSString *sceneName;
@property(nonatomic,assign) V2NIMMessageAttachmentUploadState uploadState;

@property(nonatomic,assign,readwrite) NSUInteger duration;

+ (instancetype)builder:(NSString *)path duration:(int)duration;

- (nullable V2NIMMessageAudioAttachment *)build;
@end

@interface V2NIMMessageVideoAttachmentBuilder : NSObject
@property(nullable,nonatomic,strong) NSString *path;
@property(nonatomic,assign) NSUInteger size;
@property(nonnull,nonatomic,strong) NSString *md5;
@property(nullable,nonatomic,strong) NSString *url;
@property(nullable,nonatomic,strong) NSString *ext;
@property(nonnull,nonatomic,copy) NSString *name;
@property(nullable,nonatomic,strong) NSString *sceneName;
@property(nonatomic,assign) V2NIMMessageAttachmentUploadState uploadState;

@property(nonatomic,assign) NSUInteger duration;
@property(nonatomic,assign) NSInteger width;
@property(nonatomic,assign) NSInteger height;

+ (instancetype)builder:(NSString *)path duration:(int)duration width:(int)width height:(int)height;

- (nullable V2NIMMessageVideoAttachment *)build;
@end

@interface V2NIMMessageLocationAttachmentBuilder : NSObject
@property(nonatomic,assign) double longitude;
@property(nonatomic,assign) double latitude;
@property(nonnull,nonatomic,strong) NSString *address;

+ (instancetype)builder:(double)latitude longitude:(double)longitude address:(NSString *)address;

- (nullable V2NIMMessageLocationAttachment *)build;
@end

@interface V2NIMMessageNotificationAttachmentBuilder : NSObject
@property(nonatomic,assign) V2NIMMessageNotificationType type;
@property(nullable,nonatomic,strong) NSString *serverExtension;
@property(nullable,nonatomic,strong) NSArray<NSString *> *targetIds;
@property(nonatomic,assign) BOOL chatBanned;
@property(nullable,nonatomic,strong) V2NIMUpdatedTeamInfo *updatedTeamInfo;

+ (instancetype)builder;

- (nullable V2NIMMessageNotificationAttachment *)build;
@end

@interface V2NIMMessageCallAttachmentBuilder : NSObject
@property (nonatomic, assign) NSInteger type;
@property (nonatomic, copy) NSString *channelId;
@property (nonatomic, assign) NSInteger status;
@property (nonatomic, copy) NSArray<V2NIMMessageCallDuration *>*durations;

+ (instancetype)builder:(NSInteger)type
              channelId:(NSString *)channelId
                 status:(NSInteger)status
              durations:(NSArray <V2NIMMessageCallDuration *>*)durations;

- (nullable V2NIMMessageCallAttachment *)build;
@end

@interface V2NIMMessageCustomAttachmentBuilder : NSObject
@property(nonnull,nonatomic,strong) NSString *raw;

+ (instancetype)builder:(NSString *)raw;

- (nullable V2NIMMessageAttachment *)build;
@end

NS_ASSUME_NONNULL_END
