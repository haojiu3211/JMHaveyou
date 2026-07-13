//
//  V2NIMTopicRefer.h
//  NIMLib
//
//  Created by Netease on 2026/3/30.
//  Copyright © 2026 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 话题引用
@interface V2NIMTopicRefer : NSObject<NSCopying>

/// 话题所属会话 id
@property(nullable, nonatomic, copy, readonly) NSString *conversationId;
/// 话题 id
@property(nonatomic, assign, readonly) uint64_t topicId;
/// 话题创建时间
@property(nonatomic, assign, readonly) int64_t createTime;

@end

NS_ASSUME_NONNULL_END
