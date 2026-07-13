//
//  ChatAPI.swift
//  haveseeyou
//
//  聊天相关接口定义
//

import Foundation
import Alamofire

/// 发送消息前的校验响应（成功时返回的 data）
struct SendMessagePrecheckData: Decodable {
    /// 服务端要求附带的远端扩展，发送 IM 消息时透传
    let remoteExtension: [String: String]?

    enum CodingKeys: String, CodingKey {
        case remoteExtension = "remote_extension"
    }

    init(from decoder: Decoder) throws {
        let c = try? decoder.container(keyedBy: CodingKeys.self)
        self.remoteExtension = (try? c?.decodeIfPresent([String: String].self, forKey: .remoteExtension)) ?? nil
    }
}

/// 当前感兴趣的活动信息
struct CurrentlyInterestedInfoModel: Decodable {
    let id: Int?
    let title: String?
    let content: String?
    let images: String?
    let peopleNum: Int?
    let gender: Int?
    let activityTime: Int?
    let isLongTerm: Int?
    let location: String?
    let feeType: String?
    let status: String?
    let activityType: [ActivityType]?
    let user: UserInfo?
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, images, gender, location, status, user
        case peopleNum = "people_num"
        case activityTime = "activity_time"
        case isLongTerm = "is_long_term"
        case feeType = "fee_type"
        case activityType = "activity_type"
    }
}

/// 活动类型
struct ActivityType: Decodable {
    let meetActivityId: Int?
    let name: String?
    
    enum CodingKeys: String, CodingKey {
        case meetActivityId = "meet_activity_id"
        case name
    }
}

/// 用户信息
struct UserInfo: Decodable {
    let id: Int?
    let usercode: String?
    let nickname: String?
    let avatar: String?
    let birthday: String?
    let gender: Int?
    let age: Int?
    let qqAccount: String?
    let wechatAccount: String?
    
    enum CodingKeys: String, CodingKey {
        case id, usercode, nickname, avatar, birthday, gender, age
        case qqAccount = "qq_account"
        case wechatAccount = "wechat_account"
    }
}

enum ChatAPI {
    /// 发送消息前的校验
    /// - Parameters:
    ///   - type: 消息类型 (1=文本, 2=语音, 3=图片, 4=视频, 7=文件)
    ///   - content: 消息内容
    ///   - msgId: 消息 UUID
    ///   - toUid: 目标用户 ID
    case sendMessageCheck(type: Int, content: String, msgId: String, toUid: String)
    
    /// 获取当前感兴趣的活动信息
    /// - Parameter toUserId: 与哪个用户聊天
    case currentlyInterestedInfo(toUserId: String)
}

extension ChatAPI: APITarget {
    var path: String {
        switch self {
        case .sendMessageCheck:
            return "/sendMessage"
        case .currentlyInterestedInfo:
            return "/meetv1/meet_activity/currentlyInterestedInfo"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .sendMessageCheck:
            return .post
        case .currentlyInterestedInfo:
            return .post
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case let .sendMessageCheck(type, content, msgId, toUid):
            return [
                "type": type,
                "content": content,
                "msgId": msgId,
                "to_uid": toUid
            ]
        case let .currentlyInterestedInfo(toUserId):
            return [
                "to_user_id": toUserId
            ]
        }
    }
}
