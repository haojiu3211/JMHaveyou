//
//  BaseViewModel.swift
//  haveseeyou
//
//  ViewModel 基类，基于 Combine 暴露加载状态与错误
//

import Foundation
import Combine

/// 页面数据加载状态
enum LoadingState: Equatable {
    case idle
    case loading
    case success
    case failure(String)
}

protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    func transform(input: Input) -> Output
}

class BaseViewModel {

    /// 订阅存储
    var cancellables = Set<AnyCancellable>()

    /// 加载状态
    @Published var loadingState: LoadingState = .idle

    /// 错误信息（供 UI 订阅弹 Toast）
    let errorSubject = PassthroughSubject<String, Never>()

    deinit {
        cancellables.forEach { $0.cancel() }
    }

    /// 处理错误 - 统一入口
    func handle(error: APIError) {
        let message = error.errorDescription ?? "未知错误"
        loadingState = .failure(message)
        errorSubject.send(message)
    }
}
