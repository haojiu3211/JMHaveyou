//
//  V2NIMSDKOption.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2023 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface V2NIMSDKOption : NSObject

/// 使用旧的登录接口，默认NO，不使用
@property(nonatomic,assign,readwrite) BOOL useV1Login;

/// 是否使用V2云端会话，默认NO，不使用
@property(nonatomic,assign,readwrite) BOOL enableV2CloudConversation;

/// 是否在V2云端会话增量同步时分发会话变更通知并即时刷新未读，默认NO，不分发
@property (nonatomic,assign,readwrite) BOOL enableV2ConversationIncrementalSyncNotify;

/// 是否支持V2FriendAddApplication功能，默认NO，不支持
@property (nonatomic,assign,readwrite) BOOL enableServerV2FriendAddApplication;

/// 是否支持V2TeamJoinAction功能，默认NO，不支持
@property (nonatomic,assign,readwrite) BOOL enableServerV2TeamJoinActionInfo;

@end

NS_ASSUME_NONNULL_END
