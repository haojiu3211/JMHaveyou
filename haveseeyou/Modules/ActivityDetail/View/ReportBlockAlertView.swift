//
//  ReportBlockAlertView.swift
//  haveseeyou
//
//  举报拉黑弹框（底部弹出 ActionSheet 样式）
//

import UIKit
import SnapKit

final class ReportBlockAlertView: UIView {

    // MARK: - 回调

    var onReportTapped: (() -> Void)?
    var onBlockTapped: (() -> Void)?
    var onCancelTapped: (() -> Void)?

    // MARK: - UI

    /// 半透明蒙层
    private let overlayView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        v.alpha = 0
        return v
    }()

    /// 底部弹出容器
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        v.transform = CGAffineTransform(translationX: 0, y: 300)
        return v
    }()

    /// 举报按钮
    private let reportButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("举报", for: .normal)
        btn.setTitleColor(AppColor.textMain, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.backgroundColor = .white
        return btn
    }()

    /// 拉黑按钮
    private let blockButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("拉黑", for: .normal)
        btn.setTitleColor(.red, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.backgroundColor = .white
        return btn
    }()

    /// 分隔线
    private let separator1: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F0F0F0")
        return v
    }()

    private let separator2: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F0F0F0")
        return v
    }()

    /// 取消按钮
    private let cancelButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("取消", for: .normal)
        btn.setTitleColor(AppColor.textSecondary, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.backgroundColor = .white
        return btn
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        addSubviews(overlayView, containerView)
        containerView.addSubviews(reportButton, separator1, blockButton, separator2, cancelButton)

        overlayView.snp.makeConstraints { $0.edges.equalToSuperview() }
        containerView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }

        reportButton.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(54)
        }

        separator1.snp.makeConstraints { make in
            make.top.equalTo(reportButton.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        blockButton.snp.makeConstraints { make in
            make.top.equalTo(separator1.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(54)
        }

        separator2.snp.makeConstraints { make in
            make.top.equalTo(blockButton.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(8)
        }

        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(separator2.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(54)
            make.bottom.equalToSuperview().priority(.low)
        }

        // 事件绑定
        reportButton.addTarget(self, action: #selector(reportTapped), for: .touchUpInside)
        blockButton.addTarget(self, action: #selector(blockTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let overlayTap = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
        overlayView.addGestureRecognizer(overlayTap)
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        // 清理所有回调，避免循环引用
        onReportTapped = nil
        onBlockTapped = nil
        onCancelTapped = nil
    }

    // MARK: - 显示/隐藏

    func show(in view: UIView) {
        view.addSubview(self)
        self.snp.makeConstraints { $0.edges.equalToSuperview() }
        layoutIfNeeded()

        UIView.animate(withDuration: 0.25) {
            self.overlayView.alpha = 1
            self.containerView.transform = .identity
        }
    }

    func setBlockButtonTitle(_ title: String) {
        blockButton.setTitle(title, for: .normal)
    }

    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, animations: {
            self.overlayView.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: 300)
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }

    // MARK: - Actions

    @objc private func reportTapped() {
        dismiss { [weak self] in
            self?.onReportTapped?()
        }
    }

    @objc private func blockTapped() {
        dismiss { [weak self] in
            self?.onBlockTapped?()
        }
    }

    @objc private func cancelTapped() {
        dismiss()
    }
}
