//
//  V2NIMUtilityServiceProtocol.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2025 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "V2NIMBase.h"

@class V2NIMExportMessageOption;
@class V2NIMImportMessageOption;

NS_ASSUME_NONNULL_BEGIN

/// 成功接收导出消息回调
typedef void (^V2NIMExportMessagesToPathCallback)(NSString *path);

/// 工具服务协议
@protocol V2NIMUtilityService <NSObject>

/**
 *  导出本地消息到文件
 *
 *  @param option 导出选项
 *  @param success 成功回调
 *  @param failure 失败回调
 *  @param progress 进度回调
 */
- (void)exportMessagesToPath:(V2NIMExportMessageOption *)option
                     success:(nullable V2NIMExportMessagesToPathCallback)success
                     failure:(nullable V2NIMFailureCallback)failure
                    progress:(nullable V2NIMProgressCallback)progress;

/**
 *  从文件导入本地消息
 *
 *  @param option 导入选项
 *  @param success 成功回调
 *  @param failure 失败回调
 *  @param progress 进度回调
 */
- (void)importMessagesFromPath:(V2NIMImportMessageOption *)option
                       success:(nullable V2NIMSuccessCallback)success
                       failure:(nullable V2NIMFailureCallback)failure
                      progress:(nullable V2NIMProgressCallback)progress;

/**
 *  取消导出/导入消息
 */
- (void)cancelMigrateMessages;

@end

/// 导出消息选项
@interface V2NIMExportMessageOption : NSObject

/// 文件路径
@property(nonatomic,strong,nullable) NSString *path;

@end

/// 导入消息选项
@interface V2NIMImportMessageOption : NSObject

/// 文件路径
@property(nonatomic,strong) NSString *path;

@end

NS_ASSUME_NONNULL_END
