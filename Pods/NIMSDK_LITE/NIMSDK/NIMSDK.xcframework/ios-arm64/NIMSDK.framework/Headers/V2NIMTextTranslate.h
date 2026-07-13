//
//  V2NIMTextTranslate.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2025 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 文本翻译相关参数
@interface V2NIMTextTranslateParams : NSObject

/// 需要翻译的文本信息， 最大长度5000字符。
@property(nonatomic, strong) NSString *text;

/// 输入文本对应的语言， 如果不传则默认为自动识别，如果明确源语言类型则输入源语言类型标识。支持输入：“auto”， 表示自动识别。
@property(nullable, nonatomic, strong) NSString *sourceLanguage;

/// 文本翻译的目标语言。示例："en"，更多支持的语言的代码请参考：https://doc.yunxin.163.com/messaging2/server-apis/DYxNjA4NjY?platform=server#language。
@property(nonatomic, strong) NSString *targetLanguage;

@end

/// 文本翻译结果
@interface V2NIMTextTranslationResult : NSObject

/// 翻译结果文本。
@property(nullable, nonatomic, strong) NSString *translatedText;

/// 输入文本对应的语言，支持的语言的代码请参考：https://doc.yunxin.163.com/messaging2/server-apis/DYxNjA4NjY?platform=server#language。
@property(nullable, nonatomic, strong) NSString *sourceLanguage;

/// 翻译结果文本对应的语言，支持的语言的代码请参考：https://doc.yunxin.163.com/messaging2/server-apis/DYxNjA4NjY?platform=server#language。
@property(nullable, nonatomic, strong) NSString *targetLanguage;

@end

NS_ASSUME_NONNULL_END
