//
//  V2NIMMessageBuilder.h
//  NIMSDK
//
//  Created by 陈吉力 on 2025/10/14.
//  Copyright © 2025 Netease. All rights reserved.
//

#import "V2NIMConversationEnum.h"
#import "V2NIMMessageEnum.h"
#import "V2NIMMessage.h"

@class V2NIMMessageAttachment;

NS_ASSUME_NONNULL_BEGIN

@interface V2NIMMessageBuilder : NSObject

/// 发送者账号
@property (nullable,nonatomic,strong) NSString *senderId;
/// 接收者账号
@property (nullable,nonatomic,strong) NSString *receiverId;
/// 客户端消息ID
@property (nullable,nonatomic,strong) NSString *messageClientId;
/// 服务器消息ID
@property (nullable,nonatomic,strong) NSString *messageServerId;
/// 会话类型
@property (nonatomic,assign) V2NIMConversationType conversationType;
/// 会话 ID
@property (nullable,nonatomic,strong) NSString *conversationId;
/// 消息时间
@property (nonatomic,assign) NSTimeInterval createTime;
/// 消息发送状态 可以主动查询 也可以根据回调监听来确认
/// 只有SUCCEEDED和FAILED会入库
@property(nonatomic,assign) V2NIMMessageSendingState sendingState;
/// 类型
@property(nonatomic,assign) V2NIMMessageType messageType;
/// 子类型
@property(nonatomic,assign) NSInteger subType;
/// 文本
@property(nullable,nonatomic,strong) NSString *text;
/// 附件
@property(nullable,nonatomic,strong) V2NIMMessageAttachment *attachment;
/// 服务端扩展信息，必须是Json 字符串，要不然会解析失败。
@property(nullable,nonatomic,strong) NSString *serverExtension;
/// 客户端本地扩展信息
@property(nullable,nonatomic,strong) NSString *localExtension;
/// 第三方回调扩展字段， 透传字段
@property(nullable,nonatomic,strong) NSString *callbackExtension;
/// 消息相关配置，具体参见每一个字段定义
@property(nullable,nonatomic,strong) V2NIMMessageConfig *messageConfig;
/// 推送设置
@property(nullable,nonatomic,strong) V2NIMMessagePushConfig *pushConfig;
/// 路由抄送相关配置
@property(nullable,nonatomic,strong) V2NIMMessageRouteConfig *routeConfig;
/// 反垃圾相关
@property(nullable,nonatomic,strong) V2NIMMessageAntispamConfig *antispamConfig;
/// 机器人相关配置
@property(nullable,nonatomic,strong) V2NIMMessageRobotConfig *robotConfig;
/// Thread消息引用
@property(nullable,nonatomic,strong) V2NIMMessageRefer *threadRoot;
/// 回复消息引用
@property(nullable,nonatomic,strong) V2NIMMessageRefer *threadReply;
/// AI数字人相关信息
@property(nullable,nonatomic,strong) V2NIMMessageAIConfig *aiConfig;
/// 消息状态相关
@property(nonnull,nonatomic,strong) V2NIMMessageStatus *messageStatus;
/// 消息更新时间
@property(nonatomic,assign) NSTimeInterval modifyTime;
/// 消息更新者账号
@property(nullable,nonatomic) NSString *modifyAccountId;
/// 流式配置
@property(nullable,nonatomic,strong) V2NIMMessageStreamConfig *streamConfig;
/// 消息来源
@property(nonatomic,assign) V2NIMMessageSource messageSource;

+ (instancetype)builder;
- (V2NIMMessage *)build;

@end

NS_ASSUME_NONNULL_END
