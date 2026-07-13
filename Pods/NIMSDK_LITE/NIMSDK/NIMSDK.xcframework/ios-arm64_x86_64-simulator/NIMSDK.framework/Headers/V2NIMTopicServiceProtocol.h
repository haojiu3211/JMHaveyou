//
//  V2NIMTopicServiceProtocol.h
//  NIMLib
//
//  Created by Netease on 2026/3/26.
//  Copyright © 2026 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "V2NIMMessageServiceProtocol.h"
#import "V2NIMTopic.h"

NS_ASSUME_NONNULL_BEGIN

@protocol V2NIMTopicListener;
@class V2NIMTopicRefer;

/// 成功更新话题回调
typedef void (^V2NIMUpdateTopicSuccess)(V2NIMTopic *topic);
/// 成功获取话题列表回调
typedef void (^V2NIMGetTopicListSuccess)(V2NIMTopicListResult *result);
/// 成功获取话题消息列表回调
typedef void (^V2NIMGetTopicMessageListSuccess)(V2NIMTopicMessageListResult *result);
/// 成功查询话题回调
typedef void (^V2NIMGetTopicSuccess)(V2NIMTopic *topic);

/// 话题服务协议
@protocol V2NIMTopicService <NSObject>

/**
 *  批量删除话题
 *
 *  @param params 删除话题参数
 *  @param success 成功回调
 *  @param failure 失败回调
 */
- (void)removeTopics:(V2NIMRemoveTopicsParams *)params
             success:(nullable V2NIMSuccessCallback)success
             failure:(nullable V2NIMFailureCallback)failure;

/**
 *  更新话题
 *
 *  @param params 更新话题参数
 *  @param success 成功回调
 *  @param failure 失败回调
 */
- (void)updateTopic:(V2NIMUpdateTopicParams *)params
            success:(nullable V2NIMUpdateTopicSuccess)success
            failure:(nullable V2NIMFailureCallback)failure;

/**
 *  发送话题消息
 *
 *  @param message 待发送消息
 *  @param conversationId 目标会话 id
 *  @param topic 目标话题，为空时会创建一个新的话题
 *  @param params 话题消息发送参数，topic 为空时可通过 params.createTopicParams 传创建参数
 *  @param success 成功回调
 *  @param failure 失败回调
 *  @param progress 进度回调
 *
 *  @discussion 成功后 result.message.topicRefer 可用于快速判断消息所属话题；
 *  当 topic 为空且创建成功时，SDK 还会主动触发一次 onTopicAdded
 */
- (void)sendTopicMessage:(V2NIMMessage *)message
          conversationId:(NSString *)conversationId
                   topic:(nullable V2NIMTopic *)topic
                  params:(nullable V2NIMSendTopicMessageParams *)params
                 success:(nullable V2NIMSendMessageSuccess)success
                 failure:(nullable V2NIMFailureCallback)failure
                progress:(nullable V2NIMProgressCallback)progress;

/**
 *  回复话题消息
 *
 *  @param message 待发送消息
 *  @param replyMessage 被回复的消息
 *  @param topic 目标话题
 *  @param params 消息发送参数
 *  @param success 成功回调
 *  @param failure 失败回调
 *  @param progress 进度回调
 *
 *  @discussion 成功后 result.message.topicRefer 可用于快速判断消息所属话题
 */
- (void)replyTopicMessage:(V2NIMMessage *)message
             replyMessage:(V2NIMMessage *)replyMessage
                    topic:(V2NIMTopic *)topic
                   params:(nullable V2NIMSendMessageParams *)params
                  success:(nullable V2NIMSendMessageSuccess)success
                  failure:(nullable V2NIMFailureCallback)failure
                 progress:(nullable V2NIMProgressCallback)progress;

/**
 *  通过话题引用查询话题
 *
 *  @param topicRefer 目标话题引用
 *  @param success 成功回调
 *  @param failure 失败回调
 */
- (void)getTopicByRefer:(V2NIMTopicRefer *)topicRefer
                success:(nullable V2NIMGetTopicSuccess)success
                failure:(nullable V2NIMFailureCallback)failure;

/**
 *  查询话题列表
 *
 *  @param option 查询参数
 *  @param success 成功回调
 *  @param failure 失败回调
 */
- (void)getTopicListByOption:(V2NIMTopicListOption *)option
                     success:(nullable V2NIMGetTopicListSuccess)success
                     failure:(nullable V2NIMFailureCallback)failure;

/**
 *  查询话题消息列表
 *
 *  @param option 查询参数
 *  @param success 成功回调
 *  @param failure 失败回调
 */
- (void)getTopicMessageList:(V2NIMTopicMessageListOption *)option
                    success:(nullable V2NIMGetTopicMessageListSuccess)success
                    failure:(nullable V2NIMFailureCallback)failure;

/**
 *  添加话题监听器
 *
 *  @param listener 话题监听回调
 */
- (void)addTopicListener:(id<V2NIMTopicListener>)listener;

/**
 *  删除话题监听器
 *
 *  @param listener 话题监听回调
 */
- (void)removeTopicListener:(id<V2NIMTopicListener>)listener;

@end

/**
 *  话题监听协议
 */
@protocol V2NIMTopicListener <NSObject>

/**
 *  话题创建回调
 *
 *  @param topic 新创建的话题，多端同步及本端创建成功都会触发
 */
- (void)onTopicAdded:(V2NIMTopic *)topic;

/**
 *  话题删除回调
 *
 *  @param topics 被删除的话题引用列表
 */
- (void)onTopicsRemoved:(NSArray<V2NIMTopicRefer *> *)topics;

/**
 *  话题更新回调
 *
 *  @param topic 更新后的话题
 */
- (void)onTopicUpdated:(V2NIMTopic *)topic;

@end

NS_ASSUME_NONNULL_END
