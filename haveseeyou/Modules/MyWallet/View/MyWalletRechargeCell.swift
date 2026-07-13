
//
//  MyWalletRechargeCell.swift
//  haveseeyou
//
//  Created by admin开发测试 on 2026/7/1.
//

import UIKit
import SnapKit

class MyWalletRechargeItem {
    let coins: String
    let price: String
    let bonus: String?
    let remark: String?
    let isRecommended: Bool
    
    init(coins: String, price: String, bonus: String? = nil, remark: String? = nil, isRecommended: Bool = false) {
        self.coins = coins
        self.price = price
        self.bonus = bonus
        self.remark = remark
        self.isRecommended = isRecommended
    }
}

class MyWalletRechargeCell: UICollectionViewCell {
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#2A2A2C")
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    private let coinsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor(hex: "#FFD700")
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()
    
    private let bonusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor(hex: "#999999")
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()
    
    private let coinIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "member_bg_coin_icon")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let coinsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 6
        return stackView
    }()
    
    private let recommendedTag: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "member_zunshi_biao")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 固定边距
        let padding = 14.0
        let spacing = 6.0
        let iconSize = 28.0
        let verticalSpacing = 8.0
        
        // 更新布局
        containerView.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4))
        }
        
        coinsStackView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(verticalSpacing)
            make.centerX.equalToSuperview()
        }
        
        coinIconImageView.snp.remakeConstraints { make in
            make.width.height.equalTo(iconSize)
        }
        
        bonusLabel.snp.remakeConstraints { make in
            make.top.equalTo(coinsStackView.snp.bottom).offset(verticalSpacing)
            make.centerX.equalToSuperview()
        }
        
        priceLabel.snp.remakeConstraints { make in
            make.top.equalTo(bonusLabel.snp.bottom).offset(verticalSpacing)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-verticalSpacing)
        }
        
        recommendedTag.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(-1)
            make.left.equalToSuperview().offset(-2)
            make.height.equalTo(19)
            make.width.equalTo(56)
        }
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(coinsStackView)
        coinsStackView.addArrangedSubview(coinIconImageView)
        coinsStackView.addArrangedSubview(coinsLabel)
        containerView.addSubview(bonusLabel)
        containerView.addSubview(priceLabel)
        containerView.addSubview(recommendedTag)
    }
    
    func configure(with item: MyWalletRechargeItem) {
        coinsLabel.text = "\(item.coins)"
        priceLabel.text = "¥\(item.price)"
        
        if let remark = item.remark {
            // 把"钻"替换为"活动币"
            let modifiedRemark = remark.replacingOccurrences(of: "钻", with: "活动币")
            bonusLabel.text = modifiedRemark
            bonusLabel.isHidden = false
        } else if let bonus = item.bonus {
            bonusLabel.text = "含额外赠送\(bonus)活动币"
            bonusLabel.isHidden = false
        } else {
            bonusLabel.isHidden = true
        }
        recommendedTag.isHidden = true
        if(item.bonus == "5000"){
            recommendedTag.isHidden = false
        }
       
    }
    
    override var isSelected: Bool {
        didSet {
            updateSelectionState()
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            updateSelectionState()
        }
    }
    
    private func updateSelectionState() {
        if isSelected || isHighlighted {
            containerView.backgroundColor = UIColor(hex: "#121212")
        } else {
            containerView.backgroundColor = UIColor(hex: "#2A2A2C")
        }
    }
}

