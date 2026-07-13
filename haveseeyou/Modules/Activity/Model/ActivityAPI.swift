//
//  HomeAPI.swift
//  haveseeyou
//
//  首页相关接口定义
//

import Foundation
import Alamofire

enum HomeAPI: APITarget {
    case banners(cateId: String?)
    case activityList(city: String, category: String?, page: Int)
    case homeIndex(type: Int, area: Int?, isOnline: Int?, videoStatus: Int?, ageBegin: Int?, ageEnd: Int?, isAuth: Int?, isGoddess: Int?, activity: String?, gender: Int?, page: Int, limit: Int)

    var path: String {
        switch self {
        case .banners:        return "/meetv1/banner/list"
        case .activityList:   return "/home/activities"
        case .homeIndex:      return "/meetv1/home/index"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .banners:        return .post
        case .activityList:   return .post
        case .homeIndex:      return .post
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .banners(let cateId):
            if let id = cateId {
                return ["cate_id": id]
            }
            return nil
        case let .activityList(city, category, page):
            var p: [String: Any] = ["city": city, "page": page, "pageSize": 20]
            if let c = category { p["category"] = c }
            return p
        case let .homeIndex(type, area, isOnline, videoStatus, ageBegin, ageEnd, isAuth, isGoddess, activity, gender, page, limit):
            var p: [String: Any] = ["type": type, "page": page, "limit": limit]
            if let area = area { p["area"] = area }
            if let isOnline = isOnline { p["is_online"] = isOnline }
            if let videoStatus = videoStatus { p["video_status"] = videoStatus }
            if let ageBegin = ageBegin { p["ageBegin"] = ageBegin }
            if let ageEnd = ageEnd { p["ageEnd"] = ageEnd }
            if let isAuth = isAuth { p["is_auth"] = isAuth }
            if let isGoddess = isGoddess { p["is_goddess"] = isGoddess }
            if let activity = activity, !activity.isEmpty { p["activity"] = activity }
            if let gender = gender { p["gender"] = gender }
            return p
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .banners:
            return URLEncoding.default
        default:
            return JSONEncoding.default
        }
    }

    var headers: HTTPHeaders? {
        switch self {
        case .banners:
            return ["Content-Type": "application/x-www-form-urlencoded"]
        default:
            return nil
        }
    }
}

// MARK: - HomeIndex 响应模型
struct HomeIndexResponse: Decodable {
    let page: Int
    let totalPage: Int
    let list: [HomeIndexUser]
    
    enum CodingKeys: String, CodingKey {
        case page
        case totalPage = "total_page"
        case list
        // total 字段我们不需要，不定义即可
    }
}

// MARK: - 单个搭子用户数据
struct HomeIndexUser: Decodable {
    let userId: Int
    let nickname: String
    let usercode: String
    let gender: Int
    let age: Int
    let arrangePlayCityLabel: String
    let height: Int?
    let avatar: String
    let city: Int
    let occupation: String?
    let wechatAccount: String?
    let updatetime: TimeInterval
    let cityName: String
    let activeTime: String
    let albumData: [String]
    let albumNumber: Int
    let extra: HomeIndexExtra
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nickname
        case usercode
        case gender
        case age
        case arrangePlayCityLabel = "arrange_play_city_label"
        case height
        case avatar
        case city
        case occupation
        case wechatAccount = "wechat_account"
        case updatetime
        case cityName = "city_name"
        case activeTime = "active_time"
        case albumData = "album_data"
        case albumNumber = "album_number"
        case extra
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 兼容 user_id 可能是字符串或数字
        if let userIdInt = try? container.decode(Int.self, forKey: .userId) {
            userId = userIdInt
        } else if let userIdString = try? container.decode(String.self, forKey: .userId), let userIdInt = Int(userIdString) {
            userId = userIdInt
        } else {
            userId = 0
        }
        
        nickname = try container.decode(String.self, forKey: .nickname)
        usercode = try container.decode(String.self, forKey: .usercode)
        
        // 兼容 gender 可能是字符串或数字
        if let genderInt = try? container.decode(Int.self, forKey: .gender) {
            gender = genderInt
        } else if let genderString = try? container.decode(String.self, forKey: .gender), let genderInt = Int(genderString) {
            gender = genderInt
        } else {
            gender = 0
        }
        
        // 兼容 age 可能是字符串或数字
        if let ageInt = try? container.decode(Int.self, forKey: .age) {
            age = ageInt
        } else if let ageString = try? container.decode(String.self, forKey: .age), let ageInt = Int(ageString) {
            age = ageInt
        } else {
            age = 0
        }
        
        arrangePlayCityLabel = try container.decode(String.self, forKey: .arrangePlayCityLabel)
        
        // 兼容 height 可能是字符串或数字
        if let heightInt = try? container.decodeIfPresent(Int.self, forKey: .height) {
            height = heightInt
        } else if let heightString = try? container.decodeIfPresent(String.self, forKey: .height), let heightInt = Int(heightString) {
            height = heightInt
        } else {
            height = nil
        }
        
        avatar = try container.decode(String.self, forKey: .avatar)
        
        // 兼容 city 可能是字符串或数字
        if let cityInt = try? container.decode(Int.self, forKey: .city) {
            city = cityInt
        } else if let cityString = try? container.decode(String.self, forKey: .city), let cityInt = Int(cityString) {
            city = cityInt
        } else {
            city = 0
        }
        
        occupation = try container.decodeIfPresent(String.self, forKey: .occupation)
        wechatAccount = try container.decodeIfPresent(String.self, forKey: .wechatAccount)
        
        // 兼容 updatetime 可能是字符串或数字
        if let updatetimeDouble = try? container.decode(TimeInterval.self, forKey: .updatetime) {
            updatetime = updatetimeDouble
        } else if let updatetimeString = try? container.decode(String.self, forKey: .updatetime), let updatetimeDouble = TimeInterval(updatetimeString) {
            updatetime = updatetimeDouble
        } else {
            updatetime = 0
        }
        
        cityName = try container.decode(String.self, forKey: .cityName)
        activeTime = try container.decode(String.self, forKey: .activeTime)
        
        // 兼容处理 albumData，支持空数组和可能的类型转换
        if let albumArray = try? container.decode([String].self, forKey: .albumData) {
            albumData = albumArray
        } else {
            albumData = []
        }
        
        // 兼容 album_number 可能是字符串或数字
        if let albumNumberInt = try? container.decode(Int.self, forKey: .albumNumber) {
            albumNumber = albumNumberInt
        } else if let albumNumberString = try? container.decode(String.self, forKey: .albumNumber), let albumNumberInt = Int(albumNumberString) {
            albumNumber = albumNumberInt
        } else {
            albumNumber = 0
        }
        
        // 兼容 extra 可能为 null 的情况
        if let extraValue = try? container.decode(HomeIndexExtra.self, forKey: .extra) {
            extra = extraValue
        } else {
            extra = HomeIndexExtra(initialHeart: "", activity: "")
        }
    }
}

// MARK: - 额外信息
struct HomeIndexExtra: Decodable {
    let initialHeart: String
    let activity: String
    
    enum CodingKeys: String, CodingKey {
        case initialHeart = "initial_heart"
        case activity
        // interested 字段我们不需要，不定义即可
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 兼容 initial_heart 可能为 null 的情况
        if let initialHeartValue = try? container.decode(String.self, forKey: .initialHeart) {
            initialHeart = initialHeartValue
        } else {
            initialHeart = ""
        }
        
        // 兼容 activity 可能为 null 的情况
        if let activityValue = try? container.decode(String.self, forKey: .activity) {
            activity = activityValue
        } else {
            activity = ""
        }
    }
}

// 为 HomeIndexExtra 添加便捷初始化方法
extension HomeIndexExtra {
    init(initialHeart: String, activity: String) {
        self.initialHeart = initialHeart
        self.activity = activity
    }
}

// MARK: - 转换为 RelationModel
extension HomeIndexUser {
    func toRelationModel() -> RelationModel {
        var model = RelationModel()
        model.userid = userId
        model.nickname = nickname
        model.usercode = usercode
        model.gender = gender
        model.age = age
        model.avatar = avatar
        model.city = cityName
        model.occupation = occupation
        model.sign = extra.initialHeart
        model.arrange_play_city_label = arrangePlayCityLabel
        
        // 处理标签：从 extra.activity 中分割出标签
        let activityTags = extra.activity.components(separatedBy: ",").filter { !$0.isEmpty }
        model.label = activityTags.isEmpty ? nil : activityTags
        
        return model
    }
}
