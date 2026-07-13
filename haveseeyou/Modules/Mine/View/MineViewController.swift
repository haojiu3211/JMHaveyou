//
//  MineViewController.swift
//  haveseeyou
//

import UIKit
import SnapKit
import Kingfisher
import Combine


final class MineViewController: BaseViewController {

    /// Tab根页面隐藏系统导航栏
    override var prefersNavigationBarHidden: Bool { true }
    /// 不使用标准返回按钮
    override var useStandardBackButton: Bool { false }

    // MARK: - UI Components

    // 顶部背景图
    private let headerBackgroundView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0.3, alpha: 1)
        return iv
    }()

    // 设置按钮
    private let settingsButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "me_setting"), for: .normal)
//        btn.imageView?.contentMode = .scaleAspectFit
     
        return btn
    }()

    // 内容容器（白色圆角卡片）
    private let contentCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    // 滚动视图
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        return sv
    }()

    private let contentView = UIView()

    // 头像
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 44.fit
        iv.backgroundColor = UIColor(white: 0.9, alpha: 1)
        // 占位图片
        iv.image = UIImage(named: "placeholder_avatar")
        return iv
    }()

    // 昵称
    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        return label
    }()

    private let ageImageView: UIImageView = {
        let iv = UIImageView()
        
        return iv
    }()
     
    // 年龄标签
    private let ageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .white
//        label.backgroundColor = UIColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1)
//        label.textAlignment = .center
//        label.layer.cornerRadius = 10
//        label.clipsToBounds = true
        return label
    }()

    // 性别标签
    private let shiMImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "me_shiming"))
        
        return iv
    }()
    
    // vip标签
    private let vipStateImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "me_vip_state"))
        
        return iv
    }()

    // 编辑按钮
    private let editButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("编辑", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.backgroundColor = .black
        btn.layer.cornerRadius = 15
        return btn
    }()

    // ID容器
    private let idContainerView = UIView()

    private let idLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14,weight: .medium)
        label.textColor = UIColor(white: 0.5, alpha: 1)
        return label
    }()

    private let copyButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setBackgroundImage(UIImage(named: "me_copy"), for: .normal)
        
        return btn
    }()

    // 个人简介
    private let bioLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(hex: "#FF888888")
        label.numberOfLines = 1
        return label
    }()
    
    // 统计数据视图
    private let profileHeaderView: ProfileHeaderView = {
        let view = ProfileHeaderView()
        return view
    }()
    
    // 内购付费Vip升级，钱包
    private let vipWalletCell: VIPWalletCell = {
        let view = VIPWalletCell()
        return view
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

    // 我发起的活动标题
    private let myActivitiesLabel: UILabel = {
        let label = UILabel()
        label.text = "我发起的活动"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        return label
    }()

    // MARK: - 我的相册相关组件
    // 我的相册标题
    private let myAlbumLabel: UILabel = {
        let label = UILabel()
        label.text = "我的相册"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        return label
    }()
    
    // 相册编辑按钮
    private let albumEditButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "me_photo_edit"), for: .normal)
        return btn
    }()
    
    // 相册编辑状态
    private var isAlbumEditing: Bool = false

    // 相册容器
    private let albumContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        return view
    }()

    // 相册 CollectionView
    private lazy var albumCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(PublishImageCell.self, forCellWithReuseIdentifier: PublishImageCell.identifier)
        return cv
    }()

    // 相册图片数据
    private var albumImages: [UIImage] = []
    // 相册网络数据
    private var albumItems: [MyAlbumItem] = []
    private let maxAlbumImageCount = 9

    // 空状态视图
    private let emptyStateView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    private let emptyImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "me_empty_pub")
        return iv
    }()

    // 活动列表 TableView
    private let activityTableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        tv.showsVerticalScrollIndicator = false
        tv.isScrollEnabled = false
        tv.register(MyActivityCardCell.self, forCellReuseIdentifier: MyActivityCardCell.reuseID)
        return tv
    }()

    // 活动数据源
    private var myActivities: [PublishModel] = []
    private var footprintTotal: Int = 0
    /// 标记当前页面周期是否已请求过 myLists，防止 viewWillAppear 多次触发导致重复请求
    private var hasLoadedMyActivities = false

    /// Combine 订阅持有
    private var mineCancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        registerNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !hasLoadedMyActivities {
            hasLoadedMyActivities = true
            // 1. 先加载缓存数据，立即展示
            loadCachedData()
            // 2. 再请求网络数据，更新页面并缓存
            fetchFootprintTotalThenUpdate()
            fetchAlbumList()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 离开页面时重置，下次进入可重新加载
        hasLoadedMyActivities = false
    }

    // MARK: - 缓存加载

    /// 从缓存加载数据，立即展示（viewWillAppear 第一步）
    private func loadCachedData() {
        // 从 UserManager 加载缓存的用户信息（personalCenter 接口缓存）
        loadUserData()

        // 加载缓存的足迹总数
        let cachedFootprint = UserDefaults.standard.integer(forKey: "mine_footprint_total")
        if cachedFootprint > 0 {
            footprintTotal = cachedFootprint
        }

        // 加载缓存的活动币
        let cachedCoin = UserDefaults.standard.integer(forKey: "mine_coin")
        vipWalletCell.updateCoinCount(cachedCoin)

        // 加载缓存的相册列表
        if let data = UserDefaults.standard.data(forKey: "mine_album_list"),
           let list = try? JSONDecoder().decode([MyAlbumItem].self, from: data) {
            albumItems = list
            albumCollectionView.reloadData()
        }

        // 加载缓存的统计数据（粉丝/关注/足迹/访客）
        if let numbers = UserDefaults.standard.array(forKey: "mine_usercount_numbers") as? [Int],
           numbers.count == 4 {
            profileHeaderView.updateNumbers(numbers)
        }

        // 加载我的活动（仅在此处调用一次，避免 loadUserData 多次触发导致重复请求）
        loadMyActivities()
    }

    // MARK: - 通知监听

    private func registerNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserInfoDidUpdate),
            name: .userInfoDidUpdate,
            object: nil
        )
    }

    @objc private func handleUserInfoDidUpdate() {
        print("🔄 MineViewController 收到用户资料更新通知，刷新展示")
        // 直接从 UserManager 加载本地数据刷新，不重新请求接口
        loadUserData()
    }

    override func setupUI() {
        view.backgroundColor = AppColor.background

        // 添加视图
        view.addSubview(headerBackgroundView)
        view.addSubview(settingsButton)
        view.addSubview(contentCardView)
        contentCardView.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // 布局顶部背景
        headerBackgroundView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(220)
        }

        // 设置按钮
        settingsButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.right.equalToSuperview().offset(-16)
            make.size.equalTo(26)
        }

        // 内容卡片
        contentCardView.snp.makeConstraints { make in
            make.top.equalTo(headerBackgroundView.snp.bottom).offset(-40)
            make.left.right.bottom.equalToSuperview()
        }

        // 滚动视图
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        setupContentViews()

        // 将设置按钮移到最上层，确保不被遮挡
        view.bringSubviewToFront(settingsButton)

        // 按钮事件
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(copyIdTapped), for: .touchUpInside)
        
        // VIPWalletCell 点击事件监听
        vipWalletCell.onVipTapped = { [weak self] in
            self?.handleVipTapped()
        }
        vipWalletCell.onWalletTapped = { [weak self] in
            self?.handleWalletTapped()
        }
        
        // ProfileHeaderView 点击事件监听
        profileHeaderView.onItemTapped = { [weak self] index in
            self?.handleProfileItemTapped(index: index)
        }
        
        // 相册编辑按钮点击事件
        albumEditButton.addTarget(self, action: #selector(toggleAlbumEdit), for: .touchUpInside)
    }

    private func setupContentViews() {
        // 添加所有内容视图
        contentView.addSubviews(
            avatarImageView,
            nicknameLabel,
            ageImageView,
            shiMImageView,
            vipStateImageView,
            editButton,
            idContainerView,
            bioLabel,
            profileHeaderView,
            vipWalletCell,
            tagsCollectionView,
            myAlbumLabel,
            albumEditButton,
            albumContainerView,
            myActivitiesLabel,
            emptyStateView,
            activityTableView
        )
        ageImageView.addSubview(ageLabel)
        idContainerView.addSubviews(idLabel, copyButton)
        emptyStateView.addSubviews(emptyImageView)
        albumContainerView.addSubview(albumCollectionView)

        // 头像
        avatarImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(11)
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(88.fit)
        }

        // 昵称
        nicknameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView.snp.right).offset(16)
            make.top.equalToSuperview().offset(18)
        }

        ageImageView.snp.makeConstraints { make in
            make.left.equalTo(nicknameLabel.snp.right).offset(4)
            make.centerY.equalTo(nicknameLabel)
            make.size.equalTo(CGSize(width: 32, height: 14))
        }
        
        // 年龄标签
        ageLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
//            make.width.equalTo(30)
            make.height.equalTo(14)
        }
        
        
        // 实名标签
        shiMImageView.snp.makeConstraints { make in
            make.left.equalTo(ageImageView.snp.right).offset(6)
            make.centerY.equalTo(ageImageView)
            make.width.equalTo(26)
            make.height.equalTo(14)
        }
        
        //vip标签
        vipStateImageView.snp.makeConstraints { make in
            make.left.equalTo(ageImageView.snp.right).offset(6)
            make.centerY.equalTo(ageImageView).offset(0)
            make.width.equalTo(45)
            make.height.equalTo(19)
        }
        

        // 编辑按钮
        editButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalTo(nicknameLabel)
            make.width.equalTo(60)
            make.height.equalTo(30)
        }

        // ID容器
        idContainerView.snp.makeConstraints { make in
            make.left.equalTo(nicknameLabel)
            make.top.equalTo(nicknameLabel.snp.bottom).offset(8)
        }

        idLabel.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
        }

        copyButton.snp.makeConstraints { make in
            make.left.equalTo(idLabel.snp.right).offset(8)
            make.centerY.equalTo(idLabel)
            make.right.top.bottom.equalToSuperview()
            make.size.equalTo(16)
        }

        // 个人简介
        bioLabel.snp.makeConstraints { make in
            make.left.equalTo(nicknameLabel)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(idContainerView.snp.bottom).offset(12)
        }

        // 统计数据视图 粉丝，关注，好友，访客
        profileHeaderView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(bioLabel.snp.bottom).offset(16)
            make.height.equalTo(60)
        }
        
        //内购部分会员/钱包
//        vipWalletCell.isHidden = true
        vipWalletCell.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(profileHeaderView.snp.bottom).offset(0)
            make.height.equalTo(64)
        }
        

        // 标签 CollectionView
        tagsCollectionView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(vipWalletCell.snp.bottom).offset(20)
            make.height.equalTo(0)
        }

        // 我的相册标题
        myAlbumLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(tagsCollectionView.snp.bottom).offset(20)
        }
        
        // 相册编辑按钮
        albumEditButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(myAlbumLabel)
            make.width.height.equalTo(18)
        }

        // 相册容器
        albumContainerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(myAlbumLabel.snp.bottom).offset(12)
            make.height.equalTo(112)
        }

        // 相册 CollectionView
        albumCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 我发起的活动
        myActivitiesLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(albumContainerView.snp.bottom).offset(20)
        }

        // 空状态视图（初始约束：撑开 contentView 底部，loadMyActivities 中会按需 remake）
        emptyStateView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(myActivitiesLabel.snp.bottom).offset(30)
            make.height.equalTo(200)
            make.bottom.equalToSuperview().offset(-40)
        }

        emptyImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
            make.size.equalTo(CGSizeMake(250, 128))
        }

        // 活动列表 TableView（初始无 bottom 约束，loadMyActivities 中按需 remake）
        activityTableView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(myActivitiesLabel.snp.bottom).offset(12)
            make.height.equalTo(0) // 初始高度0，数据加载后更新
        }

        // 设置 TableView 代理
        activityTableView.dataSource = self
        activityTableView.delegate = self
    }

    // MARK: - Data Loading
    
    private func fetchFootprintTotalThenUpdate() {
        NetworkManager.shared.request(MineAPI.footprint(page: 1, limit: 1), as: APIResponse<FootprintResponse>.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    print("❌ [Mine] footprint 总数请求失败: \(error.localizedDescription)")
                    // 如果失败，仍然获取 personalCenter 数据
                    self?.fetchPersonalCenterData()
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                if response.isSuccess, let data = response.data, let total = data.total {
                    print("📊 [Mine] 获取足迹总数成功: \(total)")
                    self.footprintTotal = total
                    // 缓存足迹总数
                    UserDefaults.standard.set(total, forKey: "mine_footprint_total")
                }
                // 不管成功与否，都获取 personalCenter 完整数据
                self.fetchPersonalCenterData()
            })
            .store(in: &mineCancellables)
    }

    private func fetchPersonalCenterData() {
        NetworkManager.shared.request(MineAPI.personalCenter, as: APIResponse<PersonalCenterData>.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("❌ [Mine] personalCenter 请求失败: \(error.localizedDescription)")
                    if let decodingError = error as? DecodingError {
                        print("❌ [Mine] 解码错误详情: \(decodingError)")
                    }
                    self?.loadUserData()
                }
            } receiveValue: { [weak self] response in
                print("✅ [Mine] 收到响应: code=\(response.code), message=\(response.message ?? "")")
                
                guard response.isSuccess, let data = response.data, let userinfo = data.userinfo else {
                    print("❌ [Mine] 响应数据不完整，data=\(String(describing: response.data)), userinfo=\(String(describing: response.data?.userinfo))")
                    self?.loadUserData()
                    return
                }
                
                let genderStr: String?
                switch userinfo.gender {
                case 1: genderStr = "female"
                case 2: genderStr = "male"
                default: genderStr = nil
                }
                
                let newModel = LoginModel(
                    userId: userinfo.user_id.map { "\($0)" },
                    usercode: userinfo.usercode,
                    phone: userinfo.mobile,
                    nickname: userinfo.nickname,
                    avatar: userinfo.avatar,
                    sign: userinfo.sign,
                    gender: genderStr,
                    genderRaw: userinfo.gender,
                    age: userinfo.age.map { "\($0)" },
                    birthday: userinfo.birthday,
                    city: userinfo.city,
                    education: userinfo.education, bio: userinfo.sign,
                    tags: userinfo.extra?.initial_heart?.split(separator: ",").map { String($0) },
                    favoriteActivityTypes: UserManager.shared.loginModel?.favoriteActivityTypes,
                    avatarLocalPath: UserManager.shared.loginModel?.avatarLocalPath,
                    type: userinfo.type,
                    registStep: userinfo.regist_step,
                    finishStatus: userinfo.finish_status,
                    inviteId: userinfo.invite_id,
                    imToken: userinfo.im_token,
                    isAnchor: userinfo.is_anchor,
                    voice: userinfo.voice,
                    voiceTime: userinfo.voice_time,
                    isAuth: userinfo.is_auth,
                    isRpAuth: userinfo.is_rp_auth,
                    vipIcon: userinfo.vip_icon,
                    vip: userinfo.vip,
                    token: userinfo.token,
                    createtime: userinfo.createtime,
                    expiretime: userinfo.expiretime,
                    expiresIn: userinfo.expires_in,
                    arrangePlayCityLabel: userinfo.arrange_play_city_label,
                    annualIncome: userinfo.annual_income, occupation: userinfo.occupation, wechatAccount: userinfo.wechat_account,
            qqAccount: userinfo.qq_account,
            initialHeart: userinfo.extra?.initial_heart,
            activity: userinfo.extra?.activity,
            isWx: userinfo.is_wx_int,
            isQq: userinfo.is_qq_int
        )
                
                UserManager.shared.saveLogin(model: newModel)
                
                if let usercount = data.usercount {
                    let fans = usercount.fans_count ?? 0
                    let follow = usercount.follow_count ?? 0
                    let visitor = usercount.visitor_count ?? 0
                    // 优先使用已获取的足迹总数
                    let footprint = (self?.footprintTotal ?? 0) > 0 ? (self?.footprintTotal ?? 0) : (usercount.footprint_count ?? 0)
                    print("📊 [Mine] 统计数据 - 粉丝:\(fans), 关注:\(follow), 足迹:\(footprint), 访客:\(visitor)")
                    self?.profileHeaderView.updateNumbers([fans, follow, footprint, visitor])
                    // 缓存统计数据
                    UserDefaults.standard.set([fans, follow, footprint, visitor], forKey: "mine_usercount_numbers")
                }
                
                // 处理活动币
                if let coin = userinfo.coin {
                    print("💰 [Mine] 获取活动币成功: \(coin)")
                    self?.vipWalletCell.updateCoinCount(coin)
                    UserDefaults.standard.set(coin, forKey: "mine_coin")
                }
                
                self?.loadUserData()
            }
            .store(in: &mineCancellables)
    }

    private func loadUserData() {
        let userModel = UserManager.shared
        let loginModel = userModel.loginModel
        
        // 根据性别设置顶部背景图
        if let gender = loginModel?.gender {
            if gender == "female" {
                headerBackgroundView.image = UIImage(named: "me_bg_gril")
            } else if gender == "male" {
                headerBackgroundView.image = UIImage(named: "me_bg_boy")
            } else {
                headerBackgroundView.image = UIImage(named: "me_bg")
            }
        } else {
            headerBackgroundView.image = UIImage(named: "me_bg")
        }
        
        // 加载头像
        if let avatarPath = loginModel?.avatar {
            let fullUrl = AppConfig.API.fullImageURL(path: avatarPath)
            if let url = URL(string: fullUrl) {
                avatarImageView.kf.setImage(with: url, placeholder: nil)
            }
        }

        // 加载昵称
        nicknameLabel.text = loginModel?.nickname ?? "未设置昵称"
        
        // 根据isAuth显示/隐藏实名标签
        shiMImageView.isHidden = (loginModel?.isAuth != nil)
        
        vipStateImageView.isHidden = (loginModel?.vip != 1)
        
        // 加载年龄
        if let age = loginModel?.age {
            ageLabel.text = age
            ageLabel.textColor =  UIColor(hex: loginModel?.gender == "female" ?"#FFFF67A9":"#FF037BFF")
            ageImageView.image = UIImage(named:loginModel?.gender == "female" ? "me_girl": "me_boy")
           
        } else {
            ageLabel.isHidden = true
        }

        // 加载ID
        if let userId = loginModel?.usercode {
            idLabel.text = "ID号：\(userId)"
        } else {
            idLabel.text = "ID号：未设置"
        }

        // 加载个人简介
        if let bio = loginModel?.bio, !bio.isEmpty {
            bioLabel.text = bio
            bioLabel.isHidden = false
        } else {
            bioLabel.text = "勇敢表达您的真实想法吧..."
            
        }

        // 加载标签
        loadTags()
    }

    // MARK: - 加载我的活动

    private func loadMyActivities() {
        // 先用本地数据兜底渲染
        let localActivities = PublishDataManager.shared.getPublishedActivities()
        // 本地缓存的活动不会有 rejected 状态，但为了保持一致性，我们也保留这个注释
        myActivities = localActivities
        renderMyActivities()
        // 再请求服务端覆盖
        fetchMyListsFromServer()
    }

    /// 调用 /meetv1/meet_activity/myLists 拉取我的活动
    private func fetchMyListsFromServer() {
        NetworkManager.shared
            .request(PublishAPI.myLists(page: 1,
                                        limit: 20,
                                        status: "",
                                        gender: "",
                                        activityType: "",
                                        cityId: ""),
                     as: MyActivityListData.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                #if DEBUG
                if case let .failure(error) = completion {
                    print("❌ [Mine] 我的活动列表请求失败: \(error.localizedDescription)")
                }
                #endif
            }, receiveValue: { [weak self] data in
                guard let self = self else { return }
                let items = data.list ?? []
                // 过滤掉状态为 rejected 的活动
                let filteredItems = items.filter { $0.status != "rejected" }
                self.myActivities = filteredItems.map { Self.convert($0) }
                self.renderMyActivities()
            })
            .store(in: &mineCancellables)
    }

    /// API 单条 → 本地 PublishModel 适配
    private static func convert(_ item: MyActivityItem) -> PublishModel {
        var model = PublishModel()
        model.id = item.id.map { "\($0)" }
        model.title = item.title ?? ""
        model.description = item.content ?? ""
        model.coverImages = item.imageList
        model.participantCount = item.peopleNum ?? 1
        switch item.gender {
        case 1: model.genderRequirement = .female
        case 2: model.genderRequirement = .male
        default: model.genderRequirement = .unlimited
        }
        // 时间：is_long_term=1 或 activity_time<=0 视为长期，否则用时间戳
        if (item.isLongTerm ?? 0) == 1 || (item.activityTime ?? 0) <= 0 {
            model.timeType = .longTerm
            model.specificTime = nil
        } else {
            model.timeType = .specific
            model.specificTime = Date(timeIntervalSince1970: TimeInterval(item.activityTime ?? 0))
        }
        model.city = item.location ?? ""
        model.category = item.activityTypeNames
        switch item.feeType {
        case "free":    model.expenseType = .free
        case "shared":  model.expenseType = .average
        case "you_pay": model.expenseType = .yourBuy
        case "i_pay":   model.expenseType = .myBuy
        default:        model.expenseType = .free
        }
        switch item.status {
        case "published": model.status = .ongoing
        case "expired":   model.status = .expired
        default:          model.status = .pending
        }
        return model
    }

    /// 把当前 myActivities 渲染到列表 / 空状态
    private func renderMyActivities() {
        if myActivities.isEmpty {
            // 无数据：显示空状态，隐藏列表
            emptyStateView.isHidden = false
            activityTableView.isHidden = true

            // emptyStateView 撑开 contentView 底部
            emptyStateView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.top.equalTo(myActivitiesLabel.snp.bottom).offset(30)
                make.height.equalTo(200)
                make.bottom.equalToSuperview().offset(-40)
            }
            // tableView 不参与底部撑开
            activityTableView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.top.equalTo(myActivitiesLabel.snp.bottom).offset(12)
                make.height.equalTo(0)
            }
        } else {
            // 有数据：显示列表，隐藏空状态
            emptyStateView.isHidden = true
            activityTableView.isHidden = false

            let totalHeight = CGFloat(myActivities.count) * 180

            // emptyStateView 不再参与底部撑开
            emptyStateView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.top.equalTo(myActivitiesLabel.snp.bottom).offset(30)
                make.height.equalTo(0)
            }
            // activityTableView 撑开 contentView 底部，高度为总高度
            activityTableView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.top.equalTo(myActivitiesLabel.snp.bottom).offset(12)
                make.height.equalTo(totalHeight)
                make.bottom.equalToSuperview().offset(-40)
            }
        }

        // 强制布局更新，让 tableView 拿到正确的 frame，
        // 避免 frame.height 为 0 导致 cellForRowAt 不被调用
        view.setNeedsLayout()
        view.layoutIfNeeded()

        activityTableView.reloadData()
    }

    private func loadTags() {
        tagsCollectionView.reloadData()
        
        // 计算并更新 tagsCollectionView 的高度
        let tags = UserManager.shared.loginModel?.tags ?? []
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
    }

    // MARK: - Actions

    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }

    private func handleProfileItemTapped(index: Int) {
        let isVip = (UserManager.shared.vip ?? 0) > 0
        
        switch index {
        case 0:
           
            if isVip {
                // 是 VIP，直接继续执行
                let vc = FollowerController(type: .fans)
                navigationController?.pushViewController(vc, animated: true)
            } else {
                // 不是 VIP，弹窗提示
                AppAlert.showSingle(
                    title: "提示",
                    message: "你暂无权限解锁谁关注我，请选择以下权益进行开通。",
                    confirmText: "开通会员",
                    messageAlignment: .center
                ) { [weak self] in
                    // 点击开通会员，跳转到会员中心
                    let vc = MemberCenterViewController()
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }
            
        case 1:
            let vc = FollowerController(type: .following)
            navigationController?.pushViewController(vc, animated: true)
            
        case 2:
            let vc = FootprintController()
            navigationController?.pushViewController(vc, animated: true)
            
        case 3:
            if isVip {
                // 是 VIP，直接继续执行
                let vc = FollowerController(type: .visitor)
                navigationController?.pushViewController(vc, animated: true)
            } else {
                // 不是 VIP，弹窗提示
                AppAlert.showSingle(
                    title: "提示",
                    message: "你暂无权限解锁谁访问我，请选择以下权益进行开通。",
                    confirmText: "开通会员",
                    messageAlignment: .center
                ) { [weak self] in
                    // 点击开通会员，跳转到会员中心
                    let vc = MemberCenterViewController()
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }
            
            
        default:
            break
        }
    }

    @objc private func editTapped() {
        let editVC = EditProfileController()
        navigationController?.pushViewController(editVC, animated: true)
    }

    @objc private func copyIdTapped() {
        if let userId = UserManager.shared.loginModel?.usercode {
            UIPasteboard.general.string = userId
            AppToast.show("ID已复制")
        }
    }

    // MARK: - VIPWalletCell 点击事件
    private func handleVipTapped() {
        print("🎫 VIP会员升级被点击")
        showToast("VIP会员升级")
        //会员中心
        let vc = MemberCenterViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func handleWalletTapped() {
        print("👛 我的钱包被点击")
        showToast("我的钱包")
        //我的钱包
        let vc = MyWalletViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - 一呼百应按钮事件
    private func handleActionButtonTapped(for model: PublishModel) {
        switch model.status {
        case .ongoing:
            // 跳转到一呼百应页面
            let vc = CallRespondViewController(activity: model)
            navigationController?.pushViewController(vc, animated: true)
        case .pending:
            showToast("活动正在审核中，请耐心等待")
        case .expired:
            showToast("活动已过期")
        }
    }

    // MARK: - 删除活动
    private func handleDeleteActivity(_ model: PublishModel) {
        AppAlert.showDouble(
            title: "提示",
            message: "确定要删除该活动吗？",
            cancelText: "取消",
            confirmText: "删除",
            onConfirm: { [weak self] in
                guard let self = self else { return }
                guard let activityId = model.id, !activityId.isEmpty else {
                    self.showToast("活动ID无效")
                    return
                }
                self.showLoading()
                NetworkManager.shared
                    .request(PublishAPI.deleteActivity(id: activityId), as: EmptyData.self)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { [weak self] completion in
                        self?.hideLoading()
                        switch completion {
                        case .failure(let error):
                            #if DEBUG
                            print("❌ [Mine] 删除活动失败: \(error.localizedDescription)")
                            #endif
                            self?.showToast("删除失败，请稍后重试")
                        case .finished:
                            break
                        }
                    }, receiveValue: { [weak self] _ in
                        PublishDataManager.shared.deletePublishedActivity(by: activityId)
                        self?.loadMyActivities()
                        self?.showToast("删除成功")
                    })
                    .store(in: &self.mineCancellables)
            }
        )
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension MineViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myActivities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MyActivityCardCell.reuseID, for: indexPath) as! MyActivityCardCell
        let model = myActivities[indexPath.row]
        cell.configure(with: model)

        // "一呼百应"按钮回调
        cell.onActionTapped = { [weak self] in
            self?.handleActionButtonTapped(for: model)
        }

        // 删除按钮回调
        cell.onDeleteTapped = { [weak self] in
            self?.handleDeleteActivity(model)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 点击卡片可跳转活动详情
    }
}

// MARK: - 我的相册功能
extension MineViewController {

    @objc private func toggleAlbumEdit() {
        isAlbumEditing.toggle()
        albumCollectionView.reloadData()
    }

    @objc private func addAlbumImageTapped() {
        let remainingCount = maxAlbumImageCount - albumImages.count

        var config = PhotoPickerConfig()
        config.showsCrop = false
        config.hidesPreview = true

        PhotoPicker.showMultiple(
            from: self,
            config: config,
            maxCount: remainingCount,
            onSelected: { [weak self] images in
                guard let self = self else { return }
                // 选择图片后直接上传，上传成功后通过网络刷新显示
                self.uploadAlbumImages(images)
            },
            onCancel: {
                print("取消选择图片")
            }
        )
    }

    private func deleteAlbumImage(at index: Int) {
        guard index < albumImages.count else { return }
        albumImages.remove(at: index)
        albumCollectionView.reloadData()
    }

    private func uploadAlbumImages(_ images: [UIImage]) {
        guard !images.isEmpty else { return }

        // 1. 把内存中的 UIImage 写到临时目录，拿到绝对路径（OSS 需要绝对路径）
        let tempDir = NSTemporaryDirectory()
        var absPaths: [String] = []
        let ts = Int(Date().timeIntervalSince1970 * 1000)
        for (idx, image) in images.enumerated() {
            guard let data = image.jpegData(compressionQuality: 0.8) else { continue }
            let fileName = "album_\(ts)_\(idx).jpg"
            let absPath = (tempDir as NSString).appendingPathComponent(fileName)
            do {
                try data.write(to: URL(fileURLWithPath: absPath), options: .atomic)
                absPaths.append(absPath)
            } catch {
                #if DEBUG
                print("❌ [Mine] 写临时文件失败 \(fileName): \(error.localizedDescription)")
                #endif
            }
        }
        guard !absPaths.isEmpty else {
            showToast("图片处理失败")
            return
        }

        showLoading("上传中...")

        // 2. 申请 STS
        OssUploadUtil.getSTS(type: "album") { [weak self] sts in
            guard let self = self else { return }
            guard let sts = sts else {
                self.hideLoading()
                self.showToast("获取上传凭证失败")
                return
            }
            // 3. 上传到 OSS（绝对路径）
            OssUploadUtil.uploadToOSS(sts: sts, filePaths: absPaths) { [weak self] keys in
                guard let self = self else { return }
                self.hideLoading()
                guard let keys = keys, keys.count == absPaths.count else {
                    self.showToast("图片上传失败")
                    return
                }
                #if DEBUG
                print("✅ [Mine] OSS 上传完成: \(keys)")
                #endif

                // 4. 用 OSS 返回的 key 调用添加相册接口
                let urlString = keys.joined(separator: ",")
                self.addAlbum(type: 2, url: urlString)
            }
        }
    }

    private func addAlbum(type: Int, url: String) {
        NetworkManager.shared.request(MineAPI.addAlbum(type: type, url: url), as: APIResponse<EmptyData>.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                if case .failure(let error) = completion {
                    #if DEBUG
                    print("❌ [Mine] 添加相册失败: \(error.localizedDescription)")
                    #endif
                    self.showToast("上传失败")
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                if response.isSuccess {
                    self.showToast("上传成功")
                    // 上传成功后刷新相册
                    self.fetchAlbumList()
                } else {
                    self.showToast(response.message ?? "上传失败")
                }
            })
            .store(in: &mineCancellables)
    }
    
    private func fetchAlbumList(page: Int = 1) {
        NetworkManager.shared.request(MineAPI.getAlbumList(page: page), as: APIResponse<MyAlbumListResponse>.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                if case .failure(let error) = completion {
                    #if DEBUG
                    print("❌ [Mine] 获取相册列表失败: \(error.localizedDescription)")
                    #endif
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                if response.isSuccess, let data = response.data, let list = data.list {
                    #if DEBUG
                    print("✅ [Mine] 获取相册列表成功: \(list.count) 张图片")
                    #endif
                    self.albumItems = list
                    self.albumCollectionView.reloadData()
                    // 缓存相册列表
                    if let encoded = try? JSONEncoder().encode(list) {
                        UserDefaults.standard.set(encoded, forKey: "mine_album_list")
                    }
                }
            })
            .store(in: &mineCancellables)
    }
    
    private func deleteAlbumItem(id: Int) {
        NetworkManager.shared.request(MineAPI.deleteAlbum(ids: [id]), as: APIResponse<EmptyData>.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                if case .failure(let error) = completion {
                    #if DEBUG
                    print("❌ [Mine] 删除相册失败: \(error.localizedDescription)")
                    #endif
                    self.showToast("删除失败")
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                if response.isSuccess {
                    #if DEBUG
                    print("✅ [Mine] 删除相册成功")
                    #endif
                    self.showToast("删除成功")
                    // 删除成功后刷新相册
                    self.fetchAlbumList()
                } else {
                    self.showToast(response.message ?? "删除失败")
                }
            })
            .store(in: &mineCancellables)
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate
extension MineViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == albumCollectionView {
            // 先显示添加按钮，再显示网络图片
            return albumItems.count < maxAlbumImageCount ? albumItems.count + 1 : albumItems.count
        } else {
            return UserManager.shared.loginModel?.tags?.count ?? 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == albumCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PublishImageCell.identifier, for: indexPath) as! PublishImageCell

            let hasAddButton = albumItems.count < maxAlbumImageCount
            
            if hasAddButton && indexPath.item == 0 {
                cell.configureAsAddButton()
            } else {
                let adjustedIndex = hasAddButton ? indexPath.item - 1 : indexPath.item
                // 网络图片
                let albumItem = albumItems[adjustedIndex]
                // 先设置编辑状态，再配置图片，这样configure方法会使用正确的状态
                cell.isEditing = isAlbumEditing
                if let urlPath = albumItem.url {
                    let fullUrl = AppConfig.API.fullImageURL(path: urlPath)
                    cell.configure(with: fullUrl)
                }
                cell.onDelete = { [weak self] in
                    guard let self = self, let id = albumItem.id else { return }
                    AppAlert.showDouble(
                        title: "提示",
                        message: "确定要删除该照片吗？",
                        cancelText: "取消",
                        confirmText: "删除",
                        onConfirm: { [weak self] in
                            guard let self = self else { return }
                            self.deleteAlbumItem(id: id)
                        }
                    )
                }
            }

            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagDisplayCell.reuseId, for: indexPath) as! TagDisplayCell
            let tags = UserManager.shared.loginModel?.tags ?? []
            guard indexPath.item < tags.count else { return cell }
            cell.configure(with: tags[indexPath.item])
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == albumCollectionView {
            if indexPath.item == 0 && albumItems.count < maxAlbumImageCount {
                addAlbumImageTapped()
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == albumCollectionView {
            return CGSize(width: 92, height: 92)
        } else {
            let tags = UserManager.shared.loginModel?.tags ?? []
            guard indexPath.item < tags.count else { return .zero }
            let tag = tags[indexPath.item]
            let font = UIFont.systemFont(ofSize: 14)
            let text = "# \(tag)"
            let textWidth = text.size(withAttributes: [.font: font]).width
            return CGSize(width: textWidth + 24, height: 24)
        }
    }
}
