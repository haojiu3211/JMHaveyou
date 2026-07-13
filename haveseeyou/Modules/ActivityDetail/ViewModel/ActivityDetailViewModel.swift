//
//  ActivityDetailViewModel.swift
//  haveseeyou
//
//  活动详情 ViewModel - 管理详情数据、关注/取消关注、感兴趣、举报拉黑等交互
//

import Foundation
import Combine

final class ActivityDetailViewModel: BaseViewModel {

    // MARK: - 输出（供 View 订阅）

    /// 活动详情数据
    @Published private(set) var detail: ActivityDetailModel?

    /// 是否已关注
    @Published private(set) var isFollowed: Bool = false

    /// 是否已感兴趣
    @Published private(set) var isInterested: Bool = false

    // MARK: - 事件通知

    /// 关注状态变更通知（供 UI 刷新按钮样式）
    let followChangedSubject = PassthroughSubject<Bool, Never>()
    /// 感兴趣操作成功通知
    let interestedSuccessSubject = PassthroughSubject<Void, Never>()
    /// 跳转个人资料页通知
    let gotoUserProfileSubject = PassthroughSubject<String, Never>()
    /// 跳转聊天页通知
    let gotoChatSubject = PassthroughSubject<(String, Bool), Never>() // (userId, shouldSendMessage)
    /// 显示举报拉黑弹框通知
    let showReportBlockSubject = PassthroughSubject<String, Never>()
    /// 跳转 H5 页面通知
    let gotoH5PageSubject = PassthroughSubject<String, Never>()
    /// 跳转图片浏览器通知（传图片索引）
    let gotoImagePreviewSubject = PassthroughSubject<Int, Never>()
    /// 拉黑状态切换成功通知，透出后端 message 供页面更新文案/状态
    let blockSuccessSubject = PassthroughSubject<String, Never>()

    // MARK: - 输入

    /// 活动 ID
    private let activityId: String

    // MARK: - Init

    init(activityModel: ActivityModel) {
        self.activityId = activityModel.id
        super.init()
        // 直接用 ActivityModel 转换为详情数据
        let detail = activityModel.toDetailModel()
        self.detail = detail
        self.isFollowed = detail.isFollowed
        self.isInterested = detail.isInterested
    }

    // MARK: - 加载详情

    func loadDetail() {
        fetchDetail()
    }

    // MARK: - 关注/取消关注

    func toggleFollow() {
        guard let detail = detail else { return }
        let publisherUserId = detail.publisher.userId
        guard !publisherUserId.isEmpty else { return }

        // 本地立即更新状态
        self.isFollowed = !isFollowed
        followChangedSubject.send(isFollowed)

        // 调用关注接口
        NetworkManager.shared
            .request(ActivityDetailAPI.focusOn(followUid: publisherUserId), as: APIResponse<EmptyData>.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                if case let .failure(error) = completion {
                    // 失败回滚状态
                    self.isFollowed = !self.isFollowed
                    self.followChangedSubject.send(self.isFollowed)
                    self.handle(error: error)
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                if response.code != 0 {
                    // 失败回滚状态
                    self.isFollowed = !self.isFollowed
                    self.followChangedSubject.send(self.isFollowed)
                    self.showToastMessage(response.message ?? "操作失败")
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - 标记感兴趣

    func markInterested() {
        guard !isInterested else { return }

        self.isInterested = true
        interestedSuccessSubject.send()

        let publisherUserId = detail?.publisher.userId ?? ""

        // NetworkManager 内部已经自动解一层 APIResponse 包裹（code/message/data），
        // 这里只要传业务 data 的具体类型即可；接口不返回数据用 EmptyData。
        NetworkManager.shared
            .request(ActivityDetailAPI.isInterested(id: activityId), as: EmptyData.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                if case let .failure(error) = completion {
                    // 接口失败 → 回滚 isInterested，让按钮 UI 也回到“我感兴趣”
                    self.isInterested = false
                    self.handle(error: error)
                    return
                }
            } receiveValue: { [weak self] _ in
                guard let self = self else { return }
                // 业务成功（NetworkManager 已确保 code == 0）→ 通知 View 跳转单聊
                if !publisherUserId.isEmpty {
                    self.gotoChatSubject.send((publisherUserId, true)) // 需要发送消息
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - 直接跳转聊天（已感兴趣时调用，不发送消息）
    func goToChat() {
        let publisherUserId = detail?.publisher.userId ?? ""
        if !publisherUserId.isEmpty {
            gotoChatSubject.send((publisherUserId, false)) // 不发送消息
        }
    }

    // MARK: - 头像点击 → 跳转个人资料页

    func didTapAvatar() {
        guard let userId = detail?.publisher.userId else { return }
        gotoUserProfileSubject.send(userId)//9004217
    }

    // MARK: - 更多按钮点击 → 显示举报拉黑弹框

    func didTapMore() {
        guard let userId = detail?.publisher.userId else { return }
        showReportBlockSubject.send(userId)
    }

    // MARK: - Banner 图片点击 → 查看大图

    func didTapBannerImage(at index: Int) {
        gotoImagePreviewSubject.send(index)
    }

   

    // MARK: - 举报

    func reportUser(userId: String, reason: String) {
        // 本地 Mock
        showToastMessage("举报成功，我们会尽快处理")

        // 真实接口
        // requestReport(userId: userId, reason: reason)
    }

    // MARK: - 拉黑

    func blockUser(userId: String) {
        requestBlock(userId: userId)
    }

    // MARK: - 真实接口（接入后端后启用）

    private func fetchDetail() {
        NetworkManager.shared
            .request(ActivityDetailAPI.detail(id: activityId), as: MyActivityItem.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.handle(error: error)
                } else {
                    self?.loadingState = .success
                }
            } receiveValue: { [weak self] item in
                let model = ActivityDetailModel.from(item)
                self?.detail = model
                self?.isFollowed = model.isFollowed
                self?.isInterested = model.isInterested
            }
            .store(in: &cancellables)
    }

    private func requestInterested(activityId: String) {
        NetworkManager.shared
            .request(ActivityDetailAPI.isInterested(id: activityId), as: EmptyData.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.handle(error: error)
                }
            } receiveValue: { [weak self] _ in
                self?.isInterested = true
                self?.interestedSuccessSubject.send()
            }
            .store(in: &cancellables)
    }

    private func requestReport(userId: String, reason: String) {
        NetworkManager.shared
            .request(ActivityDetailAPI.report(userId: userId, reason: reason), as: EmptyData.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.handle(error: error)
                }
            } receiveValue: { [weak self] _ in
                self?.showToastMessage("举报成功，我们会尽快处理")
            }
            .store(in: &cancellables)
    }

    private func requestBlock(userId: String) {
        NetworkManager.shared
            .request(ActivityDetailAPI.block(userId: userId), as: APIResponse<EmptyData>.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.handle(error: error)
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                if response.code == 0 {
                    let message = response.message ?? "操作成功"
                    self.blockSuccessSubject.send(message)
                    self.showToastMessage(message)
                } else {
                    self.showToastMessage(response.message ?? "操作失败")
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - 辅助

    private func showToastMessage(_ message: String) {
        errorSubject.send(message)
    }
}
