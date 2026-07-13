//
//  LoginViewController.swift
//  haveseeyou
//
//  登录/注册页面 - 启动后未登录时显示
//

import UIKit
import SnapKit
import NTESQuickPass

struct YidunPreLoginResult {
    let token: String
    let securityPhone: String?
    let carrierName: String
    let carrierProtocolName: String
    let carrierType: NTESCarrierType
}

final class LoginViewController: BaseViewController {

    private final class PassthroughView: UIView {
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            for subview in subviews.reversed() where !subview.isHidden && subview.alpha > 0.01 && subview.isUserInteractionEnabled {
                let converted = convert(point, to: subview)
                if subview.point(inside: converted, with: event) {
                    return true
                }
            }
            return false
        }
    }
    
    /// 登录页隐藏系统导航栏
    override var prefersNavigationBarHidden: Bool { true }
    /// 不使用标准返回按钮（登录页为根页面，无需返回按钮）
    override var useStandardBackButton: Bool { false }

    // MARK: - Callback
    
    /// 登录成功后回调，由外部设置跳转逻辑
    var onLoginSuccess: (() -> Void)?
    
    // MARK: - State
    
    private var isAgreed = false
    private var cachedPreLoginResult: YidunPreLoginResult?
    private var hasStartedSilentPreLogin = false

    // MARK: - Yidun Retry State
    
    private let maxRetryCount = 3
    private var currentRetryCount = 0
    private let initialRetryDelay: TimeInterval = 1.0
    
    // MARK: - Timeout State
    
    private var preLoginTimeoutTimer: Timer?
    private let preLoginTimeout: TimeInterval = 2.0
    
    // MARK: - UI Components
    
    /// 背景图片
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = UIImage(named: "sy_splash")
        return iv
    }()
    
    /// 半透明渐变蒙层（底部加深）
    //    private let gradientOverlay: UIView = {
    //        let view = UIView()
    //        return view
    //    }()
    
    /// 品牌 Slogan 图片 "见了吗 + 同城约活动"
    private let sloganImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "sy_login_sologen")
        return iv
    }()
    
    /// 副标题
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.text = "同城约活动"
        
        return label
    }()
    
    
    
    
    /// 登录按钮
    private let loginButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("登录/注册", for: .normal)
        // 渐变文字
        let gradientColor = UIColor.gradientTextColor(
            size: CGSize(width: 120, height: 30),
            colors: [
                UIColor(hex: "#A2EF4D"),
                UIColor(hex: "#F7FFFF"),
                UIColor(hex: "#F7FFFF")
            ]
        )
        btn.setTitleColor(gradientColor, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.backgroundColor = AppColor.buttonDark
        btn.layer.cornerRadius = 24.fit
        return btn
    }()
    
    
    /// 协议勾选按钮
    private let agreementCheckbox: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "sy_login_unselect"), for: .normal)
        btn.setImage(UIImage(named: "sy_login_select"), for: .selected)
        btn.contentMode = .scaleAspectFit
        return btn
    }()
    
    /// 协议文本
    private let agreementLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .white.withAlphaComponent(0.6)
        label.numberOfLines = 1
        
        let fullText = "我已阅读并同意《用户服务协议》和《隐私协议》"
        let attrStr = NSMutableAttributedString(string: fullText)
        let fullRange = NSRange(location: 0, length: fullText.count)
        attrStr.addAttribute(.foregroundColor, value: UIColor.white.withAlphaComponent(0.6), range: fullRange)
        
        // 高亮协议链接
        let serviceRange = (fullText as NSString).range(of:"《用户服务协议》")
        let privacyRange = (fullText as NSString).range(of: "《隐私协议》")
        attrStr.addAttribute(.foregroundColor, value: AppColor.theme, range: serviceRange)
        attrStr.addAttribute(.foregroundColor, value: AppColor.theme, range: privacyRange)
//        attrStr.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: serviceRange)
//        attrStr.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: privacyRange)
        
        label.attributedText = attrStr
        label.isUserInteractionEnabled = true
        return label
    }()
    
    // MARK: - Debug Environment Switcher (Only in DEBUG mode)
    
    #if DEBUG
    /// 环境切换按钮（仅 DEBUG 模式显示）
    private let environmentSwitchButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 10)
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        btn.layer.cornerRadius = 4
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        return btn
    }()
    #endif
    
    // MARK: - Lifecycle
    
    override func setupUI() {
        view.backgroundColor = .black
        
        var subviews: [UIView] = [
            backgroundImageView,
            //            gradientOverlay,
            
            agreementLabel,
            agreementCheckbox,
            loginButton,
            sloganImageView,
            subtitleLabel,
        ]
        
        #if DEBUG
        subviews.append(environmentSwitchButton)
        #endif
        
        view.addSubviews(subviews)
        
        
        
        setupConstraints()
        setupGradient()
        bindActions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSilentPreLoginIfNeeded()
    }
    
    deinit {
        preLoginTimeoutTimer?.invalidate()
        preLoginTimeoutTimer = nil
        #if DEBUG
        print("🧹 [LoginVC] 已释放")
        #endif
    }
    
    // MARK: - Constraints
    
    private func setupConstraints() {
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        //        gradientOverlay.snp.makeConstraints { make in
        //            make.edges.equalToSuperview()
        //        }
        
       
        
        

        // 协议文本
        agreementLabel.snp.makeConstraints { make in
            
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-56)
            
            
        }
        // 协议勾选
        agreementCheckbox.snp.makeConstraints { make in
            make.right.equalTo(agreementLabel.snp_leftMargin).offset(-14)
            make.centerY.equalTo(agreementLabel)
            make.width.height.equalTo(14)
        }
        // 登录按钮
        loginButton.snp.makeConstraints { make in
            make.bottom.equalTo(agreementLabel.snp_topMargin).offset(-26)
            make.centerX.equalToSuperview()
            make.height.equalTo(48.fit)
            make.width.equalTo(300.fit)
        }
        // 副标题（隐藏，保留约束占位）
        subtitleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(38.fit)
            make.bottom.equalTo(loginButton.snp_topMargin).offset(-38)
        }
        // Slogan 图片
        sloganImageView.snp.makeConstraints { make in
            make.left.equalTo(subtitleLabel)
            make.bottom.equalTo(subtitleLabel.snp_topMargin).offset(-10)
            make.width.equalTo(80)
            make.height.equalTo(44)
        }
        
        #if DEBUG
        // 环境切换按钮
        environmentSwitchButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.right.equalToSuperview().offset(-16)
        }
        #endif
    }
    
    // MARK: - Gradient
    
    private func setupGradient() {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor,
            UIColor.black.withAlphaComponent(0.7).cgColor,
            UIColor.black.withAlphaComponent(0.9).cgColor
        ]
        gradient.locations = [0.0, 0.3, 0.6, 1.0]
        gradient.frame = view.bounds
        //        gradientOverlay.layer.insertSublayer(gradient, at: 0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //        gradientOverlay.layer.sublayers?.first?.frame = gradientOverlay.bounds
    }
    
    // MARK: - Actions
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        #if DEBUG
        updateEnvironmentButtonTitle()
        #endif
    }
    
    private func bindActions() {
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        agreementCheckbox.addTarget(self, action: #selector(checkboxToggled), for: .touchUpInside)
        
        let agreementTap = UITapGestureRecognizer(target: self, action: #selector(agreementTapped(_:)))
        agreementLabel.addGestureRecognizer(agreementTap)
        
        #if DEBUG
        environmentSwitchButton.addTarget(self, action: #selector(switchEnvironmentTapped), for: .touchUpInside)
        #endif
    }
    
    #if DEBUG
    private func updateEnvironmentButtonTitle() {
        let title = "当前: \(AppConfig.current.description)"
        environmentSwitchButton.setTitle(title, for: .normal)
    }
    
    @objc private func switchEnvironmentTapped() {
        let alert = UIAlertController(title: "切换环境", message: "选择要使用的环境", preferredStyle: .actionSheet)
        
        let environments: [(name: String, env: AppEnvironment)] = [
            ("开发者", .dev),
            ("测试", .test),
            ("生产", .prod)
        ]
        
        for (name, env) in environments {
            let action = UIAlertAction(title: name, style: .default) { [weak self] _ in
                AppConfig.current = env
                self?.updateEnvironmentButtonTitle()
                print("🌍 [AppConfig] 已切换到: \(env.description)")
            }
            alert.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        alert.addAction(cancelAction)
        
        // For iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = environmentSwitchButton
            popover.sourceRect = environmentSwitchButton.bounds
        }
        
        present(alert, animated: true)
    }
    #endif
    
    @objc private func loginTapped() {
        startLoginFlow()
    }
    
    private func startLoginFlow() {
        guard checkAgreement() else { return }
        
        if canUseYidun() {
            presentAuthPageWithFreshPreLogin()
        } else {
            let phoneVC = PhoneNumberInputViewController()
            navigationController?.pushViewController(phoneVC, animated: true)
        }
    }
    
    private func startSilentPreLoginIfNeeded() {
        guard !hasStartedSilentPreLogin else { return }
        guard canUseYidun() else { return }
        hasStartedSilentPreLogin = true
        
        #if DEBUG
        print("🚀 [Yidun] LoginVC 静默预取号开始")
        #endif
        
        currentRetryCount = 0
        silentPreLogin()
    }
    
    private func silentPreLogin() {
        NTESQuickLoginManager.sharedInstance().getPhoneNumberCompletion { [weak self] resultDic in
            guard let self = self else { return }
            
            #if DEBUG
            print("📥 [Yidun] 静默预取号结果: \(resultDic)")
            #endif
            
            let success = resultDic["success"] as? Int ?? 0
            if success == 1 {
                self.cachedPreLoginResult = self.buildPreLoginResult(from: resultDic)
                
                #if DEBUG
                print("✅ [Yidun] 静默预取号成功")
                #endif
            } else {
                #if DEBUG
                print("❌ [Yidun] 静默预取号失败: \(resultDic), 当前重试次数: \(self.currentRetryCount)")
                #endif
                
                if self.currentRetryCount < self.maxRetryCount {
                    self.currentRetryCount += 1
                    let delay = self.initialRetryDelay * pow(2.0, Double(self.currentRetryCount - 1))
                    
                    #if DEBUG
                    print("🔄 [Yidun] 静默预取号 \(delay)秒后重试(\(self.currentRetryCount)/\(self.maxRetryCount))")
                    #endif
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                        self?.silentPreLogin()
                    }
                }
            }
        }
    }
    
    private func presentAuthPageWithFreshPreLogin() {
        let shouldShowLoading = cachedPreLoginResult == nil
        if shouldShowLoading {
            showLoading("准备中...")
        }
        
        // 设置 2 秒超时
        preLoginTimeoutTimer?.invalidate()
        preLoginTimeoutTimer = Timer.scheduledTimer(withTimeInterval: preLoginTimeout, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            #if DEBUG
            print("⏰ [Yidun] 预取号超时，跳转到手机号输入页")
            #endif
            self.handlePreLoginTimeout()
        }
        
        NTESQuickLoginManager.sharedInstance().getPhoneNumberCompletion { [weak self] resultDic in
            guard let self = self else { return }
            
            // 取消超时定时器
            self.preLoginTimeoutTimer?.invalidate()
            self.preLoginTimeoutTimer = nil
            
            #if DEBUG
            print("📥 [Yidun] 预取号结果: \(resultDic)")
            #endif
            
            let success = resultDic["success"] as? Int ?? 0
            if success == 1 {
                if shouldShowLoading {
                    self.hideLoading()
                }
                self.cachedPreLoginResult = self.buildPreLoginResult(from: resultDic)
                self.handlePreLoginSuccess(resultDic: resultDic)
            } else {
                if shouldShowLoading {
                    self.hideLoading()
                }
                #if DEBUG
                let resultCode = resultDic["resultCode"] as? Int ?? 0
                let desc = resultDic["desc"] as? String ?? "未知错误"
                print("❌ [Yidun] 预取号失败 - resultCode: \(resultCode), desc: \(desc)")
                #endif
                // 预取号失败，跳转到手机号输入页面
                let phoneVC = PhoneNumberInputViewController()
                self.navigationController?.pushViewController(phoneVC, animated: true)
            }
        }
    }
    
    private func handlePreLoginTimeout() {
        hideLoading()
        // 跳转到手机号输入页面
        let phoneVC = PhoneNumberInputViewController()
        navigationController?.pushViewController(phoneVC, animated: true)
    }
    
    private func handlePreLoginSuccess(resultDic: [AnyHashable: Any]) {
        let preLoginResult = cachedPreLoginResult ?? buildPreLoginResult(from: resultDic)
        cachedPreLoginResult = preLoginResult
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let model = self.makeYidunAuthModel(preLoginResult: preLoginResult)
            NTESQuickLoginManager.sharedInstance().setupModel(model)
            
            #if DEBUG
            print("🚪 [Yidun] 即将拉起授权页")
            #endif
            
            NTESQuickLoginManager.sharedInstance().cucmctAuthorizeLoginCompletion { [weak self] authResult in
                guard let self = self else { return }
                
                #if DEBUG
                print("📥 [Yidun] 授权结果: \(authResult)")
                #endif
                
                let code = authResult["code"] as? Int ?? authResult["resultCode"] as? Int ?? 0
                if code == 200020 || code == 10104 {
                    return
                }
                
                if code == 200060 || code == 10105 {
                    NTESQuickLoginManager.sharedInstance().closeAuthController {
                        
                    }
                    let phoneVC = PhoneNumberInputViewController()
                    self.navigationController?.pushViewController(phoneVC, animated: true)
                    return
                }
                
                let success = authResult["success"] as? Int ?? 0
                let accessToken = (authResult["accessToken"] as? String)
                ?? (authResult["token"] as? String)
                ?? ""
                let message = authResult["msg"] as? String ?? authResult["message"] as? String ?? "授权失败，请重试"
                
                guard success == 1, !accessToken.isEmpty else {
                    NTESQuickLoginManager.sharedInstance().closeAuthController(nil)
                    self.showToast(message)
                    return
                }
                
                self.quickLogin(accessToken: accessToken, ydToken: preLoginResult.token)
            }
        }
    }
        
    private func buildPreLoginResult(from resultDic: [AnyHashable: Any]) -> YidunPreLoginResult {
        let carrierType = NTESQuickLoginManager.sharedInstance().getCarrier()
        var carrierName = ""
        var carrierProtocolName = ""
        
        switch carrierType {
        case .telecom:
            carrierName = "中国电信"
            carrierProtocolName = "天翼账号认证服务条款"
        case .mobile:
            carrierName = "中国移动"
            carrierProtocolName = "和包认证服务条款"
        case .unicom:
            carrierName = "中国联通"
            carrierProtocolName = "联通认证服务条款"
        default:
            carrierName = "运营商"
            carrierProtocolName = ""
        }
        
        let token = resultDic["token"] as? String ?? ""
        let securityPhone = resultDic["securityPhone"] as? String
        
        return YidunPreLoginResult(
            token: token,
            securityPhone: securityPhone,
            carrierName: carrierName,
            carrierProtocolName: carrierProtocolName,
            carrierType: carrierType
        )
    }
    
    private func makeYidunAuthModel(preLoginResult: YidunPreLoginResult) -> NTESQuickLoginModel {
        let model = NTESQuickLoginModel()
        model.currentVC = self
        model.rootViewController = navigationController ?? self
        model.presentDirectionType = .presentSupportPush
        model.modalPresentationStyle = .overFullScreen
        model.modalTransitionStyle = .crossDissolve
        
        model.backgroundColor = .white
        model.statusBarStyle = .default
        
        model.navBarHidden = true
        
        model.logoHidden = true
        
        model.numberColor = .clear
        model.numberHeight = 0
        
        model.brandHidden = true
        
        model.logBtnText = "一键登录/注册"
        model.logBtnTextFont = .systemFont(ofSize: 18, weight: .medium)
        model.logBtnUsableBGColor = UIColor(hex: "#000000")
        model.logBtnRadius = 24
        model.logBtnHeight = 48
        model.logBtnOriginLeft = 40
        model.logBtnOriginRight = 40
        model.logBtnWidth = max(200, UIScreen.main.bounds.width - 80)
        let logBtnOffsetTopY: CGFloat = 350
        let logBtnHeight: CGFloat = 48
        model.logBtnOffsetTopY = logBtnOffsetTopY
        
        let gradientColor = UIColor.gradientTextColor(
            size: CGSize(width: 120, height: 30),
            colors: [
                UIColor(hex: "#A2EF4D"),
                UIColor(hex: "#F7FFFF"),
                UIColor(hex: "#F7FFFF")
            ]
        )
        model.logBtnTextColor = gradientColor
        
        model.uncheckedImg = UIImage(named: "member_select_coin_no") ?? UIImage()
        model.checkedImg = UIImage(named: "sy_login_select") ?? UIImage()
        model.checkboxWH = 14
        model.checkedSelected = isAgreed
        model.privacyState = isAgreed
        
        model.appPrivacyText = "登录并同意《默认》和《用户服务协议》《隐私协议》"
        model.appFPrivacyText = "用户服务协议"
        model.appFPrivacyURL = webUrlUserPrivacy
        model.appSPrivacyText = "隐私协议"
        model.appSPrivacyURL = webUrlPrivacy
        model.privacyColor = AppColor.textSecondary
        model.protocolColor = AppColor.theme
        model.appPrivacyAlignment = .center
        model.appPrivacyOriginBottomMargin = 40
        
        model.customViewBlock = { [weak self] customView in
            guard let self = self, let customView = customView else { return }
            if customView.viewWithTag(9901) != nil { return }
            
            let container = PassthroughView()
            container.tag = 9901
            container.backgroundColor = .clear
            customView.addSubview(container)
            container.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            let backButton = UIButton(type: .custom)
            backButton.setImage(UIImage(named: "app_back"), for: .normal)
            backButton.addTarget(self, action: #selector(self.authBackTapped), for: .touchUpInside)
            
            let welcomeLabel1 = UILabel()
            welcomeLabel1.font = .systemFont(ofSize: 28, weight: .bold)
            welcomeLabel1.textColor = AppColor.textMain
            welcomeLabel1.text = "欢迎您"
            
            let welcomeLabel2 = UILabel()
            welcomeLabel2.font = .systemFont(ofSize: 28, weight: .bold)
            welcomeLabel2.textColor = AppColor.textMain
            welcomeLabel2.text = "进入见了吗APP~"
            
            let phoneNumLabel = UILabel()
            phoneNumLabel.font = .systemFont(ofSize: 28, weight: .bold)
            phoneNumLabel.textColor = AppColor.textMain
            phoneNumLabel.textAlignment = .center
            phoneNumLabel.text = preLoginResult.securityPhone ?? "获取成功"
            
            let carrierInfoLabel = UILabel()
            carrierInfoLabel.font = .systemFont(ofSize: 14)
            carrierInfoLabel.textColor = AppColor.textSecondary
            carrierInfoLabel.textAlignment = .center
            carrierInfoLabel.text = "\(preLoginResult.carrierName)提供认证服务"
            
            let otherPhoneButton = UIButton(type: .custom)
            otherPhoneButton.clipsToBounds = true
            otherPhoneButton.layer.cornerRadius = 24
            otherPhoneButton.layer.borderWidth = 1
            otherPhoneButton.layer.borderColor = UIColor(hex: "#E0E0E0").cgColor
            otherPhoneButton.backgroundColor = .white
            otherPhoneButton.setTitle("其他手机号码", for: .normal)
            otherPhoneButton.setTitleColor(AppColor.textMain, for: .normal)
            otherPhoneButton.titleLabel?.font = .systemFont(ofSize: 16)
            otherPhoneButton.addTarget(self, action: #selector(self.authOtherPhoneTapped), for: .touchUpInside)
            
            container.addSubviews(backButton, welcomeLabel1, welcomeLabel2, phoneNumLabel, carrierInfoLabel, otherPhoneButton)
            
            backButton.snp.makeConstraints { make in
                make.top.equalTo(container.safeAreaLayoutGuide).offset(10)
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
            
            otherPhoneButton.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(logBtnOffsetTopY + logBtnHeight + 16)
                make.left.right.equalToSuperview().inset(40)
                make.height.equalTo(48)
            }
        }
        
        return model
    }
    
    @objc private func authBackTapped() {
        NTESQuickLoginManager.sharedInstance().closeAuthController(nil)
    }
    
    @objc private func authOtherPhoneTapped() {
        let phoneVC = PhoneNumberInputViewController()
        self.navigationController?.pushViewController(phoneVC, animated: true)
        NTESQuickLoginManager.sharedInstance().closeAuthController(nil)
        
    }
    
    private func quickLogin(accessToken: String, ydToken: String) {
        showLoading("正在登录...")
        
        NetworkManager.shared.request(
            LoginAPI.quickLogin(accessToken: accessToken, agreement: "1", ydToken: ydToken),
            as: LoginResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.hideLoading()
                
                switch result {
                case .failure(let error):
                    NTESQuickLoginManager.sharedInstance().closeAuthController(nil)
                    // 显示服务端返回的错误信息
                    self.showToast(error.localizedDescription)
                case .success(let response):
                    guard let userinfo = response.userinfo else {
                        NTESQuickLoginManager.sharedInstance().closeAuthController(nil)
                        self.showToast("登录数据解析失败")
                        return
                    }
                    
                    
                    
                    let loginModel = LoginModel(from: userinfo, fallbackPhone: nil)
                    UserManager.shared.saveLogin(model: loginModel)
                    
                    if let userId = loginModel.userId, !userId.isEmpty,
                       let imToken = loginModel.imToken, !imToken.isEmpty {
                        IMManager.shared.login(accountId: userId, token: imToken) { error in
                            if error == nil {
                                IMManager.shared.uploadCurrentUserProfile()
                            }
                        }
                    }
                    
                    let finishStatus = userinfo.finishStatus ?? 0
                    if finishStatus == 0 {
                        let profileVC = CompleteProfileViewController(phoneNumber: userinfo.phone ?? "")
                        profileVC.navigationItem.hidesBackButton = true
                        self.navigationController?.pushViewController(profileVC, animated: true)
                    } else {
                        NotificationCenter.default.post(name: .userDidLogin, object: nil)
                    }
                    
                    NTESQuickLoginManager.sharedInstance().closeAuthController(nil)
                }
            }
        }
    }

    
    // MARK: - 判断是否可以使用易盾
    private func canUseYidun() -> Bool {
        let shouldLogin = NTESQuickLoginManager.sharedInstance().shouldQuickLogin()
        let carrier = NTESQuickLoginManager.sharedInstance().getCarrier()
        
        #if DEBUG
        print("🔍 [Yidun] 判断是否可以使用易盾")
        print("  ├─ shouldQuickLogin: \(shouldLogin)")
        switch carrier {
        case .unknown:
            print("  └─ carrier: 未知")
        case .telecom:
            print("  └─ carrier: 电信")
        case .mobile:
            print("  └─ carrier: 移动")
        case .unicom:
            print("  └─ carrier: 联通")
        @unknown default:
            print("  └─ carrier: 未知类型")
        }
        #endif
        
        return shouldLogin
    }
    
    @objc private func registerTapped() {
        guard checkAgreement() else { return }
        // TODO: 接入真实注册接口后替换为 ViewModel 调用
        UserManager.shared.saveLogin(token: "mock_token_\(Int(Date().timeIntervalSince1970))")
        NotificationCenter.default.post(name: .userDidLogin, object: nil)
        onLoginSuccess?()
    }
    
    @objc private func checkboxToggled() {
        isAgreed.toggle()
        agreementCheckbox.isSelected = isAgreed
    }
    
    @objc private func agreementTapped(_ gesture: UITapGestureRecognizer) {
        guard let text = agreementLabel.text else { return }
        let nsText = text as NSString
        let serviceRange = nsText.range(of: "《用户服务协议》")
        let privacyRange = nsText.range(of: "《隐私协议》")
        
        let location = gesture.location(in: agreementLabel)
        
        // 简易判断点击位置
        if let serviceRect = rectFor(range: serviceRange), serviceRect.contains(location) {
            
            let web = WebViewController(urlString: webUrlUserPrivacy,title: "用户服务协议")
//            let web = WebViewController(urlString: "http://192.168.10.129:8080/")
            navigationController?.pushViewController(web, animated: true)
        } else if let privacyRect = rectFor(range: privacyRange), privacyRect.contains(location) {
            let web = WebViewController(urlString: webUrlPrivacy,title: "隐私协议")
            navigationController?.pushViewController(web, animated: true)
            
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

            AppAlert.showContentDelegateClick(title: "见了吗声明", message: "请阅读并同意《用户服务协议》和《隐私协议》", confirmText: "同意并继续") {[weak self] in
                print("点击了用户协议")
                let web = WebViewController(urlString: webUrlUserPrivacy,title: "用户服务协议")
                self?.navigationController?.pushViewController(web, animated: true)
            } onPrivacyTap: {[weak self] in
                let web = WebViewController(urlString: webUrlPrivacy,title: "隐私协议")
                self?.navigationController?.pushViewController(web, animated: true)
                print("点击了隐私协议")
            } onConfirm: { [weak self] in
                guard let self = self else { return }

                print("同意并继续")
                self.isAgreed = true
                self.agreementCheckbox.isSelected = true
                self.startLoginFlow()
            }

            
            return false
        }
        return true
    }
}
