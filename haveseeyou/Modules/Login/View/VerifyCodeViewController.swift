//
//  VerifyCodeViewController.swift
//  haveseeyou
//
//  安全验证页 - 输入4位验证码，支持59秒倒计时重发
//

import UIKit
import SnapKit
import Combine

final class VerifyCodeViewController: BaseViewController {

    /// 不使用标准返回按钮（自定义返回按钮样式）
    override var useStandardBackButton: Bool { false }
    override var prefersNavigationBarHidden: Bool{ true }
    // MARK: - ViewModel

    private let viewModel: VerifyCodeViewModel
    
    override var baseViewModel: BaseViewModel? { viewModel }

    // MARK: - Callback

    /// 验证成功后回调（已废弃，注册判断已内置到本页）
    var onVerifySuccess: (() -> Void)?

    // MARK: - UI Components

    /// 返回按钮
    private let backButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "app_back"), for: .normal)
        return btn
    }()

    /// 标题 "安全验证"
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = AppColor.textMain
        label.text = "安全验证"
        return label
    }()

    
    private let phoneHintLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor(hex: "#FFB2B6C1")
        label.numberOfLines = 1
        label.text = "验证码已通过短信发送至："
        return label
    }()
    
    private let phoneLabel:UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14,weight: .semibold)
        label.textColor = AppColor.buttonDark
        label.numberOfLines = 1
        return label
    }()
    

    /// 验证码输入容器
    private let codeInputContainer: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .equalSpacing
        sv.alignment = .center
        sv.spacing = 16
        return sv
    }()

    /// 4 个验证码输入框
    private var codeFields: [UITextField] = []

    /// 隐藏的真实输入框（接收键盘输入）
    private let hiddenTextField: UITextField = {
        let tf = UITextField()
        tf.isHidden = true
        tf.keyboardType = .numberPad
        tf.tintColor = .clear
        tf.textColor = .clear
        return tf
    }()

    /// 重新获取 / 再次发送验证码 按钮
    private let resendButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(AppColor.theme, for: .normal)
        btn.setTitleColor(AppColor.textSecondary, for: .disabled)
        btn.isEnabled = false
        return btn
    }()

    /// 下一步按钮
    private let nextButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.clipsToBounds = true
        btn.isEnabled = false
        let arrowImage = UIImage(named: "login_next")
        btn.setBackgroundImage(arrowImage, for: .normal)
        return btn
    }()

    // MARK: - Init

    init(phoneNumber: String) {
        viewModel = VerifyCodeViewModel(phoneNumber: phoneNumber)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func setupUI() {
        view.backgroundColor = .white
        

        // 启用侧滑返回
        navigationController?.interactivePopGestureRecognizer?.delegate = self

        // 配置手机号提示
        phoneLabel.text = "+86 \(viewModel.formattedPhone)"

        // 创建 4 个验证码输入框
        for _ in 0..<4 {
            let tf = makeCodeField()
            codeFields.append(tf)
            codeInputContainer.addArrangedSubview(tf)
        }

        view.addSubviews(
            backButton,
            titleLabel,
            phoneHintLabel,
            phoneLabel,
            codeInputContainer,
            hiddenTextField,
            resendButton,
            nextButton
        )

        setupConstraints()
        bindActions()

        // 页面出现即开始倒计时
        viewModel.startCountdown()

        // 自动弹出键盘
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.hiddenTextField.becomeFirstResponder()
        }
    }

    // MARK: - 创建单个验证码输入框

    private func makeCodeField() -> UITextField {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 24, weight: .bold)
        tf.textColor = AppColor.textMain
        tf.textAlignment = .center
        tf.backgroundColor = UIColor(hex: "#F5F5F5")
        tf.layer.cornerRadius = 8
        tf.clipsToBounds = true
        tf.isEnabled = false
        tf.snp.makeConstraints { make in
            make.width.equalTo(60.fit)
            make.height.equalTo(60.fit)
        }
        return tf
    }

    // MARK: - Constraints

    private func setupConstraints() {
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(44)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(40)
            make.left.equalToSuperview().offset(38.fit)
        }

        phoneHintLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(38.fit)
        }

        phoneLabel.snp.makeConstraints { make in
            make.top.equalTo(phoneHintLabel.snp_bottomMargin).offset(14)
            make.left.equalTo(phoneHintLabel)
        }
        
        codeInputContainer.snp.makeConstraints { make in
            make.top.equalTo(phoneHintLabel.snp.bottom).offset(56)
            make.left.equalToSuperview().offset(38.fit)
            make.right.equalToSuperview().offset(-38.fit)
            make.height.equalTo(60.fit)
        }

        resendButton.snp.makeConstraints { make in
            make.top.equalTo(codeInputContainer.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(38.fit)
            make.height.equalTo(30)
        }

        nextButton.snp.makeConstraints { make in
            make.top.equalTo(resendButton.snp.bottom).offset(40)
            make.centerX.equalToSuperview()
            make.width.equalTo(78.fit)
            make.height.equalTo(44.fit)
        }
    }

    // MARK: - Actions

    private func bindActions() {
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        resendButton.addTarget(self, action: #selector(resendTapped), for: .touchUpInside)

        hiddenTextField.delegate = self
        hiddenTextField.addTarget(self, action: #selector(codeTextChanged), for: .editingChanged)

        // 点击验证码区域弹出键盘
        let tap = UITapGestureRecognizer(target: self, action: #selector(codeAreaTapped))
        codeInputContainer.addGestureRecognizer(tap)
    }

    // MARK: - Bind ViewModel

    override func bindViewModel() {
        // 倒计时 -> 按钮文案
        viewModel.$countdown
            .receive(on: DispatchQueue.main)
            .sink { [weak self] seconds in
                self?.resendButton.setTitle("重新获取 \(seconds)s", for: .normal)
            }
            .store(in: &cancellables)

        // 倒计时结束 -> 切换为"再次发送验证码"
        viewModel.$isCountdownFinished
            .receive(on: DispatchQueue.main)
            .sink { [weak self] finished in
                if finished {
                    self?.resendButton.setTitle("再次发送验证码", for: .normal)
                    self?.resendButton.setTitleColor(AppColor.theme, for: .normal)
                    self?.resendButton.isEnabled = true
                } else {
                    self?.resendButton.setTitleColor(AppColor.textSecondary, for: .disabled)
                    self?.resendButton.isEnabled = false
                }
            }
            .store(in: &cancellables)

        // 验证码填满 -> 按钮状态
        viewModel.isCodeComplete
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isComplete in
                self?.nextButton.isEnabled = isComplete
                self?.nextButton.alpha = isComplete ? 1.0 : 0.5
            }
            .store(in: &cancellables)

        // 验证成功 -> 判断是否已注册
        viewModel.loginSuccess
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self else { return }
                let finishStatus = response.finishStatus ?? 0

                #if DEBUG
                print("🎯 [VerifyCode] 收到登录成功事件")
                print("  ├─ finishStatus: \(finishStatus)")
                print("  └─ usercode: \(response.usercode ?? "nil")")
                #endif

                if finishStatus == 0 {
                    // 未完善资料 -> 跳转完善资料页
                    let profileVC = CompleteProfileViewController(phoneNumber: self.viewModel.phoneNumber)
                    profileVC.navigationItem.hidesBackButton = true
                    self.navigationController?.pushViewController(profileVC, animated: true)
                } else {
                    // 已完善资料 -> 直接登录成功
                    NotificationCenter.default.post(name: .userDidLogin, object: nil)
                }
            }
            .store(in: &cancellables)

        // 错误提示
        viewModel.errorSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showToast(message)
            }
            .store(in: &cancellables)
    }

    // MARK: - Event Handlers

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func codeAreaTapped() {
        hiddenTextField.becomeFirstResponder()
    }

    @objc private func codeTextChanged() {
        let text = hiddenTextField.text ?? ""
        // 限制 4 位
        let limited = String(text.prefix(4))
        hiddenTextField.text = limited
        viewModel.verifyCode = limited

        // 更新 4 个框的显示
        for (index, field) in codeFields.enumerated() {
            if index < limited.count {
                let idx = limited.index(limited.startIndex, offsetBy: index)
                field.text = String(limited[idx])
            } else {
                field.text = nil
            }
        }

        // 输入满 4 位自动触发验证
//        if limited.count == 4 {
//            viewModel.verify()
//        }
    }

    @objc private func resendTapped() {
        viewModel.resendCode()
    }

    @objc private func nextTapped() {
        view.endEditing(true)
        
        viewModel.verify()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    // MARK: - 测试账号 Mock 数据
    
    /// 为测试账号设置 mock 数据（仅 13888888888 登录时执行）
    private func setupMockDataForTestAccount() {
        print("📦 正在为测试账号设置用户信息和活动数据...")
        
        // 设置测试用户信息
        setupTestUserInfo()
        
        // 检查是否已经设置过 mock 活动数据，避免重复添加
        let existingActivities = PublishDataManager.shared.getPublishedActivities()
        let hasMockData = existingActivities.contains { $0.title.contains("[测试]") }
        
        if !hasMockData {
            // 创建多个测试活动
            let mockActivities = createMockActivities()
            
            // 保存到本地存储
            mockActivities.forEach { activity in
                PublishDataManager.shared.savePublishedActivity(activity)
            }
            
            print("✅ 测试账号活动数据添加完成，共 \(mockActivities.count) 个活动")
        } else {
            print("📋 测试账号已有活动数据，跳过重复设置")
        }
        
        print("✅ 测试账号 mock 数据设置完成")
    }
    
    /// 设置测试用户信息（昵称、头像、ID号、标签等）
    private func setupTestUserInfo() {
        // 先检查是否存在 loginModel，如果不存在则创建一个基础模型
        if UserManager.shared.loginModel == nil {
            // 创建基础用户模型
            let baseModel = LoginModel(
                userId: "TEST_USER_001",
                phone: "13888888888",
                nickname: "测试小达人",
                avatar: nil,
                gender: "male",
                age: "25",
                city: "深圳",
                bio: "我是测试账号，用于测试各种功能！",
                tags: ["认识新朋友", "找同好伙伴", "户外运动", "美食探店"],
                favoriteActivityTypes: ["户外", "运动", "美食", "读书"],
                avatarLocalPath: nil,
                token: UserManager.shared.token
            )
            UserManager.shared.saveLogin(model: baseModel)
            print("👤 测试用户基础信息已创建")
        } else {
            // 更新现有用户信息
            UserManager.shared.updateUserInfo(
                userId: "TEST_USER_001",           // 用户ID
                nickname: "测试小达人",             // 用户昵称
                avatar: nil,                       // 头像（使用默认头像）
                age: "25",                         // 年龄
                gender: "male",                    // 性别
                city: "深圳",                       // 城市
                bio: "我是测试账号，用于测试各种功能！", // 个人简介
                tags: ["认识新朋友", "找同好伙伴", "户外运动", "美食探店"], // 标签
                favoriteActivityTypes: ["户外", "运动", "美食", "读书"] // 喜欢的活动类型
            )
            print("👤 测试用户信息已更新")
        }
    }
    
    /// 创建测试用的 mock 活动数据
    private func createMockActivities() -> [PublishModel] {
        return [
            PublishModel(
                id: "mock_1",
                coverImages: ["ac_fm_2_1"],
                title: "周末爬山徒步",
                description: "周末一起去深圳梧桐山爬山，锻炼身体，欣赏风景。欢迎喜欢户外活动的朋友加入！",
                participantCount: 10,
                genderRequirement: .unlimited,
                timeType: .weekend,
                city: "深圳",
                detailedLocation: "罗湖区梧桐山",
                category: "户外",
                expenseType: .free,
                isAgreedToTerms: true,
                status: .ongoing
            ),
            PublishModel(
                id: "mock_2",
                coverImages: ["ac_fm_1_1"],
                title: "瑜伽健身找搭子",
                description: "想找一个喜欢瑜伽的朋友，一起督促练习瑜伽。每周二、四晚上7点到8点半。",
                participantCount: 2,
                genderRequirement: .female,
                timeType: .longTerm,
                city: "深圳",
                detailedLocation: "宝安区瑜伽馆",
                category: "瑜伽",
                expenseType: .average,
                isAgreedToTerms: true,
                status: .ongoing
            ),
            PublishModel(
                id: "mock_3",
                coverImages: ["ac_fm_10_1"],
                title: "读书会交流",
                description: "每月一次读书会，分享好书，交流心得。欢迎喜欢阅读的朋友参加！",
                participantCount: 8,
                genderRequirement: .unlimited,
                timeType: .specific,
                specificTime: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                city: "深圳",
                detailedLocation: "南山区书城",
                category: "读书",
                expenseType: .free,
                isAgreedToTerms: true,
                status: .pending
            ),
            PublishModel(
                id: "mock_4",
                coverImages: ["ac_fm_6_1"],
                title: "羽毛球友谊赛",
                description: "周末羽毛球活动，水平不限，重在参与。提供场地和球拍，欢迎报名！",
                participantCount: 6,
                genderRequirement: .unlimited,
                timeType: .weekend,
                city: "深圳",
                detailedLocation: "福田区体育馆",
                category: "运动",
                expenseType: .average,
                isAgreedToTerms: true,
                status: .ongoing
            ),
        ]
    }
}

// MARK: - UITextFieldDelegate

extension VerifyCodeViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        // 限制最多输入 4 位数字
        let filtered = prospectiveText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return filtered.count <= 4 && filtered.count == prospectiveText.count
    }
}

// MARK: - UIGestureRecognizerDelegate（侧滑返回支持）

extension VerifyCodeViewController: UIGestureRecognizerDelegate {
    
//    i'm litte used to calling outside your name
//    i won't see you tonight so i can keep from going insane
//    but i don't know enough, i get some kinda lazy day
//    
//    i've been fabulous through to find my tatterd name
//    i'll be stewed tommrrow if i don't leave us both the same
//    but i don't know enough, i get some kinda lazy day
        
    
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return navigationController?.viewControllers.count ?? 0 > 1
    }
}
