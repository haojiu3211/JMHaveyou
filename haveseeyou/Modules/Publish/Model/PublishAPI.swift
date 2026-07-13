//
//  PublishAPI.swift
//  haveseeyou
//
//  发布活动相关的 API 定义
//


import Foundation
import Alamofire

/// 发布活动的 API 端点
enum PublishAPI {
    /// 发布新活动
    case publish(PublishModel)
    /// 编辑已有活动
    case edit(String, PublishModel)
    /// 获取活动类型列表
    case getCategories
    /// 获取城市列表
    case getCities
    /// 我的活动列表
    case myLists(page: Int,
                 limit: Int,
                 status: String,
                 gender: String,
                 activityType: String,
                 cityId: String)
    /// 删除活动
    case deleteActivity(id: String)
    /// 获取所有活动列表
    case listAll(gender: String?, activityType: String?, cityId: String?, status: String?, page: Int, limit: Int, userId: String?)
    /// 一呼百应发起通知
    case informPublish(meetActivityId: String, cityId: String, ageMin: String, ageMax: String, gender: String, inviteCount: String)
    /// 一呼百应我的记录列表
    case informMyLists(page: Int, limit: Int)
}

extension PublishAPI: APITarget {
    var path: String {
        switch self {
        case .publish:
            return "/meetv1/meet_activity/publish"
        case .edit(let id, _):
            return "/activities/\(id)/edit"
        case .getCategories:
            return "/categories"
        case .getCities:
            return "/cities"
        case .myLists:
            return "/meetv1/meet_activity/myLists"
        case .deleteActivity:
            return "/meetv1/meet_activity/deleteActivity"
        case .listAll:
            return "/meetv1/meet_activity/listAll"
        case .informPublish:
            return "/meetv1/inform/publish"
        case .informMyLists:
            return "/meetv1/inform/myLists"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .publish, .edit, .myLists, .deleteActivity, .listAll, .informPublish, .informMyLists:
            return .post
        case .getCategories, .getCities:
            return .get
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .publish(let model):
            return model.toPublishParams()
        case .myLists(let page, let limit, let status, let gender, let activityType, let cityId):
            return [
                "page": "\(page)",
                "limit": "\(limit)",
                "status": status,
                "gender": gender,
                "activity_type": activityType,
                "city_id": cityId
            ]
        case .deleteActivity(let id):
            return ["id": id]
        case let .listAll(gender, activityType, cityId, status, page, limit, userId):
            var params: [String: Any] = [
                "page": "\(page)",
                "limit": "\(limit)"
            ]
            if let gender = gender, !gender.isEmpty { params["gender"] = gender }
            if let activityType = activityType, !activityType.isEmpty { params["activity_type"] = activityType }
            if let cityId = cityId, !cityId.isEmpty { params["city_id"] = cityId }
            if let status = status, !status.isEmpty { params["status"] = status }
            if let userId = userId, !userId.isEmpty { params["user_id"] = userId }
            return params
        case .informPublish(let meetActivityId, let cityId, let ageMin, let ageMax, let gender, let inviteCount):
            return [
                "meet_activity_id": meetActivityId,
                "city_id": cityId,
                "age_min": ageMin,
                "age_max": ageMax,
                "gender": gender,
                "invite_count": inviteCount
            ]
        case .informMyLists(let page, let limit):
            return [
                "page": "\(page)",
                "limit": "\(limit)"
            ]
        default:
            return nil
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .publish, .edit, .myLists, .deleteActivity, .informPublish, .informMyLists:
            return URLEncoding.default
        case .listAll:
            return JSONEncoding.default
        default:
            return URLEncoding.default
        }
    }

    /// 覆盖全局 commonHeaders 的 Content-Type；走 urlencoded 的接口都返回 form 头
    var headers: HTTPHeaders? {
        switch self {
        case .publish, .edit, .myLists, .deleteActivity, .informPublish, .informMyLists:
            return ["Content-Type": "application/x-www-form-urlencoded"]
        default:
            return nil
        }
    }
}

// MARK: - 发布响应模型
struct PublishResponseModel: Codable {
    let success: Bool
    let message: String
    let data: PublishResultModel?
}

struct PublishResultModel: Codable {
    let id: String?
    let title: String?
    let createdAt: Date?
}

// MARK: - 我的活动列表响应

/// 我的活动列表数据包（APIResponse<MyActivityListData>）
struct MyActivityListData: Decodable {
    let list: [MyActivityItem]?
    let total: Int?
    let page: Int?
    let totalPage: Int?

    enum CodingKeys: String, CodingKey {
        case list, total, page
        case totalPage = "total_page"
    }
}

/// 活动类型 - 服务端是对象数组
struct MyActivityTypeItem: Decodable {
    let meetActivityId: Int?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case meetActivityId = "meet_activity_id"
        case name
    }
}

/// 活动发布者信息
struct MyActivityUser: Decodable {
    let usercode: String?
    let id: Int?
    let nickname: String?
    let avatar: String?
    let birthday: String?
    let gender: Int?
    let age: Int?
    let constellation: String?
    let isFollow: Bool?  // 是否已关注

    enum CodingKeys: String, CodingKey {
        case usercode
        case id
        case nickname
        case avatar
        case birthday
        case gender
        case age
        case constellation
        case isFollow = "is_follow"
    }
}

/// 单条活动（字段全部可选，避免后端字段缺失就解析失败）
struct MyActivityItem: Decodable {
    let id: Int?
    let title: String?
    let content: String?
    let images: String?              // 多图逗号分隔
    let peopleNum: Int?
    let gender: Int?                 // 0=未知 1=女 2=男
    let activityTime: Int?           // 时间戳；长期活动这里为 0
    let isLongTerm: Int?             // 1=长期
    let location: String?
    let provinceId: Int?
    let cityId: Int?
    let districtId: Int?
    let activityType: [MyActivityTypeItem]?
    let feeType: String?
    let status: String?              // draft / pending / published / rejected / expired
    let createtime: Int?
    let updatetime: Int?
    let rejectedMsg: String?
    let user: MyActivityUser?        // 发布者信息
    let isInterested: Int?           // 是否已感兴趣 0=否 1=是

    enum CodingKeys: String, CodingKey {
        case id, title, content, images, gender, location, status, createtime, updatetime, user
        case peopleNum     = "people_num"
        case activityTime  = "activity_time"
        case isLongTerm    = "is_long_term"
        case provinceId    = "province_id"
        case cityId        = "city_id"
        case districtId    = "district_id"
        case activityType  = "activity_type"
        case feeType       = "fee_type"
        case rejectedMsg   = "rejected_msg"
        case isInterested  = "is_interested"
    }

    /// 拆出 images 字段为数组
    var imageList: [String] {
        guard let s = images, !s.isEmpty else { return [] }
        return s.split(separator: ",").map { String($0) }
    }

    /// 把 activity_type 数组转成 "K歌,蹦迪" 形式
    var activityTypeNames: String {
        (activityType ?? []).compactMap { $0.name }.joined(separator: ",")
    }
}
