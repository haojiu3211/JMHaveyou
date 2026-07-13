//
//  LoginModel.swift
//  haveseeyou
//
//  用户登录/注册数据模型 - 与 /login/verifyLogin 返回字段对齐
//

import Foundation

/// 用户信息模型
class LoginModel: Codable {

    // MARK: - 基础信息
    /// 用户ID
    let userId: String?
    /// 用户编码
    let usercode: String?
    /// 手机号（可能为掩码格式）
    let phone: String?
    /// 昵称
    let nickname: String?
    /// 头像URL
    let avatar: String?
    /// 个性签名
    let sign: String?
    /// 性别（兼容字段）"male" / "female" / nil；原接口为 Int，保留 genderRaw 访问原值
    let gender: String?
    /// 性别原始值：1=男 2=女
    let genderRaw: Int?
    /// 年龄
    let age: String?
    /// 生日 yyyy-MM-dd
    let birthday: String?
    /// 城市
    let city: String?
    /// 年收入
    let income: String?
    /// 教育经历
    let education: String?
    /// 职业
    let profession: String?
    /// 个人简介（兼容历史字段，接口没有则与 sign 一致）
    let bio: String?
    /// 用户标签
    let tags: [String]?
    /// 喜欢的活动类型
    let favoriteActivityTypes: [String]?
    /// 头像本地缓存路径（仅本地使用）
    var avatarLocalPath: String?
    /// 约玩城市标签
    let arrangePlayCityLabel: String?
    /// 年收入（新）
    let annualIncome: String?
    /// 职业（新）
    let occupation: String?
    /// 微信号
    let wechatAccount: String?
    /// QQ号
    let qqAccount: String?
    /// 初心（用户报名活动的初心，逗号分隔）
    let initialHeart: String?
    /// 活动（逗号分隔）
    let activity: String?
    /// 微信绑定状态：-1 未填写 0 待审核 1 审核通过 2 审核失败
    let isWx: Int?
    /// QQ绑定状态：-1 未填写 0 待审核 1 审核通过 2 审核失败
    let isQq: Int?

    // MARK: - 注册 / 账户状态
    /// 用户类型
    let type: Int?
    /// 注册步骤
    let registStep: Int?
    /// 资料完成状态：0=未完成 1=完成
    let finishStatus: Int?
    /// 邀请人 id
    let inviteId: Int?

    // MARK: - IM
    /// 云信 IM Token
    let imToken: String?

    // MARK: - 主播 / 认证 / VIP
    let isAnchor: Int?
    let voice: String?
    let voiceTime: Int?
    /// 是否实名认证
    let isAuth: Int?
    /// 是否真人认证
    let isRpAuth: Int?
    /// VIP 图标
    let vipIcon: String?
    /// VIP 等级 / 状态
    let vip: Int?

    // MARK: - 登录态
    /// 业务登录 token
    let token: String?
    /// 创建时间
    let createtime: Int?
    /// 过期时间
    let expiretime: Int?
    /// 有效时长（秒）
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case userId         = "user_id"
        case usercode
        case phone
        case nickname
        case avatar
        case sign
        case gender
        case genderRaw      = "gender_raw"
        case age
        case birthday
        case city
        case income
        case education
        case profession
        case bio
        case tags
        case favoriteActivityTypes = "favorite_activity_types"
        case avatarLocalPath       = "avatar_local_path"
        case type
        case registStep     = "regist_step"
        case finishStatus   = "finish_status"
        case inviteId       = "invite_id"
        case imToken        = "im_token"
        case isAnchor       = "is_anchor"
        case voice
        case voiceTime      = "voice_time"
        case isAuth         = "is_auth"
        case isRpAuth       = "is_rp_auth"
        case vipIcon        = "vip_icon"
        case vip
        case token
        case createtime
        case expiretime
        case expiresIn      = "expires_in"
        case arrangePlayCityLabel = "arrange_play_city_label"
        case annualIncome   = "annual_income"
        case occupation
        case wechatAccount  = "wechat_account"
        case qqAccount      = "qq_account"
        case initialHeart   = "initial_heart"
        case activity
        case isWx           = "is_wx"
        case isQq           = "is_qq"
    }

    // MARK: - 初始化方法

    init(
        userId: String? = nil,
        usercode: String? = nil,
        phone: String? = nil,
        nickname: String? = nil,
        avatar: String? = nil,
        sign: String? = nil,
        gender: String? = nil,
        genderRaw: Int? = nil,
        age: String? = nil,
        birthday: String? = nil,
        city: String? = nil,
        income: String? = nil,
        education: String? = nil,
        profession: String? = nil,
        bio: String? = nil,
        tags: [String]? = nil,
        favoriteActivityTypes: [String]? = nil,
        avatarLocalPath: String? = nil,
        type: Int? = nil,
        registStep: Int? = nil,
        finishStatus: Int? = nil,
        inviteId: Int? = nil,
        imToken: String? = nil,
        isAnchor: Int? = nil,
        voice: String? = nil,
        voiceTime: Int? = nil,
        isAuth: Int? = nil,
        isRpAuth: Int? = nil,
        vipIcon: String? = nil,
        vip: Int? = nil,
        token: String? = nil,
        createtime: Int? = nil,
        expiretime: Int? = nil,
        expiresIn: Int? = nil,
        arrangePlayCityLabel: String? = nil,
        annualIncome: String? = nil,
        occupation: String? = nil,
        wechatAccount: String? = nil,
        qqAccount: String? = nil,
        initialHeart: String? = nil,
        activity: String? = nil,
        isWx: Int? = nil,
        isQq: Int? = nil
    ) {
        self.userId = userId
        self.usercode = usercode
        self.phone = phone
        self.nickname = nickname
        self.avatar = avatar
        self.sign = sign
        self.gender = gender
        self.genderRaw = genderRaw
        self.age = age
        self.birthday = birthday
        self.city = city
        self.income = income
        self.education = education
        self.profession = profession
        self.bio = bio
        self.tags = tags
        self.favoriteActivityTypes = favoriteActivityTypes
        self.avatarLocalPath = avatarLocalPath
        self.type = type
        self.registStep = registStep
        self.finishStatus = finishStatus
        self.inviteId = inviteId
        self.imToken = imToken
        self.isAnchor = isAnchor
        self.voice = voice
        self.voiceTime = voiceTime
        self.isAuth = isAuth
        self.isRpAuth = isRpAuth
        self.vipIcon = vipIcon
        self.vip = vip
        self.token = token
        self.createtime = createtime
        self.expiretime = expiretime
        self.expiresIn = expiresIn
        self.arrangePlayCityLabel = arrangePlayCityLabel
        self.annualIncome = annualIncome
        self.occupation = occupation
        self.wechatAccount = wechatAccount
        self.qqAccount = qqAccount
        self.initialHeart = initialHeart
        self.activity = activity
        self.isWx = isWx
        self.isQq = isQq
    }

    /// 从接口 LoginUserInfo 构造
    convenience init(from u: LoginUserInfo, fallbackPhone: String? = nil) {
        let genderStr: String?
        switch u.gender {
        case 1:  genderStr = "male"
        case 2:  genderStr = "female"
        default: genderStr = nil
        }
        self.init(
            userId: u.userId.map { "\($0)" },
            usercode: u.usercode,
            phone: u.phone ?? fallbackPhone,
            nickname: u.nickname,
            avatar: u.avatar,
            sign: u.sign,
            gender: genderStr,
            genderRaw: u.gender,
            age: u.age.map { "\($0)" },
            birthday: u.birthday,
            city: u.city,
            income: nil,
            education: nil,
            profession: nil,
            bio: u.bio ?? u.sign,
            tags: u.tags,
            favoriteActivityTypes: u.favoriteActivityTypes,
            avatarLocalPath: nil,
            type: u.type,
            registStep: u.registStep,
            finishStatus: u.finishStatus,
            inviteId: u.inviteId,
            imToken: u.imToken,
            isAnchor: u.isAnchor,
            voice: u.voice,
            voiceTime: u.voiceTime,
            isAuth: u.isAuth,
            isRpAuth: u.isRpAuth,
            vipIcon: u.vipIcon,
            vip: u.vip,
            token: u.token,
            createtime: u.createtime,
            expiretime: u.expiretime,
            expiresIn: u.expiresIn,
            arrangePlayCityLabel: u.arrangePlayCityLabel,
            annualIncome: u.annualIncome,
            occupation: u.occupation,
            wechatAccount: u.wechatAccount,
            qqAccount: u.qqAccount,
            initialHeart: u.initialHeart,
            activity: u.activity,
            isWx: u.isWx,
            isQq: u.isQq
        )
    }

    // MARK: - 序列化

    /// 将模型转换为 [String: Any] 字典，供 JS 调用使用
    func toDictionary() -> [String: Any] {
        return [
            "userId"               : userId               ?? "",
            "usercode"             : usercode             ?? "",
            "phone"                : phone                ?? "",
            "nickname"             : nickname             ?? "",
            "avatar"               : avatar               ?? "",
            "sign"                 : sign                 ?? "",
            "age"                  : age                  ?? "",
            "birthday"             : birthday             ?? "",
            "gender"               : gender               ?? "",
            "genderRaw"            : genderRaw            ?? 0,
            "city"                 : city                 ?? "",
            "income"               : income               ?? "",
            "education"            : education            ?? "",
            "profession"           : profession           ?? "",
            "bio"                  : bio                  ?? "",
            "tags"                 : tags                 ?? [],
            "favoriteActivityTypes": favoriteActivityTypes ?? [],
            "avatarLocalPath"      : avatarLocalPath      ?? "",
            "type"                 : type                 ?? 0,
            "registStep"           : registStep           ?? 0,
            "finishStatus"         : finishStatus         ?? 0,
            "inviteId"             : inviteId             ?? 0,
            "isAnchor"             : isAnchor             ?? 0,
            "voice"                : voice                ?? "",
            "voiceTime"            : voiceTime            ?? 0,
            "isAuth"               : isAuth               ?? 0,
            "isRpAuth"             : isRpAuth             ?? 0,
            "vipIcon"              : vipIcon              ?? "",
            "vip"                  : vip                  ?? 0
        ]
    }

    // MARK: - 便捷方法

    /// 创建一个更新后的副本
    func updated(
        userId: String? = nil,
        usercode: String? = nil,
        phone: String? = nil,
        nickname: String? = nil,
        avatar: String? = nil,
        sign: String? = nil,
        gender: String? = nil,
        genderRaw: Int? = nil,
        age: String? = nil,
        birthday: String? = nil,
        city: String? = nil,
        income: String? = nil,
        education: String? = nil,
        profession: String? = nil,
        bio: String? = nil,
        tags: [String]? = nil,
        favoriteActivityTypes: [String]? = nil,
        avatarLocalPath: String? = nil,
        type: Int? = nil,
        registStep: Int? = nil,
        finishStatus: Int? = nil,
        inviteId: Int? = nil,
        imToken: String? = nil,
        isAnchor: Int? = nil,
        voice: String? = nil,
        voiceTime: Int? = nil,
        isAuth: Int? = nil,
        isRpAuth: Int? = nil,
        vipIcon: String? = nil,
        vip: Int? = nil,
        arrangePlayCityLabel: String? = nil,
        annualIncome: String? = nil,
        occupation: String? = nil,
        wechatAccount: String? = nil,
        qqAccount: String? = nil,
        initialHeart: String? = nil,
        activity: String? = nil,
        isWx: Int? = nil,
        isQq: Int? = nil
    ) -> LoginModel {
        return LoginModel(
            userId: userId ?? self.userId,
            usercode: usercode ?? self.usercode,
            phone: phone ?? self.phone,
            nickname: nickname ?? self.nickname,
            avatar: avatar ?? self.avatar,
            sign: sign ?? self.sign,
            gender: gender ?? self.gender,
            genderRaw: genderRaw ?? self.genderRaw,
            age: age ?? self.age,
            birthday: birthday ?? self.birthday,
            city: city ?? self.city,
            income: income ?? self.income,
            education: education ?? self.education,
            profession: profession ?? self.profession,
            bio: bio ?? self.bio,
            tags: tags ?? self.tags,
            favoriteActivityTypes: favoriteActivityTypes ?? self.favoriteActivityTypes,
            avatarLocalPath: avatarLocalPath ?? self.avatarLocalPath,
            type: type ?? self.type,
            registStep: registStep ?? self.registStep,
            finishStatus: finishStatus ?? self.finishStatus,
            inviteId: inviteId ?? self.inviteId,
            imToken: imToken ?? self.imToken,
            isAnchor: isAnchor ?? self.isAnchor,
            voice: voice ?? self.voice,
            voiceTime: voiceTime ?? self.voiceTime,
            isAuth: isAuth ?? self.isAuth,
            isRpAuth: isRpAuth ?? self.isRpAuth,
            vipIcon: vipIcon ?? self.vipIcon,
            vip: vip ?? self.vip,
            token: self.token,
            createtime: self.createtime,
            expiretime: self.expiretime,
            expiresIn: self.expiresIn,
            arrangePlayCityLabel: arrangePlayCityLabel ?? self.arrangePlayCityLabel,
            annualIncome: annualIncome ?? self.annualIncome,
            occupation: occupation ?? self.occupation,
            wechatAccount: wechatAccount ?? self.wechatAccount,
            qqAccount: qqAccount ?? self.qqAccount,
            initialHeart: initialHeart ?? self.initialHeart,
            activity: activity ?? self.activity,
            isWx: isWx ?? self.isWx,
            isQq: isQq ?? self.isQq
        )
    }
}
