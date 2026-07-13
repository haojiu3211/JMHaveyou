//
//  AccountDeletionAlertView.swift
//  haveseeyou
//
//  注销账号弹框 - 独立封装的 UIView
//

import UIKit
import SnapKit

final class AccountDeletionAlertView: UIView {

    // MARK: - Callbacks

    /// 点击确认注销
    var onConfirmDeletion: (() -> Void)?

    /// 点击退出账号（仅退出，不注销）
    var onExitAccount: (() -> Void)?

    // MARK: - UI Components

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
    private lazy var closeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
        btn.tintColor = .black
        btn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return btn
    }()

    /// 顶部图片
    private let topImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "sy_delet_account")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    /// 提示文案 Label
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = AppColor.textMain
        label.numberOfLines = 0
        label.textAlignment = .center
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        let attrString = NSMutableAttributedString(
            string: "尊敬的用户您好，给您带来不好的体验\n我们深感抱歉，如您只是暂时不使用 \"见了么\" APP,可以选择 \"退出账号\"，平台将保留您的相关权益。",
            attributes: [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: AppColor.textMain,
                .paragraphStyle: paragraphStyle
            ]
        )
        label.attributedText = attrString
        return label
    }()

    /// 确认注销按钮
    private let confirmButton: UIButton = {
        let btn = UIButton(type: .custom)
        let gradientColor = UIColor.gradientTextColor(
            size: CGSizeMake(100, 26),
            colors: [UIColor(hex: "#A2EF4D"), UIColor(hex: "#F7FFFF"), UIColor(hex: "#F7FFFF")]
        )
        btn.setTitleColor(gradientColor, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.setTitle("确认注销", for: .normal)
        btn.layer.cornerRadius = 23
        btn.clipsToBounds = true
        btn.backgroundColor = AppColor.buttonDark
        return btn
    }()

    /// 退出账号按钮
    private lazy var exitButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("退出账号", for: .normal)
        btn.setTitleColor(AppColor.buttonDark, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.addTarget(self, action: #selector(exitTapped), for: .touchUpInside)
        return btn
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        bindActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear

        addSubviews(overlayView, cardView)
        cardView.addSubviews(closeButton, topImageView, messageLabel, confirmButton, exitButton)
    }

    private func setupConstraints() {
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        cardView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().priority(.medium)
            make.top.greaterThanOrEqualToSuperview().offset(80.fit)
            make.bottom.lessThanOrEqualToSuperview().offset(-80.fit)
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().offset(-40)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
            make.size.equalTo(28)
        }

        topImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(174.fit)
            make.height.equalTo(109.fit)
        }

        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(topImageView.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
        }

        confirmButton.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(24)
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
            make.height.equalTo(46)
        }

        exitButton.snp.makeConstraints { make in
            make.top.equalTo(confirmButton.snp.bottom).offset(14)
            make.centerX.equalToSuperview()
            make.height.equalTo(30)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    private func bindActions() {
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        let overlayTap = UITapGestureRecognizer(target: self, action: #selector(closeTapped))
        overlayView.addGestureRecognizer(overlayTap)
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss()
    }

    @objc private func confirmTapped() {
        dismiss { [weak self] in
            self?.onConfirmDeletion?()
        }
    }

    @objc private func exitTapped() {
        dismiss { [weak self] in
            self?.onExitAccount?()
        }
    }

    // MARK: - Show / Dismiss

    /// 显示弹框（添加到当前 Window）
    static func show(
        onConfirmDeletion: (() -> Void)? = nil,
        onExitAccount: (() -> Void)? = nil
    ) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }

        let alertView = AccountDeletionAlertView()
        alertView.onConfirmDeletion = onConfirmDeletion
        alertView.onExitAccount = onExitAccount

        alertView.frame = window.bounds
        alertView.alpha = 0
        window.addSubview(alertView)

        UIView.animate(withDuration: 0.25) {
            alertView.alpha = 1
        }
    }

    /// 隐藏弹框
    private func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
}
