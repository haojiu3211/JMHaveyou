//
//  FollowerController.swift
//  haveseeyou
//
//  粉丝/关注/访客列表页
//

import UIKit
import SnapKit
import Kingfisher
import Combine

enum FollowerType {
    case fans
    case following
    case visitor

    var title: String {
        switch self {
        case .fans: return "粉丝"
        case .following: return "关注"
        case .visitor: return "访客"
        }
    }
}

class FollowerController: BaseViewController {

    private let followerType: FollowerType
    
    private var dataList: [RelationModel] = []
    private var visitorList: [VisitorModel] = []
    private var currentPage = 1
    private let pageSize = 20
    private var hasMore = true
    private var isLoadingA = false
    /// 防止重复点击 PersionViewController 的标志
    private var isPushingUserProfile = false

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = AppColor.background
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.register(FollowerCell.self, forCellReuseIdentifier: FollowerCell.identifier)
        return tv
    }()

    private let refreshControl = UIRefreshControl()

    private let emptyStateView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    private let emptyImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "sy_delet_account")
        return iv
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = AppColor.textSecondary
        label.textAlignment = .center
        return label
    }()

//    private var cancellables = Set<AnyCancellable>()

    init(type: FollowerType) {
        self.followerType = type
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindActions()
        loadData()
    }

    override func setupUI() {
        view.backgroundColor = AppColor.background
        title = followerType.title

        view.addSubviews(tableView, emptyStateView)
        emptyStateView.addSubviews(emptyImageView, emptyLabel)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.bottom.equalToSuperview()
        }

        emptyStateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        emptyImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(120)
        }

        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyImageView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }

        switch followerType {
        case .fans:
            emptyLabel.text = "暂无粉丝"
        case .following:
            emptyLabel.text = "暂无关注"
        case .visitor:
            emptyLabel.text = "暂无访客"
        }

        tableView.dataSource = self
        tableView.delegate = self

        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    private func bindActions() {
    }

    private func loadData() {
        guard !isLoadingA else { return }
        isLoadingA = true

        let api: MineAPI
        switch followerType {
        case .fans:
            api = .fansList(page: currentPage, limit: pageSize)
        case .following:
            api = .watchList(page: currentPage, limit: pageSize)
        case .visitor:
            api = .visitorsList(page: currentPage, limit: pageSize)
        }

        if followerType == .visitor {
            loadVisitorData(api: api)
        } else {
            loadRelationData(api: api)
        }
    }

    private func loadRelationData(api: MineAPI) {
        NetworkManager.shared.request(api, as: APIResponse<RelationListResponse>.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoadingA = false
                self?.refreshControl.endRefreshing()
                if case let .failure(error) = completion {
                    print("❌ [Follower] 加载失败: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                guard let self = self, response.isSuccess, let data = response.data else {
                    return
                }
                if self.currentPage == 1 {
                    self.dataList = data.list ?? []
                } else {
                    self.dataList.append(contentsOf: data.list ?? [])
                }
                self.hasMore = (data.list?.count ?? 0) >= self.pageSize
                self.updateEmptyState()
                self.tableView.reloadData()
            })
            .store(in: &cancellables)
    }

    private func loadVisitorData(api: MineAPI) {
        NetworkManager.shared.request(api, as: APIResponse<VisitorResponse>.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoadingA = false
                self?.refreshControl.endRefreshing()
                if case let .failure(error) = completion {
                    print("❌ [Visitor] 加载失败: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                guard let self = self, response.isSuccess, let data = response.data else {
                    return
                }
                if self.currentPage == 1 {
                    self.visitorList = data.list ?? []
                } else {
                    self.visitorList.append(contentsOf: data.list ?? [])
                }
                self.hasMore = (data.list?.count ?? 0) >= self.pageSize
                self.updateEmptyState()
                self.tableView.reloadData()
            })
            .store(in: &cancellables)
    }

    private func updateEmptyState() {
        let isEmpty = followerType == .visitor ? visitorList.isEmpty : dataList.isEmpty
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }

    @objc private func handleRefresh() {
        currentPage = 1
        loadData()
    }

    private func getCellModel(at indexPath: IndexPath) -> Any? {
        if followerType == .visitor {
            return visitorList[indexPath.row]
        } else {
            return dataList[indexPath.row]
        }
    }
}

extension FollowerController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followerType == .visitor ? visitorList.count : dataList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FollowerCell.identifier, for: indexPath) as! FollowerCell
        
        if followerType == .visitor {
            let model = visitorList[indexPath.row]
            cell.configVisitor(model: model, type: followerType)
        } else {
            let model = dataList[indexPath.row]
            cell.configRelation(model: model, type: followerType)
        }
        
        cell.onAction = { [weak self] userId, action in
            self?.handleCellAction(userId: userId, action: action)
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let count = followerType == .visitor ? visitorList.count : dataList.count
        if indexPath.row == count - 1 && hasMore && !isLoadingA {
            currentPage += 1
            loadData()
        }
    }

    private func handleCellAction(userId: Int, action: FollowerCell.ActionType) {
        switch action {
        case .viewProfile:
            pushUserProfile(userId: userId)
        case .follow:
            followUser(userId: userId, isUnfollow: false)
        case .unfollow:
            showUnfollowConfirm(userId: userId)
        case .unlock:
            unlockUser(userId: userId)
        }
    }
    
    /// 跳转到用户个人主页
    private func pushUserProfile(userId: Int) {
        guard !isPushingUserProfile else { return }
        isPushingUserProfile = true
        
        NetworkManager.shared
            .request(ActivityDetailAPI.personalHomepage(userId: "\(userId)"), as: PersonalHomepageDataModel.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isPushingUserProfile = false
                if case let .failure(error) = completion {
                    print("❌ [Follower] 个人主页请求失败: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] model in
                guard let self = self else { return }
                let vc = PersionViewController()
                vc.model = model
                self.navigationController?.pushViewController(vc, animated: true)
            }
            .store(in: &cancellables)
    }
    
    private func showUnfollowConfirm(userId: Int) {
        AppAlert.showDouble(
            title: "",
            message: "不再关注该用户吗？",
            cancelText: "取消",
            confirmText: "不再关注",
            messageAlignment: .center,
            onCancel: nil,
            onConfirm: { [weak self] in
                self?.followUser(userId: userId, isUnfollow: true)
            }
        )
    }
    
    private func followUser(userId: Int, isUnfollow: Bool) {
        NetworkManager.shared.request(ActivityDetailAPI.focusOn(followUid: "\(userId)"), as: APIResponse<EmptyData>.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("❌ [Follow] 操作失败: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                if response.isSuccess {
                    self?.showToast(isUnfollow ? "已取消关注" : "关注成功")
                    self?.handleRefresh()
                }
            })
            .store(in: &cancellables)
    }

    private func unlockUser(userId: Int) {
        print("🔓 解锁用户: \(userId)")
    }
}
