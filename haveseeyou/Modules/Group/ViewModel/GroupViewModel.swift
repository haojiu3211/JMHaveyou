//
//  GroupViewModel.swift
//  haveseeyou
//
//  搭子首页 ViewModel - 使用 Combine 管理状态
//

import Foundation
import Combine

final class GroupViewModel: BaseViewModel {

    // MARK: - 输出（供 View 订阅）
    @Published private(set) var groups: [GroupModel] = []
    @Published private(set) var currentIndex: Int = 0

    // MARK: - Init

    override init() {
        super.init()
    }

    // MARK: - 数据加载

    /// 刷新所有数据
    func refresh() {
        loadingState = .loading
        // 本地 Mock（未接入真实后端时）
        groups = GroupModel.mock
        currentIndex = 0
        loadingState = .success

        // 真实接口示例（接入后端后，去掉上面 mock 并启用）
        // fetchGroups()
    }

    // MARK: - 卡片操作

    /// 标记为感兴趣
    func markInterested(_ groupId: String) {
//        if let index = groups.firstIndex(where: { $0.id == groupId }) {
//            var group = groups[index]
//            group.isInterested = true
//            groups[index] = group
//        }
    }

    /// 关注搭子
    func follow(_ groupId: String) {
//        if let index = groups.firstIndex(where: { $0.id == groupId }) {
//            var group = groups[index]
//            group.isFollowed = true
//            groups[index] = group
//        }
    }

    /// 下一张卡片
    func nextCard() {
        if currentIndex < groups.count - 1 {
            currentIndex += 1
        }
    }

    /// 上一张卡片
    func previousCard() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }

    // MARK: - 真实接口示例

    private func fetchGroups() {
        // TODO: 接入真实后端接口
        // NetworkManager.shared
        //     .request(GroupAPI.list, as: [GroupModel].self)
        //     .receive(on: DispatchQueue.main)
        //     .sink(receiveCompletion: { [weak self] completion in
        //         if case let .failure(error) = completion {
        //             self?.handle(error: error)
        //         } else {
        //             self?.loadingState = .success
        //         }
        //     }, receiveValue: { [weak self] list in
        //         self?.groups = list
        //     })
        //     .store(in: &cancellables)
    }
}
