//
//  LoginAPI.swift
//  haveseeyou
//
//  登录模块接口定义
//

import Foundation
import Alamofire

enum LoginAPI: APITarget {
    var encoding: ParameterEncoding {
        switch self {
        case .appendUserData, .appendUserDataPartial:
            return JSONEncoding.default
        default:
            return method == .get ? URLEncoding.default : JSONEncoding.default
        }
    }
    /// 手机号 + 验证码登录
    case login(mobile: String, phoneCode: String, agreement: String, yidunToken: String)
    /// 易盾一键登录
    case quickLogin(accessToken: String, agreement: String, ydToken: String)
    /// 发送验证码
    case sendCode(mobile: String, type: String)
    /// 换绑手机号
    case bindMobile(mobile: String, phoneCode: String, type: String)
    /// 举报
    case reportUser(reportUid: String, content: String, images: String, type: String)
    /// 注册补充资料
    case appendUserData(avatar: String, nickname: String, gender: Int, birthday: String, city: String?, socialMedia: Int?, socialAccount: String?)
    /// 部分更新用户资料（仅提交非空字段）
    case appendUserDataPartial(initialHeart: String?, activity: String?, sign: String?)
    /// 跳过注册
    case skipRegister
    /// 注销账号
    case deregisterAccount(userId: String)

    var path: String {
        switch self {
        case .login:      return "/login/verifyLogin"
        case .quickLogin: return "/login/quickLogin"
        case .sendCode:   return "/login/sendVerify"
        case .bindMobile: return "/bindMobile"
        case .reportUser: return "/meetv1/user/report"
        case .appendUserData: return "/meetv1/login/appendUserData"
        case .appendUserDataPartial: return "/meetv1/login/appendUserData"
        case .skipRegister: return "/meetv1/login/skipRegister"
        case .deregisterAccount: return "/deregisterAccount"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .quickLogin, .sendCode, .bindMobile, .reportUser, .appendUserData, .appendUserDataPartial, .skipRegister, .deregisterAccount(_):
            return .post
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case let .login(mobile, phoneCode, agreement, yidunToken):
            return ["mobile": mobile, "phone_code": phoneCode, "agreement": agreement, "yidunToken": yidunToken]
        case let .quickLogin(accessToken, agreement, ydToken):
            return ["accessToken": accessToken, "agreement": agreement, "ydToken": ydToken]
        case let .sendCode(mobile, type):
            return ["mobile": mobile, "type": type]
        case let .bindMobile(mobile, phoneCode, type):
            return ["mobile": mobile, "phone_code": phoneCode, "type": type]
        case let .reportUser(reportUid, content, images, type):
            return ["report_uid": reportUid, "content": content, "images": images, "type": type]
        case let .appendUserData(avatar, nickname, gender, birthday, city, socialMedia, socialAccount):
            var params: [String: Any] = [
                "avatar": avatar,
                "nickname": nickname,
                "gender": gender,
                "birthday": birthday
            ]
            if let city = city, !city.isEmpty {
                params["city"] = city
                if let cityId = CityDataManager.cityId(for: city) {
                    params["city_id"] = cityId
                }
            }
            if let socialMedia = socialMedia {
                if socialMedia == 1 {
                    params["wechat_account"] = socialAccount ?? ""
                } else if socialMedia == 2 {
                    params["qq_account"] = socialAccount ?? ""
                }
            }
            return params
        case let .appendUserDataPartial(initialHeart, activity, sign):
            var params: [String: Any] = [:]
            if let initialHeart = initialHeart, !initialHeart.isEmpty {
                params["initial_heart"] = initialHeart
            }
            if let activity = activity, !activity.isEmpty {
                params["activity"] = activity
            }
            if let sign = sign, !sign.isEmpty {
                params["sign"] = sign
            }
            return params
        case let .deregisterAccount(userId):
            return ["user_id": userId]
        case .skipRegister:
            return nil
        }
    }
}

/// 登录响应包装器（直接解析整个响应）
struct LoginResponseWrapper: Decodable {
    let code: Int
    let message: String?
    let userinfo: LoginResponse?
    
    enum CodingKeys: String, CodingKey {
        case code
        case message
        case data
    }
    
    enum DataCodingKeys: String, CodingKey {
        case userinfo
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(Int.self, forKey: .code)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        
        if let dataContainer = try? container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data) {
            self.userinfo = try dataContainer.decodeIfPresent(LoginResponse.self, forKey: .userinfo)
        } else {
            self.userinfo = nil
        }
    }
}

/// 登录响应数据（解析 data 字段内容）
struct LoginResponse: Decodable {
    let userinfo: LoginUserInfo?
    
    enum CodingKeys: String, CodingKey {
        case userinfo
    }
}

/// 用户信息
struct LoginUserInfo: Decodable {
    let token: String?
    let userId: Int?
    let usercode: String?
    let phone: String?
    let nickname: String?
    let avatar: String?
    let age: Int?
    let gender: Int?
    let birthday: String?
    let city: String?
    let bio: String?
    let tags: [String]?
    let favoriteActivityTypes: [String]?
    let finishStatus: Int?
    let sign: String?
    let type: Int?
    let registStep: Int?
    let inviteId: Int?
    let imToken: String?
    let isAnchor: Int?
    let voice: String?
    let voiceTime: Int?
    let isAuth: Int?
    let isRpAuth: Int?
    let vipIcon: String?
    let vip: Int?
    let createtime: Int?
    let expiretime: Int?
    let expiresIn: Int?
    let arrangePlayCityLabel: String?
    let annualIncome: String?
    let occupation: String?
    let wechatAccount: String?
    let qqAccount: String?
    let initialHeart: String?
    let activity: String?
    let isWx: Int?
    let isQq: Int?

    enum CodingKeys: String, CodingKey {
        case token
        case userId = "user_id"
        case usercode
        case phone = "mobile"
        case nickname
        case avatar
        case age
        case gender
        case birthday
        case city
        case bio
        case tags
        case favoriteActivityTypes = "favorite_activity_types"
        case finishStatus = "finish_status"
        case sign
        case type
        case registStep = "regist_step"
        case inviteId = "invite_id"
        case imToken = "im_token"
        case isAnchor = "is_anchor"
        case voice
        case voiceTime = "voice_time"
        case isAuth = "is_auth"
        case isRpAuth = "is_rp_auth"
        case vipIcon = "vip_icon"
        case vip
        case createtime
        case expiretime
        case expiresIn = "expires_in"
        case arrangePlayCityLabel = "arrange_play_city_label"
        case annualIncome = "annual_income"
        case occupation
        case wechatAccount = "wechat_account"
        case qqAccount = "qq_account"
        case initialHeart = "initial_heart"
        case activity
        case isWx = "is_wx"
        case isQq = "is_qq"
    }
}
