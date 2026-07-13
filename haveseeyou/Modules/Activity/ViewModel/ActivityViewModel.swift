//
//  HomeViewModel.swift
//  haveseeyou
//
//  首页 ViewModel - 使用 Combine 管理状态
//

import Foundation
import Combine

final class ActivityViewModel: BaseViewModel {

    // MARK: - 输出（供 View 订阅）
    @Published private(set) var banners: [BannerModel] = []
    @Published private(set) var activities: [ActivityModel] = []
    /// 根据城市 & 活动类型筛选后的列表
    @Published private(set) var filteredActivities: [ActivityModel] = []

    // MARK: - 输入
    @Published var currentCity: String = ""
    @Published var currentCategory: String? = nil
    /// 活动时效筛选：nil=全部, "published"=进行中, "expired"=已过期
    @Published var currentStatus: String? = nil
    /// 性别筛选：nil=不限, "2"=男, "1"=女
    @Published var currentGender: String? = nil
    /// 用户ID筛选：nil=全部
    @Published var currentUserId: String? = nil

    /// 筛选结果为空时通知重新请求无过滤条件的第一页数据
    let filterFallbackSubject = PassthroughSubject<Void, Never>()

    /// 当前页码
    private(set) var currentPage = 1
    /// 每页条数
    private let pageSize = 8
    /// 是否正在加载（防止重复请求）
    private var isLoading = false
    /// 是否正在下拉刷新
    private(set) var isRefreshing = false
    /// 是否还有更多数据可加载
    private(set) var hasMore = true

    /// 缓存 Key
    private let activityCacheKey = "com.haveseeyou.activity_cache"
    private let cacheUserDefaults = UserDefaults.standard

    /// 是否存在任意筛选条件
    private var hasAnyFilter: Bool {
        (!currentCity.isEmpty && currentCity != "全国")
            || (currentCategory?.isEmpty == false)
            || currentStatus != nil
            || currentGender != nil
    }

    // MARK: - Init

    override init() {
        super.init()
        setupFilterPipeline()
        loadCachedActivities()
    }

    // MARK: - 缓存管理

    /// 加载本地缓存的活动列表
    private func loadCachedActivities() {
        if let data = cacheUserDefaults.data(forKey: activityCacheKey),
           let cachedActivities = try? JSONDecoder().decode([ActivityModel].self, from: data) {
            self.activities = cachedActivities
        }
    }

    /// 保存活动列表到本地缓存
    private func saveToCache(_ activities: [ActivityModel]) {
        if let data = try? JSONEncoder().encode(activities) {
            cacheUserDefaults.set(data, forKey: activityCacheKey)
        }
    }

    // MARK: - 筛选管道

    /// 当 activities / currentCity / currentCategory / currentStatus / currentGender 任一变化时自动重新筛选
    private func setupFilterPipeline() {
        Publishers.CombineLatest(
            Publishers.CombineLatest(
                Publishers.CombineLatest(
                    Publishers.CombineLatest($activities, $currentCity),
                    $currentCategory
                ),
                $currentStatus
            ),
            $currentGender
        )
        .map { [weak self] pair, gender -> [ActivityModel] in
            let (((activities, city), category), status) = pair
            return self?.filter(activities, city: city, category: category, status: status, gender: gender) ?? activities
        }
        .assign(to: &$filteredActivities)
    }

    /// 筛选逻辑：
    private func filter(_ activities: [ActivityModel], city: String, category: String?, status: String?, gender: String?) -> [ActivityModel] {
        let hasCityFilter = !city.isEmpty && city != "全国"
        // 支持逗号分隔的多类别筛选
        let categoryList: [String] = {
            guard let cat = category, !cat.isEmpty else { return [] }
            return cat.split(separator: ",").map { String($0) }
        }()
        let hasCategoryFilter = !categoryList.isEmpty
        let hasStatusFilter = status != nil
        let hasGenderFilter = gender != nil

        // 没有任何筛选条件，直接返回全部
        guard hasCityFilter || hasCategoryFilter || hasStatusFilter || hasGenderFilter else { return activities }

        let result = activities.filter { activity in
            let cityMatch = !hasCityFilter || activity.location.contains(city)
            // 多类别：活动的 category 包含任一选中类别即匹配
            let categoryMatch = !hasCategoryFilter || categoryList.contains(where: { activity.category.contains($0) })
            let statusMatch = !hasStatusFilter || activity.status.rawValue == status!
            let genderMatch: Bool = {
                guard let g = gender else { return true }
                if g == "male" { return activity.gender == 2 }
                if g == "female" { return activity.gender == 1 }
                return true
            }()
            return cityMatch && categoryMatch && statusMatch && genderMatch
        }

        // 筛选结果为空 → 发送 fallback 信号，清空列表等待重新请求
        if result.isEmpty && !activities.isEmpty {
            filterFallbackSubject.send(())
            return []
        }
        return result
    }

    /// 刷新所有数据（重置 page = 1）
    func refresh() {
        guard !isLoading else { return }
        isRefreshing = true
        loadingState = .loading
        banners = BannerModel.mock
        currentPage = 1
        hasMore = true
        // 先尝试加载本地缓存展示
        loadCachedActivities()
        // 再请求后台
        fetchAllActivities()
    }

    /// 加载更多
    func loadMore() {
        guard !isLoading && !isRefreshing && hasMore else { return }
        currentPage += 1
        fetchAllActivities()
    }

    /// 筛选结果为空时，清除所有过滤条件并重新请求第一页（无任何筛选）
    func clearFiltersAndRefresh() {
        currentGender = nil
        currentStatus = nil
        currentCategory = nil
        currentCity = ""
        refresh()
    }

    // MARK: - 真实接口示例

    private func fetchBanners() {
        NetworkManager.shared
            .request(HomeAPI.banners(cateId: nil), as: [BannerModel].self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.handle(error: error)
                }
            }, receiveValue: { [weak self] list in
                self?.banners = list
            })
            .store(in: &cancellables)
    }

    private func fetchAllActivities() {
        guard !isLoading else { return }
        isLoading = true
        let cityId: String?
        if currentCity == "全国" {
            cityId = nil
        } else if currentCity.isEmpty {
            cityId = nil
        } else {
            cityId = CityDataManager.cityId(for: currentCity).map { "\($0)" }
        }
        NetworkManager.shared
            .request(PublishAPI.listAll(
                gender: currentGender,
                activityType: currentCategory,
                cityId: cityId,
                status: currentStatus,
                page: currentPage,
                limit: pageSize,
                userId: currentUserId
            ), as: MyActivityListData.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                defer {
                    self?.isLoading = false
                    self?.isRefreshing = false
                }
                if case let .failure(error) = completion {
                    self?.handle(error: error)
//                    self?.activities = ActivityModel.mock
                } else {
                    self?.loadingState = .success
                }
            }, receiveValue: { [weak self] data in
                guard let self = self else { return }
                let items = data.list ?? []
                self.hasMore = items.count >= self.pageSize
                let newActivities = items.map { ActivityModel.from($0) }
                if self.currentPage == 1 {
                    self.activities = newActivities
                    // 保存到本地缓存
                    self.saveToCache(newActivities)
                    if items.isEmpty && self.hasAnyFilter {
                        self.filterFallbackSubject.send(())
                    }else if (items.isEmpty){
                        self.filterFallbackSubject.send(())
                    }
                    
                } else {
                    self.activities += newActivities
                    // 追加到缓存（只追加到已有缓存
                    var allActivities = self.activities
                    self.saveToCache(allActivities)
                }
            })
            .store(in: &cancellables)
    }
}
