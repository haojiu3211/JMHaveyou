//
//  UserManager.swift
//  haveseeyou
//
//  全局用户状态管理 - 基于 UserDefaults 存储
//

import Foundation

final class UserManager {

    static let shared = UserManager()

    // MARK: - UserDefaults Key
    private let tokenKey       = "user_token"
    private let loginModelKey  = "user_login_model"
    private let allUsersKey    = "user_all_models"
    private let selectedCityKey = "user_selected_city"

    /// 本地最多存储5个用户（FIFO淘汰）
    private let maxStoredUsers = 5

    private let defaults = UserDefaults.standard

    private init() {
        migrateIfNeeded()
    }

    // MARK: - 老数据迁移（首次升级将单一 loginModel 归入列表）

    private func migrateIfNeeded() {
        // 如果多用户列表为空且存在旧单用户数据，则自动迁入
        if allUsers.isEmpty, let current = loginModel {
            saveUserToList(current)
        }
    }

    // MARK: - Token

    /// 当前 token（单独存储用于判断登录态）
    var token: String? {
        get { defaults.string(forKey: tokenKey) }
        set { defaults.set(newValue, forKey: tokenKey) }
    }

    /// 是否已登录
    var isLoggedIn: Bool {
        // 必须同时满足：
        // 1. token 不为空
        // 2. finishStatus == 1（资料已完善）
        guard let token = token, !token.isEmpty else {
            #if DEBUG
            print("🔒 [UserManager] 未登录: token 为空")
            #endif
            return false
        }
        guard let finishStatus = loginModel?.finishStatus else {
            #if DEBUG
            print("🔒 [UserManager] 未登录: finishStatus 为 nil")
            #endif
            return false
        }
        let result = finishStatus == 1
        #if DEBUG
        print("🔓 [UserManager] 登录状态: \(result), finishStatus: \(finishStatus)")
        #endif
        return result
    }

    // MARK: - 当前用户信息模型（兼容所有现有代码）

    var loginModel: LoginModel? {
        get {
            guard let data = defaults.data(forKey: loginModelKey) else { return nil }
            return try? JSONDecoder().decode(LoginModel.self, from: data)
        }
        set {
            if let model = newValue {
                let data = try? JSONEncoder().encode(model)
                defaults.set(data, forKey: loginModelKey)
            } else {
                defaults.removeObject(forKey: loginModelKey)
            }
        }
    }

    // MARK: - 多用户列表（最多 5 个，按录入顺序 FIFO 淘汰）

    /// 所有已存储的用户列表
    var allUsers: [LoginModel] {
        get {
            guard let data = defaults.data(forKey: allUsersKey) else { return [] }
            return (try? JSONDecoder().decode([LoginModel].self, from: data)) ?? []
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            defaults.set(data, forKey: allUsersKey)
        }
    }

    /// 根据手机号查找已存储的用户
    func findUser(byPhone phone: String) -> LoginModel? {
        return allUsers.first { $0.phone == phone }
    }

    /// 判断该手机号是否已注册（本地列表中有对应记录视为已注册）
    func isRegistered(phone: String) -> Bool {
        return allUsers.contains { $0.phone == phone }
    }

    /// 切换当前用户为指定手机号对应的用户（找到则加载为 currentModel + 更新 token）
    func switchToUser(phone: String) {
        guard let model = findUser(byPhone: phone) else { return }
        loginModel = model
        if let t = model.token, !t.isEmpty {
            token = t
        }
        defaults.synchronize()
    }

    /// 保存/更新用户到多用户列表（同 phone 则覆盖，否则追加；超出 5 个则删除最老的）
    private func saveUserToList(_ model: LoginModel) {
        guard let phone = model.phone, !phone.isEmpty else { return }
        var users = allUsers
        if let idx = users.firstIndex(where: { $0.phone == phone }) {
            users[idx] = model   // 同一手机号 -> 更新
        } else {
            if users.count >= maxStoredUsers {
                users.removeFirst()  // 超出上限 -> 移除最老的（FIFO）
            }
            users.append(model)
        }
        allUsers = users
    }
    // MARK: - 便捷访问属性（兼容旧代码）

    var userId: String? {
        get { loginModel?.userId }
        set {
            if let model = loginModel {
                loginModel = model.updated(userId: newValue)
            } else if let value = newValue {
                loginModel = LoginModel(userId: value)
            }
        }
    }

    var usercode: String? {
        get { loginModel?.usercode }
        set {
            if let model = loginModel {
                loginModel = model.updated(usercode: newValue)
            } else if let value = newValue {
                loginModel = LoginModel(usercode: value)
            }
        }
    }

    var phone: String? {
        get { loginModel?.phone }
        set {
            if let model = loginModel {
                loginModel = model.updated(phone: newValue)
            } else if let value = newValue {
                loginModel = LoginModel(phone: value)
            }
        }
    }

    var nickname: String? {
        get { loginModel?.nickname }
        set {
            if let model = loginModel {
                loginModel = model.updated(nickname: newValue)
            } else if let value = newValue {
                loginModel = LoginModel(nickname: value)
            }
        }
    }

    var avatar: String? {
        get { loginModel?.avatar }
        set {
            if let model = loginModel {
                loginModel = model.updated(avatar: newValue)
            } else if let value = newValue {
                loginModel = LoginModel(avatar: value)
            }
        }
    }

    var avatarLocalPath: String? {
        get { loginModel?.avatarLocalPath }
        set {
            if let model = loginModel {
                loginModel = model.updated(avatarLocalPath: newValue)
            } else if let value = newValue {
                loginModel = LoginModel(avatarLocalPath: value)
            }
        }
    }

    var age: String? {
        get { loginModel?.age }
        set {
            if let model = loginModel {
                loginModel = model.updated(age: newValue)
            } else if let value = newValue {
                loginModel = LoginModel(age: value)
            }
        }
    }

    var gender: String? {
        get { loginModel?.gender }
        set {
            if let model = loginModel {
                loginModel = model.updated(gender: newValue)
            } else if let value = newValue {
                loginModel = LoginModel(gender: value)
            }
        }
    }

    var city: String? {
        get { loginModel?.city }
        set {
            if let model = loginModel {
                loginModel = model.updated(city: newValue)
            } else if let value = newValue {
                loginModel = LoginModel(city: value)
            }
        }
    }

    var bio: String? {
        get { loginModel?.bio }
        set {
            if let model = loginModel {
                loginModel = model.updated(bio: newValue)
            } else if let value = newValue {
                loginModel = LoginModel(bio: value)
            }
        }
    }

    var tags: [String] {
        get { loginModel?.tags ?? [] }
        set {
            if let model = loginModel {
                loginModel = model.updated(tags: newValue)
            } else {
                loginModel = LoginModel(tags: newValue)
            }
        }
    }

    var favoriteActivityTypes: [String] {
        get { loginModel?.favoriteActivityTypes ?? [] }
        set {
            if let model = loginModel {
                loginModel = model.updated(favoriteActivityTypes: newValue)
            } else {
                loginModel = LoginModel(favoriteActivityTypes: newValue)
            }
        }
    }

    /// 个性签名
    var sign: String? { loginModel?.sign }
    /// 生日 yyyy-MM-dd
    var birthday: String? { loginModel?.birthday }
    /// 性别原始值：1=男 2=女
    var genderRaw: Int? { loginModel?.genderRaw }
    /// 云信 IM Token
    var imToken: String? { loginModel?.imToken }
    /// VIP 等级
    var vip: Int? { loginModel?.vip }
    /// VIP 图标
    var vipIcon: String? { loginModel?.vipIcon }
    /// 实名认证
    var isAuth: Int? { loginModel?.isAuth }
    /// 真人认证
    var isRpAuth: Int? { loginModel?.isRpAuth }
    
    /// 微信号
    var wechatAccount: String? {
        get { loginModel?.wechatAccount }
        set {
            if let model = loginModel {
                loginModel = model.updated(wechatAccount: newValue)
            } else if let value = newValue {
                loginModel = LoginModel(wechatAccount: value)
            }
        }
    }
    
    /// QQ号
    var qqAccount: String? {
        get { loginModel?.qqAccount }
        set {
            if let model = loginModel {
                loginModel = model.updated(qqAccount: newValue)
            } else if let value = newValue {
                loginModel = LoginModel(qqAccount: value)
            }
        }
    }
    
    /// 微信绑定状态
    var isWx: Int? { loginModel?.isWx }
    
    /// QQ绑定状态
    var isQq: Int? { loginModel?.isQq }
    
    /// 用户选择过的城市（用于 Activity 页面）
    var selectedCity: String? {
        get { defaults.string(forKey: selectedCityKey) }
        set {
            if let value = newValue {
                defaults.set(value, forKey: selectedCityKey)
            } else {
                defaults.removeObject(forKey: selectedCityKey)
            }
        }
    }

    // MARK: - 登录 / 退出

    /// 保存登录信息（使用LoginModel）
    func saveLogin(model: LoginModel) {
        // 保存 token
        if let t = model.token {
            self.token = t
        }
        // 保存为当前用户
        self.loginModel = model
        // 同步写入多用户列表
        saveUserToList(model)
        defaults.synchronize()

        // 打印登录信息
        print("🔑 [UserManager] 用户登录成功")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("用户ID: \(model.userId ?? "未设置")")
        print("用户编码: \(model.usercode ?? "未设置")")
        print("手机号: \(model.phone ?? "未设置")")
        print("昵称: \(model.nickname ?? "未设置")")
        print("头像: \(model.avatar ?? "未设置")")
        print("个性签名: \(model.sign ?? "未设置")")
        print("性别: \(model.gender ?? "未设置") (原始值: \(model.genderRaw ?? 0))")
        print("年龄: \(model.age ?? "未设置")")
        print("生日: \(model.birthday ?? "未设置")")
        print("城市: \(model.city ?? "未设置")")
        print("个人简介: \(model.bio ?? "未设置")")
        print("用户标签: \(model.tags ?? [])")
        print("喜欢的活动类型: \(model.favoriteActivityTypes ?? [])")
        print("用户类型: \(model.type ?? 0)")
        print("注册步骤: \(model.registStep ?? 0)")
        print("资料完成状态: \(model.finishStatus ?? 0) (0=未完成 1=完成)")
        print("邀请人ID: \(model.inviteId ?? 0)")
        print("云信IM Token: \(model.imToken ?? "未设置")")
        print("是否主播: \(model.isAnchor ?? 0)")
        print("语音: \(model.voice ?? "未设置")")
        print("语音时长: \(model.voiceTime ?? 0)")
        print("是否实名认证: \(model.isAuth ?? 0)")
        print("是否真人认证: \(model.isRpAuth ?? 0)")
        print("VIP图标: \(model.vipIcon ?? "未设置")")
        print("VIP等级: \(model.vip ?? 0)")
        print("业务Token: \(model.token ?? "未设置")")
        print("创建时间: \(model.createtime ?? 0)")
        print("过期时间: \(model.expiretime ?? 0)")
        print("有效时长(秒): \(model.expiresIn ?? 0)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // 发送登录成功通知
//        NotificationCenter.default.post(name: .userDidLogin, object: nil)
    }

    /// 保存登录信息（兼容旧方法）
    @available(*, deprecated, message: "请使用 saveLogin(model:) 方法")
    func saveLogin(token: String, userId: String? = nil, phone: String? = nil, nickname: String? = nil, avatar: String? = nil, age: String? = nil, city: String? = nil, bio: String? = nil, tags: [String]? = nil) {
        let model = LoginModel(
            userId: userId,
            phone: phone,
            nickname: nickname,
            avatar: avatar,
            gender: nil,
            age: age,
            city: city,
            bio: bio,
            tags: tags,
            favoriteActivityTypes: nil,
            avatarLocalPath: nil,
            token: token
        )
        saveLogin(model: model)
    }

    /// 更新用户信息（同时更新多用户列表中对应条目）
    func updateUserInfo(
        userId: String? = nil,
        phone: String? = nil,
        nickname: String? = nil,
        avatar: String? = nil,
        age: String? = nil,
        gender: String? = nil,
        city: String? = nil,
        bio: String? = nil,
        tags: [String]? = nil,
        favoriteActivityTypes: [String]? = nil,
        avatarLocalPath: String? = nil,
        finishStatus: Int? = nil,
        birthday: String? = nil,
        income: String? = nil,
        education: String? = nil,
        profession: String? = nil,
        sign: String? = nil,
        arrangePlayCityLabel: String? = nil,
        annualIncome: String? = nil,
        occupation: String? = nil,
        wechatAccount: String? = nil,
        qqAccount: String? = nil,
        initialHeart: String? = nil,
        activity: String? = nil,
        isWx: Int? = nil,
        isQq: Int? = nil,
        vip: Int? = nil,
        shouldNotify: Bool = true
    ) {
        guard let currentModel = loginModel else { return }

        let updatedModel = currentModel.updated(
            userId: userId,
            phone: phone,
            nickname: nickname,
            avatar: avatar,
            sign: sign,
            gender: gender,
            age: age,
            birthday: birthday,
            city: city,
            income: income,
            education: education,
            profession: profession,
            bio: bio,
            tags: tags,
            favoriteActivityTypes: favoriteActivityTypes,
            avatarLocalPath: avatarLocalPath,
            finishStatus: finishStatus,
            vip: vip, arrangePlayCityLabel: arrangePlayCityLabel,
            annualIncome: annualIncome,
            occupation: occupation,
            wechatAccount: wechatAccount,
            qqAccount: qqAccount,
            initialHeart: initialHeart,
            activity: activity,
            isWx: isWx,
            isQq: isQq
        )

        loginModel = updatedModel
        // 同步更新到多用户列表
        saveUserToList(updatedModel)
        defaults.synchronize()
        // 通知监听者（云信资料同步等）
        if shouldNotify {
            NotificationCenter.default.post(name: .userInfoDidUpdate, object: nil)
        }
    }

    /// 退出登录：仅清空 token，保留 loginModel 与多用户列表（下次可直接匹配手机号登录）
    func logout() {
        token = nil
        defaults.synchronize()
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }

    /// 注销账号：清除当前用户的 token + loginModel，并从多用户列表中移除
    func deleteAccount() {
        // 从多用户列表中移除当前用户
        if let phone = loginModel?.phone {
            var users = allUsers
            users.removeAll { $0.phone == phone }
            allUsers = users
        }
        token = nil
        loginModel = nil
        // 清除所有 user_ 前缀缓存
        let keys = defaults.dictionaryRepresentation().keys
        keys.filter { $0.hasPrefix("user_") }.forEach { defaults.removeObject(forKey: $0) }
        defaults.synchronize()
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }

    // MARK: - 测试数据（开发用）

    /// 设置测试数据，方便开发调试
}



