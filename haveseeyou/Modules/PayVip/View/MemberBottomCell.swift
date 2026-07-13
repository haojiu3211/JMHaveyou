//
//  MemberBottomCell.swift
//  haveseeyou
//
//  Created by admin开发测试 on 2026/6/12.
//

import UIKit
import SnapKit

struct PrivilegeItem {
    let icon: String
    let title: String
    let subtitle: String
}

class MemberBottomCell: UICollectionViewCell {
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1.0) // 深灰背景
        contentView.layer.cornerRadius = 12

        // 图标
        iconImageView.tintColor = UIColor(red: 0.95, green: 0.75, blue: 0.45, alpha: 1.0) // 金色图标
        iconImageView.contentMode = .scaleAspectFit
        contentView.addSubview(iconImageView)

        // 标题
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        contentView.addSubview(titleLabel)

        // 副标题
        subtitleLabel.font = .systemFont(ofSize: 11)
        subtitleLabel.textColor = .gray
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.8
        contentView.addSubview(subtitleLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 根据屏幕宽度计算缩放比例（以96为基准高度）
        let screenWidth = UIScreen.main.bounds.width
        let baseWidth: CGFloat = 375.0 // iPhone 12/13/14 作为基准
        let scale = min(screenWidth / baseWidth, 1.2) // 最大放大到 1.2 倍
        
        // 基于96高度的自适应边距
        let padding = (96.0 - 32.0) / 2.0 * scale // 保持icon在垂直居中的padding
        let spacing = 12.0 * scale
        let iconSize = 32.0 * scale
        let titleFontSize = 14.0 * scale
        let subtitleFontSize = 11.0 * scale
        
        // 更新字体大小
        titleLabel.font = .systemFont(ofSize: titleFontSize, weight: .medium)
        subtitleLabel.font = .systemFont(ofSize: subtitleFontSize)
        
        // 更新布局
        iconImageView.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(8) // 距离左边 8
            make.centerY.equalToSuperview()
            make.width.height.equalTo(iconSize)
        }

        titleLabel.snp.remakeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(spacing)
            make.top.equalToSuperview().offset(padding - 2.0 * scale)
            make.right.equalToSuperview().offset(-8) // 距离右边 25
        }

        subtitleLabel.snp.remakeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4.0 * scale)
            make.right.equalToSuperview().offset(-8) // 距离右边 25
        }
    }

    func configure(with item: PrivilegeItem) {
        iconImageView.image = UIImage(named: item.icon)
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
    }
}
