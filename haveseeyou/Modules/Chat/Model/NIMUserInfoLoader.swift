//
//  NIMUserInfoLoader.swift
//  haveseeyou
//
//  云信用户资料按需加载 + 内存缓存，给会话列表 / 聊天页面统一使用
//

import Foundation
import NIMSDK

final class NIMUserInfoLoader {

    static let shared = NIMUserInfoLoader()

    private var cache: [String: V2NIMUser] = [:]
    private var pending: [String: [(V2NIMUser?) -> Void]] = [:]
    private let queue = DispatchQueue(label: "com.haveseeyou.NIMUserInfoLoader", attributes: .concurrent)

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLogout),
            name: .userDidLogout,
            object: nil
        )
    }

    @objc private func handleLogout() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
            self.pending.removeAll()
        }
    }

    /// 主动写入/更新缓存（云信资料变更回调可调用）
    func update(_ user: V2NIMUser) {
        guard let accid = user.accountId else { return }
        queue.async(flags: .barrier) {
            self.cache[accid] = user
        }
    }

    /// 同步读取缓存（用于立即展示，未命中返回 nil）
    func cachedUser(accountId: String) -> V2NIMUser? {
        queue.sync { cache[accountId] }
    }

    /// 异步获取用户资料：先本地缓存 → 本地数据库 → 云端
    func fetch(accountId: String, completion: @escaping (V2NIMUser?) -> Void) {
        guard !accountId.isEmpty else {
            completion(nil)
            return
        }

        if let cached = cachedUser(accountId: accountId) {
            completion(cached)
            return
        }

        // 合并并发请求
        var shouldStart = false
        queue.async(flags: .barrier) {
            if self.pending[accountId] != nil {
                self.pending[accountId]?.append(completion)
            } else {
                self.pending[accountId] = [completion]
                shouldStart = true
            }
            if shouldStart {
                DispatchQueue.main.async {
                    self.startFetch(accountId: accountId)
                }
            }
        }
    }

    private func startFetch(accountId: String) {
        // 先用本地 getUserList，未命中再走云端
        NIMSDK.shared().v2UserService.getUserList(
            [accountId],
            success: { [weak self] users in
                if let user = users.first(where: { $0.accountId == accountId }) {
                    self?.finish(accountId: accountId, user: user)
                } else {
                    self?.fetchFromCloud(accountId: accountId)
                }
            },
            failure: { [weak self] _ in
                self?.fetchFromCloud(accountId: accountId)
            }
        )
    }

    private func fetchFromCloud(accountId: String) {
        NIMSDK.shared().v2UserService.getUserList(
            fromCloud: [accountId],
            success: { [weak self] users in
                self?.finish(accountId: accountId, user: users.first)
            },
            failure: { [weak self] _ in
                self?.finish(accountId: accountId, user: nil)
            }
        )
    }

    private func finish(accountId: String, user: V2NIMUser?) {
        var callbacks: [(V2NIMUser?) -> Void] = []
        queue.async(flags: .barrier) {
            if let user = user {
                self.cache[accountId] = user
            }
            callbacks = self.pending.removeValue(forKey: accountId) ?? []
            DispatchQueue.main.async {
                callbacks.forEach { $0(user) }
            }
        }
    }
}
