//
//  V2NIMTopic.h
//  NIMLib
//
//  Created by Netease on 2026/3/26.
//  Copyright © 2026 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "V2NIMBase.h"
#import "V2NIMMessage.h"

@class V2NIMMessageRefer;

NS_ASSUME_NONNULL_BEGIN

/// 话题对象
@interface V2NIMTopic : NSObject<NSCopying>

/// 会话 id
@property(nullable, nonatomic, copy, readonly) NSString *conversationId;
/// 话题 id
@property(nonatomic, assign, readonly) uint64_t topicId;
/// 话题名称
@property(nullable, nonatomic, copy, readonly) NSString *topicName;
/// 话题根消息客户端 id
@property(nullable, nonatomic, copy, readonly) NSString *messageClientId;
/// 话题根消息服务端 id
@property(nullable, nonatomic, copy, readonly) NSString *messageServerId;
/// 话题根消息时间
@property(nonatomic, assign, readonly) int64_t messageTime;
/// 服务端扩展字段
@property(nullable, nonatomic, copy, readonly) NSString *serverExtension;
/// 话题创建时间
@property(nonatomic, assign, readonly) int64_t createTime;
/// 话题更新时间
@property(nonatomic, assign, readonly) int64_t updateTime;

@end

/// 更新话题参数
@interface V2NIMUpdateTopicParams : NSObject<NSCopying>

/// 待更新的话题
@property(nullable, nonatomic, strong) V2NIMTopic *topic;
/// 话题名称
@property(nullable, nonatomic, copy) NSString *topicName;
/// 服务端扩展字段
@property(nullable, nonatomic, copy) NSString *serverExtension;

@end

/// 删除话题参数
@interface V2NIMRemoveTopicsParams : NSObject<NSCopying>

/// 待删除话题列表
@property(nonatomic, copy) NSArray<V2NIMTopic *> *topicList;

@end

/// 话题列表查询参数
@interface V2NIMTopicListOption : NSObject<NSCopying>

/// 会话 id
@property(nullable, nonatomic, copy) NSString *conversationId;
/// 查询开始时间
@property(nonatomic, assign) int64_t beginTime;
/// 查询结束时间
@property(nonatomic, assign) int64_t endTime;
/// 分页 token
@property(nullable, nonatomic, copy) NSString *nextToken;
/// 分页大小
@property(nonatomic, assign) NSInteger limit;
/// 查询方向
@property(nonatomic, assign) V2NIMQueryDirection direction;

@end

/// 话题列表查询结果
@interface V2NIMTopicListResult : NSObject<NSCopying>

///// 结果总数
//@property(nonatomic, assign, readonly) NSUInteger totalCount;
/// 话题列表
@property(nonatomic, copy, readonly) NSArray<V2NIMTopic *> *topicList;
/// 下一页 token
@property(nullable, nonatomic, copy, readonly) NSString *nextToken;
/// 是否还有更多数据
@property(nonatomic, assign, readonly) BOOL hasMore;

@end

/// 创建话题参数
@interface V2NIMCreateTopicParams : NSObject<NSCopying>

/// 话题名称，序列化到 data.client.topicName
@property(nullable, nonatomic, copy) NSString *topicName;
/// 服务端扩展字段
@property(nullable, nonatomic, copy) NSString *serverExtension;

@end

/// 发送话题消息参数
@interface V2NIMSendTopicMessageParams : NSObject<NSCopying>

/// 原有消息发送参数
@property(nullable, nonatomic, strong) V2NIMSendMessageParams *sendMessageParams;
/// 创建话题参数，仅在新建话题发送时生效，topic 为空时可选
@property(nullable, nonatomic, strong) V2NIMCreateTopicParams *createTopicParams;

@end

/// 话题消息列表查询参数
@interface V2NIMTopicMessageListOption : NSObject<NSCopying>

/// 目标话题
@property(nullable, nonatomic, strong) V2NIMTopic *topic;
/// 查询开始时间
@property(nonatomic, assign) int64_t beginTime;
/// 查询结束时间
@property(nonatomic, assign) int64_t endTime;
/// 锚点消息
@property(nullable, nonatomic, strong) V2NIMMessage *anchorMessage;
/// 分页大小
@property(nonatomic, assign) NSInteger limit;
/// 查询方向
@property(nonatomic, assign) V2NIMQueryDirection direction;
/// 排序方式
@property(nonatomic, assign) V2NIMSortOrder sortOrder;

@end

/// 话题消息列表查询结果
@interface V2NIMTopicMessageListResult : NSObject<NSCopying>

/// 回复消息列表
@property(nonatomic, copy, readonly) NSArray<V2NIMMessage *> *replyList;
/// 是否还有更多数据
@property(nonatomic, assign, readonly) BOOL hasMore;
/// 返回结果中的锚点消息
@property(nullable, nonatomic, strong, readonly) V2NIMMessage *anchorMessage;

@end

NS_ASSUME_NONNULL_END
