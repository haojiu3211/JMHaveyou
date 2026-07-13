//
//  ChatBannerViewModel.swift
//  haveseeyou
//
//  Created by admin on 2026/6/10.
//

import Foundation
import Combine

final class ChatBannerViewModel: BaseViewModel {

    // MARK: - 输出（供 View 订阅）
    @Published private(set) var banners: [ChatBannerModel] = []


    // MARK: - 输入


    // MARK: - Init

    override init() {
        super.init()
        setupFilterPipeline()
        loadCachedBanners()
    }

    // MARK: - 筛选管道

    /// 当 activities / currentCity / currentCategory / currentStatus 任一变化时自动重新筛选
    private func setupFilterPipeline() {
        
    }

    
    /// 刷新所有数据
    func refresh() {
        loadingState = .loading
        // 本地 Mock（未接入真实后端时）
//        banners = ChatBannerModel.mock
       
        // filteredActivities 会通过 Combine 管道自动更新
        loadingState = .success

        // 真实接口示例（接入后端后，去掉上面 mock 并启用）
         fetchBanners()
    }

    // MARK: - 真实接口示例

    private func fetchBanners() {
        NetworkManager.shared
            .request(HomeAPI.banners(cateId: "21"), as: [ChatBannerModel].self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.handle(error: error)
                }
            }, receiveValue: { [weak self] list in
                self?.banners = list
                // 缓存 Banner 数据
                if let encoded = try? JSONEncoder().encode(list) {
                    UserDefaults.standard.set(encoded, forKey: "chat_banner_list")
                }
            })
            .store(in: &cancellables)
    }

    // MARK: - 缓存

    private func loadCachedBanners() {
        guard let data = UserDefaults.standard.data(forKey: "chat_banner_list"),
              let list = try? JSONDecoder().decode([ChatBannerModel].self, from: data) else { return }
        banners = list
    }

 
}
