//
//  PersonalHomepageModel.swift
//  haveseeyou
//
//  个人主页数据模型
//

import Foundation

// MARK: - 标签对象
struct LabelItem: Decodable {
    let name: String?
}

// MARK: - 个人主页根数据

struct PersonalHomepageModel: Decodable {
    let code: Int
    let message: String
    let time: String
    let data: PersonalHomepageDataModel

    enum CodingKeys: String, CodingKey {
        case code, message, time, data
    }
}

// MARK: - 个人主页数据

struct PersonalHomepageDataModel: Decodable {
    let userId: Int
    let usercode: String
    let nickname: String
    let age: Int
    let gender: Int
    let height: String
    let weight: String
    let education: String
    let occupation: String
    let signs: String
    let avatar: String
    let city: String
    let isAuth: Int
    let isRpAuth: Int
    let label: [String]
    let likePersonLabel: [String]
    let hopeRelationshipLabel: [String]
    let arrangePlayCityLabel: String
    let willGoCityLabel: String
    let sign: String
    let activeTime: String
    let remarkName: String
    var unlockPrivate: Int
    var unlockWechat: Int
    let wechatAccount: String
    var isFollow: Int
    let isBlack: Int
    let distance: String
    let headAlbum: [String]
    let album: [AlbumItem]
    let dynamicNum: Int
    let dynamic: [DynamicItem]
    let getGifts: [String]
    let sendGifts: [String]
    let isVip: Int
    let bottomText: String
    let extra: PersonalExtraInfo?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        userId = try container.decode(Int.self, forKey: .userId)
        usercode = try container.decode(String.self, forKey: .usercode)
        nickname = try container.decode(String.self, forKey: .nickname)
        age = try container.decode(Int.self, forKey: .age)
        gender = try container.decode(Int.self, forKey: .gender)
        height = try container.decode(String.self, forKey: .height)
        weight = try container.decode(String.self, forKey: .weight)
        education = try container.decode(String.self, forKey: .education)
        occupation = try container.decode(String.self, forKey: .occupation)
        signs = try container.decode(String.self, forKey: .signs)
        avatar = try container.decode(String.self, forKey: .avatar)
        city = try container.decode(String.self, forKey: .city)
        isAuth = try container.decode(Int.self, forKey: .isAuth)
        isRpAuth = try container.decode(Int.self, forKey: .isRpAuth)
        
        // 兼容 label 的两种格式：[String] 或 [{"name": "xxx"}]
        if let labelStrings = try? container.decode([String].self, forKey: .label) {
            label = labelStrings
        } else if let labelObjects = try? container.decode([LabelItem].self, forKey: .label) {
            label = labelObjects.compactMap { $0.name }
        } else {
            label = []
        }
        
        // 兼容 likePersonLabel 的两种格式
        if let likePersonLabelStrings = try? container.decode([String].self, forKey: .likePersonLabel) {
            likePersonLabel = likePersonLabelStrings
        } else if let likePersonLabelObjects = try? container.decode([LabelItem].self, forKey: .likePersonLabel) {
            likePersonLabel = likePersonLabelObjects.compactMap { $0.name }
        } else {
            likePersonLabel = []
        }
        
        // 兼容 hopeRelationshipLabel 的两种格式
        if let hopeRelationshipLabelStrings = try? container.decode([String].self, forKey: .hopeRelationshipLabel) {
            hopeRelationshipLabel = hopeRelationshipLabelStrings
        } else if let hopeRelationshipLabelObjects = try? container.decode([LabelItem].self, forKey: .hopeRelationshipLabel) {
            hopeRelationshipLabel = hopeRelationshipLabelObjects.compactMap { $0.name }
        } else {
            hopeRelationshipLabel = []
        }
        
        arrangePlayCityLabel = try container.decode(String.self, forKey: .arrangePlayCityLabel)
        willGoCityLabel = try container.decode(String.self, forKey: .willGoCityLabel)
        sign = try container.decode(String.self, forKey: .sign)
        activeTime = try container.decode(String.self, forKey: .activeTime)
        remarkName = try container.decode(String.self, forKey: .remarkName)
        unlockPrivate = try container.decode(Int.self, forKey: .unlockPrivate)
        unlockWechat = try container.decode(Int.self, forKey: .unlockWechat)
        wechatAccount = try container.decode(String.self, forKey: .wechatAccount)
        isFollow = try container.decode(Int.self, forKey: .isFollow)
        isBlack = try container.decode(Int.self, forKey: .isBlack)
        distance = try container.decode(String.self, forKey: .distance)
        headAlbum = try container.decode([String].self, forKey: .headAlbum)
        album = try container.decode([AlbumItem].self, forKey: .album)
        dynamicNum = try container.decode(Int.self, forKey: .dynamicNum)
        
        // 兼容 dynamic 的两种格式：[String] 或 [DynamicItem]
        if let dynamicItems = try? container.decode([DynamicItem].self, forKey: .dynamic) {
            dynamic = dynamicItems
        } else {
            dynamic = []
        }
        
        getGifts = try container.decode([String].self, forKey: .getGifts)
        sendGifts = try container.decode([String].self, forKey: .sendGifts)
        isVip = try container.decode(Int.self, forKey: .isVip)
        bottomText = try container.decode(String.self, forKey: .bottomText)
        
        // 兼容 extra 的两种格式：对象或空数组
        if let extraObj = try? container.decode(PersonalExtraInfo.self, forKey: .extra) {
            extra = extraObj
        } else {
            extra = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case usercode, nickname, age, gender, height, weight, education, occupation, signs, avatar, city
        case isAuth = "is_auth"
        case isRpAuth = "is_rp_auth"
        case label
        case likePersonLabel = "like_person_label"
        case hopeRelationshipLabel = "hope_relationship_label"
        case arrangePlayCityLabel = "arrange_play_city_label"
        case willGoCityLabel = "will_go_city_label"
        case sign, activeTime = "active_time", remarkName = "remark_name"
        case unlockPrivate = "unlock_private"
        case unlockWechat = "unlock_wechat"
        case wechatAccount = "wechat_account"
        case isFollow = "is_follow"
        case isBlack = "is_black"
        case distance
        case headAlbum = "head_album"
        case album
        case dynamicNum = "dynamic_num"
        case dynamic
        case getGifts = "get_gifts"
        case sendGifts = "send_gifts"
        case isVip = "is_vip"
        case bottomText = "bottom_text"
        case extra
    }
}

// MARK: - 扩展信息

struct PersonalExtraInfo: Decodable {
    let initialHeart: String?
    let activity: String?
    
    enum CodingKeys: String, CodingKey {
        case initialHeart = "initial_heart"
        case activity
    }
}

// MARK: - 相册项

struct AlbumItem: Decodable {
    let id: Int
    let userId: Int
    let type: Int
    let status: Int
    let url: String
    let videoId: String?
    let coverImgUrl: String?
    let videoUrl: String?
    let price: Int?
    let checkTime: Int
    let size: Int
    let createTime: Int
    let adminTime: Int
    let adminId: Int
    let notes: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type, status, url
        case videoId = "video_id"
        case coverImgUrl = "cover_img_url"
        case videoUrl = "video_url"
        case price
        case checkTime = "check_time"
        case size
        case createTime = "create_time"
        case adminTime = "admin_time"
        case adminId = "admin_id"
        case notes
    }
}

// MARK: - 动态项

struct DynamicItem: Decodable {
    let url: String
    let dynamicId: Int
    let type: Int
    let likes: Int
    let id: Int
    let content: String
    let timeDay: String
    let timeMonth: String

    enum CodingKeys: String, CodingKey {
        case url
        case dynamicId = "dynamic_id"
        case type, likes, id, content
        case timeDay = "time_day"
        case timeMonth = "time_month"
    }
}
