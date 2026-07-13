//
//  V2NIMAIServiceProtocol.h
//  NIMLib
//
//  Created by Netease on 2024/5/20.
//  Copyright © 2024 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "V2NIMUserServiceProtocol.h"
#import "V2NIMBase.h"

NS_ASSUME_NONNULL_BEGIN

@class V2NIMUserAIBot;
@class V2NIMCreateUserAIBotParams;
@class V2NIMCreateUserAIBotResult;
@class V2NIMGetUserAIBotListParams;
@class V2NIMGetUserAIBotListResult;
@class V2NIMGetUserAIBotParams;
@class V2NIMUpdateUserAIBotParams;
@class V2NIMDeleteUserAIBotParams;
@class V2NIMRefreshUserAIBotTokenParams;
@class V2NIMRefreshUserAIBotTokenResult;
@class V2NIMBindUserAIBotToQrCodeParams;

@class V2NIMProxyAIModelCallParams;
@class V2NIMAIModelCallContent;
@class V2NIMAIUser;
@class V2NIMProxyAICallAntispamConfig;
@class V2NIMAIModelCallResult;
@class V2NIMAIRAGInfo;
@class V2NIMAIModelStreamCallStopParams;
@class V2NIMAIModelStreamCallResult;

@protocol V2NIMAIListener;

typedef void (^V2NIMGetAlUserListSuccess)(NSArray <V2NIMAIUser *> * _Nullable result);

/// 用户级 AI Bot 相关回调
typedef void (^V2NIMCreateUserAIBotSuccess)(V2NIMCreateUserAIBotResult * _Nullable result);
typedef void (^V2NIMGetUserAIBotListSuccess)(V2NIMGetUserAIBotListResult * _Nullable result);
typedef void (^V2NIMGetUserAIBotSuccess)(V2NIMUserAIBot * _Nullable result);
typedef void (^V2NIMRefreshUserAIBotTokenSuccess)(V2NIMRefreshUserAIBotTokenResult * _Nullable result);

/// 大模型类型
typedef NS_ENUM(NSInteger, V2NIMAIModelType) {
    V2NIM_AI_MODEL_TYPE_UNKNOW, // 未知
    V2NIM_AI_MODEL_TYPE_QWEN,   // 通义千问大模型
    V2NIM_AI_MODEL_TYPE_AZURE,  // 微软Azure
    V2NIM_AI_MODEL_TYPE_PRIVATE // 私有本地大模型
};


/// 大模型请求内容类型
typedef NS_ENUM(NSInteger, V2NIMAIModelCallContentType) {
    V2NIM_AI_MODEL_CONTENT_TYPE_TEXT = 0 // 暂时只有0，代表文本，预留扩展能力
};

/// 大模型角色内容
typedef NS_ENUM(NSInteger, V2NIMAIModelRoleType) {
    V2NIM_AI_MODEL_ROLE_TYPE_SYSTEM,
    V2NIM_AI_MODEL_ROLE_TYPE_USER,
    V2NIM_AI_MODEL_ROLE_TYPE_ASSISTANT
};

/// 数字人流式消息状态
typedef NS_ENUM(NSInteger, V2NIMAIModelStreamCallStatus) {
    /// 非流式状态
    V2NIM_AI_MODEL_STREAM_CALL_STATUS_NONE = 0,
    
    /// 停止输出
    V2NIM_AI_MODEL_STREAM_CALL_STATUS_CANCEL = 2,
    
    /// 输出完成
    V2NIM_AI_MODEL_STREAM_CALL_STATUS_GENERATED = 4,
    
    /// 服务器异常终止
    V2NIM_AI_MODEL_STREAM_CALL_STATUS_ABORTED = 5,
};

@protocol V2NIMAIService <NSObject>

/**
 *  数字人拉取接口
 *  返回全量的本Appkey相关的数字人用户
 *
 *  @param success  请求成功回调
 *  @param failure  请求失败回调
 */
- (void)getAIUserList:(nullable V2NIMGetAlUserListSuccess)success
              failure:(nullable V2NIMFailureCallback)failure;


/**
 *  Al数字人请求代理接口
 *
 *  @param params   接口入参
 *  @param success  请求成功回调
 *  @param failure  请求失败回调
 */

- (void)proxyAIModelCall:(V2NIMProxyAIModelCallParams *)params
                 success:(nullable V2NIMSuccessCallback)success
                 failure:(nullable V2NIMFailureCallback)failure;


/**
 * 停止流式输出
 *
 *  @param params   接口入参
 *  @param completion  完成后的回调
 */
- (void)stopAIModelStreamCall:(V2NIMAIModelStreamCallStopParams *)params
                            success:(nullable V2NIMSuccessCallback)success
                            failure:(nullable V2NIMFailureCallback)failure;



/**
* 添加数字人监听器
*
* @param listener 消息监听回调
*/
- (void)addAIListener:(id<V2NIMAIListener>)listener;

/**
* 删除数字人监听器
*
* @param listener 消息监听回调
*/
- (void)removeAIListener:(id<V2NIMAIListener>)listener;

/**
 * 创建用户级 AI Bot（协议 37-1）
 *
 * @param params  创建参数，accid 和 name 为必填
 * @param success 成功回调，返回新 Bot 的登录 token
 * @param failure 失败回调
 */
- (void)createUserAIBot:(V2NIMCreateUserAIBotParams *)params
                success:(nullable V2NIMCreateUserAIBotSuccess)success
                failure:(nullable V2NIMFailureCallback)failure;

/**
 * 分页查询用户级 AI Bot 列表（协议 37-2）
 *
 * @param params  分页参数，可为 nil（默认 limit=100，从第一页开始）
 * @param success 成功回调，返回 bot 列表及分页信息
 * @param failure 失败回调
 */
- (void)getUserAIBotList:(nullable V2NIMGetUserAIBotListParams *)params
                 success:(nullable V2NIMGetUserAIBotListSuccess)success
                 failure:(nullable V2NIMFailureCallback)failure;

/**
 * 查询单个用户级 AI Bot（协议 37-5）
 *
 * @param params  查询参数，accid 为必填
 * @param success 成功回调，返回 bot 完整信息
 * @param failure 失败回调
 */
- (void)getUserAIBot:(V2NIMGetUserAIBotParams *)params
             success:(nullable V2NIMGetUserAIBotSuccess)success
             failure:(nullable V2NIMFailureCallback)failure;

/**
 * 更新用户级 AI Bot（协议 37-4）
 *
 * @param params  更新参数，accid 为必填，其余字段选填（nil 表示不更新）
 * @param success 成功回调
 * @param failure 失败回调
 */
- (void)updateUserAIBot:(V2NIMUpdateUserAIBotParams *)params
                success:(nullable V2NIMSuccessCallback)success
                failure:(nullable V2NIMFailureCallback)failure;

/**
 * 删除用户级 AI Bot（协议 37-3）
 *
 * @param params  删除参数，accid 为必填
 * @param success 成功回调
 * @param failure 失败回调
 */
- (void)deleteUserAIBot:(V2NIMDeleteUserAIBotParams *)params
                success:(nullable V2NIMSuccessCallback)success
                failure:(nullable V2NIMFailureCallback)failure;

/**
 * 刷新用户级 AI Bot 登录 Token（协议 37-6）
 *
 * @param params  刷新参数，accid 为必填
 * @param success 成功回调，返回新 token
 * @param failure 失败回调
 */
- (void)refreshUserAIBotToken:(V2NIMRefreshUserAIBotTokenParams *)params
                       success:(nullable V2NIMRefreshUserAIBotTokenSuccess)success
                       failure:(nullable V2NIMFailureCallback)failure;

/**
 * 二维码绑定用户级 AI Bot（协议 37-7）
 *
 * @param params  绑定参数，accid / token / qrCode 均为必填
 * @param success 成功回调
 * @param failure 失败回调
 */
- (void)bindUserAIBotToQrCode:(V2NIMBindUserAIBotToQrCodeParams *)params
                      success:(nullable V2NIMSuccessCallback)success
                      failure:(nullable V2NIMFailureCallback)failure;

@end

// Al数字人监听
@protocol V2NIMAIListener <NSObject>
@optional

/**
 *  AI透传接口的响应的回调
 *  接口调用完毕后, 接下来服务器响应以通知的形式下发, 端测需要触发回调提供.
 *  @param data  响应内容
 */
- (void)onProxyAIModelCall:(V2NIMAIModelCallResult *)data;

/**
 *  AI 透传接口的流式响应的回调
 *  流式过程中回调此方法，流式结束后还是会统一调用onProxyAIModelCall方法
 *  @param data 本次响应的结构体
 */
- (void)onProxyAIModelStreamCall:(V2NIMAIModelStreamCallResult *)data;

@end


@interface V2NIMAIModelCallContent : NSObject<NSCopying>

/// 请求/响应的文本内容
@property(nonatomic,copy) NSString *msg;

/// 类型,暂时只有0，代表文本，预留扩展能力
@property(nonatomic,assign) V2NIMAIModelCallContentType type;

@end

/// 请求调用上下文内容
@interface V2NIMAIModelCallMessage : NSObject

/// 上下文内容的角色
@property(nonatomic,assign) V2NIMAIModelRoleType role;

/// 上下文内容的内容
@property(nonatomic,copy) NSString *msg;

/// 类型
@property(nonatomic,assign) V2NIMAIModelCallContentType type;

@end

/**
 *  Ai 大模型配置覆盖， 配置了该字段， 则默认覆盖控制台相关配置
 *  如果所有字段均为空，则以控制台配置为准， 本地不做格式校验
 *  如果设置参数超过范围， 则会主动纠正到正确范围
 */
@interface V2NIMAIModelConfigParams : NSObject<NSCopying>

/// 提示词
@property(nullable,nonatomic,copy) NSString *prompt;

/// 模型最大tokens数量
@property(nonatomic,assign) NSInteger maxTokens;

/**
 *  取值范围（0，1），生成时，核采样方法的概率阈值。
 *  例如，取值为0.8时，仅保留累计概率之和大于等于0.8的概率分布中的token，作为随机采样的候选集。取值范围为（0,1.0)，取值越大，生成的随机性越高；取值越低，生成的随机性越低。
 *  默认值 0.5。注意，取值不要大于等于1
 */

@property(nonatomic,assign) CGFloat topP;

/**
 *  取值范围(0,2)，用于控制随机性和多样性的程度。
 *  具体来说，temperature值控制了生成文本时对每个候选词的概率分布进行平滑的程度。较高的temperature值会降低概率分布的峰值，使得更多的低概率词被选择，生成结果更加多样化；而较低的temperature值则会增强概率分布的峰值，使得高概率词更容易被选择，生成结果更加确定。
 */
@property(nonatomic,assign) CGFloat temperature;

@end

@interface V2NIMProxyAIModelCallParams : NSObject

/// 机器人账号ID
@property(nonatomic,copy) NSString *accountId;

/// 请求id
@property(nonatomic,copy) NSString *requestId;

/// 请求大模型的内容
@property(nonatomic,strong) V2NIMAIModelCallContent *content;

/// 上下文内容
@property(nullable,nonatomic,strong) NSArray<V2NIMAIModelCallMessage *> *messages;

/// 提示词变量占位符替换
/// JSON 格式的字符串
/// 用于填充prompt中的变量
@property(nullable,nonatomic,copy) NSString *promptVariables;

/// 请求接口模型相关参数配置， 如果参数不为空，则默认覆盖控制相关配置
@property(nullable,nonatomic,strong) V2NIMAIModelConfigParams *modelConfigParams;

/// AI 透传接口的反垃圾配置
@property(nullable,nonatomic,strong) V2NIMProxyAICallAntispamConfig *antispamConfig;

/// 是否是流式响应，默认NO
@property(nonatomic,assign,readwrite) BOOL aiStream;
@end

@interface V2NIMAIModelConfig : NSObject

/// 具体大模型版本模型名
@property(nonatomic,copy) NSString *model;

/// 提示词
@property(nonatomic,copy) NSString *prompt;

/// 提示词对应的变量
@property(nullable,nonatomic,strong) NSArray *promptKeys;

/// 模型最大tokens数量
@property(nonatomic,assign) NSInteger maxTokens;

/**
 *  取值范围（0，1），生成时，核采样方法的概率阈值。
 *  例如，取值为0.8时，仅保留累计概率之和大于等于0.8的概率分布中的token，作为随机采样的候选集。取值范围为（0,1.0)，取值越大，生成的随机性越高；取值越低，生成的随机性越低。
 *  默认值 0.5。注意，取值不要大于等于1
 */

@property(nonatomic,assign) CGFloat topP;

/**
 *  取值范围(0,2)，用于控制随机性和多样性的程度。
 *  具体来说，temperature值控制了生成文本时对每个候选词的概率分布进行平滑的程度。较高的temperature值会降低概率分布的峰值，使得更多的低概率词被选择，生成结果更加多样化；而较低的temperature值则会增强概率分布的峰值，使得高概率词更容易被选择，生成结果更加确定。
 */
@property(nonatomic,assign) CGFloat temperature;

@end

@interface V2NIMAIUser : V2NIMUser

/// 大模型类型
/// @deprecated 该字段已废弃，使用 {@link #aiModelType}
@property(nonatomic,assign) V2NIMAIModelType modelType;

///获取大模型类型
///0: 未知
///1: 通义千问
///2: 微软Azure
///3: 私有本地大模型
@property(nonatomic,assign) NSInteger aiModelType;

/// 模型相关配置信息
@property(nullable,nonatomic) V2NIMAIModelConfig *modelConfig;

@end


@interface V2NIMProxyAICallAntispamConfig : NSObject
/// 指定消息是否需要经过安全通。默认为 true
/// 对于已开通安全通的用户有效，默认消息都会走安全通，如果对单条消息设置 enable 为 false，则此消息不会走安全通
@property(nonatomic,assign) BOOL antispamEnabled;

/// 指定易盾业务id
@property(nullable,nonatomic,copy) NSString *antispamBusinessId;
@end

@interface V2NIMAIModelCallResult : NSObject

/// 数字人的accountId
@property(nonatomic,copy) NSString *accountId;

/// 本次响应的标识
@property(nonatomic,copy) NSString *requestId;

/// 请求AI的回复
@property(nonatomic,strong) V2NIMAIModelCallContent *content;

/// AI响应的状态码
@property(nonatomic,assign) NSInteger code;

/// 数字人回复内容的引用资源列表
@property (nonatomic, strong) NSArray<V2NIMAIRAGInfo *> *aiRAGs;

/// 回复的时间戳
@property (nonatomic, assign) NSTimeInterval timestamp;

/// 是否是流式响应，默认false
@property (nonatomic, assign) BOOL aiStream;

/// 数字人流式响应状态
@property (nonatomic, assign) V2NIMAIModelStreamCallStatus aiStreamStatus;

@end

/// 透传协议流式分片信息
@interface V2NIMAIModelStreamCallChunk : NSObject

/// 数字人流式回复分片文本
@property (nonatomic, copy) NSString *content;

/// 数字人流式回复当前分片时间
@property (nonatomic, assign) NSTimeInterval chunkTime;

/// 类型，当前仅支持0表示文本
@property (nonatomic, assign) NSInteger type;

/// 分片序号，从0开始
@property (nonatomic, assign) NSInteger index;

@end

/// 流式回复内容
@interface V2NIMAIModelStreamCallContent : NSObject

/// 数字人流式回复分片组装好的文本
@property (nonatomic, copy, readonly) NSString *msg;

/// 类型，当前仅支持0表示文本
@property (nonatomic, assign, readonly) NSInteger type;

/// 数字人流式回复最近一个分片
@property (nonatomic, strong, readonly) V2NIMAIModelStreamCallChunk *lastChunk;

@end

/// 透传接口的 AI 流式回复的结构体
@interface V2NIMAIModelStreamCallResult : NSObject

/// AI 响应的状态码
@property (nonatomic, assign, readonly) NSInteger code;

/// 数字人的 accountId
@property (nonatomic, copy, readonly) NSString *accountId;

/// 本次响应的标识
@property (nonatomic, copy, readonly) NSString *requestId;

/// 请求 AI 的回复
@property (nonatomic, strong, readonly) V2NIMAIModelStreamCallContent *content;

/// 数字人回复内容的引用资源列表
/// 第一个分片才下发
@property (nonatomic, copy, readonly) NSArray<V2NIMAIRAGInfo *> *aiRAGs;

/// 分片的时间戳
@property (nonatomic, assign, readonly) NSTimeInterval timestamp;

@end

/// 停止透传接口的 AI 流式回复
@interface V2NIMAIModelStreamCallStopParams : NSObject

/// 机器人账号ID
/// AIUser对应的账号ID
@property (nonatomic, copy) NSString *accountId;

/// 请求id
@property (nonatomic, copy) NSString *requestId;

@end

#pragma mark - 用户级 AI Bot 数据模型

/** 用户级 AI Bot 完整账号信息（AiAccountTag） */
@interface V2NIMUserAIBot : NSObject
/** Bot 的账号 ID（Tag 1） */
@property(nonatomic, copy) NSString *accid;
/** 应用 ID（Tag 2） */
@property(nonatomic, assign) NSInteger appid;
/** Bot 的昵称（Tag 3） */
@property(nullable, nonatomic, copy) NSString *name;
/** Bot 的头像（Tag 4） */
@property(nullable, nonatomic, copy) NSString *icon;
/** Bot 的个性签名（Tag 5） */
@property(nullable, nonatomic, copy) NSString *sign;
/** 性别（Tag 6） */
@property(nonatomic, assign) NSInteger gender;
/** 邮箱（Tag 7） */
@property(nullable, nonatomic, copy) NSString *email;
/** 生日（Tag 8） */
@property(nullable, nonatomic, copy) NSString *birth;
/** 手机号（Tag 9） */
@property(nullable, nonatomic, copy) NSString *mobile;
/** 扩展字段（Tag 10） */
@property(nullable, nonatomic, copy) NSString *ex;
/** 类型（Tag 11） */
@property(nonatomic, assign) NSInteger type;
/** 模型配置（JSON 字符串，Tag 12） */
@property(nullable, nonatomic, copy) NSString *modelConfigStr;
/** 云信配置（JSON 字符串，Tag 13） */
@property(nullable, nonatomic, copy) NSString *yunxinConfig;
/** 有效标志（Tag 14） */
@property(nonatomic, assign) NSInteger validFlag;
/** 创建时间（Unix 时间戳，毫秒，Tag 15） */
@property(nonatomic, assign) uint64_t createTime;
/** 更新时间（Unix 时间戳，毫秒，Tag 16） */
@property(nonatomic, assign) uint64_t updateTime;
/** 业务类型（Tag 17） */
@property(nonatomic, assign) NSInteger business;
/** 等级：1 应用级，2 用户级（Tag 18） */
@property(nonatomic, assign) NSInteger level;
/** 所有者 ID（Tag 19） */
@property(nullable, nonatomic, copy) NSString *ownerid;
/** 登录密钥（Tag 20） */
@property(nullable, nonatomic, copy) NSString *token;
@end

/** 创建用户级 AI Bot 请求参数（协议 37-1） */
@interface V2NIMCreateUserAIBotParams : NSObject
/** Bot 的账号 ID，需全局唯一（Tag 1） */
@property(nonatomic, copy) NSString *accid;
/** Bot 的昵称（Tag 2） */
@property(nonatomic, copy) NSString *name;
/** Bot 的头像 URL（Tag 3） */
@property(nullable, nonatomic, copy) NSString *icon;
/** Bot 的个性签名（Tag 4） */
@property(nullable, nonatomic, copy) NSString *sign;
/** 扩展字段（Tag 5） */
@property(nullable, nonatomic, copy) NSString *ex;
@end

/** 创建用户级 AI Bot 响应结果（协议 37-1） */
@interface V2NIMCreateUserAIBotResult : NSObject
/** Bot 的登录密钥（Tag 1） */
@property(nonatomic, copy) NSString *token;
@end

/** 分页查询用户级 AI Bot 列表请求参数（协议 37-2） */
@interface V2NIMGetUserAIBotListParams : NSObject
/** 分页标记（Tag 1），首次不传，翻页传上一次的 nextToken */
@property(nullable, nonatomic, copy) NSString *pageToken;
/** 每页返回数量（Tag 2），默认 100 */
@property(nonatomic, assign) NSInteger limit;
@end

/** 分页查询用户级 AI Bot 列表响应结果（协议 37-2） */
@interface V2NIMGetUserAIBotListResult : NSObject
/** Bot 账号信息列表 */
@property(nonatomic, copy) NSArray<V2NIMUserAIBot *> *bots;
/** 是否还有更多数据 */
@property(nonatomic, assign) BOOL hasMore;
/** 下一页的分页标记 */
@property(nullable, nonatomic, copy) NSString *nextToken;
@end

/** 查询单个用户级 AI Bot 请求参数（协议 37-5） */
@interface V2NIMGetUserAIBotParams : NSObject
/** 需要查询的 Bot 账号 ID（Tag 1） */
@property(nonatomic, copy) NSString *accid;
@end

/** 更新用户级 AI Bot 请求参数（协议 37-4） */
@interface V2NIMUpdateUserAIBotParams : NSObject
/** 需要更新的 Bot 账号 ID（Tag 1） */
@property(nonatomic, copy) NSString *accid;
/** 新的昵称（Tag 2） */
@property(nullable, nonatomic, copy) NSString *name;
/** 新的头像 URL（Tag 3） */
@property(nullable, nonatomic, copy) NSString *icon;
/** 新的个性签名（Tag 4） */
@property(nullable, nonatomic, copy) NSString *sign;
/** 新的扩展字段（Tag 5） */
@property(nullable, nonatomic, copy) NSString *ex;
@end

/** 删除用户级 AI Bot 请求参数（协议 37-3） */
@interface V2NIMDeleteUserAIBotParams : NSObject
/** 需要删除的 Bot 账号 ID（Tag 1） */
@property(nonatomic, copy) NSString *accid;
@end

/** 刷新用户级 AI Bot Token 请求参数（协议 37-6） */
@interface V2NIMRefreshUserAIBotTokenParams : NSObject
/** 需要刷新 token 的 Bot 账号 ID（Tag 1） */
@property(nonatomic, copy) NSString *accid;
@end

/** 刷新用户级 AI Bot Token 响应结果（协议 37-6） */
@interface V2NIMRefreshUserAIBotTokenResult : NSObject
/** 刷新后的新登录密钥（Tag 1） */
@property(nonatomic, copy) NSString *token;
@end

/** 二维码绑定用户级 AI Bot 请求参数（协议 37-7） */
@interface V2NIMBindUserAIBotToQrCodeParams : NSObject
/** Bot 的账号 ID（Tag 1） */
@property(nonatomic, copy) NSString *accid;
/** Bot 的登录 token（Tag 2） */
@property(nonatomic, copy) NSString *token;
/** 二维码标识 UUID，有效期 300 秒（Tag 3） */
@property(nonatomic, copy) NSString *qrCode;
@end

NS_ASSUME_NONNULL_END
