//
//  PhoneNumberInputViewModel.swift
//  haveseeyou
//
//  手机号输入页 ViewModel
//

import Foundation
import Combine

final class PhoneNumberInputViewModel: BaseViewModel {

    // MARK: - Input

    /// 当前输入的手机号
    @Published var phoneNumber: String = ""

    // MARK: - Output

    /// 手机号是否有效（11位数字）
    var isPhoneValid: AnyPublisher<Bool, Never> {
        $phoneNumber
            .map { $0.count == 11 && $0.allSatisfy(\.isNumber) }
            .eraseToAnyPublisher()
    }

    /// 发送验证码成功
    let sendCodeSuccess = PassthroughSubject<Void, Never>()

    // MARK: - Methods

    /// 发送验证码
    func sendVerifyCode() {
        guard phoneNumber.count == 11 else { return }
        loadingState = .loading

        // TODO: 接入真实发送验证码接口
        // 当前模拟 1 秒 loading 后成功
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
//            self?.loadingState = .success
//            self?.sendCodeSuccess.send()
//        }

        // AES-128-ECB 加密手机号
        guard let encryptedPhone = AESUtil.aes128Encrypt(phoneNumber) else {
            loadingState = .idle
            return
        }

        NetworkManager.shared
            .request(LoginAPI.sendCode(mobile: encryptedPhone,type: "login"), as: EmptyData.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.handle(error: error)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] _ in
                self?.loadingState = .success
                self?.sendCodeSuccess.send()
            }
            .store(in: &cancellables)
    }
}
