//
//  LoginViewModel.swift
//  haveseeyou
//
//  登录模块 ViewModel
//

import Foundation
import Combine

final class LoginViewModel: BaseViewModel {

    // MARK: - Output

    /// 登录成功
    let loginSuccess = PassthroughSubject<Void, Never>()

    // MARK: - Methods

    /// 手机号 + 验证码登录
//    func loginWithPhone(phone: String, code: String) {
//        loadingState = .loading
//
//        NetworkManager.shared
//            .request(LoginAPI.login(phone: phone, code: code), as: LoginModel.self)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] completion in
//                switch completion {
//                case .failure(let error):
//                    self?.handle(error: error)
//                case .finished:
//                    break
//                }
//            } receiveValue: { [weak self] model in
//                // 保存登录信息（使用新的LoginModel）
//                UserManager.shared.saveLogin(model: model)
//                self?.loadingState = .success
//                self?.loginSuccess.send()
//            }
//            .store(in: &cancellables)
//    }

    /// 注册
//    func register(phone: String, code: String, nickname: String) {
//        loadingState = .loading
//
//        NetworkManager.shared
//            .request(LoginAPI.register(phone: phone, code: code, nickname: nickname), as: LoginModel.self)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] completion in
//                switch completion {
//                case .failure(let error):
//                    self?.handle(error: error)
//                case .finished:
//                    break
//                }
//            } receiveValue: { [weak self] model in
//                // 保存登录信息（使用新的LoginModel）
//                UserManager.shared.saveLogin(model: model)
//                self?.loadingState = .success
//                self?.loginSuccess.send()
//            }
//            .store(in: &cancellables)
//    }
}
