//
//  AppAlert.swift
//  haveseeyou
//
//  全局统一弹框组件
//  支持单按钮 / 双按钮，标题、副标题、按钮文案均可动态传入
//

import UIKit
import SnapKit

// MARK: - 弹框配置模型

struct AppAlertConfig {

    /// 标题
    var title: String = ""
    /// 副标题 / 描述内容
    var message: String = ""
    /// 确认按钮文案
    var confirmText: String = "确定"
    /// 取消按钮文案（双按钮时使用）
    var cancelText: String = "取消"
    /// 是否显示取消按钮（false = 单按钮弹框）
    var showCancel: Bool = false
    /// 确认按钮回调
    var onConfirm: (() -> Void)?
    /// 取消按钮回调
    var onCancel: (() -> Void)?
    /// 副标题是否居中（默认左对齐）
    var messageAlignment: NSTextAlignment = .left
    /// 用户协议点击回调
    var onAgreementTap: (() -> Void)?
    /// 隐私政策点击回调
    var onPrivacyTap: (() -> Void)?
    /// 是否显示输入框
    var showInput: Bool = false
    /// 输入框占位符
    var inputPlaceholder: String = ""
    /// 输入框默认值
    var inputValue: String = ""
    /// 输入框回调（带输入内容）
    var onConfirmWithInput: ((String) -> Void)?
    /// 输入框键盘类型
    var inputKeyboardType: UIKeyboardType = .default
    /// 输入框是否限制只能输入字母和数字（禁止中文等）
    var inputRestrictAlphanumeric: Bool = false

}

// MARK: - 全局调用入口

enum AppAlert {

    /// 点击用户协议，隐私协议跳转
    @discardableResult
    static func showContentDelegateClick(
        title: String = "温馨提示",
        message: String = "",
        confirmText: String = "确定",
        messageAlignment: NSTextAlignment = .left,
        onAgreementTap: (() -> Void)? = nil,      // 用户协议点击回调
        onPrivacyTap: (() -> Void)? = nil,        // 隐私协议点击回调
        onConfirm: (() -> Void)? = nil
        
    ) -> AppAlertController {
        let config = AppAlertConfig(
            title: title,
            message: message,
            confirmText: confirmText,
            showCancel: false,
            onConfirm: onConfirm,
            messageAlignment: messageAlignment,
            onAgreementTap: onAgreementTap,
            onPrivacyTap: onPrivacyTap
        )
        
        return present(config: config)

    }
    
    /// 单按钮弹框
    @discardableResult
    static func showSingle(
        title: String = "温馨提示",
        message: String = "",
        confirmText: String = "确定",
        messageAlignment: NSTextAlignment = .left,
        onConfirm: (() -> Void)? = nil
    ) -> AppAlertController {
        let config = AppAlertConfig(
            title: title,
            message: message,
            confirmText: confirmText,
            showCancel: false,
            onConfirm: onConfirm,
            messageAlignment: messageAlignment
        )
        return present(config: config)
    }

    /// 双按钮弹框
    @discardableResult
    static func showDouble(
        title: String = "温馨提示",
        message: String = "",
        cancelText: String = "取消",
        confirmText: String = "确定",
        messageAlignment: NSTextAlignment = .left,
        onCancel: (() -> Void)? = nil,
        onConfirm: (() -> Void)? = nil
    ) -> AppAlertController {
        let config = AppAlertConfig(
            title: title,
            message: message,
            confirmText: confirmText,
            cancelText: cancelText,
            showCancel: true,
            onConfirm: onConfirm,
            onCancel: onCancel,
            messageAlignment: messageAlignment
        )
        return present(config: config)
    }

    /// 输入式弹框（双按钮）
    @discardableResult
    static func showInput(
        title: String = "",
        placeholder: String = "",
        defaultValue: String = "",
        cancelText: String = "取消",
        confirmText: String = "确定",
        keyboardType: UIKeyboardType = .default,
        restrictAlphanumeric: Bool = false,
        onCancel: (() -> Void)? = nil,
        onConfirm: @escaping (String) -> Void
    ) -> AppAlertController {
        let config = AppAlertConfig(
            title: title,
            message: "",
            confirmText: confirmText,
            cancelText: cancelText,
            showCancel: true,
            onCancel: onCancel,
            showInput: true,
            inputPlaceholder: placeholder,
            inputValue: defaultValue,
            onConfirmWithInput: onConfirm,
            inputKeyboardType: keyboardType,
            inputRestrictAlphanumeric: restrictAlphanumeric
        )
        return present(config: config)
    }

    /// 统一呈现入口
    @discardableResult
    private static func present(config: AppAlertConfig) -> AppAlertController {
        let alertVC = AppAlertController(config: config)
        alertVC.modalPresentationStyle = .overFullScreen
        alertVC.modalTransitionStyle = .crossDissolve

        // 获取当前最顶层的 ViewController
        if let topVC = UIViewController.topViewController {
            topVC.present(alertVC, animated: true)
        }
        return alertVC
    }
    
}



// MARK: - 弹框控制器

final class AppAlertController: UIViewController, UITextFieldDelegate {

    private let config: AppAlertConfig

    // MARK: - UI

    /// 半透明蒙层
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        return view
    }()

    /// 弹框卡片容器
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16.fit
        view.clipsToBounds = true
        return view
    }()
    
    /// 关闭按钮
    private let closeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "alert_close"), for: .normal)
        return btn
    }()

    /// 标题 Label
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = AppColor.textMain
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    /// 副标题 / 描述 Label
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = AppColor.textMain
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true  // 启用交互以支持点击
        return label
    }()

    /// 输入框
    private let inputTextField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 14)
        tf.textColor = AppColor.textMain
        tf.layer.cornerRadius = 8
        tf.layer.masksToBounds = true
        tf.layer.borderWidth = 1
        tf.keyboardType = .default
        tf.layer.borderColor = UIColor(hex: "#F0F0F0").cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.rightViewMode = .always
        return tf
    }()

    /// 按钮分隔线
//    private let buttonTopLine: UIView = {
//        let view = UIView()
//        view.backgroundColor = UIColor(hex: "#E5E5E5")
//        return view
//    }()

    /// 双按钮中间竖线
    private let buttonMiddleLine: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    /// 取消按钮
    private let cancelButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitleColor(AppColor.textMain, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 23
        btn.clipsToBounds = true
        btn.layer.borderWidth = 1
        btn.layer.borderColor = AppColor.buttonDark.cgColor
        return btn
    }()

    /// 确认按钮
    private let confirmButton: UIButton = {
        let btn = UIButton(type: .custom)
        let gradientColor = UIColor.gradientTextColor(size: CGSizeMake(100, 26), colors: [UIColor(hex: "#A2EF4D"),
                                                                                  UIColor(hex: "#F7FFFF"),                               UIColor(hex: "#F7FFFF")])
        btn.setTitleColor(gradientColor, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.layer.cornerRadius = 23
        btn.clipsToBounds = true
        btn.backgroundColor = AppColor.buttonDark
        return btn
    }()

    // MARK: - Init

    init(config: AppAlertConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        configureContent()
        addSubviews()
        setupConstraints()
        bindActions()
    }

    // MARK: - Configure

    private func configureContent() {
        titleLabel.text = config.title
        messageLabel.text = config.message
        messageLabel.textAlignment = config.messageAlignment
        confirmButton.setTitle(config.confirmText, for: .normal)

        if config.showCancel {
            cancelButton.setTitle(config.cancelText, for: .normal)
        }
        
        if config.showInput {
            inputTextField.placeholder = config.inputPlaceholder
            inputTextField.text = config.inputValue
            inputTextField.delegate = self
            inputTextField.returnKeyType = .done
            inputTextField.keyboardType = config.inputKeyboardType
        }
        
        // 处理用户协议和隐私协议的变色和点击
        setupAttributedMessage()
    }
    
    /// 设置富文本，让《用户协议》和《隐私协议》变色并支持点击
    private func setupAttributedMessage() {
        let fullText = config.message
        let attributedString = NSMutableAttributedString(string: fullText)
        let normalColor = AppColor.textMain
        let linkColor = AppColor.theme
    
        // 查找《用户协议》
        if let range = fullText.range(of: "《用户服务协议》") {
            let nsRange = NSRange(range, in: fullText)
            attributedString.addAttribute(.foregroundColor, value: linkColor, range: nsRange)
//            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
        }
        
        // 查找《隐私政策》
        if let range = fullText.range(of: "《隐私协议》") {
            let nsRange = NSRange(range, in: fullText)
            attributedString.addAttribute(.foregroundColor, value: linkColor, range: nsRange)
//            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
        }
        
        messageLabel.attributedText = attributedString
    }

    private func addSubviews() {
        view.addSubviews(overlayView, cardView)
        // 添加关闭按钮到 view 上，放在 cardView 上方
        view.addSubview(closeButton)

        // 双按钮模式才需要分割线和取消按钮
        if config.showCancel {
            if config.showInput {
                cardView.addSubviews(titleLabel, inputTextField, buttonMiddleLine, cancelButton, confirmButton)
            } else {
                cardView.addSubviews(titleLabel, messageLabel, buttonMiddleLine, cancelButton, confirmButton)
            }
        } else {
            cardView.addSubviews(titleLabel, messageLabel, confirmButton)
        }
    }

    // MARK: - Constraints

    private func setupConstraints() {
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        cardView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().priority(.medium)
            // 允许弹框内容多时向上偏移，不被压缩
            make.top.greaterThanOrEqualToSuperview().offset(60.fit)
            // 防止卡片底部超出屏幕，导致按钮被截断
            make.bottom.lessThanOrEqualToSuperview().offset(-60.fit)
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().offset(-40)
        }
        
        // 关闭按钮约束：位于 cardView 右上角的外面
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(cardView.snp.top).offset(5)
            make.right.equalTo(cardView.snp.right).offset(-5)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }

        if config.showInput {
            inputTextField.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(12)
                make.left.equalToSuperview().offset(28)
                make.right.equalToSuperview().offset(-28)
                make.height.equalTo(44)
            }
        } else {
            messageLabel.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(12)
                make.left.equalToSuperview().offset(28)
                make.right.equalToSuperview().offset(-28)
            }
        }

        if config.showCancel {
            let contentView = config.showInput ? inputTextField : messageLabel
            buttonMiddleLine.snp.makeConstraints { make in
                make.top.equalTo(contentView.snp.bottom).offset(10)
                make.bottom.equalToSuperview()
                make.centerX.equalToSuperview()
                make.width.equalTo(0.5)
            }
            cancelButton.snp.makeConstraints { make in
                make.top.equalTo(contentView.snp.bottom).offset(20)
                make.bottom.equalToSuperview().offset(-10)
                make.right.equalTo(buttonMiddleLine.snp_leftMargin).offset(-18)
                make.height.equalTo(48)
                make.width.equalTo(120)
            }

            confirmButton.snp.makeConstraints { make in
                make.top.bottom.height.width.equalTo(cancelButton)
                make.left.equalTo(buttonMiddleLine.snp.right).offset(8)
            }
        } else {
            // 单按钮布局：无分割线，按钮与 messageLabel 之间留间距
            confirmButton.snp.makeConstraints { make in
                make.top.equalTo(messageLabel.snp.bottom).offset(24)
                make.right.equalToSuperview().offset(-28)
                make.left.equalToSuperview().offset(28)
                make.height.equalTo(44)
                make.bottom.equalToSuperview().offset(-20)
            }
        }

       
    }

    // MARK: - Actions

    private func bindActions() {
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        // 添加关闭按钮点击事件
        closeButton.addTarget(self, action: #selector(overlayTapped), for: .touchUpInside)

        let overlayTap = UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
        overlayView.addGestureRecognizer(overlayTap)
        
        // 添加点击手势监听用户协议和隐私协议
        let messageTap = UITapGestureRecognizer(target: self, action: #selector(messageTapped))
        messageLabel.addGestureRecognizer(messageTap)
    }
    
    @objc private func messageTapped(_ gesture: UITapGestureRecognizer) {
        guard let attributedText = messageLabel.attributedText else { return }
        
        let tapLocation = gesture.location(in: messageLabel)
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: messageLabel.bounds.size)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = messageLabel.numberOfLines
        textContainer.lineBreakMode = messageLabel.lineBreakMode
        
        let characterIndex = layoutManager.characterIndex(for: tapLocation, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        // 检查是否点击在《用户服务协议》上
        if let range = attributedText.string.range(of: "《用户服务协议》") {
            let nsRange = NSRange(range, in: attributedText.string)
            if NSLocationInRange(characterIndex, nsRange) {
                cancelTapped()
                config.onAgreementTap?()
                return
            }
        }
        
        // 检查是否点击在《隐私政策》上
        if let range = attributedText.string.range(of: "《隐私协议》") {
            let nsRange = NSRange(range, in: attributedText.string)
            if NSLocationInRange(characterIndex, nsRange) {
                cancelTapped()
                config.onPrivacyTap?()
                return
            }
        }
    }

    @objc private func confirmTapped() {
        dismiss(animated: true) {
            if self.config.showInput {
                self.config.onConfirmWithInput?(self.inputTextField.text ?? "")
            } else {
                self.config.onConfirm?()
            }
        }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true) {
            self.config.onCancel?()
        }
    }
    
    @objc private func overlayTapped() {
        // 点击蒙层只关闭弹窗，不触发回调
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        confirmTapped()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard config.inputRestrictAlphanumeric else { return true }
        // 空字符串允许（退格操作）
        if string.isEmpty { return true }
        // 只允许字母和数字
        let allowed = CharacterSet.alphanumerics
        return string.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}

// MARK: - UIViewController 扩展：获取最顶层 VC

extension UIViewController {

    /// 获取当前最顶层的 ViewController
    static var topViewController: UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        guard let windowScene = scenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else {
            return nil
        }
        return topFrom(rootVC)
    }

    private static func topFrom(_ vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return topFrom(presented)
        }
        if let nav = vc as? UINavigationController, let visible = nav.visibleViewController {
            return topFrom(visible)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return topFrom(selected)
        }
        return vc
    }
}
