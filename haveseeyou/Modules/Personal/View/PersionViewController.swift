//
//  PersionViewController.swift
//  haveseeyou
//
//  个人主页
//

import UIKit
import SnapKit
import Combine
import Kingfisher
import NIMSDK
import NEChatKit

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

final class PersionViewController: BaseViewController, UIScrollViewDelegate {

    /// 判断当前 ViewController 是否是被 Present 出来的
    private var isPresented: Bool {
        // 如果有 presentingViewController，说明是 Present 出来的
        if presentingViewController != nil {
            return true
        }
        // 如果在导航控制器中，且不是导航控制器的根视图控制器，说明是 Push 出来的
        if let nav = navigationController, nav.viewControllers.count > 1 {
            return false
        }
        // 其他情况（比如导航控制器本身被 Present）也认为是 Present 模式
        return navigationController?.presentingViewController != nil
    }

    // MARK: - Data

    var model: PersonalHomepageDataModel? {
        didSet {
            if isViewLoaded {
                setupData()
            }
        }
    }

    /// 当前显示的标签
    private var currentTags: [String] = []
    /// 默认标签选项
    private let defaultTagOptions = ["认识新朋友", "找同好搭子", "寻找恋爱/脱单", "体验新鲜事物", "满足兴趣爱好", "学习新技能", "向上社交资源", "朋友一起娱乐", "打发枯燥生活"]

    /// 单独的活动相关订阅容器，避免重复订阅
    private var activityCancellables = Set<AnyCancellable>()

    // MARK: - UI 组件

    /// 滚动视图
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    /// 内容容器
    private let contentView: UIView = {
        let v = UIView()
        return v
    }()

    /// Banner 轮播
    private let bannerView = DetailBannerView()

    /// 白色内容卡片（覆盖在 Banner 上面）
    private let contentCardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 14
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.clipsToBounds = true
        return v
    }()

    /// 卡片内部容器
    private let innerContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    // MARK: - 底部固定操作栏

    /// 底部固定操作栏（不参与滚动），承载“私聊”按钮
    private let bottomBar: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }()

    /// 私聊按钮
    private let chatButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("私聊TA", for: .normal)
        let gradientColor = UIColor.gradientTextColor(
            size: CGSize(width: 80, height: 30),
            colors: sy_gradientArr)
        btn.setTitleColor(gradientColor, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btn.backgroundColor = AppColor.buttonDark
        btn.layer.cornerRadius = 25
        btn.clipsToBounds = true
        return btn
    }()

    /// 私聊按钮高度（与 scrollView 底部锚定共用）
    private let chatButtonHeight: CGFloat = 50
    /// 私聊按钮上下内边距
    private let bottomBarVerticalInset: CGFloat = 12

    // MARK: - 用户信息区域

    /// 用户头像
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 25
        iv.backgroundColor = UIColor(hex: "#E5E5E5")
        iv.isUserInteractionEnabled = true
        return iv
    }()

    /// 用户昵称
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = AppColor.textMain
        return l
    }()

    /// 性别图标
    private let genderImageView: UIImageView = {
        let iv = UIImageView()
        return iv
    }()

    /// 年龄标签
    private let ageLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .medium)
        l.textColor = .white
        return l
    }()

    /// 认证标签
    private let authLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .semibold)
        l.textColor = .white
        l.backgroundColor = UIColor(hex: "#4CAF50")
        l.textAlignment = .center
        l.layer.cornerRadius = 6
        l.clipsToBounds = true
        return l
    }()

    /// VIP 图标
    private let vipStateImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "me_vip_state"))
        return iv
    }()

    /// ID 号
    private let idLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColor.textSecondary
        return l
    }()

    /// 复制按钮
    private let copyButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "me_copy"), for: .normal)
        btn.tintColor = AppColor.textSecondary
        return btn
    }()

    /// 个性签名
    private let bioLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = AppColor.textSecondary
        l.numberOfLines = 1
        l.textAlignment = .left
        return l
    }()

    /// 关注按钮
    private let followButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        btn.layer.cornerRadius = 16
        btn.clipsToBounds = true
        return btn
    }()

    /// 用户信息容器
    private let userInfoContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    // 标签 CollectionView
    private lazy var tagsCollectionView: UICollectionView = {
        let layout = LeftAlignedFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 18
        layout.minimumLineSpacing = 9
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.isScrollEnabled = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(TagDisplayCell.self, forCellWithReuseIdentifier: TagDisplayCell.reuseId)
        return cv
    }()

    // MARK: - 微信区域

    /// 微信容器
    private let wechatContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F8F8F8")
        v.layer.cornerRadius = 10
        v.clipsToBounds = true
        return v
    }()

    private let wechatIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "persion_wx"))
//        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let wechatLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = AppColor.textMain
        return l
    }()

    private let wechatDescLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColor.textSecondary
        l.numberOfLines = 0
        return l
    }()

    private let wechatLockIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "persion_lock"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let wechatViewButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("  查看", for: .normal)
        let gradientColor = UIColor.gradientTextColor(
            size: CGSize(width: 80, height: 30),
            colors: sy_gradientArr)
        btn.setTitleColor(gradientColor, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        btn.backgroundColor = AppColor.buttonDark
        btn.layer.cornerRadius = 14
        btn.clipsToBounds = true
        return btn
    }()

    // MARK: - 相册区域

    private let albumHeaderLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = AppColor.textMain
        l.text = "TA的相册/视频"
        return l
    }()

    private let albumCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(AlbumCell.self, forCellWithReuseIdentifier: "AlbumCell")
        return cv
    }()

    // MARK: - 喜欢的活动类型区域

    private let activityTypeContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    private let activityTypeHeaderLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = AppColor.textMain
        l.text = "喜欢的活动类型"
        return l
    }()

    private let activityTypeTagsContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    // MARK: - TA发起的活动区域

    private let taActivitiesContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    private let taActivitiesHeaderLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = AppColor.textMain
        l.text = "TA发起的活动"
        return l
    }()

    private let taActivitiesTableView: SelfSizingTableView = {
        let tv = SelfSizingTableView(frame: .zero, style: .plain)
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        tv.showsVerticalScrollIndicator = false
        tv.register(ActivityCell.self, forCellReuseIdentifier: ActivityCell.reuseID)
        tv.rowHeight = 152
        tv.contentInsetAdjustmentBehavior = .never
        tv.isScrollEnabled = false
        return tv
    }()

    private let activityViewModel = ActivityViewModel()
    private var taActivities: [ActivityModel] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupData()
        setupGestures()
    }

    // MARK: - 透明导航栏

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureTransparentNavigationBar()
    }

    /// 配置透明导航栏：背景透明 + 返回按钮白色 + 标题白色
    private func configureTransparentNavigationBar() {
        guard let navBar = navigationController?.navigationBar else { return }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]

        appearance.backgroundImage = makeGradientImage(
            size: CGSize(
                width: UIScreen.main.bounds.width,
                height: 70
            )
        )
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.tintColor = .white

        navigationItem.leftBarButtonItem?.tintColor = .white
    }

    func makeGradientImage(size: CGSize) -> UIImage? {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.black.cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.frame = CGRect(origin: .zero, size: size)

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        gradientLayer.render(in: ctx)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        restoreNavigationBarAppearance()
        // 清理所有的订阅和回调，避免循环引用
        activityCancellables.removeAll()
        bannerView.onImageTapped = nil
    }

    private func restoreNavigationBarAppearance() {
        guard let navBar = navigationController?.navigationBar else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [
            .foregroundColor: AppColor.textMain,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.tintColor = AppColor.textMain
        navigationItem.leftBarButtonItem?.tintColor = AppColor.textMain
    }

    // MARK: - SetupUI

    override func setupUI() {
        view.backgroundColor = AppColor.background

        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        navigationItem.title = "个人主页"
        
        // 只在 Present 模式下显示关闭按钮
        if isPresented {
            let closeButton = UIBarButtonItem(image: UIImage(named: "member_navBack_bg"), style: .plain, target: self, action: #selector(closeTapped))
            closeButton.tintColor = .white
            navigationItem.leftBarButtonItem = closeButton
        }

        view.addSubviews(scrollView)
        scrollView.addSubview(contentView)

        // 底部固定栏：不参与滚动，承载“私聊”按钮
        view.addSubview(bottomBar)
        bottomBar.addSubview(chatButton)
        bottomBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(chatButton.snp.top).offset(-bottomBarVerticalInset)
            // 锚到 safeArea 底，按钮下方再留 inset，避免被 Home Indicator 挡
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        chatButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-bottomBarVerticalInset)
            make.height.equalTo(chatButtonHeight)
        }
        chatButton.addTarget(self, action: #selector(handleChatButtonTapped), for: .touchUpInside)

        // scrollView 顶到 view 顶，底锚到 bottomBar 顶 —— 整页滚动到末尾时正好不会被按钮挡住
        scrollView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
        }

        contentView.snp.makeConstraints { make in
            // 关键：4 条边都得绑到 scrollView，否则 scrollView 的 contentLayoutGuide
            // 拿不到 bottom，contentSize.height 永远 ≤ frame.height，整页无法滚动。
            make.edges.equalToSuperview()
            // 宽度等于 scrollView 可视宽度，让内容只能纵向滚
            make.width.equalToSuperview()
        }

        setupBannerSection()
        setupContentCard()
    }

    // MARK: - Actions

    @objc private func handleChatButtonTapped() {
        
        if AuditConfigManager.shared.isAudit {
                    // 审核模式 UI
            guard let userId = model?.userId else { return }
            self.pushToChat(userId: userId)
            
            return
        }

        
        if (self.isPresented){
            dismiss(animated: true)
        }else {
            guard let userId = model?.userId else { return }
            
            // 先调用解锁状态检查，再调用解锁
            NetworkManager.shared.request(PurchaseAPI.unlockPrivateStatus(toUid: userId), as: APIResponse<UnlockPrivateStatusResponse>.self) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let wrappedResponse):
                    DispatchQueue.main.async {
                        if wrappedResponse.code == 0 {
                            if let response = wrappedResponse.data, response.isUnlocked == 1 {
                                // 已解锁，直接跳转聊天
                                self.pushToChat(userId: userId)
                            } else {
                                // 未解锁，尝试调用 diamondUnlock
                                self.tryDiamondUnlock(userId: userId, type: .message) { [weak self] success in
                                    if success {
                                        self?.pushToChat(userId: userId)
                                    }
                                }
                            }
                        } else {
                            // 业务失败，也尝试调用 diamondUnlock
                            self.tryDiamondUnlock(userId: userId, type: .message) { [weak self] success in
                                if success {
                                    self?.pushToChat(userId: userId)
                                }
                            }
                        }
                    }
                case .failure(_):
                    // 失败也尝试调用 diamondUnlock
                    DispatchQueue.main.async {
                        self.tryDiamondUnlock(userId: userId, type: .message) { [weak self] success in
                            if success {
                                self?.pushToChat(userId: userId)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 添加跳转聊天的辅助方法
    private func pushToChat(userId: Int) {
        let accountId = "\(userId)"
        guard let cid = V2NIMConversationIdUtil.p2pConversationId(accountId) else { return }
        let vc = HSYP2PChatViewController(conversationId: cid)
        self.present(vc, animated: true)
    }
    
    // 添加钻石解锁的通用方法
    private func tryDiamondUnlock(userId: Int, type: UnlockType, completion: @escaping (Bool) -> Void) {
        let decCoin = type == .message ? 100 : 200
        
        NetworkManager.shared.request(PurchaseAPI.diamondUnlock(type: type.rawValue, toUid: userId, decCoin: decCoin), as: SimpleResponse.self) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    if response.code == 0 || response.code == 1 {
                        completion(true)
                    } else {
                        self.showUnlockFailedAlert()
                        completion(false)
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    if case let APIError.business(code, _) = error, code == 0 || code == 1 {
                        completion(true)
                    } else {
                        self.showUnlockFailedAlert()
                        completion(false)
                    }
                }
            }
        }
    }
    
    // 添加显示解锁失败弹窗的方法
    private func showUnlockFailedAlert() {
        let isVip = (UserManager.shared.vip ?? 0) > 0
        
        if isVip {
            // VIP 用户：单按钮弹窗
            AppAlert.showSingle(
                title: "提示",
                message: "您今日 VIP 次数使用完毕，可充值活动币无限畅聊。",
                confirmText: "充值活动币",
                messageAlignment: .center
            ) { [weak self] in
                self?.pushWallet()
            }
        } else {
            // 普通用户：双按钮弹窗
            AppAlert.showDouble(
                title: "提示",
                message: "您的活动币余额不足，请选择以下权益进行开通。",
                cancelText: "开通会员",
                confirmText: "充值活动币",
                messageAlignment: .center,
                onCancel: { [weak self] in
                    self?.pushMemberCenter()
                },
                onConfirm: { [weak self] in
                    self?.pushWallet()
                }
            )
        }
    }
    
    // 添加跳转钱包和会员中心的方法
    private func pushWallet() {
        let vc = MyWalletViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func pushMemberCenter() {
        let vc = MemberCenterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // 处理手势冲突：水平滑动时让 banner 内部处理，垂直滑动时外层 scrollView 处理
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: scrollView)
        // 水平速度大于垂直速度时，认为是横向滑动，让 banner 处理
        if abs(velocity.x) > abs(velocity.y) {
            return false
        }
        return true
    }

    // MARK: - Banner 区域

    private func setupBannerSection() {
        contentView.addSubview(bannerView)

        bannerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(500)
        }

        bannerView.onImageTapped = { [weak self] index in
            self?.showImagePreview(initialIndex: index)
        }
    }

    // MARK: - 白色内容卡片

    private func setupContentCard() {
        contentView.addSubview(contentCardView)
        contentCardView.addSubview(innerContainer)

        // 卡片顶部向上偏移 20pt 覆盖 banner
        contentCardView.snp.makeConstraints { make in
            make.top.equalTo(bannerView.snp.bottom).offset(-20)
            make.left.right.equalToSuperview()
        }

        innerContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.left.right.equalToSuperview().inset(14)
            make.bottom.equalToSuperview()
        }

        setupUserInfoSection()
        setupTagsSection()
        setupWechatSection()
        setupAlbumSection()
        setupTaActivitiesSection()

        // 让 contentCardView 直接闭合 contentView 的底部，避免之前 400pt bottomSpacer
        // 导致 scrollView contentSize 多算了一截、底部出现大片空白。
        contentCardView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(20)
        }
    }

    // MARK: - 用户信息区域

    private func setupUserInfoSection() {
        innerContainer.addSubview(userInfoContainer)
        userInfoContainer.addSubviews(avatarImageView, nameLabel, genderImageView, ageLabel, authLabel, vipStateImageView,
                                      idLabel, copyButton, bioLabel, followButton)

        userInfoContainer.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(80)
        }

        // 头像
        avatarImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
            make.size.equalTo(CGSize(width: 50, height: 50))
        }

        // 昵称
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView.snp.right).offset(12)
            make.top.equalToSuperview().offset(10)
        }

        // 性别图标
        genderImageView.snp.makeConstraints { make in
            make.left.equalTo(nameLabel.snp.right).offset(6)
            make.centerY.equalTo(nameLabel)
            make.size.equalTo(CGSize(width: 28, height: 14))
        }

        // 年龄
        ageLabel.snp.makeConstraints { make in
            make.left.equalTo(genderImageView.snp.right).offset(-15)
            make.centerY.equalTo(nameLabel)
        }

        // 认证
        authLabel.snp.makeConstraints { make in
            make.left.equalTo(ageLabel.snp.right).offset(4)
            make.centerY.equalTo(nameLabel)
            make.height.equalTo(14)
            make.width.equalTo(20)
        }

        // VIP
        vipStateImageView.snp.makeConstraints { make in
            make.left.equalTo(authLabel.snp.right).offset(4)
            make.centerY.equalTo(nameLabel)
        }

        // ID 号
        idLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView.snp.right).offset(12)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
        }

        // 复制按钮
        copyButton.snp.makeConstraints { make in
            make.left.equalTo(idLabel.snp.right).offset(4)
            make.centerY.equalTo(idLabel)
            make.size.equalTo(CGSize(width: 16, height: 16))
        }

        // 个性签名
        bioLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView.snp.right).offset(12)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(idLabel.snp.bottom).offset(6)
        }

        // 关注按钮
        followButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(18)
            make.height.equalTo(32)
            make.width.equalTo(80)
        }
    }
    
    private func setupTagsSection() {
        innerContainer.addSubview(tagsCollectionView)
        
        // 初始先给一个非 0 高度，确保视图能正常布局
        tagsCollectionView.snp.makeConstraints { make in
            make.top.equalTo(userInfoContainer.snp.bottom).offset(18)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(200)
        }
    }

    private func setupTags() {
        guard let model = model else { return }
        
        // 优先使用 extra.initialHeart 字段（逗号分隔），没有时使用默认标签
        if let initialHeart = model.extra?.initialHeart, !initialHeart.isEmpty {
            currentTags = initialHeart.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        } else {
            currentTags = defaultTagOptions
        }
        
        loadTags()
    }
    
    private func loadTags() {
        // 计算并更新 tagsCollectionView 的高度
        let tags = currentTags
        if tags.isEmpty {
            tagsCollectionView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        } else {
            let availableWidth = UIScreen.main.bounds.width - 40
            var totalHeight: CGFloat = 0
            var currentX: CGFloat = 0
            var currentLineHeight: CGFloat = 0
            
            for tag in tags {
                let font = UIFont.systemFont(ofSize: 14)
                let text = "# \(tag)"
                let textWidth = text.size(withAttributes: [.font: font]).width
                let cellWidth = textWidth + 24
                let cellHeight: CGFloat = 24
                let lineSpacing: CGFloat = 9
                let interitemSpacing: CGFloat = 18
                
                if currentX + cellWidth > availableWidth && currentX > 0 {
                    // 换行
                    totalHeight += currentLineHeight + lineSpacing
                    currentX = 0
                    currentLineHeight = 0
                }
                
                currentX += cellWidth + interitemSpacing
                currentLineHeight = max(currentLineHeight, cellHeight)
            }
            
            totalHeight += currentLineHeight
            tagsCollectionView.snp.updateConstraints { make in
                make.height.equalTo(totalHeight)
            }
        }
        
        // 强制布局更新，让 tagsCollectionView 拿到正确的 frame，
        // 避免 frame.height 为 0 导致 cellForItemAt 不被调用
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // 最后才 reloadData
        tagsCollectionView.reloadData()
    }

    // MARK: - 微信区域

    private func setupWechatSection() {
        innerContainer.addSubview(wechatContainer)
        wechatContainer.addSubviews(wechatIcon, wechatLabel, wechatDescLabel,wechatViewButton)

        wechatContainer.snp.makeConstraints { make in
            make.top.equalTo(tagsCollectionView.snp.bottom).offset(16)
            make.left.right.equalToSuperview()
            make.height.equalTo(70)
        }

        wechatIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        wechatLabel.snp.makeConstraints { make in
            make.left.equalTo(wechatIcon.snp.right).offset(8)
            make.top.equalToSuperview().offset(14)
        }

        wechatDescLabel.snp.makeConstraints { make in
            make.left.equalTo(wechatIcon.snp.right).offset(8)
            make.top.equalTo(wechatLabel.snp.bottom).offset(4)
            make.right.equalToSuperview().inset(100)
        }

        // 锁图标和查看按钮组合在一起
        wechatViewButton.addSubview(wechatLockIcon)

        wechatViewButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 72, height: 28))
        }

        wechatLockIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 14, height: 14))
        }
    }

    // MARK: - 相册区域

    private func setupAlbumSection() {
        let albumContainer = UIView()
        albumContainer.backgroundColor = .white
        albumContainer.addSubviews(albumHeaderLabel, albumCollectionView, activityTypeContainer)

        innerContainer.addSubview(albumContainer)
        albumContainer.snp.makeConstraints { make in
            make.top.equalTo(wechatContainer.snp.bottom).offset(16)
            make.left.right.equalToSuperview()
        }

        albumHeaderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
        }

        albumCollectionView.snp.makeConstraints { make in
            make.top.equalTo(albumHeaderLabel.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().inset(16)
            make.height.equalTo(80)
        }

        // 喜欢的活动类型容器
        activityTypeContainer.snp.makeConstraints { make in
            make.top.equalTo(albumCollectionView.snp.bottom).offset(24)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            self.activityTypeHeightConstraint = make.height.equalTo(80).constraint
        }

        activityTypeContainer.addSubviews(activityTypeHeaderLabel, activityTypeTagsContainer)

        activityTypeHeaderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }

        activityTypeTagsContainer.snp.makeConstraints { make in
            make.top.equalTo(activityTypeHeaderLabel.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }

        albumCollectionView.dataSource = self
        albumCollectionView.delegate = self
    }

    private func setupTaActivitiesSection() {
        taActivitiesContainer.backgroundColor = .white

        innerContainer.addSubview(taActivitiesContainer)
        taActivitiesContainer.snp.makeConstraints { make in
            make.top.equalTo(activityTypeContainer.snp.bottom).offset(16)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        taActivitiesContainer.addSubviews(taActivitiesHeaderLabel, taActivitiesTableView)

        taActivitiesHeaderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
        }

        taActivitiesTableView.snp.makeConstraints { make in
            make.top.equalTo(taActivitiesHeaderLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview()
            // 由 SelfSizingTableView 暴露 intrinsicContentSize，bottom 反向拉高 container
            make.bottom.equalToSuperview()
        }

        taActivitiesTableView.dataSource = self
        taActivitiesTableView.delegate = self
    }

    // MARK: - Setup Data

    private func setupData() {
        guard let model = model else { return }

        // 配置 Banner：有 headAlbum 显示 headAlbum，没有显示 avatar
        let bannerUrls: [String]
        if !model.headAlbum.isEmpty {
            bannerUrls = model.headAlbum.map { AppConfig.API.fullImageURL(path: $0) }
        } else {
            bannerUrls = [AppConfig.API.fullImageURL(path: model.avatar)]
        }
        bannerView.configure(bannerUrls)

        let fullURLString: String = AppConfig.API.fullImageURL(path: model.avatar)
        if let imageURL = URL(string: fullURLString) {
                avatarImageView.kf.setImage(
                    with: imageURL,
                    placeholder: UIImage(named: "app_default_avatar")
                )
        }
    
        // 用户信息
        nameLabel.text = model.nickname
        idLabel.text = "ID号: \(model.usercode)"

        // 性别和年龄
        switch model.gender {
        case 1: // 女性
            genderImageView.image = UIImage(named: "me_girl")
            ageLabel.textColor = UIColor(hex: "#FFFF67A9")
        case 2: // 男性
            genderImageView.image = UIImage(named: "me_boy")
            ageLabel.textColor = UIColor(hex: "#FF037BFF")
        default:
            genderImageView.image = nil
            ageLabel.textColor = .white
        }
        ageLabel.text = "\(model.age)"

        // 认证标签
        if model.isAuth == 1 {
            authLabel.text = "实"
            authLabel.isHidden = false
            authLabel.snp.updateConstraints { make in
                make.width.equalTo(20)
            }
        } else {
            authLabel.isHidden = true
            authLabel.snp.updateConstraints { make in
                make.width.equalTo(0)
            }
        }
     
        // VIP 图标
        vipStateImageView.isHidden = (model.isVip != 1)

        // 个性签名
        bioLabel.text = model.sign

        // 关注状态
        updateFollowButton(isFollowed: model.isFollow == 1)

        // 设置标签
        setupTags()

        // 微信
        if !model.wechatAccount.isEmpty {
            wechatContainer.isHidden = false
            wechatContainer.snp.updateConstraints { make in
                make.height.equalTo(70)
            }
            
            if model.unlockWechat == 1 {
                // 已解锁：显示完整微信号，按钮变复制
                wechatLabel.text = "微信: \(model.wechatAccount)"
                wechatDescLabel.text = "已解锁TA的微信号"
                wechatViewButton.setTitle("复制", for: .normal)
                wechatLockIcon.isHidden = true
            } else {
                // 未解锁：隐藏微信号，显示解锁按钮
                let maskedWechat = maskWechatAccount(model.wechatAccount)
                wechatLabel.text = "微信: \(maskedWechat)"
                wechatDescLabel.text = "解锁TA的微信号开始聊天吧~"
                wechatViewButton.setTitle("  查看", for: .normal)
                wechatLockIcon.isHidden = false
            }
        } else {
            wechatContainer.isHidden = true
            wechatContainer.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        }

        // 相册
        albumCollectionView.reloadData()

        // 喜欢的活动类型
        setupActivityTypeTags()

        // TA发起的活动
        loadTaActivities()
    }

    // MARK: - TA发起的活动数据加载

    private func loadTaActivities() {
        // 个人主页“TA发起的活动”通过 user_id 参数获取该用户的活动
        activityViewModel.currentCity = ""
        activityViewModel.currentCategory = nil
        activityViewModel.currentStatus = nil
        activityViewModel.currentGender = nil
        activityViewModel.currentUserId = model.map { "\($0.userId)" }
        
        // 先清理旧的活动相关订阅
        activityCancellables.removeAll()

        activityViewModel.$filteredActivities
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activities in
                guard let self = self else { return }
                self.taActivities = activities
                self.taActivitiesTableView.reloadData()
                // SelfSizingTableView 会在 contentSize 变化时 invalidate intrinsicContentSize
                // 这里再 layoutIfNeeded 一次，让外层 scrollView 立刻拿到新的 contentSize
                self.view.layoutIfNeeded()
            }
            .store(in: &activityCancellables)

        activityViewModel.errorSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                self?.showToast(msg)
            }
            .store(in: &activityCancellables)

        activityViewModel.refresh()
    }

    // MARK: - 关注状态

    private func updateFollowButton(isFollowed: Bool) {
        if isFollowed {
            followButton.setTitle("已关注", for: .normal)
            followButton.setTitleColor(AppColor.textMain, for: .normal)
            followButton.backgroundColor = .white
            followButton.layer.borderWidth = 1
            followButton.layer.borderColor = UIColor(hex: "#E5E5E5").cgColor
        } else {
            followButton.setTitle("添加关注", for: .normal)
            let gradientColor = UIColor.gradientTextColor(
                size: CGSize(width: 230, height: 30),
                colors: sy_gradientArr)
            followButton.setTitleColor(gradientColor, for: .normal)
            followButton.backgroundColor = AppColor.buttonDark
            followButton.layer.borderWidth = 0
            followButton.layer.borderColor = nil
        }
    }

    // MARK: - 手势绑定

    private func setupGestures() {
        followButton.addTarget(self, action: #selector(followTapped), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)
        wechatViewButton.addTarget(self, action: #selector(wechatViewTapped), for: .touchUpInside)
    }

    @objc private func followTapped() {
        guard let model = model else { return }
        let userId = "\(model.userId)"
        guard !userId.isEmpty else { return }

        let isCurrentlyFollowed = model.isFollow == 1
        let newFollowState = !isCurrentlyFollowed

        updateFollowButton(isFollowed: newFollowState)

        NetworkManager.shared
            .request(ActivityDetailAPI.focusOn(followUid: userId), as: APIResponse<EmptyData>.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                if case let .failure(error) = completion {
                    self.updateFollowButton(isFollowed: isCurrentlyFollowed)
                    self.showToast(error.localizedDescription)
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                if response.code != 0 {
                    self.updateFollowButton(isFollowed: isCurrentlyFollowed)
                    self.showToast(response.message ?? "操作失败")
                } else {
                    self.model?.isFollow = newFollowState ? 1 : 0
                }
            }
            .store(in: &cancellables)
    }

    @objc private func copyTapped() {
        guard let model = model else { return }
        UIPasteboard.general.string = model.usercode
        showToast("ID已复制")
    }

    @objc private func wechatViewTapped() {
        guard let model = model, !model.wechatAccount.isEmpty else {
            showToast("对方暂未添加微信号")
            return
        }
        
        if model.unlockWechat == 1 {
            // 已解锁：直接复制微信号
            UIPasteboard.general.string = model.wechatAccount
            showToast("微信号已复制")
        } else {
            // 未解锁：调用解锁逻辑，type == 2
            tryDiamondUnlock(userId: model.userId, type: .wechat) { [weak self] success in
                if success, let self = self {
                    // 解锁成功，重新请求服务器获取完整信息
                    NetworkManager.shared
                        .request(ActivityDetailAPI.personalHomepage(userId: "\(model.userId)"), as: PersonalHomepageDataModel.self)
                        .receive(on: DispatchQueue.main)
                        .sink { completion in
                            switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                print("❌ [PersonalHomepage] 请求失败: \(error)")
                            }
                        } receiveValue: { [weak self] newModel in
                            guard let self = self else { return }
                            // 更新模型并刷新UI
                            self.model = newModel
                            // 复制微信号
                            UIPasteboard.general.string = newModel.wechatAccount
                            self.showToast("微信号已复制")
                        }
                        .store(in: &cancellables)
                }
            }
        }
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    /// 隐藏微信号中间部分，显示格式为 "前2位****后3位"
    private func maskWechatAccount(_ wechat: String) -> String {
        guard wechat.count > 5 else {
            return wechat
        }
        
        let prefix = String(wechat.prefix(2))
        let suffix = String(wechat.suffix(3))
        return "\(prefix)****\(suffix)"
    }

    // MARK: - 喜欢的活动类型标签

    /// 活动类型容器高度约束
    private var activityTypeHeightConstraint: Constraint?

    private func setupActivityTypeTags() {
        guard let model = model else { return }

        activityTypeTagsContainer.subviews.forEach { $0.removeFromSuperview() }

        let tagNames = model.likePersonLabel
        guard !tagNames.isEmpty else {
            activityTypeContainer.isHidden = true
            activityTypeHeightConstraint?.update(offset: 0)
            return
        }

        activityTypeContainer.isHidden = false

        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        let spacing: CGFloat = 8
        let lineHeight: CGFloat = 28

        for name in tagNames {
            let tagButton = createTagButton(title: name)
            activityTypeTagsContainer.addSubview(tagButton)

            let tagWidth = tagButton.intrinsicContentSize.width

            if currentX + tagWidth > UIScreen.main.bounds.width - 40 {
                currentX = 0
                currentY += lineHeight + spacing
            }

            tagButton.frame = CGRect(x: currentX, y: currentY, width: tagWidth, height: lineHeight)
            currentX += tagWidth + spacing
        }

        let headerHeight: CGFloat = 15
        let headerSpacing: CGFloat = 12
        let bottomPadding: CGFloat = 16
        let totalHeight = headerHeight + headerSpacing + currentY + lineHeight + bottomPadding

        activityTypeHeightConstraint?.update(offset: totalHeight)
        innerContainer.setNeedsLayout()
        innerContainer.layoutIfNeeded()
    }

    private func createTagButton(title: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13)
        let gtc = UIColor.gradientTextColor(
            size: CGSize(width: 80.fit, height: 28.fit),
            colors: [UIColor(hex: "#A2EF4D"), UIColor(hex: "#C2FF7F")]
        )
        button.backgroundColor = gtc
        
        button.layer.cornerRadius = 14
        button.clipsToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        return button
    }

    // MARK: - Image Preview

    private func showImagePreview(initialIndex: Int) {
        guard let model = model else { return }

        let imageUrls: [String]
        if !model.headAlbum.isEmpty {
            imageUrls = model.headAlbum.map { AppConfig.API.fullImageURL(path: $0) }
        } else {
            imageUrls = [AppConfig.API.fullImageURL(path: model.avatar)]
        }
        let vc = ImagePreviewController(imageUrls: imageUrls, initialIndex: initialIndex)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension PersionViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === tagsCollectionView {
            return currentTags.count
        }
        
        if let count = model?.album.count, count > 0 {
            return count
        }
        // 当没有相册照片时，显示1张头像
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === tagsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagDisplayCell.reuseId, for: indexPath) as! TagDisplayCell
            cell.configure(with: currentTags[indexPath.item])
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumCell", for: indexPath) as! AlbumCell
        if let albumArray = model?.album, indexPath.item < albumArray.count {
            let album = albumArray[indexPath.item]
            let url = AppConfig.API.fullImageURL(path: album.url)
            cell.configure(url: url)
        } else if let avatar = model?.avatar {
            // 没有相册照片时显示头像
            let url = AppConfig.API.fullImageURL(path: avatar)
            cell.configure(url: url)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === tagsCollectionView {
            let font = UIFont.systemFont(ofSize: 14)
            let tag = currentTags[indexPath.item]
            let text = "# \(tag)"
            let textWidth = text.size(withAttributes: [.font: font]).width
            let cellWidth = textWidth + 24
            return CGSize(width: cellWidth, height: 24)
        }
        
        return CGSize(width: 80, height: 80)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === tagsCollectionView {
            return
        }
        
        guard let model = model else { return }
        let imageUrls: [String]
        if !model.album.isEmpty {
            imageUrls = model.album.map { AppConfig.API.fullImageURL(path: $0.url) }
        } else {
            // 没有相册照片时，图片预览显示头像
            imageUrls = [AppConfig.API.fullImageURL(path: model.avatar)]
        }
        let vc = ImagePreviewController(imageUrls: imageUrls, initialIndex: indexPath.item)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
}

// MARK: - UITableViewDataSource & Delegate

extension PersionViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taActivities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ActivityCell.reuseID, for: indexPath) as! ActivityCell
        let activity = taActivities[indexPath.row]
        cell.configure(activity)
        cell.onActionTapped = { [weak self] model in
            guard let self = self else { return }
            let detailVC = ActivityDetailViewController(activityModel: model)
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let activity = taActivities[indexPath.row]
        let detailVC = ActivityDetailViewController(activityModel: activity)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - Album Cell

final class AlbumCell: UICollectionViewCell {

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = UIColor(hex: "#E5E5E5")
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(url: String) {
        imageView.kf.setImage(with: URL(string: url))
    }
}
