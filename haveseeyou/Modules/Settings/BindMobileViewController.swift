//
//
//  haveseeyou
//
//  原生换绑手机号页面
//

import UIKit
import SnapKit
import Combine

final class BindMobileViewController: BaseViewController {

    private let countryCodeLabel: UILabel = {
        let label = UILabel()
        label.text = "+86"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = AppColor.textMain
        return label
    }()

    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#D9D9D9")
        return view
    }()

    private let phoneTextField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 16)
        tf.textColor = AppColor.textMain
        tf.keyboardType = .numberPad
        tf.textAlignment = .left
        tf.attributedPlaceholder = NSAttributedString(
            string: "输入手机号",
            attributes: [
                .foregroundColor: UIColor(hex: "#B2B6C1"),
                .font: UIFont.systemFont(ofSize: 16)
            ]
        )
        return tf
    }()

    private let clearButton: UIButton = {
        let btn = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        btn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        btn.tintColor = UIColor(hex: "#C0C0C0")
        btn.isHidden = true
        return btn
    }()

    private let phoneBottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#ECECEC")
        return view
    }()

    private let codeTextField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 16)
        tf.textColor = AppColor.textMain
        tf.keyboardType = .numberPad
        tf.textAlignment = .left
        tf.attributedPlaceholder = NSAttributedString(
            string: "请输入验证码",
            attributes: [
                .foregroundColor: UIColor(hex: "#B2B6C1"),
                .font: UIFont.systemFont(ofSize: 16)
            ]
        )
        return tf
    }()

    private let sendCodeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("获取验证码", for: .normal)
        btn.setTitleColor(AppColor.textMain, for: .normal)
        btn.setTitleColor(UIColor(hex: "#B2B6C1"), for: .disabled)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.layer.cornerRadius = 18
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor(hex: "#999999").cgColor
        btn.isEnabled = false
        return btn
    }()

    private let codeBottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#ECECEC")
        return view
    }()

    private let submitButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("提交", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btn.backgroundColor = UIColor(hex: "#B3B3B3")
        btn.layer.cornerRadius = 24
        btn.clipsToBounds = true
        btn.isEnabled = false
        return btn
    }()

    private var phoneNumber: String = "" {
        didSet { updateUIState() }
    }

    private var verifyCode: String = "" {
        didSet { updateUIState() }
    }

    private var countdown = 0 {
        didSet { updateSendCodeButtonTitle() }
    }

    private var countdownTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "换绑手机号"
    }

    @MainActor
    deinit {
        stopCountdown()
    }

    override func setupUI() {
        super.setupUI()
        view.backgroundColor = .white

        let phoneTitleLabel = makeSectionTitleLabel(text: "请输入您的新号码")
        let codeTitleLabel = makeSectionTitleLabel(text: "验证码")

        view.addSubviews(
            phoneTitleLabel,
            countryCodeLabel,
            separatorLine,
            phoneTextField,
            clearButton,
            phoneBottomLine,
            codeTitleLabel,
            codeTextField,
            sendCodeButton,
            codeBottomLine,
            submitButton
        )

        phoneTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(28)
            make.left.equalToSuperview().offset(24)
        }

        countryCodeLabel.snp.makeConstraints { make in
            make.top.equalTo(phoneTitleLabel.snp.bottom).offset(18)
            make.left.equalToSuperview().offset(24)
        }

        separatorLine.snp.makeConstraints { make in
            make.left.equalTo(countryCodeLabel.snp.right).offset(10)
            make.centerY.equalTo(countryCodeLabel)
            make.width.equalTo(1)
            make.height.equalTo(16)
        }

        clearButton.snp.makeConstraints { make in
            make.centerY.equalTo(countryCodeLabel)
            make.right.equalToSuperview().offset(-24)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }

        phoneTextField.snp.makeConstraints { make in
            make.left.equalTo(separatorLine.snp.right).offset(10)
            make.centerY.equalTo(countryCodeLabel)
            make.right.equalTo(clearButton.snp.left).offset(-8)
            make.height.equalTo(24)
        }

        phoneBottomLine.snp.makeConstraints { make in
            make.top.equalTo(countryCodeLabel.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
            make.height.equalTo(1)
        }

        codeTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(phoneBottomLine.snp.bottom).offset(26)
            make.left.equalToSuperview().offset(24)
        }

        sendCodeButton.snp.makeConstraints { make in
            make.centerY.equalTo(codeTitleLabel.snp.bottom).offset(32)
            make.right.equalToSuperview().offset(-24)
            make.width.equalTo(108)
            make.height.equalTo(36)
        }

        codeTextField.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.centerY.equalTo(sendCodeButton)
            make.right.equalTo(sendCodeButton.snp.left).offset(-16)
            make.height.equalTo(24)
        }

        codeBottomLine.snp.makeConstraints { make in
            make.top.equalTo(codeTextField.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
            make.height.equalTo(1)
        }

        submitButton.snp.makeConstraints { make in
            make.top.equalTo(codeBottomLine.snp.bottom).offset(56)
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
            make.height.equalTo(48)
        }

        phoneTextField.delegate = self
        codeTextField.delegate = self
        phoneTextField.addTarget(self, action: #selector(phoneTextChanged), for: .editingChanged)
        codeTextField.addTarget(self, action: #selector(codeTextChanged), for: .editingChanged)
        clearButton.addTarget(self, action: #selector(clearPhoneTapped), for: .touchUpInside)
        sendCodeButton.addTarget(self, action: #selector(sendCodeTapped), for: .touchUpInside)
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        updateUIState()
    }

    private func makeSectionTitleLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColor.textMain
        return label
    }

    private func updateUIState() {
        clearButton.isHidden = phoneNumber.isEmpty

        let isPhoneValid = phoneNumber.count == 11
        sendCodeButton.isEnabled = isPhoneValid && countdown == 0
        sendCodeButton.layer.borderColor = (sendCodeButton.isEnabled ? UIColor(hex: "#999999") : UIColor(hex: "#D9D9D9")).cgColor

        let canSubmit = isPhoneValid && verifyCode.count == 4
        submitButton.isEnabled = canSubmit
        submitButton.backgroundColor = canSubmit ? AppColor.buttonDark : UIColor(hex: "#B3B3B3")
    }

    private func updateSendCodeButtonTitle() {
        if countdown > 0 {
            sendCodeButton.setTitle("\(countdown)s", for: .disabled)
        } else {
            sendCodeButton.setTitle("获取验证码", for: .normal)
            sendCodeButton.setTitleColor(AppColor.textMain, for: .normal)
        }
    }

    private func startCountdown() {
        stopCountdown()
        countdown = 60
        updateUIState()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.countdown -= 1
            if self.countdown <= 0 {
                self.stopCountdown()
                self.updateUIState()
            }
        }
    }

    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        if countdown < 0 {
            countdown = 0
        }
    }

    @objc private func phoneTextChanged() {
        phoneNumber = phoneTextField.text ?? ""
    }

    @objc private func codeTextChanged() {
        verifyCode = codeTextField.text ?? ""
    }

    @objc private func clearPhoneTapped() {
        phoneTextField.text = ""
        phoneNumber = ""
    }

    @objc private func sendCodeTapped() {
        guard phoneNumber.count == 11 else {
            showToast("请输入正确的手机号")
            return
        }
        guard let encryptedPhone = AESUtil.aes128Encrypt(phoneNumber) else {
            showToast("手机号加密失败")
            return
        }

        showLoading("发送中...")
        NetworkManager.shared
            .request(LoginAPI.sendCode(mobile: encryptedPhone, type: "bind"), as: APIResponse<EmptyData>.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.hideLoading()
                if case let .failure(error) = completion {
                    self?.showToast(error.localizedDescription)
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                if response.isSuccess {
                    self.showToast(response.message ?? "验证码已发送")
                    self.startCountdown()
                } else {
                    self.showToast(response.message ?? "发送失败")
                }
            }
            .store(in: &cancellables)
    }

    @objc private func submitTapped() {
        guard phoneNumber.count == 11 else {
            showToast("请输入正确的手机号")
            return
        }
        guard verifyCode.count == 4 else {
            showToast("请输入4位验证码")
            return
        }
        guard let encryptedPhone = AESUtil.aes128Encrypt(phoneNumber) else {
            showToast("手机号加密失败")
            return
        }

        showLoading("提交中...")
        NetworkManager.shared
            .request(LoginAPI.bindMobile(mobile: encryptedPhone, phoneCode: verifyCode, type: "modify"), as: APIResponse<EmptyData>.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.hideLoading()
                if case let .failure(error) = completion {
                    self?.showToast(error.localizedDescription)
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                if response.isSuccess {
                    UserManager.shared.updateUserInfo(phone: self.phoneNumber)
                    self.showToast(response.message ?? "换绑成功")
                    self.navigationController?.popViewController(animated: true)
                } else {
                    self.showToast(response.message ?? "换绑失败")
                }
            }
            .store(in: &cancellables)
    }
}

extension BindMobileViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        if textField === phoneTextField {
            return prospectiveText.count <= 11
        }
        if textField === codeTextField {
            return prospectiveText.count <= 4
        }
        return true
    }
}
