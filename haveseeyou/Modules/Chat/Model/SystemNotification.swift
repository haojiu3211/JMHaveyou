//
//  SystemNotification.swift
//  haveseeyou
//
//  系统通知数据模型
//

import UIKit
import NIMSDK
import NECoreIM2Kit

/// 自定义系统通知消息
/// 对应自定义消息：
/// {
///   "type": 10001,           // 10001(用户操作) / 11(系统消息)
///   "data": {
///     "user_id": Int,
///     "nickname": String,
///     "avatar": String,
///     "title": String,        // 例如：已关注了你
///     "time": String,
///     "date": String,
///     "txt1": String,
///     "txt2": String,
///     "link_url": String,
///     "link_type": Int,
///     "jump_obj": { "name": String, "color": "#F6D242" },
///     "action": Int,
///     "report_id": Int,
///     "image": String
///   },
///   "title": String,          // 位置消息标题
///   "lat": Double,
///   "lng": Double,
///   "address": String
/// }
struct SystemNotification {
    /// 唯一标识（messageClientId / report_id 优先）
    let id: String
    /// 消息类型 10001(用户操作) / 11(系统消息) 等
    let type: Int

    // MARK: data
    let userId: Int?
    let userName: String
    let userAvatar: String?
    let vip: Int?
    /// 文案，例如 "已关注了你"
    let content: String
    let time: String
    let date: String?
    let txt1: String?
    let txt2: String?
    let linkUrl: String?
    let linkType: Int?
    /// 跳转按钮文案，没有时为 nil
    let jumpName: String?
    /// 跳转按钮颜色，"#FFFFFF"
    let jumpColor: String?
    let action: Int?
    let reportId: Int?
    /// 卡片附图
    let image: String?

    // MARK: 位置消息
    let locationTitle: String?
    let latitude: Double?
    let longitude: Double?
    let address: String?

    /// 排序用
    let createTime: TimeInterval
}

// MARK: - 自定义消息解析

extension SystemNotification {
    /// 从云信 V2NIMMessage 解析。无法识别的自定义消息返回 nil。
    static func parse(_ message: V2NIMMessage) -> SystemNotification? {
        guard message.messageType == .MESSAGE_TYPE_CUSTOM,
              let dict = NECustomUtils.attachmentOfCustomMessage(message.attachment)
        else { return nil }
        return parse(dict: dict,
                     fallbackId: message.messageClientId,
                     createTime: message.createTime)
    }

    /// 从已解码的字典解析（方便单测 / 兜底数据使用）
    /// - type=1014 为被过滤类型，直接返回 nil
    static func parse(dict: [String: Any],
                      fallbackId: String? = nil,
                      createTime: TimeInterval = 0) -> SystemNotification? {
        let type = (dict["type"] as? Int) ?? Int(any: dict["type"]) ?? 0
        guard type > 0, type != 1014 else { return nil }

        let data = dict["data"] as? [String: Any] ?? [:]
        let jump = data["jump_obj"] as? [String: Any] ?? [:]

        let reportId = Int(any: data["report_id"])
        let userId = Int(any: data["user_id"])

        let id: String
        if let rid = reportId {
            id = "rid_\(rid)"
        } else if let mid = fallbackId, !mid.isEmpty {
            id = mid
        } else {
            id = UUID().uuidString
        }

        return SystemNotification(
            id: id,
            type: type,
            userId: userId,
            userName: (data["nickname"] as? String) ?? "",
            userAvatar: data["avatar"] as? String,
            vip: Int(any: data["vip"]),
            content: (data["title"] as? String) ?? "",
            time: (data["time"] as? String) ?? "",
            date: data["date"] as? String,
            txt1: data["txt1"] as? String,
            txt2: data["txt2"] as? String,
            linkUrl: data["link_url"] as? String,
            linkType: Int(any: data["link_type"]),
            jumpName: jump["name"] as? String,
            jumpColor: jump["color"] as? String,
            action: Int(any: data["action"]),
            reportId: reportId,
            image: data["image"] as? String,
            locationTitle: dict["title"] as? String,
            latitude: Double(any: dict["lat"]),
            longitude: Double(any: dict["lng"]),
            address: dict["address"] as? String,
            createTime: createTime
        )
    }
}

// MARK: - 业务类型

extension SystemNotification {
    enum Kind {
        /// 10001：用户操作（关注/访问/解锁）→ 看 Ta 主页
        case userAction
        /// 11：系统消息（公告/审核）→ 查看详情
        case system
        /// 位置消息（顶层 lat/lng/address）
        case location
        /// 其它未知类型
        case unknown
    }

    var kind: Kind {
        if latitude != nil && longitude != nil { return .location }
        switch type {
        case 10001: return .userAction
        case 11:    return .system
        default:    return .unknown
        }
    }

    /// 跳转按钮文案：优先取后端 jump_obj.name；缺省时按 type 兜底
    var actionTitle: String? {
        if let n = jumpName, !n.isEmpty { return n }
        switch kind {
        case .userAction: return "看Ta主页"
        case .system:     return "查看详情"
        case .location, .unknown: return nil
        }
    }
}

// MARK: - 数字解析兜底（JSON 里可能是 NSNumber / String / Int）

private extension Int {
    init?(any value: Any?) {
        if let v = value as? Int { self = v; return }
        if let v = value as? NSNumber { self = v.intValue; return }
        if let v = value as? String, let parsed = Int(v) { self = parsed; return }
        return nil
    }
}

private extension Double {
    init?(any value: Any?) {
        if let v = value as? Double { self = v; return }
        if let v = value as? NSNumber { self = v.doubleValue; return }
        if let v = value as? String, let parsed = Double(v) { self = parsed; return }
        return nil
    }
}
