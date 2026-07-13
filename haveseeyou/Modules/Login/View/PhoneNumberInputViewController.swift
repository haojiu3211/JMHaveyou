//
//  PhoneNumberInputViewController.swift
//  haveseeyou
//
//  手机号输入页 - 登录/注册后进入，输入手机号发送验证码
//

import UIKit
import SnapKit
import Combine

final class PhoneNumberInputViewController: BaseViewController {

    /// 不使用标准返回按钮（自定义返回按钮样式）
    override var useStandardBackButton: Bool { false }
    
    override var prefersNavigationBarHidden: Bool{ true }
    // MARK: - ViewModel

    private let viewModel = PhoneNumberInputViewModel()
    
    override var baseViewModel: BaseViewModel? { viewModel }

    // MARK: - Callback

    /// 验证码发送成功后回调，由外部设置跳转验证码输入页
    var onSendCodeSuccess: ((String) -> Void)?

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

    /// 手机号输入容器
    private let phoneInputContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    /// 底部分割线
    private let bottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#E0E0E0")
        return view
    }()

    /// 区号按钮 (+86 ▼)
    private let countryCodeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("+86", for: .normal)
        btn.setTitleColor(AppColor.textMain, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        return btn
    }()

    /// 分隔竖线
    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#FFB2B6C1")
        return view
    }()

    /// 手机号输入框
    private let phoneTextField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 18)
        tf.textColor = AppColor.textMain
        tf.attributedPlaceholder = NSAttributedString(
            string: "输入手机号",
            attributes: [
                .foregroundColor: AppColor.textSecondary,
                .font: UIFont.systemFont(ofSize: 16)
            ]
        )
        tf.keyboardType = .phonePad
        tf.tintColor = AppColor.theme
        tf.clearButtonMode = .never
        return tf
    }()

    /// 清除按钮
    private let clearButton: UIButton = {
        let btn = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        btn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        btn.tintColor = UIColor(hex: "#C0C0C0")
        btn.isHidden = true
        return btn
    }()

    /// 下一步按钮
    private let nextButton: UIButton = {
        let btn = UIButton(type: .custom)
//        btn.backgroundColor = AppColor.darkButton
//        btn.layer.cornerRadius = 28.fit
        btn.clipsToBounds = true
        btn.isEnabled = false
//        btn.alpha = 0.5

        
        
        let arrowImage = UIImage(named: "login_next")
        btn.setBackgroundImage(arrowImage, for: .normal)

        return btn
    }()

    // MARK: - Combine

    // 使用父类 BaseViewController 的 cancellables

    // MARK: - Lifecycle

    override func setupUI() {
        view.backgroundColor = .white
        

        // 启用侧滑返回手势（导航栏隐藏时系统默认禁用）
        navigationController?.interactivePopGestureRecognizer?.delegate = self

        view.addSubviews(
            backButton,
            welcomeLabel1,
            welcomeLabel2,
            phoneInputContainer,
            nextButton
        )

        phoneInputContainer.addSubviews(
            countryCodeButton,
            separatorLine,
            phoneTextField,
            clearButton,
            bottomLine
        )

        setupConstraints()
        bindActions()
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

        phoneInputContainer.snp.makeConstraints { make in
            make.top.equalTo(welcomeLabel2.snp.bottom).offset(50)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
        }

        countryCodeButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(38.fit)
            make.centerY.equalToSuperview()
            make.width.equalTo(50)
        }

        separatorLine.snp.makeConstraints { make in
            make.left.equalTo(countryCodeButton.snp.right).offset(4)
            make.centerY.equalToSuperview()
            make.width.equalTo(1)
            make.height.equalTo(20)
        }

        phoneTextField.snp.makeConstraints { make in
            make.left.equalTo(separatorLine.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.equalTo(clearButton.snp.left).offset(-8)
            make.height.equalTo(30)
        }

        clearButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-38.fit)
            make.width.height.equalTo(24)
        }

        bottomLine.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(38.fit)
            make.right.equalToSuperview().offset(-38.fit)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }

        nextButton.snp.makeConstraints { make in
            make.top.equalTo(phoneInputContainer.snp.bottom).offset(50)
            make.centerX.equalToSuperview()
            make.width.equalTo(78.fit)
            make.height.equalTo(44.fit)
        }
    }

    // MARK: - Actions

    private func bindActions() {
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        phoneTextField.delegate = self
        phoneTextField.addTarget(self, action: #selector(phoneTextChanged), for: .editingChanged)
    }

    // MARK: - Bind ViewModel

    override func bindViewModel() {
        // 手机号有效性 -> 按钮状态
        viewModel.isPhoneValid
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isValid in
                self?.nextButton.isEnabled = isValid
                UIView.animate(withDuration: 0.25) {
                    self?.nextButton.alpha = isValid ? 1.0 : 0.5
                }
            }
            .store(in: &cancellables)

        // 发送验证码成功 -> 跳转安全验证页
        viewModel.sendCodeSuccess
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let verifyVC = VerifyCodeViewController(phoneNumber: self.viewModel.phoneNumber) //"77499494920"一呼百应测试 self.viewModel.phoneNumber
                self.navigationController?.pushViewController(verifyVC, animated: true)
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

    @objc private func clearTapped() {
        phoneTextField.text = nil
        viewModel.phoneNumber = ""
        clearButton.isHidden = true
    }

    @objc private func phoneTextChanged() {
        let text = phoneTextField.text ?? ""
        viewModel.phoneNumber = text
        clearButton.isHidden = text.isEmpty
    }

    @objc private func nextTapped() {
        view.endEditing(true)
        
        if viewModel.phoneNumber.hasPrefix("77") {
            let verifyVC = VerifyCodeViewController(phoneNumber: viewModel.phoneNumber)
            navigationController?.pushViewController(verifyVC, animated: true)
            return
        }
        
        viewModel.sendVerifyCode()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate

extension PhoneNumberInputViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        // 限制最多输入 11 位
        return prospectiveText.count <= 11
    }
}

// MARK: - UIGestureRecognizerDelegate（侧滑返回支持）

extension PhoneNumberInputViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // 导航栈中有多个 VC 时允许侧滑返回
        return navigationController?.viewControllers.count ?? 0 > 1
    }
}
