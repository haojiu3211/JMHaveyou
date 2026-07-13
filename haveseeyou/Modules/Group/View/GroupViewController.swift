//
//  GroupViewController.swift
//  haveseeyou
//
//  搭子首页 - 一级页面，展示搭子卡片
//

import UIKit
import SnapKit
import Combine
import MJRefresh

final class GroupViewController: BaseViewController {

    /// Tab根页面隐藏系统导航栏
    override var prefersNavigationBarHidden: Bool { true }
    /// 不使用标准返回按钮
    override var useStandardBackButton: Bool { false }

    // MARK: - UI

    private let navView = GroupNavigationView()

    private let cardContainer = UIView()
    private let cardView = GroupCardView()
    // 右上角活动规则按钮
    private let ruleButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "group_rule"), for: .normal)
        btn.setTitle("活动规则", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = AppColor.buttonDark
        btn.layer.cornerRadius = 14
        btn.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMinXMaxYCorner
        ]
        btn.clipsToBounds = true
        
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left:-2 , bottom: 0, right: 2)
        btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 5)
        return btn
    }()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = AppColor.background
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.register(GroupPartnerCell.self, forCellReuseIdentifier: GroupPartnerCell.identifier)
        tv.isHidden = true
        return tv
    }()

    private var dataList: [RelationModel] = []
    private var currentPage = 1
    private let pageSize = 10 // 方便测试上下拉加载
    private var hasMore = true
    private var isLoadingA = false
    private var isPushingUserProfile = false
    private var isPushingChat = false
    
    // MARK: - 筛选条件
    private var filterGender: Int?
    private var filterType: Int = 1 // 默认推荐
    private var filterActivity: String?
    private var filterArea: Int?
    private var currentFilterParams: [String: String] = [:]

    // MARK: - Lifecycle

    override func setupUI() {
        view.backgroundColor = .white

        view.addSubviews(navView, cardContainer, ruleButton, tableView)

        // 导航栏
        navView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
        }

        // 卡片容器
        cardContainer.snp.makeConstraints { make in
            make.top.equalTo(navView.snp.bottom).offset(0)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(cardContainer.snp.width).multipliedBy(1.8) // 固定宽高比 1:1.8，配合背景图比例
        }

        cardContainer.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 配置卡片文字
        cardView.configure()
        
        // 设置卡片回调
        cardView.onLaunchTapped = { [weak self] in
            self?.handleLaunchTapped()
        }
        
        // 右上角规则按钮
        ruleButton.snp.makeConstraints { make in
            make.top.equalTo(navView.snp.bottom).offset(16)
            make.right.equalToSuperview()
            make.width.equalTo(80)
            make.height.equalTo(28)
        }
        
        ruleButton.addTarget(self, action: #selector(ruleTapped), for: .touchUpInside)
        
        // TableView
        tableView.snp.makeConstraints { make in
            make.top.equalTo(navView.snp.bottom).offset(0)
            make.left.right.bottom.equalToSuperview()
        }

        tableView.dataSource = self
        tableView.delegate = self

        // 设置 MJRefresh - 下拉刷新
        let header = MJRefreshNormalHeader { [weak self] in
            self?.handleRefresh()
        }
        // 设置无文字模式
        header.stateLabel?.isHidden = true
        header.lastUpdatedTimeLabel?.isHidden = true
        tableView.mj_header = header

        // 设置 MJRefresh - 上拉加载更多
        let footer = MJRefreshAutoNormalFooter { [weak self] in
            self?.loadMoreData()
        }
        // 设置无文字模式
        footer.stateLabel?.isHidden = true
        footer.isRefreshingTitleHidden = true
        tableView.mj_footer = footer

        // 导航回调
        navView.onFilterButtonTapped = { [weak self] in
            self?.handleFilterTapped()
        }
        
        navView.onTabSelected = { [weak self] tabName in
            self?.handleTabSelected(tabName)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始加载数据 - viewDidLoad 只调用一次
        if dataList.isEmpty {
            loadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 用户进入页面自动弹窗
        showAutoGreetAlert()
    }
    
    // MARK: - Auto Greet Alert
    private func showAutoGreetAlert() {
        let alertView = AutoGreetAlertView()
        alertView.show()
    }
    
    override func bindViewModel() {
        // 暂无数据绑定需求
    }
}

// MARK: - Card View Actions
extension GroupViewController {
    private func handleLaunchTapped() {
        NetworkManager.shared
            .request(PublishAPI.myLists(page: 1,
                                        limit: 20,
                                        status: "published",
                                        gender: "",
                                        activityType: "",
                                        cityId: ""),
                     as: MyActivityListData.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure = completion {
                    self?.showNoActivityAlert()
                }
            }, receiveValue: { [weak self] data in
                guard let self = self else { return }
                let items = data.list ?? []
                if items.isEmpty {
                    self.showNoActivityAlert()
                } else {
                    let activities = items.map { Self.convert($0) }
                    let selectVC = SelectActivityViewController()
                    selectVC.externalActivities = activities
                    self.navigationController?.pushViewController(selectVC, animated: true)
                }
            })
            .store(in: &cancellables)
    }

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

    private func showNoActivityAlert() {
        AppAlert.showSingle(title: "您还未发布活动",
                           message: "请立即发布活动才能使用“一呼百应”功能哦！",
                           confirmText: "去发布",
                           onConfirm: { [weak self] in
            self?.tabBarController?.selectedIndex = 2
        })
    }
    @objc private func ruleTapped() {
        showRuleAlert()
    }

    private func showRuleAlert() {
        let ruleView = GroupRuleView(frame: UIScreen.main.bounds)
        ruleView.show()
    }

    private func handleFilterTapped() {
        // 将当前筛选条件传过去
        let filterVC = GroupPartnerFilterViewController(
            currentGender: currentFilterParams["gender"],
            currentZone: currentFilterParams["zone"],
            currentCity: currentFilterParams["city"]
        )
        filterVC.onFilterApplied = { [weak self] filterParams in
            guard let self = self else { return }
            print("收到筛选参数: \(filterParams)")
            
            // 保存筛选参数
            self.currentFilterParams = filterParams
            
            // 解析筛选条件
            self.applyFilterParams(filterParams)
            
            // 重置页面并刷新
            self.handleRefresh()
        }
        navigationController?.pushViewController(filterVC, animated: true)
    }
    
    // 解析筛选参数
    private func applyFilterParams(_ params: [String: String]) {
        // 性别
        if let genderStr = params["gender"], let gender = Int(genderStr) {
            filterGender = gender
        } else {
            filterGender = nil
        }
        
        // 专区类型映射
        if let zone = params["zone"] {
            switch zone {
            case "recommend": filterType = 1
            case "sameCity": filterType = 2
            case "newbie": filterType = 3
            default: filterType = 1 // 全部/推荐
            }
        } else {
            filterType = 1 // 默认推荐
        }
        
        // 类别
        if let activity = params["category"] {
            filterActivity = activity
        } else {
            filterActivity = nil
        }
        
        // 地区：从城市名称获取编码
        if let city = params["city"] {
            filterArea = CityDataManager.cityId(for: city)
        } else {
            filterArea = nil
        }
    }

    private func handleTabSelected(_ tabName: String) {
        if tabName == "一呼百应" {
            showCardView()
        } else {
            showTableView()
            if dataList.isEmpty {
                loadData()
            }
        }
    }

    private func showCardView() {
        cardContainer.isHidden = false
        ruleButton.isHidden = false
        tableView.isHidden = true
    }

    private func showTableView() {
        cardContainer.isHidden = true
        ruleButton.isHidden = true
        tableView.isHidden = false
    }
}

// MARK: - TableView DataSource & Delegate
extension GroupViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GroupPartnerCell.identifier, for: indexPath) as! GroupPartnerCell
        
        let model = dataList[indexPath.row]
        cell.configure(model: model)
        
        cell.onActionTapped = { [weak self] userId in
            self?.handleChatAction(userId: userId)
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        print("👀 [Group] willDisplay row: \(indexPath.row), total: \(dataList.count), hasMore: \(hasMore), isLoading: \(isLoadingA)")
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = dataList[indexPath.row]
        if let userId = model.userid {
            pushUserProfile(userId: userId)
        }
    }
}

// MARK: - TableView Data & Actions
extension GroupViewController {
    private func loadData() {
        guard !isLoadingA else { return }
        isLoadingA = true
        
        print("🎯 [Group] 请求数据，页码: \(currentPage), 每页数量: \(pageSize)")
        
        NetworkManager.shared.request(
            HomeAPI.homeIndex(
                type: filterType,
                area: filterArea,
                isOnline: nil,
                videoStatus: nil,
                ageBegin: nil,
                ageEnd: nil,
                isAuth: nil,
                isGoddess: nil,
                activity: filterActivity,
                gender: filterGender,
                page: currentPage,
                limit: pageSize
            ),
            as: APIResponse<HomeIndexResponse>.self
        ) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoadingA = false
            self.tableView.mj_header?.endRefreshing()
            self.tableView.mj_footer?.endRefreshing()
            
            switch result {
            case .success(let response):
                print("✅ [Group] 数据请求成功，code: \(response.code)")
                
                if response.code == 0 {
                    // 将 HomeIndexUser 转换为 RelationModel
                    let homeIndexUsers = response.data?.list ?? []
                    let relationModels = homeIndexUsers.map { $0.toRelationModel() }
                    
                    print("📄 [Group] 获取到 \(relationModels.count) 个搭子，当前页: \(self.currentPage)，总页数: \(response.data?.totalPage ?? 0)")
                    
                    // 检查是否是第一页且筛选结果为空
                    if self.currentPage == 1 && relationModels.isEmpty {
                        // 筛选结果为空，清空筛选条件
                        print("🔍 [Group] 筛选结果为空，清空筛选条件并推荐内容")
                        
                        // 清空筛选条件
                        self.filterGender = nil
                        self.filterType = 1
                        self.filterActivity = nil
                        self.filterArea = nil
                        self.currentFilterParams = [:]
                        
                        // 提示用户
                        self.showToast("暂未找到符合你要求的搭子，已为你推荐以下内容", duration: 2.0)
                        
                        // 重置页码并重新请求
                        self.currentPage = 1
                        self.loadData()
                        return
                    }
                    
                    if self.currentPage == 1 {
                        self.dataList = relationModels
                    } else {
                        self.dataList.append(contentsOf: relationModels)
                    }
                    
                    // 判断是否还有更多数据：当前页 < 总页数
                    if let totalPage = response.data?.totalPage {
                        self.hasMore = self.currentPage < totalPage
                    } else {
                        self.hasMore = relationModels.count >= self.pageSize
                    }
                    
                    print("📊 [Group] hasMore: \(self.hasMore)")
                    
                    // 如果没有更多数据，隐藏 footer
                    if !self.hasMore {
                        self.tableView.mj_footer?.endRefreshingWithNoMoreData()
                    }
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                } else {
                    print("⚠️ [Group] 业务失败，message: \(response.message ?? "")")
                    AppToast.show(response.message ?? "数据加载失败")
                }
                
            case .failure(let error):
                print("❌ [Group] 数据请求失败: \(error.localizedDescription)")
//                AppToast.show("网络请求失败")
            }
        }
    }
    
    @objc private func handleRefresh() {
        currentPage = 1
        // 重置 footer 状态
        tableView.mj_footer?.resetNoMoreData()
        hasMore = true
        loadData()
    }
    
    private func loadMoreData() {
        guard hasMore && !isLoadingA else {
            tableView.mj_footer?.endRefreshing()
            return
        }
        currentPage += 1
        loadData()
    }
    
    private func handleChatAction(userId: Int) {
        pushChatViewController(userId: userId)
    }
    
    private func pushChatViewController(userId: Int) {
//        guard !isPushingChat else { return }
//        isPushingChat = true
//        
//        IMManager.shared.pushOrShowConversation(with: "\(userId)", in: self)
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
//            self?.isPushingChat = false
//        }
    }
    
    private func pushUserProfile(userId: Int) {
        guard !isPushingUserProfile else { return }
        isPushingUserProfile = true
        
        NetworkManager.shared
            .request(ActivityDetailAPI.personalHomepage(userId: "\(userId)"), as: PersonalHomepageDataModel.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isPushingUserProfile = false
                if case let .failure(error) = completion {
                    print("❌ [GroupPartner] 个人主页请求失败: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] model in
                guard let self = self else { return }
                let vc = PersionViewController()
                vc.model = model
                self.navigationController?.pushViewController(vc, animated: true)
            }
            .store(in: &cancellables)
    }
    
    
    
}
