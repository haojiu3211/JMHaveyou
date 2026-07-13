//
//  ConversationListViewController.swift
//  haveseeyou
//
//  会话列表（单聊）
//

import UIKit
import SnapKit
import NIMSDK
import NEChatKit
import NEChatUIKit
import Combine

// 简单的响应模型 - 只解析 code 和 message，忽略 data
private struct ActivitySimpleResponse: Decodable {
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

final class ConversationListViewController: BaseViewController {

    /// 首页使用自定义导航栏，隐藏系统导航栏
    override var prefersNavigationBarHidden: Bool { true }
    /// 首页不需要标准返回按钮
    override var useStandardBackButton: Bool { false }
    // MARK: - UI

    private let bannerView = ChatBannerView()
    private let chatBannerViewModel = ChatBannerViewModel()
    private let navigationView = ChatNavigationView()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .white
        tv.separatorStyle = .none
        tv.rowHeight = 72
        return tv
    }()

  

    // MARK: - State

    /// 预设系统会话：置顶展示、不可删除；用户没有时自动创建
    private struct PresetMeta {
        let accountId: String
        let displayName: String
        let avatar: String
    }
    private let presetMetas: [PresetMeta] = [
        PresetMeta(accountId: "8997904", displayName: "活动公告", avatar: ""),
        PresetMeta(accountId: "8997905", displayName: "系统通知", avatar: ""),
        PresetMeta(accountId: "8997906", displayName: "官方客服", avatar: "")
    ]
    /// 与 presetMetas 一一对应的真实会话；尚未创建好的位置为 nil
    private var presetConversations: [V2NIMLocalConversation?] = []

    private var conversations: [V2NIMLocalConversation] = []
    private var nextOffset: Int = 0
    private var finished: Bool = false
    private var isLoadingchat: Bool = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
//        title = "消息"
        view.backgroundColor = .white
        setupUI()
        bindViewModel()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reload),
                                               name: .userDidLogin,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleLogout),
                                               name: .userDidLogout,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reload),
                                               name: .imConversationDidChange,
                                               object: nil)
        reload()
    }

    override func bindViewModel() {
        // Banner 数据
        chatBannerViewModel.$banners
            .receive(on: DispatchQueue.main)
            .sink { [weak self] list in
                self?.bannerView.configure(list)
            }
            .store(in: &cancellables)

        chatBannerViewModel.refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    override func setupUI() {
        view.addSubviews(navigationView, tableView)

        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
        }

        // 配置 Banner 作为 tableHeaderView
        let width = UIScreen.main.bounds.width
        let imageWidth = width - 32
        let imageHeight = imageWidth / 3.5  // 按 3.5:1 比例计算图片高度
        let bannerHeight = imageHeight + 34  // 加上上下内边距
        bannerView.frame = CGRect(x: 0, y: 0, width: width, height: bannerHeight)
        tableView.tableHeaderView = bannerView

        // Banner 点击跳转 Web 详情页
        bannerView.onBannerTapped = { [weak self] banner in
            guard let url = banner.linkUrl, !url.isEmpty else { return }
            let web = WebViewController(urlString: url)
            self?.navigationController?.pushViewController(web, animated: true)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        tableView.register(ChatConversationCell.self, forCellReuseIdentifier: ChatConversationCell.identifier)
        tableView.register(FixedConversationCell.self, forCellReuseIdentifier: FixedConversationCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
    }

//    deinit {
//        NotificationCenter.default.removeObserver(self)
//    }

    // MARK: - Data

    @objc private func reload() {
        guard IMManager.shared.isLoggedIn else {
            conversations = []
            presetConversations = Array(repeating: nil, count: presetMetas.count)
            tableView.reloadData()
            return
        }
        // 一次性拉前 200 条覆盖，避免边清边渲染导致 index out of range
        IMManager.shared.fetchConversationList(offset: 0, limit: 200) { [weak self] list, next, done, _ in
            guard let self = self else { return }
            self.nextOffset = next
            self.finished = done

            // 拆分：预设系统会话 vs 其它会话
            let presetIds = Set(self.presetMetas.map(\.accountId))
            var presetMap: [String: V2NIMLocalConversation] = [:]
            var others: [V2NIMLocalConversation] = []
            for conv in list {
                let target = V2NIMConversationIdUtil.conversationTargetId(conv.conversationId) ?? ""
                if presetIds.contains(target) {
                    presetMap[target] = conv
                } else {
                    others.append(conv)
                }
            }
            self.presetConversations = self.presetMetas.map { presetMap[$0.accountId] }
            self.conversations = others
            self.tableView.reloadData()

            // 缺失的预设会话自动创建（创建后云信会通过 LocalConversationListener
            // 触发 .imConversationDidChange，再回到本方法把新会话填回 section 0）
            for meta in self.presetMetas where presetMap[meta.accountId] == nil {
                guard let cid = V2NIMConversationIdUtil.p2pConversationId(meta.accountId) else { continue }
                LocalConversationRepo.shared.createConversation(cid) { _, _ in }
            }
        }
    }

    @objc private func handleLogout() {
        conversations.removeAll()
        presetConversations = Array(repeating: nil, count: presetMetas.count)
        tableView.reloadData()
    }

    /// 点击预设系统会话 → 直接进入对应单聊
    private func openPreset(at index: Int) {
        guard index < presetMetas.count else { return }
        let accountId = presetMetas[index].accountId
        if (accountId == "8997906"){
            // 获取当前时间戳（秒级，Int 类型）
            let timestamp = Int(Date().timeIntervalSince1970)

            // 将时间戳拼接到 URL 中
            let urlString = "\(webUrlonlineSever)?time=\(timestamp)"

            // 初始化并跳转
            let web = WebViewController(urlString: urlString)
            navigationController?.pushViewController(web, animated: true)
        }else if (accountId == "8997905"){
           openSystemNotificationPage(accountId: accountId)
        }else {
            
            
            
            guard let cid = V2NIMConversationIdUtil.p2pConversationId(accountId) else { return }
            let vc = HSYP2PChatViewController(conversationId: cid)
            navigationController?.pushViewController(vc, animated: true)
        }
        
    }

    /// 打开系统通知页：拉取与指定账号的会话历史，解析自定义消息（type=10001 等），
    /// 排序后传入 ChatSystemNotifiViewController 展示；同时清空该会话未读红点。
    private func openSystemNotificationPage(accountId: String) {
        let vc = ChatSystemNotifiViewController()
        navigationController?.pushViewController(vc, animated: true)

        guard IMManager.shared.isLoggedIn,
              let cid = V2NIMConversationIdUtil.p2pConversationId(accountId) else {
            vc.update(notifications: [])
            return
        }

        // 清空未读红点（云信会通过 LocalConversationListener 回调 reload，刷新 cell badge）
        LocalConversationRepo.shared.clearUnreadCountByIds([cid]) { _, _ in }

        let opt = V2NIMMessageListOption()
        opt.conversationId = cid
        opt.limit = 100
        opt.direction = .QUERY_DIRECTION_DESC
        // 仅查询自定义消息，减少无关消息
        opt.messageTypes = [NSNumber(value: V2NIMMessageType.MESSAGE_TYPE_CUSTOM.rawValue)]

        ChatRepo.shared.getMessageList(option: opt) { [weak vc] messages, _ in
            let list = (messages ?? [])
                .compactMap { SystemNotification.parse($0) }
                .sorted { $0.createTime > $1.createTime }
            DispatchQueue.main.async {
                vc?.update(notifications: list)
            }
        }
    }

    /// 打招呼：与指定账号建立单聊并 push 进入聊天页
    private func sayHi(toAccountId accountId: String) {
        guard IMManager.shared.isLoggedIn else { return }
        guard let cid = V2NIMConversationIdUtil.p2pConversationId(accountId) else { return }

        let pushChat: () -> Void = { [weak self] in
            let vc = HSYP2PChatViewController(conversationId: cid)
            self?.navigationController?.pushViewController(vc, animated: true)
        }

        // 先把对端用户资料预拉进缓存，会话 cell 才能立刻显示昵称/头像
        NIMUserInfoLoader.shared.fetch(accountId: accountId) { _ in
            LocalConversationRepo.shared.getConversation(cid) { conv, _ in
                if conv != nil {
                    pushChat()
                } else {
                    LocalConversationRepo.shared.createConversation(cid) { _, _ in
                        pushChat()
                    }
                }
            }
        }
    }

    private func loadMore() {
        guard !isLoadingchat, !finished else { return }
        guard IMManager.shared.isLoggedIn else { return }
        isLoadingchat = true
        let snapshotCount = conversations.count
        IMManager.shared.fetchConversationList(offset: nextOffset, limit: 100) { [weak self] list, next, done, error in
            guard let self = self else { return }
            self.isLoadingchat = false
            if error != nil { return }
            // 期间若发生了 reload（行数被重置），丢弃本次分页结果
            guard self.conversations.count == snapshotCount else { return }
            self.conversations.append(contentsOf: list)
            self.nextOffset = next
            self.finished = done
            self.tableView.reloadData()
        }
    }

    // MARK: - Push 单聊

    private func openChat(_ conv: V2NIMLocalConversation) {
        let cid = conv.conversationId
        guard V2NIMConversationIdUtil.conversationType(cid) == .CONVERSATION_TYPE_P2P else { return }
        
        // 获取对方用户ID
        guard let targetId = V2NIMConversationIdUtil.conversationTargetId(cid),
              let publisherId = Int(targetId) else {
            // 无法获取用户ID，直接跳转
            print("❌ [ConversationList] 无法获取对方用户ID，直接跳转")
            self.showLoading("会话信息异常，暂时无法进入聊天")
            return
        }
        
        if AuditConfigManager.shared.isAudit {
                    // 审核模式 UI
            let vc = HSYP2PChatViewController(conversationId: cid)
            self.navigationController?.pushViewController(vc, animated: true)
            return
         }
        
        
        print("🎯 [ConversationList] 开始检查私聊解锁状态，targetId: \(targetId), publisherId: \(publisherId)")
        
        // 检查是否已解锁
        NetworkManager.shared.request(PurchaseAPI.unlockPrivateStatus(toUid: publisherId), as: APIResponse<UnlockPrivateStatusResponse>.self) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let wrappedResponse):
                print("✅ [ConversationList] unlockPrivateStatus 原始响应，code: \(wrappedResponse.code), message: \(wrappedResponse.message ?? "nil")")
                
                DispatchQueue.main.async {
                    if wrappedResponse.code == 0 {
                        // 业务成功
                        if let response = wrappedResponse.data, response.isUnlocked == 1 {
                            // 已解锁，直接跳转
                            print("🎉 [ConversationList] 已解锁，直接跳转聊天")
                            let vc = HSYP2PChatViewController(conversationId: cid)
                            self.navigationController?.pushViewController(vc, animated: true)
                        } else {
                            // 未解锁，尝试调用 diamondUnlock
                            print("🔓 [ConversationList] 未解锁，尝试调用 diamondUnlock")
                            self.tryDiamondUnlock(publisherId: publisherId, conversationId: cid)
                        }
                    } else {
                        // 业务失败（code != 0），也尝试调用 diamondUnlock
                        print("⚠️ [ConversationList] unlockPrivateStatus 业务失败，code: \(wrappedResponse.code), message: \(wrappedResponse.message ?? "nil")")
                        self.tryDiamondUnlock(publisherId: publisherId, conversationId: cid)
                    }
                }
                
            case .failure(let error):
                print("❌ [ConversationList] unlockPrivateStatus 调用失败: \(error)")
                // 失败也尝试调用 diamondUnlock
                DispatchQueue.main.async {
                    self.tryDiamondUnlock(publisherId: publisherId, conversationId: cid)
                }
            }
        }
    }
    
    private func tryDiamondUnlock(publisherId: Int, conversationId: String) {
        let unlockType = UnlockType.message.rawValue
        let decCoin = getDecCoin(for: unlockType)
        
        print("💎 [ConversationList] 开始调用 diamondUnlock，publisherId: \(publisherId), type: \(unlockType) (私信), decCoin: \(decCoin)")
        
        NetworkManager.shared.request(PurchaseAPI.diamondUnlock(type: unlockType, toUid: publisherId, decCoin: decCoin), as: ActivitySimpleResponse.self) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                print("📋 [ConversationList] diamondUnlock 原始响应，code: \(response.code), message: \(response.message ?? "nil")")
                
                DispatchQueue.main.async {
                    if response.code == 0 || response.code == 1 {
                        // 业务成功(code == 0) 或者已经解锁过了(code == 1)，都直接跳转
                        print("✅ [ConversationList] diamondUnlock 成功或已解锁，code: \(response.code)")
                        let vc = HSYP2PChatViewController(conversationId: conversationId)
                        self.navigationController?.pushViewController(vc, animated: true)
                    } else {
                        // 其他业务失败（code != 0 且 != 1），特别是 1003 余额不足
                        print("⚠️ [ConversationList] diamondUnlock 业务失败，code: \(response.code), message: \(response.message ?? "nil")")
                        self.showUnlockFailedAlert()
                    }
                }
                
            case .failure(let error):
                print("❌ [ConversationList] diamondUnlock 调用失败: \(error)")
                
                // 尝试从错误中提取业务码（如果是 APIError.business）
                if case let APIError.business(code, message) = error {
                    print("📋 [ConversationList] 检测到业务错误，code: \(code), message: \(message)")
                    DispatchQueue.main.async {
                        if code == 0 || code == 1 {
                            // 即使解析失败，但如果错误中包含 code == 0 或 1，也直接跳转
                            print("✅ [ConversationList] 从错误中检测到成功，code: \(code)")
                            let vc = HSYP2PChatViewController(conversationId: conversationId)
                            self.navigationController?.pushViewController(vc, animated: true)
                        } else {
                            // 其他情况显示弹窗
                            self.showUnlockFailedAlert()
                        }
                    }
                } else {
                    // 其他类型的错误，显示弹窗
                    DispatchQueue.main.async {
                        self.showUnlockFailedAlert()
                    }
                }
            }
        }
    }
    
    private func getDecCoin(for type: Int) -> Int {
        // 解锁聊天（私信）一次 100 活动币，解锁社媒账号一次 200 活动币
        switch type {
        case UnlockType.message.rawValue:
            // 解锁聊天/私信：100 活动币
            return 100
        case UnlockType.wechat.rawValue:
            // 解锁社媒账号（微信）：200 活动币
            return 200
        default:
            // 其他类型默认 100
            return 100
        }
    }
    
    private func showUnlockFailedAlert() {
        print("⚠️ [ConversationList] 显示解锁失败弹窗")
        
        let isVip = (UserManager.shared.vip ?? 0) > 0
        print("👤 [ConversationList] 用户 VIP 状态: \(isVip ? "VIP" : "普通用户")")
        
        if isVip {
            // VIP 用户：单按钮弹窗
            print("📱 [ConversationList] 显示 VIP 用户单按钮弹窗")
            AppAlert.showSingle(
                title: "提示",
                message: "您今日 VIP 次数使用完毕，可充值活动币无限畅聊。",
                confirmText: "充值活动币",
                messageAlignment: .center
            ) { [weak self] in
                print("💰 [ConversationList] 用户点击了充值活动币")
                self?.pushWallet()
            }
        } else {
            // 普通用户：双按钮弹窗
            print("📱 [ConversationList] 显示普通用户双按钮弹窗")
            AppAlert.showDouble(
                title: "提示",
                message: "您的活动币余额不足，请选择以下权益进行开通。",
                cancelText: "开通会员",
                confirmText: "充值活动币",
                messageAlignment: .center,
                onCancel: { [weak self] in
                    print("💎 [ConversationList] 用户点击了开通会员")
                    self?.pushMemberCenter()
                },
                onConfirm: { [weak self] in
                    print("💰 [ConversationList] 用户点击了充值活动币")
                    self?.pushWallet()
                }
            )
        }
    }
    
    private func pushWallet() {
        print("🚀 [ConversationList] 跳转到钱包页面")
        let vc = MyWalletViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func pushMemberCenter() {
        print("🚀 [ConversationList] 跳转到会员中心页面")
        let vc = MemberCenterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension ConversationListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? presetMetas.count : conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatConversationCell.identifier, for: indexPath) as! ChatConversationCell
        if indexPath.section == 0 {
            let meta = presetMetas[indexPath.row]
            let conv: V2NIMBaseConversation? = indexPath.row < presetConversations.count
                ? presetConversations[indexPath.row]
                : nil
            cell.configurePreset(accountId: meta.accountId,
                                 name: meta.displayName,
                                 avatar: meta.avatar,
                                 conversation: conv)
        } else {
            cell.configure(with: conversations[indexPath.row])
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            openPreset(at: indexPath.row)
        } else {
            openChat(conversations[indexPath.row])
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 只对真实会话区做上拉加载
        if indexPath.section == 1, indexPath.row >= conversations.count - 3 {
            loadMore()
        }
    }

    // 仅真实会话区（section 1）支持左滑删除；预设项 section 0 不可删除
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 1, indexPath.row < conversations.count else { return nil }

        let action = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, done in
            self?.deleteConversation(at: indexPath, completion: done)
        }
        let config = UISwipeActionsConfiguration(actions: [action])
        config.performsFirstActionWithFullSwipe = true
        return config
    }

    private func deleteConversation(at indexPath: IndexPath,
                                    completion: @escaping (Bool) -> Void) {
        guard indexPath.row < conversations.count else {
            completion(false)
            return
        }
        let conv = conversations[indexPath.row]
        LocalConversationRepo.shared.deleteConversation(conv.conversationId) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { completion(false); return }
                if let error = error {
                    self.showToast(error.localizedDescription, duration: 1.5)
                    completion(false)
                    return
                }
                // .destructive 样式调用 completion(true) 后，UITableView 会自己把该行动画移除。
                // 这里只更新数据源；如果再手动 deleteRows 会触发二次删除导致 "number of rows" assert 崩溃。
                if indexPath.row < self.conversations.count,
                   self.conversations[indexPath.row].conversationId == conv.conversationId {
                    self.conversations.remove(at: indexPath.row)
                }
                completion(true)
            }
        }
    }
}

