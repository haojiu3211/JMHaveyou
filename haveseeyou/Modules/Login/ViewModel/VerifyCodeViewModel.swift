//
//  VerifyCodeViewModel.swift
//  haveseeyou
//
//  安全验证页 ViewModel - 验证码倒计时、验证逻辑
//

import Foundation
import Combine

final class VerifyCodeViewModel: BaseViewModel {

    // MARK: - Input

    /// 手机号
    let phoneNumber: String

    /// 当前输入的验证码
    @Published var verifyCode: String = ""

    // MARK: - Output

    /// 验证码是否填满（4位）
    var isCodeComplete: AnyPublisher<Bool, Never> {
        $verifyCode
            .map { $0.count == 4 }
            .eraseToAnyPublisher()
    }

    /// 倒计时剩余秒数
    @Published private(set) var countdown: Int = 59

    /// 倒计时是否结束
    @Published private(set) var isCountdownFinished: Bool = false

    /// 验证成功
    let verifySuccess = PassthroughSubject<Void, Never>()

    /// 登录成功
    let loginSuccess = PassthroughSubject<LoginUserInfo, Never>()

    // MARK: - Private

    private var countdownTimer: Timer?

    // MARK: - Init

    init(phoneNumber: String) {
        self.phoneNumber = phoneNumber
        super.init()
    }

    deinit {
        stopCountdown()
    }

    // MARK: - Countdown

    /// 开始 59 秒倒计时
    func startCountdown() {
        countdown = 59
        isCountdownFinished = false
        stopCountdown()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.countdown -= 1
            if self.countdown <= 0 {
                self.isCountdownFinished = true
                self.stopCountdown()
            }
        }
    }

    /// 停止倒计时
    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    /// 重新发送验证码（重置倒计时）
    func resendCode() {
        guard isCountdownFinished else { return }
        // TODO: 接入真实重发接口
        startCountdown()
        sendVerifyCode()
    }

    /// 验证码校验（当前为模拟）
    func verify() {
        guard verifyCode.count == 4 else { return }
        loadingState = .loading

        #if DEBUG
        print("🔐 [Verify] 开始验证")
        print("  ├─ phoneNumber: \(phoneNumber)")
        print("  ├─ verifyCode: \(verifyCode)")
        print("  └─ yidunToken: (空)")
        #endif

        login(agreement: "1", yidunToken: "")
    }

    // MARK: - 格式化手机号

    /// 格式化手机号显示：132 5324 5465
    var formattedPhone: String {
        let digits = phoneNumber
        guard digits.count == 11 else { return digits }
        let index1 = digits.index(digits.startIndex, offsetBy: 3)
        let index2 = digits.index(digits.startIndex, offsetBy: 7)
        return String(digits[..<index1]) + " " + String(digits[index1..<index2]) + " " + String(digits[index2...])
    }
    
    //再次发验证码
    func sendVerifyCode() {
        guard phoneNumber.count == 11 else { return }
        loadingState = .loading


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
            
            }
            .store(in: &cancellables)
    }
    
    //登陆
    func login(agreement: String, yidunToken: String) {
        guard verifyCode.count == 4 else { return }
        loadingState = .loading

        // AES-128-ECB 加密手机号
        guard let encryptedPhone = AESUtil.aes128Encrypt(phoneNumber) else {
            loadingState = .idle
            return
        }

        NetworkManager.shared
            .request(LoginAPI.login(mobile: encryptedPhone, phoneCode: verifyCode, agreement: agreement, yidunToken: yidunToken), as: LoginResponse.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    #if DEBUG
                    print("❌ [Login] 网络请求失败: \(error.localizedDescription)")
                    #endif
                    self?.handle(error: error)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                #if DEBUG
                print("📥 [Login] 收到响应")
                print("  └─ response.userinfo: \(response.userinfo != nil ? "存在" : "nil")")
                #endif
                
                guard let userinfo = response.userinfo else {
                    #if DEBUG
                    print("❌ [Login] 登录响应中未找到 userinfo")
                    #endif
                    self?.handle(error: APIError.business(code: -1, message: "登录数据解析失败"))
                    return
                }
                
                #if DEBUG
                print("✅ [Login] 登录成功")
                print("  ├─ userId: \(userinfo.userId)")
                print("  ├─ usercode: \(userinfo.usercode ?? "nil")")
                print("  ├─ phone: \(userinfo.phone ?? "nil")")
                print("  ├─ nickname: \(userinfo.nickname ?? "nil")")
                print("  ├─ finishStatus: \(userinfo.finishStatus ?? -1)")
                #endif
                
                self?.loadingState = .success
                // 保存用户信息（接口字段与 LoginModel 一一对应）
                let loginModel = LoginModel(from: userinfo, fallbackPhone: self?.phoneNumber)
                UserManager.shared.saveLogin(model: loginModel)

                // 缓存云信凭证（accid 用业务 userId），并立即登录
                if let userId = loginModel.userId, !userId.isEmpty,
                   let imToken = loginModel.imToken, !imToken.isEmpty {
                    IMManager.shared.login(accountId: userId, token: imToken) { error in
                        if error == nil {
                            // 登录成功后把年龄/性别/昵称/头像同步到云信
                            IMManager.shared.uploadCurrentUserProfile()
                        }
                    }
                }
                self?.loginSuccess.send(userinfo)
            }
            .store(in: &cancellables)
    }

}
