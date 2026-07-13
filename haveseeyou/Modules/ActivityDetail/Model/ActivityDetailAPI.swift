//
//  ActivityDetailAPI.swift
//  haveseeyou
//
//  活动详情相关接口定义
//

import Foundation
import Alamofire

enum ActivityDetailAPI: APITarget {
    /// 获取活动详情
    case detail(id: String)
    /// 关注用户
    case focusOn(followUid: String)
    /// 标记感兴趣
    case isInterested(id: String)
    /// 举报用户
    case report(userId: String, reason: String)
    /// 拉黑用户
    case block(userId: String)
    /// 获取用户个人主页信息
    case personalHomepage(userId: String)

    var path: String {
        switch self {
        case .detail:            return "/meetv1/meet_activity/detail"
        case .focusOn:          return "/meetv1/focusOn"
        case .isInterested:      return "/meetv1/meet_activity/isInterested"
        case .report:            return "/user/report"
        case .block:             return "/meetv1/user/black"
        case .personalHomepage:  return "/meetv1/others/home/index"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .detail:   return .post
        case .focusOn, .isInterested, .report, .block:
            return .post
        case .personalHomepage(userId: let userId):
            return .post
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case let .detail(id):
            return ["id": id]
        case let .focusOn(followUid):
            return ["follow_uid": followUid]
        case let .isInterested(id):
            return ["id": id]
        case let .report(userId, reason):
            return ["userId": userId, "reason": reason]
        case let .block(userId):
            return ["black_uid": userId]
        case let .personalHomepage(userId):
            return ["user_id": userId]
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .block:
            return URLEncoding.default
        default:
            return method == .get ? URLEncoding.default : JSONEncoding.default
        }
    }

    var headers: HTTPHeaders? {
        switch self {
        case .block:
            return ["Content-Type": "application/x-www-form-urlencoded"]
        default:
            return nil
        }
    }
}
