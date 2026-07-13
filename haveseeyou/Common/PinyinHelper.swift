//
//  PinyinHelper.swift
//  haveseeyou
//
//  汉字转拼音工具（基于 Core Foundation，零第三方依赖）
//

import Foundation

enum PinyinHelper {

    /// 获取汉字的拼音首字母（大写），非汉字原样返回
    static func firstLetter(_ text: String) -> String {
        guard let first = text.first else { return "#" }
        let pinyin = convertToPinyin(String(first))
        let letter = pinyin.uppercased().first ?? Character("#")
        return letter.isLetter ? String(letter) : "#"
    }

    /// 获取完整拼音（小写，无声调）
    static func fullPinyin(_ text: String) -> String {
        return convertToPinyin(text)
    }

    /// 将中文字符串转为无声调拼音
    private static func convertToPinyin(_ text: String) -> String {
        let mutable = NSMutableString(string: text)
        // transform 标记为拉丁字母（带声调）
        CFStringTransform(mutable, nil, kCFStringTransformToLatin, false)
        // 去掉声调
        CFStringTransform(mutable, nil, kCFStringTransformStripDiacritics, false)
        return (mutable as String).lowercased()
    }
}
