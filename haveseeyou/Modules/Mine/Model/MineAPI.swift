//
//  MineAPI.swift
//  haveseeyou
//
//  我的模块接口定义
//

import Foundation
import Alamofire

enum MineAPI: APITarget {
    /// 个人中心
    case personalCenter
    /// 粉丝列表
    case fansList(page: Int, limit: Int)
    /// 关注列表
    case watchList(page: Int, limit: Int)
    /// 访客列表
    case visitorsList(page: Int, limit: Int)
    /// 足迹列表
    case footprint(page: Int, limit: Int)
    /// 谁解锁我
    case whoUnlockedMe(page: Int, limit: Int)
    /// 添加相册
    case addAlbum(type: Int, url: String)
    /// 获取相册列表
    case getAlbumList(page: Int)
    /// 删除相册
    case deleteAlbum(ids: [Int])
    /// 保存用户信息
    case saveUserInfo(params: [String: String])

    var path: String {
        switch self {
        case .personalCenter:
            return "/meetv1/user/home/index"
        case .fansList:
            return "/fansList"
        case .watchList:
            return "/watchList"
        case .visitorsList:
            return "/visitorsList"
        case .footprint:
            return "/footprint"
        case .whoUnlockedMe:
            return "/whoUnlockedMe"
        case .addAlbum:
            return "/addAlbum"
        case .getAlbumList:
            return "/myAlbumList"
        case .deleteAlbum:
            return "/deleteAlbum"
        case .saveUserInfo:
            return "/meetv1/user/info/save"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .personalCenter, .fansList, .watchList, .visitorsList, .footprint, .whoUnlockedMe, .addAlbum, .getAlbumList, .deleteAlbum, .saveUserInfo:
            return .post
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .personalCenter:
            return nil
        case .fansList(let page, let limit):
            return ["page": page, "limit": limit]
        case .watchList(let page, let limit):
            return ["page": page, "limit": limit]
        case .visitorsList(let page, let limit):
            return ["page": page, "limit": limit]
        case .footprint(let page, let limit):
            return ["page": page, "limit": limit]
        case .whoUnlockedMe(let page, let limit):
            return ["page": page, "limit": limit]
        case .addAlbum(let type, let url):
            return ["type": type, "url": url]
        case .getAlbumList(let page):
            return ["page": page]
        case .deleteAlbum(let ids):
            return ["ids": ids]
        case .saveUserInfo(let params):
            return params
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .saveUserInfo:
            return URLEncoding.default
        default:
            return JSONEncoding.default
        }
    }

    var headers: HTTPHeaders? {
        switch self {
        case .saveUserInfo:
            return ["Content-Type": "application/x-www-form-urlencoded"]
        default:
            return nil
        }
    }
}

struct PersonalCenterData: Decodable {
    let tip: String?
    let userinfo: PersonalCenterUserInfo?
    let usercount: PersonalCenterUserCount?
    let webUrl: PersonalCenterWebUrl?
}

struct PersonalCenterUserInfo: Decodable {
    let usercode: String?
    let nickname: String?
    let sign: String?
    let type: Int?
    let mobile: String?
    let avatar: String?
    let gender: Int?
    let age: Int?
    let birthday: String?
    let city: String?
    let regist_step: Int?
    let finish_status: Int?
    let invite_id: Int?
    let im_token: String?
    let is_anchor: Int?
    let voice: String?
    let voice_time: Int?
    let is_auth: Int?
    let is_rp_auth: Int?
    let vip_icon: String?
    let vip: Int?
    let token: String?
    let user_id: Int?
    let createtime: Int?
    let expiretime: Int?
    let expires_in: Int?
    let expire_time: String?
    let is_edit_profile_pop: Int?
    let edit_profile_give_num: Int?
    let user_visitor_count: Int?
    let extra: PersonalCenterExtra?
    let arrange_play_city_label: String?
    let qq_account: String?
    let wechat_account: String?
    let annual_income: String?
    let education: String?
    let occupation: String?
    let is_wx: String?
    let is_qq: String?
    let coin: Int?
    
    // 计算属性，提供 Int 类型的值
    var is_wx_int: Int? {
        guard let stringValue = is_wx else { return nil }
        return Int(stringValue)
    }
    
    var is_qq_int: Int? {
        guard let stringValue = is_qq else { return nil }
        return Int(stringValue)
    }
}

struct PersonalCenterExtra: Decodable {
    let initial_heart: String?
    let activity: String?
}

struct PersonalCenterUserCount: Decodable {
    let fans_count: Int?
    let new_fans_count: Int?
    let follow_count: Int?
    let visitor_count: Int?
    let new_visitor_count: Int?
    let footprint_count: Int?
    let dynamic_count: Int?
}

struct PersonalCenterWebUrl: Decodable {
    let recharge_renew: String?
    let user: String?
    let privacy: String?
    let use_standards: String?
    let prevent_fraud: String?
    let purify_network: String?
    let share_url: String?

    enum CodingKeys: String, CodingKey {
        case recharge_renew
        case user
        case privacy
        case use_standards
        case prevent_fraud
        case purify_network = "purify-network"
        case share_url
    }
}

struct RelationListResponse: Decodable {
    let list: [RelationModel]?
    let total: Int?
    let totalPage: Int?
    let page: Int?

    enum CodingKeys: String, CodingKey {
        case list
        case total
        case totalPage = "total_page"
        case page
    }
}

struct RelationModel: Decodable {
    var userid: Int?
    var avatar: String?
    var nickname: String?
    var constellation: String?
    var isFollow: Int?
    var isFans: Int?
    var age: Int?
    var height: String?
    var addTime: String?
    var vip: Int?
    var gender: Int?
    var vipIcon: String?
    var city: String?
    var sign: String?
    var usercode: String?
    var weight: String?
    var occupation: String?
    var isWatch: Int?
    var isLive: Int?
    var isVideoShow: Int?
    var avatarFrame: String?
    var label: [String]?
    var arrange_play_city_label: String?

    enum CodingKeys: String, CodingKey {
        case userid
        case avatar
        case nickname
        case constellation
        case isFollow = "is_follow"
        case isFans = "is_fans"
        case age
        case height
        case addTime = "add_time"
        case vip
        case gender
        case vipIcon = "vip_icon"
        case city
        case sign
        case usercode
        case weight
        case occupation
        case isWatch = "is_watch"
        case isLive = "is_live"
        case isVideoShow = "is_video_show"
        case avatarFrame = "avatar_frame"
        case label
        case arrange_play_city_label
    }
    
    init(
        userid: Int? = nil,
        avatar: String? = nil,
        nickname: String? = nil,
        constellation: String? = nil,
        isFollow: Int? = nil,
        isFans: Int? = nil,
        age: Int? = nil,
        height: String? = nil,
        addTime: String? = nil,
        vip: Int? = nil,
        gender: Int? = nil,
        vipIcon: String? = nil,
        city: String? = nil,
        sign: String? = nil,
        usercode: String? = nil,
        weight: String? = nil,
        occupation: String? = nil,
        isWatch: Int? = nil,
        isLive: Int? = nil,
        isVideoShow: Int? = nil,
        avatarFrame: String? = nil,
        label: [String]? = nil,
        arrange_play_city_label: String? = nil
    ) {
        self.userid = userid
        self.avatar = avatar
        self.nickname = nickname
        self.constellation = constellation
        self.isFollow = isFollow
        self.isFans = isFans
        self.age = age
        self.height = height
        self.addTime = addTime
        self.vip = vip
        self.gender = gender
        self.vipIcon = vipIcon
        self.city = city
        self.sign = sign
        self.usercode = usercode
        self.weight = weight
        self.occupation = occupation
        self.isWatch = isWatch
        self.isLive = isLive
        self.isVideoShow = isVideoShow
        self.avatarFrame = avatarFrame
        self.label = label
        self.arrange_play_city_label = arrange_play_city_label
    }
}

struct VisitorResponse: Decodable {
    let list: [VisitorModel]?
    let total: Int?
    let totalPage: Int?
    let page: Int?

    enum CodingKeys: String, CodingKey {
        case list
        case total
        case totalPage = "total_page"
        case page
    }
}

struct VisitorModel: Decodable {
    let userid: Int?
    let avatar: String?
    let nickname: String?
    let viewCount: Int?
    let addTime: String?
    let addNum: Int?
    let isAuth: Int?
    let sign: String?
    let gender: Int?
    let age: Int?
    let vip: Int?
    let vipIcon: String?
    let isFollow: Int?
    let isFans: Int?
    let avatarFrame: String?

    enum CodingKeys: String, CodingKey {
        case userid
        case avatar
        case nickname
        case viewCount = "view_count"
        case addTime = "add_time"
        case addNum = "add_num"
        case isAuth = "is_auth"
        case sign
        case gender
        case age
        case vip
        case vipIcon = "vip_icon"
        case isFollow = "is_follow"
        case isFans = "is_fans"
        case avatarFrame = "avatar_frame"
    }
}

struct FootprintResponse: Decodable {
    let list: [FootprintModel]?
    let total: Int?
    let totalPage: Int?
    let page: Int?

    enum CodingKeys: String, CodingKey {
        case list
        case total
        case totalPage = "total_page"
        case page
    }
}

struct FootprintModel: Decodable {
    let userid: Int?
    let avatar: String?
    let nickname: String?
    let viewCount: Int?
    let addTime: String?
    let addNum: Int?
    let isAuth: Int?
    let sign: String?
    let gender: Int?
    let age: Int?
    let vip: Int?
    let vipIcon: String?
    let isFollow: Int?
    let isFans: Int?
    let avatarFrame: String?

    enum CodingKeys: String, CodingKey {
        case userid
        case avatar
        case nickname
        case viewCount = "view_count"
        case addTime = "add_time"
        case addNum = "add_num"
        case isAuth = "is_auth"
        case sign
        case gender
        case age
        case vip
        case vipIcon = "vip_icon"
        case isFollow = "is_follow"
        case isFans = "is_fans"
        case avatarFrame = "avatar_frame"
    }
}

// MARK: - 相册相关模型
struct MyAlbumListResponse: Decodable {
    let list: [MyAlbumItem]?
    let total: Int?
    let totalPage: Int?
    let page: Int?

    enum CodingKeys: String, CodingKey {
        case list
        case total
        case totalPage = "total_page"
        case page
    }
}

struct MyAlbumItem: Codable {
    let id: Int?
    let url: String?
    let type: Int?
    let addTime: String?

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case type
        case addTime = "add_time"
    }
}