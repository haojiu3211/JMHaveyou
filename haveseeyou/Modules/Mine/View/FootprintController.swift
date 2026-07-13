//
//  FootprintController.swift
//  haveseeyou
//
//  足迹列表页
//

import UIKit
import SnapKit
import Kingfisher
import Combine

class FootprintController: BaseViewController {

    private var dataList: [FootprintModel] = []
    private var currentPage = 1
    private let pageSize = 1
    private var hasMore = true
    private var isLoadingA = false
    private var hasLoadedFirstPage = false
    private var footprintTotal: Int = 0
    /// 防止重复点击 PersionViewController 的标志
    private var isPushingUserProfile = false

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = AppColor.background
        cv.showsVerticalScrollIndicator = false
        cv.register(FootprintCell.self, forCellWithReuseIdentifier: FootprintCell.identifier)
        return cv
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
        label.text = "暂无足迹"
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindActions()
        loadData()
    }

    override func setupUI() {
        view.backgroundColor = AppColor.background
        title = "足迹"

        view.addSubviews(collectionView, emptyStateView)
        emptyStateView.addSubviews(emptyImageView, emptyLabel)

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.bottom.equalToSuperview().inset(16)
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

        collectionView.dataSource = self
        collectionView.delegate = self

        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }

    private func bindActions() {
    }

    private func loadData() {
        guard !isLoadingA else { 
            print("⚠️ [Footprint] 正在加载中，忽略此次请求")
            return 
        }
        print("🚀 [Footprint] 开始加载第 \(currentPage) 页数据")
        isLoadingA = true

        let api = MineAPI.footprint(page: currentPage, limit: pageSize)

        NetworkManager.shared.request(api, as: APIResponse<FootprintResponse>.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                print("✅ [Footprint] 请求完成")
                self.isLoadingA = false
                self.refreshControl.endRefreshing()
                if case let .failure(error) = completion {
                    print("❌ [Footprint] 加载失败: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                guard let self = self, response.isSuccess, let data = response.data else {
                    print("⚠️ [Footprint] 响应数据无效")
                    return
                }
                print("📦 [Footprint] 收到数据，count: \(data.list?.count ?? 0), total: \(data.total ?? 0)")
                if let total = data.total {
                    self.footprintTotal = total
                }
                if self.currentPage == 1 {
                    self.dataList = data.list ?? []
                } else {
                    self.dataList.append(contentsOf: data.list ?? [])
                }
                self.hasMore = (data.list?.count ?? 0) >= self.pageSize
                self.hasLoadedFirstPage = true
                self.updateEmptyState()
                self.collectionView.reloadData()
            })
            .store(in: &cancellables)
    }

    private func updateEmptyState() {
        let isEmpty = dataList.isEmpty
        emptyStateView.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }

    @objc private func handleRefresh() {
        currentPage = 1
        hasLoadedFirstPage = false
        loadData()
    }
}

extension FootprintController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FootprintCell.identifier, for: indexPath) as! FootprintCell
        
        let model = dataList[indexPath.item]
        cell.config(model: model)
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 12) / 2
        return CGSize(width: width, height: width + 60)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        
        // 只有当内容高度大于 frameHeight 时才可能滚动到底部
        guard contentHeight > frameHeight else { return }
        
        let shouldLoad = hasLoadedFirstPage && 
                        offsetY > contentHeight - frameHeight - 100 && 
                        hasMore && 
                        !isLoadingA
        
        if shouldLoad {
            print("⬇️ [Footprint] 滚动到底部，准备加载更多")
            currentPage += 1
            loadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let model = dataList[indexPath.item]
        guard let userId = model.userid else { return }
        pushUserProfile(userId: userId)
    }
}

// MARK: - 跳转用户主页
extension FootprintController {
    
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
                    print("❌ [Footprint] 个人主页请求失败: \(error.localizedDescription)")
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
