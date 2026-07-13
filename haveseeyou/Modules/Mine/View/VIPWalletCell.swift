//
//  VIPWalletCell.swift
//  haveseeyou
//
//  Created by admin on 2026/6/9.
//

import UIKit
import SnapKit

class VIPWalletCell: UIView {

    // MARK: - 回调闭包
    var onVipTapped: (() -> Void)?
    var onWalletTapped: (() -> Void)?

    // 1. 定义 UI 元素
    // --- 左侧：VIP 卡片 ---
    private let vipContainer = UIView()
    private let vipTitleLabel = UILabel()
    private let vipValueLabel = UILabel()
    private let vipImageView = UIImageView()

    // --- 右侧：钱包 卡片 ---
    private let walletContainer = UIView()
    private let walletTitleLabel = UILabel()
    private let walletValueLabel = UILabel()
    private let walletImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        // 添加子视图到主视图
        addSubview(vipContainer)
        addSubview(walletContainer)

        // --- 配置 VIP 卡片内容 ---
        vipContainer.backgroundColor = UIColor(hex: "#2A2A2C") // 深灰色背景
        vipContainer.layer.cornerRadius = 8
        vipContainer.clipsToBounds = true
        vipContainer.isUserInteractionEnabled = true
        let vipTap = UITapGestureRecognizer(target: self, action: #selector(vipTapped))
        vipContainer.addGestureRecognizer(vipTap)

        vipTitleLabel.text = "会员升级特权"
        vipTitleLabel.font = .systemFont(ofSize: 14)
        vipTitleLabel.textColor = .lightGray

        vipValueLabel.text = "VIP"
        vipValueLabel.font = .boldSystemFont(ofSize: 22)
        vipValueLabel.textColor = .white

        vipImageView.image = UIImage(named: "me_updateVip")
        vipImageView.contentMode = .scaleAspectFit

        vipContainer.addSubviews([vipTitleLabel, vipValueLabel, vipImageView])

        // --- 配置 钱包 卡片内容 ---
        walletContainer.backgroundColor = UIColor(hex: "#2A2A2C")
        walletContainer.layer.cornerRadius = 8
        walletContainer.clipsToBounds = true
        walletContainer.isUserInteractionEnabled = true
        let walletTap = UITapGestureRecognizer(target: self, action: #selector(walletTapped))
        walletContainer.addGestureRecognizer(walletTap)

        walletTitleLabel.text = "我的钱包"
        walletTitleLabel.font = .systemFont(ofSize: 14)
        walletTitleLabel.textColor = .lightGray

        walletValueLabel.text = "0"
        walletValueLabel.font = .boldSystemFont(ofSize: 22)
        walletValueLabel.textColor = .white

        walletImageView.image = UIImage(named: "member_bg_coin_icon")
        walletImageView.contentMode = .scaleAspectFit

        walletContainer.addSubviews([walletTitleLabel, walletValueLabel, walletImageView])

        // ==========================================
        //           Masonry 布局开始
        // ==========================================

        // 1. 布局 VIP 卡片 (左侧)
        vipContainer.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview().inset(0) // 贴左边、上边、下边
            make.right.equalTo(walletContainer.snp.left).offset(-10) // 距离右边卡片 10pt
            make.width.equalTo(walletContainer) // 可选：让两个卡片等宽
        }

        // VIP 卡片内部布局
        vipTitleLabel.snp.makeConstraints { make in
            make.left.top.equalToSuperview().inset(12) // 左上角内边距
            make.height.equalTo(20)                    // 设置固定高度为 20
        }
        vipValueLabel.snp.makeConstraints { make in
            make.left.equalTo(vipTitleLabel) // 与标题左对齐
            make.top.equalTo(vipTitleLabel.snp.bottom).offset(4) // 在标题下方
            make.bottom.equalToSuperview().inset(12) // 底部留白
        }
        vipImageView.snp.makeConstraints { make in
            make.centerY.equalTo(vipContainer) // 垂直居中
            make.right.equalToSuperview().inset(12) // 靠右
            make.width.height.equalTo(40) // 固定图标大小
        }


        // 2. 布局 钱包 卡片 (右侧)
        walletContainer.snp.makeConstraints { make in
            make.right.top.bottom.equalToSuperview().inset(0) // 贴右边、上边、下边
            // width 已经在上面通过 equalTo 限制了，这里不需要再写
        }

        // 钱包 卡片内部布局
        walletTitleLabel.snp.makeConstraints { make in
            make.left.top.equalToSuperview().inset(12)
            make.height.equalTo(20)
        }
        walletValueLabel.snp.makeConstraints { make in
            make.left.equalTo(walletTitleLabel)
            make.top.equalTo(walletTitleLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().inset(12)
        }
        walletImageView.snp.makeConstraints { make in
            make.centerY.equalTo(walletContainer)
            make.right.equalToSuperview().inset(12)
            make.width.height.equalTo(40)
        }
    }
    
    // MARK: - 点击事件处理
        @objc private func vipTapped() {
            onVipTapped?()
        }
        
        @objc private func walletTapped() {
            onWalletTapped?()
        }
    
    // MARK: - 更新活动币余额
    func updateCoinCount(_ count: Int) {
        walletValueLabel.text = "\(count)"
    }
}




// 辅助扩展方法，方便添加多个子视图
extension UIView {
    func addSubviews(_ views: [UIView]) {
        views.forEach { addSubview($0) }
    }
}
