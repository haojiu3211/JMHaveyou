//
//  IMManager.swift
//  haveseeyou
//
//  云信 IM 统一入口：SDK 初始化、登录登出、用户资料同步、会话列表拉取
//

import Foundation
import NIMSDK
import NEChatKit
import NEChatUIKit
import NECoreIM2Kit
import SDWebImage
import SnapKit
import Combine

// 简单的响应模型 - 只解析 code 和 message，忽略 data
private struct SimpleResponse: Decodable {
    let code: Int
    let message: String?
    let time: String?
    
    // 只解析我们需要的字段，忽略 data
    enum CodingKeys: String, CodingKey {
        case code
        case message
        case time
    }
}

// 关联对象 key，用于保存 tableView 拦截器
private var tableViewDelegateInterceptorKey = 0

final class IMManager: NSObject {

    static let shared = IMManager()

    private(set) var isSetup: Bool = false
    private(set) var isLoggedIn: Bool = false
    
    /// Combine 订阅持有
    var cancellables = Set<AnyCancellable>()
    
    /// 已处理过的视图控制器集合
    private static var processedVCs = NSHashTable<ChatViewController>.weakObjects()
    
    /// 关联对象 key，用于在按钮中保存活动信息
    private static var activityInfoKey = 0
    /// 关联对象 key，用于在 banner 中保存活动信息
    private static var bannerActivityInfoKey = 1

    private override init() {
        super.init()
    }

    // MARK: - 初始化

    /// App 启动时调用，初始化云信 SDK + UIKit
    func setup() {
        guard !isSetup else { return }
        isSetup = true

        let option = NIMSDKOption()
        option.appKey = AppConfig.ThirdKey.nimAppKey
        option.apnsCername = AppConfig.ThirdKey.apnsName

        let v2Option = V2NIMSDKOption()
        // 走本地会话；云端会话需要服务端开通，未开通时拿不到列表/监听
        v2Option.enableV2CloudConversation = false

        IMKitClient.instance.config.fcsEnable = false
        IMKitClient.instance.config.shouldSyncStickTopSessionInfos = true
        IMKitClient.instance.config.shouldSyncUnreadCount = true
        IMKitClient.instance.config.fetchAttachmentAutomaticallyAfterReceiving = true
        IMKitClient.instance.config.shouldConsiderRevokedMessageUnreadCount = true

        IMKitClient.instance.setupIM2(option, v2Option)
        IMKitClient.instance.addLoginListener(self)

        // 关闭单聊标题后缀的 (在线)/(离线)
    IMKitConfigCenter.shared.enableOnlineStatus = false
    
    // 首先通过 SDK 配置清除气泡图片并设置初始颜色
    ChatUIConfig.shared.messageProperties.selfMessageBgImage = nil
    ChatUIConfig.shared.messageProperties.receiveMessageBgImage = nil
    ChatUIConfig.shared.messageProperties.selfMessageBgColor = UIColor(hex: "#A2EF4D")
    ChatUIConfig.shared.messageProperties.receiveMessageBgColor = UIColor(hex: "#2A2A2C")
    ChatUIConfig.shared.messageProperties.selfMessageTextColor = .black
    ChatUIConfig.shared.messageProperties.receiveMessageTextColor = .white
    
    // 隐藏聊天页右上角的「...」更多按钮 + 顶部安全提示横幅
    ChatUIConfig.shared.customController = { vc in
            vc.navigationView.moreButton.isHidden = true
            vc.navigationItem.rightBarButtonItems = []
            vc.navigationItem.rightBarButtonItem = nil
            
            // 设置导航栏标题颜色为黑色（针对 iOS 18 兼容性）
            let navView = vc.navigationView
            // 设置 navTitle 的颜色
            if navView.responds(to: NSSelectorFromString("navTitle")) {
                if let navTitleLabel = navView.value(forKey: "navTitle") as? UILabel {
                    navTitleLabel.textColor = .black
                }
            }
            // 递归设置 navigationView 中所有标签的颜色为黑色
            func setAllLabelsColor(in view: UIView) {
                for subview in view.subviews {
                    if let label = subview as? UILabel {
                        label.textColor = .black
                    }
                    setAllLabelsColor(in: subview)
                }
            }
            setAllLabelsColor(in: navView)
            
            // 拦截 tableView 的 delegate 来修改气泡样式
            if let tableView = vc.value(forKey: "tableView") as? UITableView {
                // 保存原始 delegate
                let originalDelegate = tableView.delegate
                
                // 替换为我们的拦截器
                let interceptor = ChatTableViewDelegateInterceptor(originalDelegate: originalDelegate)
                tableView.delegate = interceptor
                
                // 使用关联对象保持拦截器的引用，避免被释放
                objc_setAssociatedObject(vc, &tableViewDelegateInterceptorKey, interceptor, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            
            IMManager.addAuthWarningBanner(to: vc)
        }

  

        // 注册 UIKit 路由（单聊页面）
        ChatKitClient.shared.setupInit(isFun: false)

        // 全局会话变更监听（长驻整个 App 生命周期）
        LocalConversationRepo.shared.addLocalConversationListener(self)

        // 兜底：云信 UIKit 内部用 SDWebImage 加载头像，对端只存了相对路径时，
        // 这里在下载前把请求 URL 改写成"业务 imageBaseUrl + path"
        installSDWebImageRelativePathRewriter()
    }

    // MARK: - 聊天页顶部安全提示横幅

    private static let authBannerTag = 8801
    private static let bannerHeight: CGFloat = 74
    private static let topSpacing: CGFloat = 11
    private static func addAuthWarningBanner(to vc: ChatViewController) {
        let toUserId = ChatRepo.sessionId
        
        print("🔍 [Banner] 开始处理，toUserId: \(toUserId), vc: \(vc)")
        
        // 系统账号不需要显示 banner
        let systemAccountIds = ["8997904", "8997905", "8997906"]
        guard !systemAccountIds.contains(toUserId) else {
            print("🔍 [Banner] 是系统账号，不显示")
            return
        }
        
        // 检查是否已经处理过这个视图控制器
        guard !processedVCs.contains(vc) else {
            print("🔍 [Banner] 已处理过此视图控制器，跳过")
            return
        }
        processedVCs.add(vc)
        
        // 请求接口获取活动信息
        fetchCurrentlyInterestedInfo(toUserId: toUserId) { [weak vc] info in
            guard let vc = vc else { return }
            
            print("🔍 [Banner] 接口返回，info: \(String(describing: info))")
            
            if let info = info, let _ = info.id {
                print("🔍 [Banner] 有数据，添加 banner")
                // 有数据，添加 banner
                DispatchQueue.main.async {
                    addBannerView(to: vc, with: info)
                }
            } else {
                print("🔍 [Banner] 无数据，不移除（可能之前已添加）")
            }
        }
    }
    
    /// 获取当前感兴趣的活动信息
    private static func fetchCurrentlyInterestedInfo(
        toUserId: String,
        completion: @escaping (CurrentlyInterestedInfoModel?) -> Void
    ) {
        print("🔍 [Banner] 请求接口，toUserId: \(toUserId)")
        
        NetworkManager.shared
            .request(ChatAPI.currentlyInterestedInfo(toUserId: toUserId), as: APIResponse<CurrentlyInterestedInfoModel>.self)
            .sink { completionState in
                print("🔍 [Banner] 接口完成，状态: \(completionState)")
                completion(nil)
            } receiveValue: { response in
                print("🔍 [Banner] 接口响应，code: \(response.code), message: \(response.message ?? ""), data: \(String(describing: response.data))")
                completion(response.data)
            }
            .store(in: &shared.cancellables)
    }
    
    /// 添加 banner 视图
    private static func addBannerView(to vc: ChatViewController, with info: CurrentlyInterestedInfoModel) {
        guard vc.bodyTopView.viewWithTag(authBannerTag) == nil else { return }

        let banner = UIView()
        banner.tag = authBannerTag
        banner.backgroundColor = UIColor(hex: "#F5F6F9")
        banner.layer.cornerRadius = 8
        banner.layer.masksToBounds = true
        banner.isUserInteractionEnabled = true
        
        // 使用关联对象保存活动信息到 banner
        objc_setAssociatedObject(banner, &bannerActivityInfoKey, info, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // 给整个 banner 添加点击手势
        let bannerTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBannerTapped(_:)))
        banner.addGestureRecognizer(bannerTapGesture)

        // ========== 第一行 ==========
        
        // 1. 左侧图标: chat_covation_actviti_logo - 20x20, 上12, 左12
        let activityIcon = UIImageView(image: UIImage(named: "chat_covation_actviti_logo"))
        activityIcon.contentMode = .scaleAspectFit
        activityIcon.backgroundColor = .clear
        activityIcon.tag = 2001
        
        // 2. 活动类型文字
        let activityTypeLabel = UILabel()
        let activityTypeName = info.activityType?
            .compactMap { $0.name }          // 1. 提取所有非空的 name，过滤掉 nil
            .map { "#\($0)" }                // 2. 给每个 name 加上 "#" 前缀
            .joined(separator: "，")         // 3. 用中文逗号拼接成字符串
            ?? "活动类型：暂定"              // 4. 如果整个数组为空或为 nil，显示默认值
        activityTypeLabel.text = activityTypeName
        activityTypeLabel.font = .systemFont(ofSize: 16)
        activityTypeLabel.textColor = UIColor(hex: "#100A1D")
        activityTypeLabel.lineBreakMode = .byTruncatingTail
        activityTypeLabel.numberOfLines = 1
        
        // 3. 右上角进行中图标: chat_covation_ing - 86x30, 上右0
        let inProgressIcon = UIImageView(image: UIImage(named: "chat_covation_ing"))
        inProgressIcon.contentMode = .scaleAspectFit
        inProgressIcon.tag = 2002
        
        // ========== 第二行 ==========
        
        // 4. 联系方式图标
        let contactIcon = UIImageView()
        contactIcon.contentMode = .scaleAspectFit
        contactIcon.tag = 2003
        
        // 判断显示哪个图标
        let hasWechat = !(info.user?.wechatAccount?.isEmpty ?? true)
        let hasQQ = !(info.user?.qqAccount?.isEmpty ?? true)
        
        if hasWechat {
            // 有微信优先显示微信
            contactIcon.image = UIImage(named: "login_wx_yes")
        } else if hasQQ {
            // 只有QQ显示QQ
            contactIcon.image = UIImage(named: "login_qq_yes")
        } else {
            // 都没有显示login_wx_yes占位图
            contactIcon.image = UIImage(named: "login_wx_yes")
        }
        
        // 5. 申请互换联系方式文字
        let contactLabel = UILabel()
        contactLabel.text = "申请互换联系方式（更快！）"
        contactLabel.font = .systemFont(ofSize: 14)
        contactLabel.textColor = UIColor(hex: "#888888")
        
        // 6. 锁头+查看按钮 - 58x24, 右12, 下14
        let lockButton = UIButton()
        lockButton.setImage(UIImage(named: "persion_lock"), for: .normal)
        lockButton.setTitle(" 查看", for: .normal)
        lockButton.titleLabel?.font = .systemFont(ofSize: 12)
        lockButton.tintColor = .white
        lockButton.backgroundColor = UIColor(hex: "#100A1D")
        lockButton.layer.cornerRadius = 12
        lockButton.tag = 2004
        
        // 使用关联对象保存活动信息到按钮
        objc_setAssociatedObject(lockButton, &activityInfoKey, info, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        // 添加点击事件
        lockButton.addTarget(self, action: #selector(handleViewButtonTapped(_:)), for: .touchUpInside)
        
        // 添加子视图
        banner.addSubview(activityIcon)
        banner.addSubview(activityTypeLabel)
        banner.addSubview(inProgressIcon)
        banner.addSubview(contactIcon)
        banner.addSubview(contactLabel)
        banner.addSubview(lockButton)
        
        vc.bodyTopView.addSubview(banner)

        // 设置 bodyTopView 的高度 = 顶部间距 + banner高度
        vc.bodyTopViewHeightAnchor?.constant = topSpacing + bannerHeight
        
        // Banner 约束
        banner.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(topSpacing)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(bannerHeight)
        }
        
        // ========== 第一行约束 ==========
        
        // 进行中图标
        inProgressIcon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(0)
            make.right.equalToSuperview().offset(0)
            make.size.equalTo(CGSize(width: 75, height: 30))
        }
        
        // 活动图标
        activityIcon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(12)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
        
        // 活动类型文字
        activityTypeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(activityIcon)
            make.left.equalTo(activityIcon.snp.right).offset(8)
            make.right.lessThanOrEqualTo(inProgressIcon.snp.left).offset(-8)
        }
        
        // ========== 第二行约束 ==========
        
        // 锁头+查看按钮（先设置底部位置）
        lockButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-14)
            make.size.equalTo(CGSize(width: 58, height: 24))
        }
        
        // 联系方式图标
        contactIcon.snp.makeConstraints { make in
            make.top.equalTo(activityIcon.snp.bottom).offset(5)
            make.left.equalToSuperview().offset(12)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
        
        // 申请互换联系方式文字
        contactLabel.snp.makeConstraints { make in
            make.centerY.equalTo(contactIcon)
            make.left.equalTo(contactIcon.snp.right).offset(8)
            make.right.lessThanOrEqualTo(lockButton.snp.left).offset(-8)
        }
    }
    
    /// 移除 banner 视图
    private static func removeBanner(from vc: ChatViewController) {
        if let banner = vc.bodyTopView.viewWithTag(authBannerTag) {
            banner.removeFromSuperview()
            vc.bodyTopViewHeightAnchor?.constant = 0
        }
    }
    
    private static func printDebugInfo(view: UIView, level: Int) {
        let indent = String(repeating: "  ", count: level)
        let viewType = type(of: view)
        
        // 获取视图描述
        var description = "\(indent)🔹 \(viewType)"
        if view.tag != 0 {
            description += " (tag: \(view.tag))"
        }
        
        // 添加 frame 信息
        description += "\n\(indent)   Frame: x=\(Int(view.frame.origin.x)), y=\(Int(view.frame.origin.y)), w=\(Int(view.frame.size.width)), h=\(Int(view.frame.size.height))"
        description += "\n\(indent)   Bounds: x=\(Int(view.bounds.origin.x)), y=\(Int(view.bounds.origin.y)), w=\(Int(view.bounds.size.width)), h=\(Int(view.bounds.size.height))"
        
        // 如果是图片视图，检查图片
        if let imageView = view as? UIImageView {
            let hasImage = imageView.image != nil
            description += "\n\(indent)   Has Image: \(hasImage)"
            if let image = imageView.image {
                description += ", Size: \(Int(image.size.width))x\(Int(image.size.height))"
            }
        }
        
        // 如果是按钮，检查图片
        if let button = view as? UIButton {
            let hasImage = button.image(for: .normal) != nil
            description += "\n\(indent)   Has Image: \(hasImage)"
            if let image = button.image(for: .normal) {
                description += ", Size: \(Int(image.size.width))x\(Int(image.size.height))"
            }
            if let title = button.title(for: .normal) {
                description += ", Title: \(title)"
            }
        }
        
        // 如果是标签，显示文字
        if let label = view as? UILabel {
            if let text = label.text {
                description += "\n\(indent)   Text: \(text)"
            }
        }
        
        print(description)
        
        // 递归打印子视图
        for subview in view.subviews {
            printDebugInfo(view: subview, level: level + 1)
        }
    }

    private func installSDWebImageRelativePathRewriter() {
        let base = AppConfig.API.imageBaseUrl
        guard !base.isEmpty, let baseURL = URL(string: base) else { return }

        SDWebImageDownloader.shared.requestModifier = SDWebImageDownloaderRequestModifier { request in
            guard let url = request.url else { return request }
            // 已经是完整 URL（含 host），不动
            if url.host != nil { return request }
            // 只剩 path（甚至可能是 path-only URL，如 "/upload/xxx.jpg"）
            let rel = url.absoluteString
            let path = rel.hasPrefix("/") ? String(rel.dropFirst()) : rel
            guard let fixed = URL(string: path, relativeTo: baseURL)?.absoluteURL else { return request }
            var newRequest = request
            newRequest.url = fixed
            return newRequest
        }
    }

    /// 当前总未读数（含群聊等所有会话）
    func totalUnreadCount() -> Int {
        LocalConversationRepo.shared.getTotalUnreadCount()
    }

    // MARK: - 登录 / 登出

    /// 业务登录成功后调用：账号 = userId、token = imToken
    func login(accountId: String,
               token: String,
               completion: ((Error?) -> Void)? = nil) {
        if !isSetup { setup() }
        guard !accountId.isEmpty, !token.isEmpty else {
            completion?(NSError(domain: "IMManager",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "IM 账号或 Token 为空"]))
            return
        }

        IMKitClient.instance.login(accountId, token, nil) { [weak self] error in
            if let err = error {
                #if DEBUG
                print("❌ [IM] 登录失败: \(err.localizedDescription)")
                #endif
            } else {
                #if DEBUG
                print("✅ [IM] 登录成功 accid=\(accountId)")
                #endif
                self?.isLoggedIn = true
                self?.uploadCurrentUserProfile()
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .imConversationDidChange, object: nil)
                }
            }
            completion?(error)
        }
    }

    func logout(completion: ((Error?) -> Void)? = nil) {
        IMKitClient.instance.logoutIM { [weak self] error in
            self?.isLoggedIn = false
            completion?(error)
        }
    }

    // MARK: - 用户资料

    /// 把当前 UserManager 里完整的资料（昵称/头像/年龄/性别）一次性同步到云信
    func uploadCurrentUserProfile(completion: ((Error?) -> Void)? = nil) {
        guard let model = UserManager.shared.loginModel else {
            completion?(nil)
            return
        }

        let params = V2NIMUserUpdateParams()
        if let nickname = model.nickname, !nickname.isEmpty {
            params.name = nickname
        }
        if let avatar = model.avatar, !avatar.isEmpty {
            // 写完整 URL 到云信，聊天页框架内部用 URL(string:) 加载，不会拼 baseUrl
            params.avatar = avatar
        }
        if let birthday = model.birthday, !birthday.isEmpty {
            params.birthday = birthday
        }
        params.gender = nimGender(from: model.genderRaw)

        // 年龄走 serverExtension 透传（V2NIMUserUpdateParams 无 age 字段）
        if let age = model.age, !age.isEmpty {
            let dict: [String: Any] = ["age": age]
            if let data = try? JSONSerialization.data(withJSONObject: dict),
               let json = String(data: data, encoding: .utf8) {
                params.serverExtension = json
            }
        }

        update(params: params, completion: completion)
    }

    /// 更新单个资料字段（昵称/头像/性别等任一）
    func updateProfile(nickname: String? = nil,
                       avatar: String? = nil,
                       gender: Int? = nil,
                       birthday: String? = nil,
                       sign: String? = nil,
                       extra: [String: Any]? = nil,
                       completion: ((Error?) -> Void)? = nil) {
        let params = V2NIMUserUpdateParams()
        if let nickname = nickname { params.name = nickname }
        if let avatar = avatar {
            params.avatar = avatar
        }
        if let gender = gender { params.gender = nimGender(from: gender) }
        if let birthday = birthday { params.birthday = birthday }
        if let sign = sign { params.sign = sign }
        if let extra = extra,
           let data = try? JSONSerialization.data(withJSONObject: extra),
           let json = String(data: data, encoding: .utf8) {
            params.serverExtension = json
        }
        update(params: params, completion: completion)
    }

    private func update(params: V2NIMUserUpdateParams,
                        completion: ((Error?) -> Void)?) {
        guard isLoggedIn else {
            completion?(NSError(domain: "IMManager",
                                code: -2,
                                userInfo: [NSLocalizedDescriptionKey: "IM 未登录"]))
            return
        }
        NIMSDK.shared().v2UserService.updateSelfUserProfile(params) {
            #if DEBUG
            print("✅ [IM] 资料上传成功")
            #endif
            completion?(nil)
        } failure: { error in
            #if DEBUG
            print("❌ [IM] 资料上传失败:")
            #endif
//            completion?(error)
        }
    }

    private func nimGender(from raw: Int?) -> V2NIMGender {
        switch raw {
        case 1: return .GENDER_MALE
        case 2: return .GENDER_FEMALE
        default: return .GENDER_UNKNOWN
        }
    }

    // MARK: - 会话列表

    /// 分页拉取会话列表
    /// - Parameters:
    ///   - offset: 偏移（首次传 0，下次传上一次返回的 offset）
    ///   - limit: 单页数量
    func fetchConversationList(offset: Int = 0,
                               limit: Int = 100,
                               completion: @escaping (_ list: [V2NIMLocalConversation],
                                                     _ nextOffset: Int,
                                                     _ finished: Bool,
                                                     _ error: Error?) -> Void) {
        guard isLoggedIn else {
            completion([], 0, true, NSError(domain: "IMManager",
                                            code: -2,
                                            userInfo: [NSLocalizedDescriptionKey: "IM 未登录"]))
            return
        }
        NIMSDK.shared().v2LocalConversationService.getConversationList(offset, limit: limit) { result in
            let list = result.conversationList ?? []
            let next = Int(result.offset ?? Int(Int64(offset)))
            let finished = result.finished ?? true
            completion(list, next, finished, nil)
        } failure: { error in
//            completion([], offset, true, error)
        }
    }

    // MARK: - 发送一条文本消息（不进入聊天页）

    /// 给指定账号发送一条文本消息（自动确保会话存在 + 预拉对端资料）
    /// 用于"我感兴趣"等业务场景：用户停留在当前页，后台静默与对端建立会话并发消息。
    /// - Parameters:
    ///   - accountId: 对端 IM 账号
    ///   - text: 要发送的文本
    ///   - completion: 完成回调（成功时 error 为 nil；非主线程，调用方按需切回主线程）
    func sendHello(toAccountId accountId: String,
                   text: String,
                   completion: ((Error?) -> Void)? = nil) {
        guard isLoggedIn else {
            completion?(NSError(domain: "IMManager",
                                code: -2,
                                userInfo: [NSLocalizedDescriptionKey: "IM 未登录"]))
            return
        }
        guard !accountId.isEmpty,
              let cid = V2NIMConversationIdUtil.p2pConversationId(accountId) else {
            completion?(NSError(domain: "IMManager",
                                code: -3,
                                userInfo: [NSLocalizedDescriptionKey: "对端账号无效"]))
            return
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion?(NSError(domain: "IMManager",
                                code: -4,
                                userInfo: [NSLocalizedDescriptionKey: "消息内容为空"]))
            return
        }

        let send: () -> Void = {
            let message = MessageUtils.textMessage(text: trimmed)
            ChatRepo.shared.sendMessage(message: message, conversationId: cid) { _, error, _ in
                completion?(error)
            }
        }

        // 预拉对端资料 → 确保会话存在 → 发送
        NIMUserInfoLoader.shared.fetch(accountId: accountId) { _ in
            LocalConversationRepo.shared.getConversation(cid) { conv, _ in
                if conv != nil {
                    send()
                } else {
                    LocalConversationRepo.shared.createConversation(cid) { _, _ in
                        send()
                    }
                }
            }
        }
    }
}

// MARK: - NELocalConversationListener

extension IMManager: NELocalConversationListener {
    func onLocalConversationChanged(_ conversations: [V2NIMLocalConversation]) {
        postChange()
    }
    func onLocalConversationCreated(_ conversation: V2NIMLocalConversation) {
        postChange()
    }
    func onLocalConversationDeleted(_ conversationIds: [String]) {
        postChange()
    }
    func onLocalTotalUnreadCountChanged(_ unreadCount: Int) {
        postChange()
    }

    private func postChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .imConversationDidChange, object: nil)
        }
    }
}

// MARK: - NEIMKitClientListener

extension IMManager: NEIMKitClientListener {
    func onLoginFailed(_ error: V2NIMError) {
        #if DEBUG
        print("❌ [IM] 登录监听失败 code=\(error.code)")
        #endif
        isLoggedIn = false
    }

    func onKickedOffline(_ detail: V2NIMKickedOfflineDetail) {
        #if DEBUG
        print("⚠️ [IM] 被踢下线 reason=\(detail.reason.rawValue)")
        #endif
        isLoggedIn = false
    }
}

// MARK: - Banner 点击处理和数据转换

extension IMManager {
    
    /// 处理 banner 点击
    @objc private static func handleBannerTapped(_ gesture: UITapGestureRecognizer) {
        print("🔍 [Banner] 整个 banner 被点击")
        
        guard let banner = gesture.view else {
            return
        }
        
        // 从 banner 的关联对象中获取活动信息
        guard let info = objc_getAssociatedObject(banner, &bannerActivityInfoKey) as? CurrentlyInterestedInfoModel else {
            print("🔍 [Banner] 无法从 banner 获取活动信息")
            return
        }
        
        // 找到 banner 所在的视图控制器
        var responder: UIResponder? = banner
        var vc: ChatViewController?
        while let next = responder?.next {
            if let chatVC = next as? ChatViewController {
                vc = chatVC
                break
            }
            responder = next
        }
        
        guard let presentVC = vc else {
            print("🔍 [Banner] 无法找到视图控制器")
            return
        }
        
        // 跳转到活动详情页
        pushActivityDetail(from: presentVC, with: info)
    }
    
    /// 处理查看按钮点击
    @objc private static func handleViewButtonTapped(_ sender: UIButton) {
        print("🔍 [Banner] 查看按钮被点击")
        
        // 从按钮的关联对象中获取活动信息
        guard let info = objc_getAssociatedObject(sender, &activityInfoKey) as? CurrentlyInterestedInfoModel else {
            print("🔍 [Banner] 无法获取活动信息")
            return
        }
        
        // 找到按钮所在的视图控制器
        var responder: UIResponder? = sender
        var vc: ChatViewController?
        while let next = responder?.next {
            if let chatVC = next as? ChatViewController {
                vc = chatVC
                break
            }
            responder = next
        }
        
        guard let presentVC = vc else {
            print("🔍 [Banner] 无法找到视图控制器")
            return
        }
        
        // 弹窗显示联系方式
        showContactInfoAlert(from: presentVC, with: info.user)
    }
    
    /// 跳转到活动详情页
    private static func pushActivityDetail(from viewController: UIViewController, with info: CurrentlyInterestedInfoModel) {
        // 转换数据模型
        let activityModel = convertToActivityModel(from: info)
        
        // 创建 ActivityDetailViewController
        let detailVC = ActivityDetailViewController(activityModel: activityModel)
        
        // 创建独立的导航控制器包装详情页，避免与第三方 IM SDK 的导航栏冲突
        let navController = UINavigationController(rootViewController: detailVC)
        navController.modalPresentationStyle = .fullScreen
        
        // 以 Present 方式弹出
        viewController.present(navController, animated: true, completion: nil)
    }
    
    /// 显示联系方式弹窗
    private static func showContactInfoAlert(from viewController: UIViewController, with userInfo: UserInfo?) {
        guard let user = userInfo else { return }
        
        // 获取用户 ID，用于解锁
        guard let userId = user.id else {
            print("❌ [Contact] 无法获取用户 ID")
            return
        }
        
        print("🔍 [Contact] 开始检查解锁状态，userId: \(userId)")
        
        // 先调用 diamondUnlock 接口尝试解锁社媒联系方式（type == 2）
        tryUnlockContact(userId: userId, from: viewController, userInfo: user)
    }
    
    /// 尝试解锁联系方式
    private static func tryUnlockContact(userId: Int, from viewController: UIViewController, userInfo: UserInfo) {
        let unlockType = UnlockType.wechat.rawValue // 社媒解锁用 type == 2
        let decCoin = 200 // 解锁社媒账号需要 200 活动币
        
        print("💎 [Contact] 开始调用 diamondUnlock，userId: \(userId), type: \(unlockType) (社媒), decCoin: \(decCoin)")
        
        NetworkManager.shared.request(PurchaseAPI.diamondUnlock(type: unlockType, toUid: userId, decCoin: decCoin), as: SimpleResponse.self) { result in
            
            switch result {
            case .success(let response):
                print("📋 [Contact] diamondUnlock 原始响应，code: \(response.code), message: \(response.message ?? "nil")")
                
                DispatchQueue.main.async {
                    if response.code == 0 || response.code == 1 {
                        // 解锁成功或已解锁过，显示联系方式
                        print("✅ [Contact] 解锁成功或已解锁，显示联系方式")
                        showActualContactAlert(from: viewController, with: userInfo)
                    } else {
                        // 其他业务失败（如余额不足），显示引导充值弹窗
                        print("⚠️ [Contact] 解锁失败，显示引导充值")
                        showUnlockFailedAlert(from: viewController)
                    }
                }
                
            case .failure(let error):
                print("❌ [Contact] diamondUnlock 调用失败: \(error)")
                
                // 尝试从错误中提取业务码
                if case let APIError.business(code, message) = error {
                    print("📋 [Contact] 检测到业务错误，code: \(code), message: \(message)")
                    DispatchQueue.main.async {
                        if code == 0 || code == 1 {
                            // 即使解析失败，但如果错误中包含 code == 0 或 1，也显示联系方式
                            print("✅ [Contact] 从错误中检测到成功，显示联系方式")
                            showActualContactAlert(from: viewController, with: userInfo)
                        } else {
                            // 其他情况显示引导充值弹窗
                            showUnlockFailedAlert(from: viewController)
                        }
                    }
                } else {
                    // 其他类型的错误，也显示引导充值弹窗
                    DispatchQueue.main.async {
                        showUnlockFailedAlert(from: viewController)
                    }
                }
            }
        }
    }
    
    /// 实际显示联系方式弹窗
    private static func showActualContactAlert(from viewController: UIViewController, with userInfo: UserInfo) {
        var message = ""
        var hasContact = false
        
        if let wechat = userInfo.wechatAccount, !wechat.isEmpty {
            message += "微信号：\(wechat)\n"
            hasContact = true
        }
        
        if let qq = userInfo.qqAccount, !qq.isEmpty {
            message += "QQ号：\(qq)\n"
            hasContact = true
        }
        
        if !hasContact {
            message = "对方暂未添加联系方式"
        }
        
        let alert = UIAlertController(
            title: "联系方式",
            message: message,
            preferredStyle: .alert
        )
        
        let copyAction = UIAlertAction(title: "复制", style: .default) { _ in
            // 复制联系方式到剪贴板
            var copyText = ""
            if let wechat = userInfo.wechatAccount, !wechat.isEmpty {
                copyText += "微信：\(wechat) "
            }
            if let qq = userInfo.qqAccount, !qq.isEmpty {
                copyText += "QQ：\(qq)"
            }
            
            UIPasteboard.general.string = copyText.trimmingCharacters(in: .whitespaces)
        }
        
        let closeAction = UIAlertAction(title: "关闭", style: .cancel, handler: nil)
        
        if hasContact {
            alert.addAction(copyAction)
        }
        alert.addAction(closeAction)
        
        viewController.present(alert, animated: true, completion: nil)
    }
    
    /// 显示解锁失败引导充值弹窗
    private static func showUnlockFailedAlert(from viewController: UIViewController) {
        print("⚠️ [Contact] 显示解锁失败弹窗")
        
        let isVip = (UserManager.shared.vip ?? 0) > 0
        print("👤 [Contact] 用户 VIP 状态: \(isVip ? "VIP" : "普通用户")")
        
        if isVip {
            // VIP 用户：单按钮弹窗
            print("📱 [Contact] 显示 VIP 用户单按钮弹窗")
            AppAlert.showSingle(
                title: "提示",
                message: "您今日 VIP 次数使用完毕，可充值活动币无限解锁特权。",
                confirmText: "充值活动币",
                messageAlignment: .center
            ) { 
                print("💰 [Contact] 用户点击了充值活动币")
                pushWallet(from: viewController)
            }
        } else {
            // 普通用户：双按钮弹窗
            print("📱 [Contact] 显示普通用户双按钮弹窗")
            AppAlert.showDouble(
                title: "提示",
                message: "您的活动币余额不足，请选择以下权益进行开通。",
                cancelText: "开通会员",
                confirmText: "充值活动币",
                messageAlignment: .center,
                onCancel: { 
                    print("💎 [Contact] 用户点击了开通会员")
                    pushMemberCenter(from: viewController)
                },
                onConfirm: { 
                    print("💰 [Contact] 用户点击了充值活动币")
                    pushWallet(from: viewController)
                }
            )
        }
    }
    
    /// 跳转到钱包页面
    private static func pushWallet(from viewController: UIViewController) {
        print("🚀 [Contact] 跳转到钱包页面")
        let vc = MyWalletViewController()
        if let nav = viewController.navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: vc)
            navController.modalPresentationStyle = .fullScreen
            viewController.present(navController, animated: true, completion: nil)
        }
    }
    
    /// 跳转到会员中心页面
    private static func pushMemberCenter(from viewController: UIViewController) {
        print("🚀 [Contact] 跳转到会员中心页面")
        let vc = MemberCenterViewController()
        if let nav = viewController.navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: vc)
            navController.modalPresentationStyle = .fullScreen
            viewController.present(navController, animated: true, completion: nil)
        }
    }
    
    /// 将 CurrentlyInterestedInfoModel 转换为 ActivityModel
    private static func convertToActivityModel(from info: CurrentlyInterestedInfoModel) -> ActivityModel {
        let status: ActivityStatus = {
            switch info.status {
            case "published", "ongoing": return .ongoing
            case "pending": return .pending
            case "expired", "rejected", "draft": return .expired
            default: return .ongoing
            }
        }()
        
        // 解析图片列表
        let imageUrls: [String]
        if let images = info.images, !images.isEmpty {
            // 假设 images 是逗号分隔的字符串
            imageUrls = images.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        } else {
            imageUrls = []
        }
        
        // 构建活动类型字符串
        let category = info.activityType?.compactMap { $0.name }.map { "#\($0)" }.joined(separator: "，") ?? ""
        
        // 构建性别要求
        let genderRequirement: String = {
            switch info.gender {
            case 0: return "不限男女"
            case 1: return "只限女性"
            case 2: return "只限男性"
            default: return "不限男女"
            }
        }()
        
        // 构建活动时间
        let activityTime: String = {
            if (info.isLongTerm ?? 0) == 1 || (info.activityTime ?? 0) <= 0 {
                return "长期有效"
            } else {
                let date = Date(timeIntervalSince1970: TimeInterval(info.activityTime ?? 0))
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm"
                return formatter.string(from: date)
            }
        }()
        
        // 费用类型映射
        let feeType: String = {
            switch info.feeType {
            case "free": return "免费"
            case "shared": return "平摊费用"
            case "you_pay": return "由你买单"
            case "i_pay": return "我买单"
            default: return info.feeType ?? "免费"
            }
        }()
        
        return ActivityModel(
            id: info.id.map { "\($0)" } ?? UUID().uuidString,
            coverURL: imageUrls.first ?? "",
            userId: info.user?.id.map { "\($0)" } ?? "",
            avatarUrl: info.user?.avatar ?? "",
            nickName: info.user?.nickname ?? "",
            gender: info.user?.gender ?? info.gender ?? 0,
            age: info.user?.age.map { "\($0)" } ?? "",
            constellation: "", // 这个模型中没有星座信息
            status: status,
            title: info.title ?? "",
            announcements: info.content ?? "",
            teamInfo: "\(info.peopleNum ?? 0)",
            genderRequirement: genderRequirement,
            isInterested: true, // 既然显示在 banner 上，应该是已感兴趣的
            isFollowed: false,
            time: activityTime,
            location: info.location ?? "",
            category: category,
            descriptionFees: feeType
        )
    }
}

// MARK: - Chat Cell Bubble Customization
class ChatTableViewDelegateInterceptor: NSObject, UITableViewDelegate {
  private weak var originalDelegate: UITableViewDelegate?
  
  init(originalDelegate: UITableViewDelegate?) {
    self.originalDelegate = originalDelegate
    super.init()
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    // 先调用原始 delegate 的方法
    originalDelegate?.tableView?(tableView, willDisplay: cell, forRowAt: indexPath)
    
    // 直接访问 cell 中的 bubbleImageLeft 和 bubbleImageRight 属性
    customizeCellAppearance(cell: cell)
  }
  
  private func customizeCellAppearance(cell: UITableViewCell) {
    // 检查 cell 是否有 bubbleImageLeft 和 bubbleImageRight 属性
    if cell.responds(to: NSSelectorFromString("bubbleImageLeft")),
       let bubbleImageLeft = cell.value(forKey: "bubbleImageLeft") as? UIImageView,
       cell.responds(to: NSSelectorFromString("bubbleImageRight")),
       let bubbleImageRight = cell.value(forKey: "bubbleImageRight") as? UIImageView {
      
      // 修改左侧气泡（对方消息）
      if !bubbleImageLeft.isHidden {
        bubbleImageLeft.image = nil // 移除气泡图片
        bubbleImageLeft.backgroundColor = UIColor(hex: "#2A2A2C") // 设置背景色
        bubbleImageLeft.layer.cornerRadius = 8 // 添加圆角
        bubbleImageLeft.clipsToBounds = true
        
        // 修改气泡内的文本颜色为白色
        updateTextColor(in: bubbleImageLeft, to: .white)
      }
      
      // 修改右侧气泡（自己消息）
      if !bubbleImageRight.isHidden {
        bubbleImageRight.image = nil // 移除气泡图片
        bubbleImageRight.backgroundColor = UIColor(hex: "#A2EF4D") // 设置背景色
        bubbleImageRight.layer.cornerRadius = 8 // 添加圆角
        bubbleImageRight.clipsToBounds = true
        
        // 修改气泡内的文本颜色为黑色
        updateTextColor(in: bubbleImageRight, to: .black)
      }
    }
  }
  
  private func updateTextColor(in view: UIView, to color: UIColor) {
    for subview in view.subviews {
      if let label = subview as? UILabel {
        label.textColor = color
      }
      if let textView = subview as? UITextView {
        textView.textColor = color
        textView.backgroundColor = .clear
      }
      // 递归更新子视图
      updateTextColor(in: subview, to: color)
    }
  }
  
  // 转发其他 delegate 方法
  override func responds(to aSelector: Selector!) -> Bool {
    return super.responds(to: aSelector) || originalDelegate?.responds(to: aSelector) ?? false
  }
  
  override func forwardingTarget(for aSelector: Selector!) -> Any? {
    if originalDelegate?.responds(to: aSelector) == true {
      return originalDelegate
    }
    return super.forwardingTarget(for: aSelector)
  }
}
