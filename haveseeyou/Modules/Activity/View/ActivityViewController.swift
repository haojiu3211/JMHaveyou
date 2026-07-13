//
//  HomeViewController.swift
//  haveseeyou
//
//  首页 View 层 - 订阅 HomeViewModel 刷新 UI
//

import UIKit
import SnapKit
import Combine

final class ActivityViewController: BaseViewController {

    /// 首页使用自定义导航栏，隐藏系统导航栏
    override var prefersNavigationBarHidden: Bool { true }
    /// 首页不需要标准返回按钮
    override var useStandardBackButton: Bool { false }

    private let viewModel = ActivityViewModel()

    // 自定义导航
    private let navView = ActivityNavigationView()

    // Banner 容器（作为 tableHeaderView）
    private let bannerView = ActivityBannerView()

    // 列表
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.separatorStyle = .none
        tv.backgroundColor = AppColor.background
        tv.showsVerticalScrollIndicator = false
        tv.register(ActivityCell.self, forCellReuseIdentifier: ActivityCell.reuseID)
        tv.rowHeight = 152
        tv.contentInsetAdjustmentBehavior = .never
        return tv
    }()

    // 下拉刷新
    private let refreshControl = UIRefreshControl()

    // MARK: - Lifecycle
    override func setupUI() {
        view.backgroundColor = .white

        view.addSubviews(navView, tableView)

        navView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(navView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
        }

        tableView.dataSource = self
        tableView.delegate = self

        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        // 城市点击回调
        navView.onCityTapped = { [weak self] in
            self?.pushCityPicker()
        }



        // 筛选区域点击回调
        navView.onFilterTapped = { [weak self] in
            self?.pushActivityFilter()
        }

        // 配置 Banner 作为 tableHeaderView
        tableView.layoutIfNeeded()
        let width = tableView.bounds.width
        // 根据 banner 图片原始尺寸 686x240 比例计算高度
        let bannerHeight = width * 240 / 686
        bannerView.frame = CGRect(x: 0, y: 0, width: width, height: bannerHeight)
        tableView.tableHeaderView = bannerView

        // Banner 点击跳转 Web 详情页
        bannerView.onBannerTapped = { [weak self] banner in
            guard let url = banner.linkURL, !url.isEmpty else { return }
            let web = WebViewController(urlString: url)
            self?.navigationController?.pushViewController(web, animated: true)
        }
    }

    override func bindViewModel() {
        // Banner 数据
        viewModel.$banners
            .receive(on: DispatchQueue.main)
            .sink { [weak self] list in
                self?.bannerView.configure(list)
            }
            .store(in: &cancellables)

        // 筛选后的活动列表数据
        viewModel.$filteredActivities
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        // 城市 + 分类变更刷新导航
        Publishers
            .CombineLatest(viewModel.$currentCity, viewModel.$currentCategory)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] city, category in
                self?.navView.update(city: city, category: category)
            }
            .store(in: &cancellables)

        // 错误订阅
        viewModel.errorSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                self?.showToast(msg)
            }
            .store(in: &cancellables)

        // 筛选结果为空时，清除过滤条件并重新请求第一页
        viewModel.filterFallbackSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.showToast("暂未找到符合你要求的活动，已为你推荐以下内容", duration: 2.0)
                self?.viewModel.clearFiltersAndRefresh()
            }
            .store(in: &cancellables)

        // 监听加载状态，停止下拉刷新
        viewModel.$loadingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .success, .failure:
                    self?.refreshControl.endRefreshing()
                default: 
                    break
                }
            }
            .store(in: &cancellables)

        viewModel.refresh()
    }

    // MARK: - 下拉刷新

    @objc private func handleRefresh() {
        viewModel.refresh()
    }

    // MARK: - 城市选择

    private func pushCityPicker() {
        let vc = CityPickerViewController()
        vc.onCitySelected = { [weak self] city in
            guard let self = self else { return }
            // 更新 viewModel - 这会触发本地筛选，先显示缓存中的数据
            self.viewModel.currentCity = city
            // 然后请求后台获取最新数据
            self.viewModel.refresh()
        }
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            // navigationController 为 nil 时模态弹出兜底
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }

    // MARK: - 活动筛选

    private func pushActivityFilter() {
        let vc = ActivityFilterViewController(
            currentStatus: viewModel.currentStatus,
            currentCategory: viewModel.currentCategory,
            currentGender: viewModel.currentGender,
            currentCity: viewModel.currentCity
        )
        vc.onFilterApplied = { [weak self] filterMap in
            guard let self else { return }
            // 更新筛选条件 - 这会触发本地筛选，先显示缓存中的数据
            self.viewModel.currentGender = filterMap["gender"]
            self.viewModel.currentStatus = filterMap["status"]
            self.viewModel.currentCategory = filterMap["category"]
            self.viewModel.currentCity = filterMap["city"] ?? ""
            // 然后请求后台获取最新数据
            self.viewModel.refresh()
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UITableViewDataSource / Delegate
extension ActivityViewController: UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.filteredActivities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ActivityCell.reuseID, for: indexPath) as! ActivityCell
        let model = viewModel.filteredActivities[indexPath.row]
        cell.configure(model)
        cell.onActionTapped = { [weak self] activityModel in
            self?.pushActivityDetail(activityModel: activityModel)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let activityModel = viewModel.filteredActivities[indexPath.row]
        pushActivityDetail(activityModel: activityModel)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !viewModel.isRefreshing else { return }

        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.height

        if offsetY > 0 && offsetY > contentHeight - frameHeight - 100 {
            viewModel.loadMore()
        }
    }

    // MARK: - 活动详情跳转

    private func pushActivityDetail(activityModel: ActivityModel) {
        let vc = ActivityDetailViewController(activityModel: activityModel)
        navigationController?.pushViewController(vc, animated: true)
    }


}
