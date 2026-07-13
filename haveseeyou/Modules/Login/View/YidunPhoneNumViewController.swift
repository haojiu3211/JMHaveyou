//
//  YidunPhoneNumViewController.swift
//  haveseeyou
//
//  易盾一键登录页面
//
//

import UIKit
import SnapKit
import NTESQuickPass
import Combine

final class YidunPhoneNumViewController: BaseViewController {
    
    /// 不使用标准返回按钮（自定义返回按钮样式）
    override var useStandardBackButton: Bool { false }
    
    override var prefersNavigationBarHidden: Bool { true }
    
    /// 登录成功回调
    var onLoginSuccess: ((String, String) -> Void)?
    
    //易盾token
    private var yiduntoken = ""

    
    // MARK: - State
    
    private var isAgreed = false
    private var currentCarrierName = ""
    private var currentCarrierProtocolName = ""
    
    // MARK: - Retry State
    private let maxRetryCount = 3
    private var currentRetryCount = 0
    private let initialRetryDelay: TimeInterval = 1.0
    
    // MARK: - UI Components
    
    /// 返回按钮
    private let backButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "app_back"), for: .normal)
        return btn
    }()
    
    /// 欢迎文字第一行
    private let welcomeLabel1: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = AppColor.textMain
        label.text = "欢迎您"
        return label
    }()
    
    /// 欢迎文字第二行
    private let welcomeLabel2: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = AppColor.textMain
        label.text = "进入见了吗APP~"
        return label
    }()
    
    /// 脱敏手机号标签
    private let phoneNumLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = AppColor.textMain
        label.textAlignment = .center
        label.text = "获取中..."
        return label
    }()
    
    /// 运营商提供认证服务标签
    private let carrierInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = AppColor.textSecondary
        label.textAlignment = .center
        label.text = ""
        return label
    }()
    
    /// 一键登录/注册按钮
    private let loginButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.clipsToBounds = true
        btn.layer.cornerRadius = 24
        btn.backgroundColor = UIColor(hex: "#000000")
        btn.isEnabled = false
        btn.alpha = 0.5
        btn.setTitle("一键登录/注册", for: .normal)
        let gradientColor = UIColor.gradientTextColor(
            size: CGSize(width: 120, height: 30),
            colors: [
                UIColor(hex: "#A2EF4D"),
                UIColor(hex: "#F7FFFF"),
                UIColor(hex: "#F7FFFF")
            ]
        )
        btn.setTitleColor(gradientColor, for: .normal)
        
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        return btn
    }()
    
    /// 其他手机号码按钮
    private let switchAccountButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.clipsToBounds = true
        btn.layer.cornerRadius = 24
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor(hex: "#E0E0E0").cgColor
        btn.backgroundColor = .white
        btn.setTitle("其他手机号码", for: .normal)
        btn.setTitleColor(AppColor.textMain, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        return btn
    }()
    
    /// 协议勾选按钮
    private let agreementCheckbox: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "member_select_coin_no"), for: .normal)
        btn.setImage(UIImage(named: "sy_login_select"), for: .selected)
        btn.contentMode = .scaleAspectFit
        btn.isHidden = true
        return btn
    }()
    
    /// 协议文本
    private let agreementLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = AppColor.textSecondary
        label.numberOfLines = 1
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        return label
    }()
    
    /// 加载指示器
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = AppColor.theme
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Lifecycle
    
    override func setupUI() {
        view.backgroundColor = .white
        
        // 启用侧滑返回手势
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        view.addSubviews(
            backButton,
            welcomeLabel1,
            welcomeLabel2,
            phoneNumLabel,
            carrierInfoLabel,
            loginButton,
            switchAccountButton,
            agreementLabel,
            agreementCheckbox,
            activityIndicator
        )
        
        setupConstraints()
        bindActions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startPreGetPhoneNumber()
    }
    
    // MARK: - Constraints
    
    private func setupConstraints() {
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(44)
        }
        
        welcomeLabel1.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(40)
            make.left.equalToSuperview().offset(38.fit)
        }
        
        welcomeLabel2.snp.makeConstraints { make in
            make.top.equalTo(welcomeLabel1.snp.bottom).offset(8)
            make.left.equalTo(welcomeLabel1)
        }
        
        phoneNumLabel.snp.makeConstraints { make in
            make.top.equalTo(welcomeLabel2.snp.bottom).offset(60)
            make.left.right.equalToSuperview().inset(20)
        }
        
        carrierInfoLabel.snp.makeConstraints { make in
            make.top.equalTo(phoneNumLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(20)
        }
        
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(carrierInfoLabel.snp.bottom).offset(60)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(48)
        }
        
        switchAccountButton.snp.makeConstraints { make in
            make.top.equalTo(loginButton.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(48)
        }
        
        // 协议文本
        agreementLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
        }
        
        // 协议勾选
        agreementCheckbox.snp.makeConstraints { make in
            make.right.equalTo(agreementLabel.snp_leftMargin).offset(0)
            make.centerY.equalTo(agreementLabel)
            make.width.height.equalTo(50)
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(phoneNumLabel)
        }
    }
    
    // MARK: - Actions
    
    private func bindActions() {
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        switchAccountButton.addTarget(self, action: #selector(switchAccountTapped), for: .touchUpInside)
        agreementCheckbox.addTarget(self, action: #selector(checkboxToggled), for: .touchUpInside)
        
        let agreementTap = UITapGestureRecognizer(target: self, action: #selector(agreementTapped(_:)))
        agreementLabel.addGestureRecognizer(agreementTap)
    }
    
    // MARK: - 易盾一键登录
    
    /// 开始预取号
    private func startPreGetPhoneNumber() {
        activityIndicator.startAnimating()
        phoneNumLabel.text = "获取中..."
        carrierInfoLabel.text = ""
        
        #if DEBUG
        print("🚀 [Yidun] 开始预取号")
        #endif
        
        NTESQuickLoginManager.sharedInstance().getPhoneNumberCompletion { [weak self] resultDic in
            guard let self = self else { return }
            
            self.activityIndicator.stopAnimating()
            
            #if DEBUG
            print("📥 [Yidun] 预取号结果: \(resultDic)")
            #endif
            
            let success = resultDic["success"] as? Int ?? 0
            if success == 1 {
                self.handlePreGetPhoneSuccess(resultDic: resultDic)
            } else {
                self.handlePreGetPhoneFailed(resultDic: resultDic)
            }
        }
    }
    
    /// 预取号成功
    private func handlePreGetPhoneSuccess(resultDic: [AnyHashable: Any]) {
        currentRetryCount = 0
        
        #if DEBUG
        print("✅ [Yidun] 预取号成功，重置重试计数")
        #endif
        
        updateLoginButtonState()
        
        // 获取运营商信息
        let carrierType = NTESQuickLoginManager.sharedInstance().getCarrier()
        var carrierName = ""
        
        switch carrierType {
        case .telecom:
            carrierName = "中国电信"
            currentCarrierProtocolName = "天翼账号认证服务条款"
        case .mobile:
            carrierName = "中国移动"
            currentCarrierProtocolName = "和包认证服务条款"
        case .unicom:
            carrierName = "中国联通"
            currentCarrierProtocolName = "联通认证服务条款"
        default:
            carrierName = "运营商"
            currentCarrierProtocolName = ""
        }
        
        currentCarrierName = carrierName
        
        // 显示脱敏手机号和运营商信息
        if let securityPhone = resultDic["securityPhone"] as? String {
            phoneNumLabel.text = securityPhone
        } else {
            phoneNumLabel.text = "获取成功"
        }
        
        if let yiduntoken = resultDic["token"] as? String {
            self.yiduntoken = yiduntoken
        }
        
        carrierInfoLabel.text = "\(carrierName)提供认证服务"
        
        // 更新协议文本
        updateAgreementLabel()
    }
    
    /// 更新登录按钮状态
    private func updateLoginButtonState() {
        let shouldEnable = isAgreed
        loginButton.isEnabled = shouldEnable
        UIView.animate(withDuration: 0.25) {
            self.loginButton.alpha = shouldEnable ? 1.0 : 0.5
        }
    }
    
    /// 更新协议文本
    private func updateAgreementLabel() {
        guard !currentCarrierProtocolName.isEmpty else {
            agreementLabel.attributedText = nil
            agreementLabel.isHidden = true
            agreementCheckbox.isHidden = true
            isAgreed = true
            agreementCheckbox.isSelected = true
            updateLoginButtonState()
            return
        }
        
        agreementLabel.isHidden = false
        agreementCheckbox.isHidden = false
        
        let fullText = "我已阅读并同意《\(currentCarrierProtocolName)》"
        let attrStr = NSMutableAttributedString(string: fullText)
        let fullRange = NSRange(location: 0, length: fullText.count)
        attrStr.addAttribute(.foregroundColor, value: AppColor.textSecondary, range: fullRange)
        
        let carrierRange = (fullText as NSString).range(of: "《\(currentCarrierProtocolName)》")
        attrStr.addAttribute(.foregroundColor, value: AppColor.theme, range: carrierRange)
        
        agreementLabel.attributedText = attrStr
    }
    
    /// 预取号失败
    private func handlePreGetPhoneFailed(resultDic: [AnyHashable: Any]) {
        #if DEBUG
        print("❌ [Yidun] 预取号失败: \(resultDic), 当前重试次数: \(currentRetryCount)")
        #endif
        
        if currentRetryCount < maxRetryCount {
            currentRetryCount += 1
            let delay = initialRetryDelay * pow(2.0, Double(currentRetryCount - 1))
            
            #if DEBUG
            print("🔄 [Yidun] \(delay)秒后进行第\(currentRetryCount)次重试")
            #endif
            
            phoneNumLabel.text = "重试中(\(currentRetryCount)/\(maxRetryCount))..."
            activityIndicator.startAnimating()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.startPreGetPhoneNumber()
            }
        } else {
            phoneNumLabel.text = "获取失败"
            carrierInfoLabel.text = ""
            activityIndicator.stopAnimating()
            
            #if DEBUG
            print("❌ [Yidun] 已达到最大重试次数\(maxRetryCount)，停止重试")
            #endif
        }
    }
    

    
    /// 切换到普通登录
    private func switchToNormalLogin() {
        let phoneVC = PhoneNumberInputViewController()
        navigationController?.pushViewController(phoneVC, animated: true)
    }
    
    // MARK: - Event Handlers
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func loginTapped() {
        guard checkAgreement() else { return }
        
        showLoading("正在登录...")
        
        #if DEBUG
        print("🚀 [Yidun] 调用 quickLogin 接口，token: \(yiduntoken)")
        #endif
        
        NetworkManager.shared
            .request(LoginAPI.quickLogin(accessToken: yiduntoken, agreement: "1", ydToken: yiduntoken), as: LoginResponse.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                
                self.hideLoading()
                
                switch completion {
                case .failure(let error):
                    #if DEBUG
                    print("❌ [Login] 网络请求失败: \(error.localizedDescription)")
                    #endif
                    self.showToast("登录失败，请重试")
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                #if DEBUG
                print("📥 [Login] 收到响应")
                print("  └─ response.userinfo: \(response.userinfo != nil ? "存在" : "nil")")
                #endif
                
                guard let userinfo = response.userinfo else {
                    #if DEBUG
                    print("❌ [Login] 登录响应中未找到 userinfo")
                    #endif
                    self.showToast("登录数据解析失败")
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
                
                // 保存用户信息
                let loginModel = LoginModel(from: userinfo, fallbackPhone: nil)
                UserManager.shared.saveLogin(model: loginModel)
                
                // 缓存云信凭证并登录
                if let userId = loginModel.userId, !userId.isEmpty,
                   let imToken = loginModel.imToken, !imToken.isEmpty {
                    IMManager.shared.login(accountId: userId, token: imToken) { error in
                        if error == nil {
                            IMManager.shared.uploadCurrentUserProfile()
                        }
                    }
                }
                
                // 处理 finishStatus
                let finishStatus = userinfo.finishStatus ?? 0
                
                #if DEBUG
                print("🎯 [VerifyCode] 收到登录成功事件")
                print("  ├─ finishStatus: \(finishStatus)")
                print("  └─ usercode: \(userinfo.usercode ?? "nil")")
                #endif
                
                if finishStatus == 0 {
                    // 未完善资料 -> 跳转完善资料页
                    let profileVC = CompleteProfileViewController(phoneNumber: userinfo.phone ?? "")
                    profileVC.navigationItem.hidesBackButton = true
                    self.navigationController?.pushViewController(profileVC, animated: true)
                } else {
                    // 已完善资料 -> 直接登录成功
                    NotificationCenter.default.post(name: .userDidLogin, object: nil)
                }
            }
            .store(in: &cancellables)
    }
    
    @objc private func switchAccountTapped() {
        switchToNormalLogin()
    }
    
    @objc private func checkboxToggled() {
        isAgreed.toggle()
        agreementCheckbox.isSelected = isAgreed
        updateLoginButtonState()
    }
    
    @objc private func agreementTapped(_ gesture: UITapGestureRecognizer) {
        let text = agreementLabel.attributedText?.string ?? agreementLabel.text ?? ""
        if text.isEmpty { return }
        let nsText = text as NSString
        
        // 获取协议范围
        let carrierRange = !currentCarrierProtocolName.isEmpty ? nsText.range(of: "《\(currentCarrierProtocolName)》") : NSRange(location: NSNotFound, length: 0)
        
        let location = gesture.location(in: agreementLabel)
        
        // 判断点击位置
        if carrierRange.location != NSNotFound, let carrierRect = rectFor(range: carrierRange), carrierRect.contains(location) {
            // 点击了运营商协议
            showToast("运营商协议需在授权页面查看")
        } else {
            // 点击非链接区域，切换勾选状态
            checkboxToggled()
        }
    }
    
    private func rectFor(range: NSRange) -> CGRect? {
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: agreementLabel.bounds.size)
        let textStorage = NSTextStorage(attributedString: agreementLabel.attributedText ?? NSAttributedString(string: ""))
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }
    
    /// 检查是否同意协议
    private func checkAgreement() -> Bool {
        if !isAgreed {
            if currentCarrierProtocolName.isEmpty {
                showToast("请勾选同意后继续")
            } else {
                showToast("请阅读并同意《\(currentCarrierProtocolName)》")
            }
            return false
        }
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

// MARK: - UIGestureRecognizerDelegate（侧滑返回支持）

extension YidunPhoneNumViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return navigationController?.viewControllers.count ?? 0 > 1
    }
}
