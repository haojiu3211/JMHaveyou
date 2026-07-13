//
//  ActivityDetailViewController.swift
//  haveseeyou
//
//  活动详情页 - 包含 Banner 轮播、发布者信息、活动详情、底部操作按钮
//

import UIKit
import SnapKit
import Combine
import Kingfisher
import NEChatKit
import NIMSDK

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

final class ActivityDetailViewController: BaseViewController,UIScrollViewDelegate {
    
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
    
    /// 防止重复点击 PersionViewController 的标志
    private var isPushingUserProfile = false

    // MARK: - ViewModel

    private let viewModel: ActivityDetailViewModel

    /// 标记是否已经给当前发布者发送过"我感兴趣"问候消息，避免每次 UI 刷新都重发
    

    // MARK: - UI 组件

    /// Banner 轮播
    private let bannerView = DetailBannerView()

    /// 发布者头像
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 25
        iv.backgroundColor = UIColor(hex: "#E5E5E5")
        iv.isUserInteractionEnabled = true
        return iv
    }()

    /// 发布者昵称
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = AppColor.textMain
        return l
    }()
    
    private let genderImageView:UIImageView = {
        let iv = UIImageView();
        return iv
    }()
    /// 年龄标签
    private let ageLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = AppColor.textSecondary
        return l
    }()
    
    /// 星座标签
    private let constellationLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = AppColor.textSecondary
        return l
    }()

    /// 添加关注按钮
    private let followButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        btn.layer.cornerRadius = 16
        btn.clipsToBounds = true
        return btn
    }()

    /// 更多按钮（...）
    private let moreButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "sy_detail_more"), for: .normal)
        
        return btn
    }()

    /// 发布者区域容器
    private let publisherContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.isUserInteractionEnabled = true
        return v
    }()

    /// 活动详情卡片容器
    private let detailCard: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    /// 活动标题
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = AppColor.textMain
        l.numberOfLines = 0
        return l
    }()

    /// 活动类型标签
    private let categoryLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColor.textSecondary
        l.backgroundColor = UIColor(hex: "#FFF5F5F5")
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        return l
    }()

    /// 状态标签
    private let statusImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "sy_detai_ing"))
      
        return iv
    }()

    /// 性别要求标签
    private let genderLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColor.textSecondary
        return l
    }()

    /// 组队人数标签
    private let teamLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColor.textSecondary
        return l
    }()

    /// 活动时间
    private let timeIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "sy_detai_time"))
        iv.tintColor = AppColor.textSecondary
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = AppColor.textMain
        return l
    }()

    /// 活动费用
    private let feeIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "sy_detai_money"))
        iv.tintColor = AppColor.textSecondary
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    private let feeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = AppColor.textMain
        return l
    }()

    /// 活动地址
    private let locationIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "sy_detai_local"))
        iv.tintColor = AppColor.textSecondary
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    private let locationLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = AppColor.textMain
        return l
    }()

    /// 注意事项标题
    private let noticeHeaderLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = AppColor.textMain
        l.text = "注意事项"
        return l
    }()

    /// 注意事项内容
    private let noticeContentLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = AppColor.textSecondary
        l.numberOfLines = 0
        return l
    }()

    /// 注意事项背景
    private let noticeBgView: UIView = {
        let v = UIView()
        v.backgroundColor = AppColor.background
        v.layer.cornerRadius = 8
        v.clipsToBounds = true
        return v
    }()

    /// 滚动容器
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.backgroundColor = .clear
        return sv
    }()

    /// 滚动内容容器（手动布局，支持 banner 与内容卡片重叠）
    private let contentView = UIView()

    /// 白色内容卡片（覆盖在 banner 上面，顶部圆角）
    private let contentCardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner
        ]
        v.layer.masksToBounds = true
        return v
    }()

    /// 内容卡片内部纵向堆栈
    private let innerStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 0
        sv.alignment = .fill
        return sv
    }()

    /// 底部操作区域
    private let bottomBar: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }()

    /// 我感兴趣按钮
    private let interestedButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btn.layer.cornerRadius = 24
        btn.clipsToBounds = true
        return btn
    }()

    /// 报名活动须知按钮
    private let noticeLinkButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = .systemFont(ofSize: 13)
        btn.setTitleColor(AppColor.textSecondary, for: .normal)
        btn.setTitle("报名活动须知", for: .normal)
        btn.setUnderlinedTitle("报名活动须知")
        return btn
    }()

    /// 举报拉黑弹框
    private var reportBlockAlert: ReportBlockAlertView?
    /// 当前页面内是否已拉黑当前发布者，仅用于本次进入页面的按钮文案切换
    private var isBlockedInCurrentSession = false

    // MARK: - Init

    init(activityModel: ActivityModel) {
        self.viewModel = ActivityDetailViewModel(activityModel: activityModel)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }
    // MARK: - 透明导航栏
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // SDK 聊天页 (NEChatBaseViewController) 进入时会把 isNavigationBarHidden = true，
        // 且 pop 时不会还原；BaseViewController.viewWillAppear 又会先强制把 navBar 改成白底，
        // 所以这里要显式：1) 让 navBar 立刻显示  2) 覆盖透明外观  3) 等 pop 动画结束再写一次
        // （动画进行中 transitionCoordinator 会把中间帧的外观覆盖回来）。
        navigationController?.setNavigationBarHidden(false, animated: false)
        configureTransparentNavigationBar()

        if let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.navigationController?.setNavigationBarHidden(false, animated: false)
                self?.configureTransparentNavigationBar()
            }
        }
    }

    /// 配置透明导航栏：背景透明 + 返回按钮白色 + 标题白色
    /// 写到 `navigationItem.*Appearance`（per-VC），pop 回本页时由系统自动按本 VC 的外观应用，
    /// 避免被 SDK 聊天页改全局 `navigationBar.standardAppearance` 影响。
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

        // per-VC 外观（iOS 15+ 起优先级最高，pop 回时系统会自动按这套外观应用）
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationItem.compactScrollEdgeAppearance = appearance
        }

        // 同步刷一次全局 navBar，避免 pop 动画进行中那一帧出现错样式
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.tintColor = .white

        // 返回按钮颜色改为白色
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

        UIGraphicsBeginImageContextWithOptions(
            size,
            false,
            UIScreen.main.scale
        )

        guard let ctx = UIGraphicsGetCurrentContext() else {
            return nil
        }

        gradientLayer.render(in: ctx)

        let image = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return image
    }
    /// 页面消失时恢复导航栏默认外观，避免影响其他页面
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        restoreNavigationBarAppearance()
    }

    private func restoreNavigationBarAppearance() {
        guard let navBar = navigationController?.navigationBar else { return }
        // 恢复到 BaseViewController 的白底外观
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
        view.backgroundColor = .white

        // 导航栏透明：scrollView 从屏幕顶部开始，内容延伸到 nav bar 区域下方
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        navigationItem.title = "活动详情"
        
        // 只在 Present 模式下显示关闭按钮
        if isPresented {
            let closeButton = UIBarButtonItem(image: UIImage(named: "member_navBack_bg"), style: .plain, target: self, action: #selector(closeTapped))
            closeButton.tintColor = .white
            navigationItem.leftBarButtonItem = closeButton
        }

        view.addSubviews(scrollView, bottomBar)
        scrollView.addSubview(contentView)

        // scrollView 从屏幕最顶部开始，让 banner 延伸到 nav bar 下方
        scrollView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
        }
        bottomBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(20)
            make.height.equalTo(90)
        }

        contentView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.width.equalToSuperview()
            make.bottom.equalToSuperview().priority(.low)
            make.height.greaterThanOrEqualTo(600)
            // 不设 bottom，让内容由子视图撑开，scrollView 才能滚动
        }

        // 组装内容区域：banner + 覆盖在 banner 上的白色卡片
        setupBannerSection()
        setupContentCard()

        // 底部操作区域
        setupBottomBar()

        // 手势绑定
        setupGestures()
    }

    // MARK: - Banner 区域

    private func setupBannerSection() {
        contentView.addSubview(bannerView)
        // Banner 高度包含导航栏 + 状态栏区域，让图片从屏幕最顶部铺满
        // 导航栏区域约 91pt（status bar 47 + nav bar 44），加上可视 banner 260pt = 351pt
        bannerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(500)
        }
    }

    // MARK: - 白色内容卡片（覆盖在 Banner 上面）

    private func setupContentCard() {
        contentView.addSubview(contentCardView)
        contentCardView.addSubview(innerStack)

        // contentCardView 顶部向上偏移 20pt 覆盖 banner，形成浮层效果
        contentCardView.snp.makeConstraints { make in
            make.top.equalTo(bannerView.snp.bottom).offset(-20)
            make.left.right.bottom.equalToSuperview()
        }

        innerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        // 组装卡片内部内容
        setupPublisherSection()
        setupDetailSection()
        setupNoticeSection()
    }

    // MARK: - 发布者区域

    private func setupPublisherSection() {
        publisherContainer.addSubviews(avatarImageView, nameLabel, genderImageView, ageLabel, constellationLabel, followButton, moreButton)

        innerStack.addArrangedSubview(publisherContainer)
        publisherContainer.snp.makeConstraints { make in
            make.height.equalTo(70)
        }

        avatarImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 50, height: 50))
        }

        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView.snp.right).offset(12)
            make.top.equalToSuperview().offset(14)
        }
        
        genderImageView.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(6)
            make.size.equalTo(CGSizeMake(12, 12))
        }
        
        ageLabel.snp.makeConstraints { make in
            make.left.equalTo(genderImageView.snp.right).offset(2)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
        }
        
        constellationLabel.snp.makeConstraints { make in
            make.left.equalTo(ageLabel.snp.right).offset(12)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
        }

        moreButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        // 添加关注按钮
        followButton.snp.makeConstraints { make in
            make.right.equalTo(moreButton.snp.left).offset(-7)
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
            make.width.equalTo(80)
        }

       
    }

    // MARK: - 活动详情卡片

    private func setupDetailSection() {
        detailCard.addSubviews(titleLabel, categoryLabel, statusImageView, genderLabel, teamLabel,
                               timeIcon, timeLabel, feeIcon, feeLabel, locationIcon, locationLabel)

        innerStack.addArrangedSubview(detailCard)
        detailCard.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(200)
        }

        // 活动标题
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().inset(80)
        }

        // 活动类型
        categoryLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
        }

        // 状态标签
        statusImageView.snp.makeConstraints { make in
            make.top.equalTo(categoryLabel.snp.bottom).offset(13)
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(18)
            make.width.equalTo(46)
        }

        // 性别要求
        genderLabel.snp.makeConstraints { make in
            make.left.equalTo(statusImageView.snp.right).offset(10)
            make.centerY.equalTo(statusImageView)
        }

        // 组队人数
        teamLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalTo(statusImageView)
        }

        // 分隔线
        let sepView = UIView()
        sepView.backgroundColor = UIColor(hex: "#F0F0F0")
        detailCard.addSubview(sepView)
        sepView.snp.makeConstraints { make in
            make.top.equalTo(statusImageView.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(0.5)
        }

        // 活动时间
        timeIcon.snp.makeConstraints { make in
            make.top.equalTo(sepView.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(CGSize(width: 16, height: 16))
        }
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(timeIcon.snp.right).offset(8)
            make.centerY.equalTo(timeIcon)
            make.right.equalToSuperview().inset(16)
        }

        // 活动费用
        feeIcon.snp.makeConstraints { make in
            make.top.equalTo(timeIcon.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(CGSize(width: 16, height: 16))
        }
        feeLabel.snp.makeConstraints { make in
            make.left.equalTo(feeIcon.snp.right).offset(8)
            make.centerY.equalTo(feeIcon)
            make.right.equalToSuperview().inset(16)
        }

        // 活动地址
        locationIcon.snp.makeConstraints { make in
            make.top.equalTo(feeIcon.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(CGSize(width: 16, height: 16))
        }
        locationLabel.snp.makeConstraints { make in
            make.left.equalTo(locationIcon.snp.right).offset(8)
            make.centerY.equalTo(locationIcon)
            make.right.equalToSuperview().inset(16)
        }

        // 底部 padding
        let bottomSpacer = UIView()
        detailCard.addSubview(bottomSpacer)
        bottomSpacer.snp.makeConstraints { make in
            make.top.equalTo(locationIcon.snp.bottom).offset(16)
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(8)
        }
    }

    // MARK: - 注意事项区域

    private func setupNoticeSection() {
        let noticeContainer = UIView()
        noticeContainer.backgroundColor = .white
        noticeContainer.layer.cornerRadius = 14
        noticeContainer.clipsToBounds = true

        noticeContainer.addSubviews(noticeHeaderLabel, noticeBgView)
        noticeBgView.addSubview(noticeContentLabel)

        innerStack.addArrangedSubview(noticeContainer)
        noticeContainer.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(80)
        }

        noticeHeaderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
        }

        noticeBgView.snp.makeConstraints { make in
            make.top.equalTo(noticeHeaderLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }

        noticeContentLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
    }

    // MARK: - 底部操作栏

    private func setupBottomBar() {
        bottomBar.addSubviews(interestedButton, noticeLinkButton)

        interestedButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }

        noticeLinkButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(interestedButton.snp.bottom).offset(4)
        }

        interestedButton.addTarget(self, action: #selector(interestedTapped), for: .touchUpInside)
        noticeLinkButton.addTarget(self, action: #selector(noticeLinkTapped), for: .touchUpInside)
    }

    // MARK: - 手势绑定

    private func setupGestures() {
        // 整个发布者区域点击
        let publisherTap = UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        publisherContainer.addGestureRecognizer(publisherTap)

        // 更多按钮
        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)

        // 关注按钮
        followButton.addTarget(self, action: #selector(followTapped), for: .touchUpInside)

        // Banner 图片点击
        bannerView.onImageTapped = { [weak self] index in
            self?.viewModel.didTapBannerImage(at: index)
        }
    }
    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        if scrollView.contentOffset.y < 0 {

            scrollView.contentOffset.y = 0
        }
    }
    // MARK: - BindViewModel

    override func bindViewModel() {
        // 详情数据加载
        viewModel.$detail
            .receive(on: DispatchQueue.main)
            .sink { [weak self] detail in
                guard let detail, let self else { return }
                self.updateUI(with: detail)
            }
            .store(in: &cancellables)

        // 关注状态变更
        viewModel.$isFollowed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFollowed in
                self?.updateFollowButton(isFollowed: isFollowed)
            }
            .store(in: &cancellables)

        // 感兴趣状态变更
        viewModel.$isInterested
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isInterested in
                self?.updateInterestedButton(isInterested: isInterested)
            }
            .store(in: &cancellables)

        // 错误订阅
        viewModel.errorSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                self?.showToast(msg)
            }
            .store(in: &cancellables)

        // 跳转个人资料页
        viewModel.gotoUserProfileSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userId in
                self?.pushUserProfile(userId: userId)
            }
            .store(in: &cancellables)

        // 显示举报拉黑弹框
        viewModel.showReportBlockSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userId in
                self?.showReportBlockAlert(userId: userId)
            }
            .store(in: &cancellables)

        viewModel.blockSuccessSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.isBlockedInCurrentSession.toggle()
            }
            .store(in: &cancellables)

        // 跳转聊天页：感兴趣接口成功后由 ViewModel 触发
        // 这里先用 IMManager.sendHello 给发布者发一条问候消息，发送回调里再 push 单聊页，
        // 保证用户进入聊天页时已经能在历史里看到那条消息。
        viewModel.gotoChatSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userId, shouldSendMessage in
                guard let self = self, !userId.isEmpty else { return }
                
                if shouldSendMessage {
                    // 发送消息后跳转
                    let title = self.viewModel.detail?.title ?? ""
                    let category = self.viewModel.detail?.category ?? ""
                    
                    let messageText = """
                    活动标题：\(title)
                    活动类型：\(category)
                    
                    你好，我对你发布的这个活动很感兴趣。
                    """
                    
                    IMManager.shared.sendHello(toAccountId: userId,
                                               text: messageText) { [weak self] error in
                        DispatchQueue.main.async {
                            guard let self = self else { return }
                            if let error = error {
                                self.showToast(error.localizedDescription)
                            }
                            // 不管发送是否成功都进入聊天页（失败时已 toast 提示）
                            self.pushChat(withAccountId: userId)
                        }
                    }
                } else {
                    // 直接跳转聊天页
                    self.pushChat(withAccountId: userId)
                }
            }
            .store(in: &cancellables)

        // 跳转 H5 页面
        viewModel.gotoH5PageSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in
                self?.pushH5Page(url: url)
            }
            .store(in: &cancellables)

        // 跳转图片浏览器
        viewModel.gotoImagePreviewSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                self?.pushImagePreview(initialIndex: index)
            }
            .store(in: &cancellables)

        viewModel.loadDetail()
    }

    // MARK: - UI 更新

    private func updateUI(with detail: ActivityDetailModel) {
        // Banner
        bannerView.configure(detail.imageUrls)

        // 发布者信息
        genderImageView.image = UIImage(named: detail.publisher.gender == 1 ? "sy_detail_female" : "sy_detail_male")
//        avatarImageView.image = UIImage(named: detail.publisher.avatarUrl)
       
        let fullURLString: String = AppConfig.API.fullImageURL(path: detail.publisher.avatarUrl)
        if let imageURL = URL(string: fullURLString) {
                avatarImageView.kf.setImage(
                    with: imageURL,
                    placeholder: UIImage(named: "app_default_avatar")
                )
        }
        
            
        nameLabel.text = detail.publisher.nickName
        ageLabel.text = detail.publisher.age
        constellationLabel.text = detail.publisher.constellation

        // 关注状态
        updateFollowButton(isFollowed: detail.isFollowed)

        // 感兴趣状态
        updateInterestedButton(isInterested: detail.isInterested)

        // 活动详情
        titleLabel.text = detail.title
        categoryLabel.text = "活动类型：" + detail.category

        // 状态
        switch detail.status {
        case .ongoing:
            statusImageView.image = UIImage(named: "sy_detai_ing")
        case .pending:
            statusImageView.image = UIImage(named: "sy_detai_ing")
        case .expired:
            statusImageView.image = UIImage(named: "sy_detai_ing")
        }

        genderLabel.text = detail.genderRequirement
        teamLabel.text = "组队人数：" + detail.teamCount
        timeLabel.text = "活动时间：" + detail.activityTime
        feeLabel.text = "活动费用：" + detail.fee
        locationLabel.text = "活动地址：" + detail.location

        // 注意事项
        noticeContentLabel.text = detail.notice
    }

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
                size: CGSize(width: 80, height: 30),
                colors: sy_gradientArr)
            
            followButton.setTitleColor(gradientColor, for: .normal)
            followButton.backgroundColor = AppColor.buttonDark
            followButton.layer.borderWidth = 0
            followButton.layer.borderColor = nil
        }
    }

    private func updateInterestedButton(isInterested: Bool) {
        if isInterested {
            let gradientColor = UIColor.gradientTextColor(
                size: CGSize(width: 200, height: 30),
                colors: sy_gradientArr
            )
            
            interestedButton.setTitleColor(gradientColor, for: .normal)
            interestedButton.backgroundColor = AppColor.buttonDark
            interestedButton.setTitle("已感兴趣", for: .normal)
//            interestedButton.setTitleColor(AppColor.textMain, for: .normal)
//            interestedButton.backgroundColor = AppColor.tagExpired
//            interestedButton.isEnabled = false
        } else {
            let gradientColor = UIColor.gradientTextColor(
                size: CGSize(width: 200, height: 30),
                colors: sy_gradientArr
            )
            
            interestedButton.setTitleColor(gradientColor, for: .normal)
            interestedButton.backgroundColor = AppColor.buttonDark
            interestedButton.setTitle("我感兴趣", for: .normal)
//            interestedButton.isEnabled = true
        }
    }

    /// 跳转到与指定账号的单聊页
    private func pushChat(withAccountId accountId: String) {
        guard let cid = V2NIMConversationIdUtil.p2pConversationId(accountId) else { return }

        let vc = HSYP2PChatViewController(conversationId: cid)
        
        self.present(vc, animated: true)
    }

    // MARK: - Actions

    @objc private func followTapped() {
        viewModel.toggleFollow()
    }

    @objc private func interestedTapped() {
        print("🎯 [ActivityDetail] interestedTapped 被点击")
        
        if AuditConfigManager.shared.isAudit {
            // 审核模式 UI
            if viewModel.isInterested {
                viewModel.goToChat()
            }else {
                self.viewModel.markInterested()
            }
            
            
            return
        }
        
        if viewModel.isInterested {
            // 已感兴趣时，直接跳转聊天
            print("✅ [ActivityDetail] 已感兴趣，直接跳转聊天")
            if (isPresented){
                dismiss(animated: true) {
                    
                }
            }else {
                viewModel.goToChat()
            }
            return
        }
        
        // 未感兴趣时，先检查解锁状态
        guard let publisherId = viewModel.detail?.publisher.userId, let uid = Int(publisherId) else {
            print("❌ [ActivityDetail] 无法获取发布者用户ID")
            viewModel.markInterested()
            return
        }
        
        print("🔍 [ActivityDetail] 开始调用 unlockPrivateStatus 检查解锁状态，publisherId: \(uid)")
        
        // 调用 unlockPrivateStatus 检查是否已解锁 - 使用 APIResponse 包裹来直接检查 code
        NetworkManager.shared.request(PurchaseAPI.unlockPrivateStatus(toUid: uid), as: APIResponse<UnlockPrivateStatusResponse>.self) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let wrappedResponse):
                print("✅ [ActivityDetail] unlockPrivateStatus 原始响应，code: \(wrappedResponse.code), message: \(wrappedResponse.message ?? "nil")")
                
                DispatchQueue.main.async {
                    if wrappedResponse.code == 0 {
                        // 业务成功
                        if let response = wrappedResponse.data, response.isUnlocked == 1 {
                            // 已解锁，直接标记感兴趣并跳转
                            print("🎉 [ActivityDetail] 已解锁，标记感兴趣并跳转")
                            self.viewModel.markInterested()
                        } else {
                            // 未解锁，尝试调用 diamondUnlock
                            print("🔓 [ActivityDetail] 未解锁，尝试调用 diamondUnlock")
                            self.tryDiamondUnlock(publisherId: uid)
                        }
                    } else {
                        // 业务失败（code != 0），也尝试调用 diamondUnlock
                        print("⚠️ [ActivityDetail] unlockPrivateStatus 业务失败，code: \(wrappedResponse.code), message: \(wrappedResponse.message ?? "nil")")
                        self.tryDiamondUnlock(publisherId: uid)
                    }
                }
                
            case .failure(let error):
                print("❌ [ActivityDetail] unlockPrivateStatus 调用失败: \(error)")
                // 失败也尝试调用 diamondUnlock
                DispatchQueue.main.async {
                    self.tryDiamondUnlock(publisherId: uid)
                }
            }
        }
    }
    
    private func tryDiamondUnlock(publisherId: Int) {
        let unlockType = UnlockType.message.rawValue
        let decCoin = getDecCoin(for: unlockType)
        
        print("💎 [ActivityDetail] 开始调用 diamondUnlock，publisherId: \(publisherId), type: \(unlockType) (私信), decCoin: \(decCoin)")
        
        // 直接使用 ActivitySimpleResponse，NetworkManager 会直接解析它，不会先尝试解析 APIResponse
        NetworkManager.shared.request(PurchaseAPI.diamondUnlock(type: unlockType, toUid: publisherId, decCoin: decCoin), as: ActivitySimpleResponse.self) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                print("📋 [ActivityDetail] diamondUnlock 原始响应，code: \(response.code), message: \(response.message ?? "nil")")
                
                DispatchQueue.main.async {
                    if response.code == 0 || response.code == 1 {
                        // 业务成功(code == 0) 或者已经解锁过了(code == 1)，都直接标记感兴趣并跳转
                        print("✅ [ActivityDetail] diamondUnlock 成功或已解锁，code: \(response.code)")
                        self.viewModel.markInterested()
                    } else {
                        // 其他业务失败（code != 0 且 != 1），特别是 1003 余额不足
                        print("⚠️ [ActivityDetail] diamondUnlock 业务失败，code: \(response.code), message: \(response.message ?? "nil")")
                        self.showUnlockFailedAlert()
                    }
                }
                
            case .failure(let error):
                print("❌ [ActivityDetail] diamondUnlock 调用失败: \(error)")
                
                // 尝试从错误中提取业务码（如果是 APIError.business）
                if case let APIError.business(code, message) = error {
                    print("📋 [ActivityDetail] 检测到业务错误，code: \(code), message: \(message)")
                    DispatchQueue.main.async {
                        if code == 0 || code == 1 {
                            // 即使解析失败，但如果错误中包含 code == 0 或 1，也直接跳转
                            print("✅ [ActivityDetail] 从错误中检测到成功，code: \(code)")
                            self.viewModel.markInterested()
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
        print("⚠️ [ActivityDetail] 显示解锁失败弹窗")
        
        let isVip = (UserManager.shared.vip ?? 0) > 0
        print("👤 [ActivityDetail] 用户 VIP 状态: \(isVip ? "VIP" : "普通用户")")
        
        if isVip {
            // VIP 用户：单按钮弹窗
            print("📱 [ActivityDetail] 显示 VIP 用户单按钮弹窗")
            AppAlert.showSingle(
                title: "提示",
                message: "您今日 VIP 次数使用完毕，可充值活动币无限畅聊。",
                confirmText: "充值活动币",
                messageAlignment: .center
            ) { [weak self] in
                print("💰 [ActivityDetail] 用户点击了充值活动币")
                self?.pushWallet()
            }
        } else {
            // 普通用户：双按钮弹窗
            print("📱 [ActivityDetail] 显示普通用户双按钮弹窗")
            AppAlert.showDouble(
                title: "提示",
                message: "您的活动币余额不足，请选择以下权益进行开通。",
                cancelText: "开通会员",
                confirmText: "充值活动币",
                messageAlignment: .center,
                onCancel: { [weak self] in
                    print("💎 [ActivityDetail] 用户点击了开通会员")
                    self?.pushMemberCenter()
                },
                onConfirm: { [weak self] in
                    print("💰 [ActivityDetail] 用户点击了充值活动币")
                    self?.pushWallet()
                }
            )
        }
    }
    
    
    private func pushWallet() {
        print("🚀 [ActivityDetail] 跳转到钱包页面")
        let vc = MyWalletViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func pushMemberCenter() {
        print("🚀 [ActivityDetail] 跳转到会员中心页面")
        let vc = MemberCenterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func avatarTapped() {
        viewModel.didTapAvatar()
    }

    @objc private func moreTapped() {
        viewModel.didTapMore()
    }

    @objc private func noticeLinkTapped() {
        let web = WebViewController(urlString: webUrlActivityNotice)
        navigationController?.pushViewController(web, animated: true)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - 导航跳转

    private func pushUserProfile(userId: String) {
        guard !isPushingUserProfile else { return }
        isPushingUserProfile = true
        
        // 请求用户个人主页信息
        NetworkManager.shared
            .request(ActivityDetailAPI.personalHomepage(userId: userId), as: PersonalHomepageDataModel.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isPushingUserProfile = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("❌ [PersonalHomepage] 请求失败: \(error)")
                }
            } receiveValue: { [weak self] model in
                guard let self = self else { return }
                
                print("✅ [PersonalHomepage] 请求成功")
                print("  昵称: \(model.nickname)")
                print("  年龄: \(model.age)")
                print("  性别: \(model.gender)")
                print("  城市: \(model.city)")
                print("  签名: \(model.sign)")
                print("  相册数量: \(model.album.count)")
                print("  动态数量: \(model.dynamicNum)")
                // DO: 把模型数据传给控制器展示
                let vc = PersionViewController()
                vc.model = model
                self.navigationController?.pushViewController(vc, animated: true)
            }
            .store(in: &cancellables)
    }

    private func pushH5Page(url: String) {
        // TODO: 接入 H5 WebView 页面
        showToast("跳转 H5 页面：\(url)")
    }

    private func pushImagePreview(initialIndex: Int) {
        guard let detail = viewModel.detail else { return }
        let vc = ImagePreviewController(imageUrls: detail.imageUrls, initialIndex: initialIndex)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }

    // MARK: - 举报拉黑弹框

    private func showReportBlockAlert(userId: String) {
        let alert = ReportBlockAlertView()
        alert.setBlockButtonTitle(isBlockedInCurrentSession ? "取消拉黑" : "拉黑")
        alert.onReportTapped = { [weak self] in
            let vc = HelpFeedbackViewController(userId: userId)
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        alert.onBlockTapped = { [weak self] in
            self?.viewModel.blockUser(userId: userId)
        }
        alert.show(in: view)
        reportBlockAlert = alert
    }
    
    deinit {
        // 清理引用
        reportBlockAlert?.onReportTapped = nil
        reportBlockAlert?.onBlockTapped = nil
        reportBlockAlert?.onCancelTapped = nil
        reportBlockAlert = nil
        
        // 清空 Combine 订阅
        cancellables.removeAll()
        
        #if DEBUG
        print("✅ [ActivityDetailViewController] 已释放")
        #endif
    }
}

// MARK: - UIButton 下划线扩展

private extension UIButton {
    func setUnderlinedTitle(_ title: String) {
        let attrs: [NSAttributedString.Key: Any] = [
//            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: AppColor.textSecondary,
            .font: UIFont.systemFont(ofSize: 13)
        ]
        let attrString = NSAttributedString(string: title, attributes: attrs)
        setAttributedTitle(attrString, for: .normal)
    }
}
