//
//  MenberCenterViewCell.swift
//  haveseeyou
//
//  Created by admin开发测试 on 2026/6/12.
//

import UIKit
import SnapKit

// MARK: - 数据模型
class PlanItem {
    let title: String
    let price: String
    let dailyPrice: String
    var isRecommended: Bool // 使用 var 以便修改
    var isSeleted: Bool // 使用 var 以便修改
    let productId: String // StoreKit 产品 ID
    let vipId: Int? // VIP ID
    let vipGoodsId: String? // VIP 商品 ID
    
    init(title: String, price: String, dailyPrice: String, isRecommended: Bool, isSeleted: Bool, productId: String, vipId: Int? = nil, vipGoodsId: String? = nil) {
        self.title = title
        self.price = price
        self.dailyPrice = dailyPrice
        self.isRecommended = isRecommended
        self.isSeleted = isSeleted
        self.productId = productId
        self.vipId = vipId
        self.vipGoodsId = vipGoodsId
    }
}

// MARK: - 自定义 Cell
class MenberCenterViewCell: UICollectionViewCell {
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let dailyLabel = UILabel()
    private let vipImageView = UIImageView() // 性价比推荐标签
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        // 1. 卡片容器 (白色或米色背景)
        contentView.addSubview(containerView)
        containerView.backgroundColor = UIColor.white
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        
        // 2. 标题 (7天)
        containerView.addSubview(titleLabel)
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor(hex: "#333333")
        titleLabel.textAlignment = .center
        
        // 3. 价格 (¥88)
        containerView.addSubview(priceLabel)
        priceLabel.font = UIFont.boldSystemFont(ofSize: 28)
        let gradientColor = UIColor.gradientTextColor(
            size: CGSize(width: 120, height: 30),
            colors: [
                UIColor(hex: "#83500D"),
                UIColor(hex: "#D0A83C")
            ]
        )
        priceLabel.textColor = gradientColor
        
        priceLabel.textAlignment = .center
        
        // 4. 日均价 (12/天)
        containerView.addSubview(dailyLabel)
        dailyLabel.font = UIFont.systemFont(ofSize: 12)
        dailyLabel.textColor = UIColor(hex: "#999999")
        dailyLabel.textAlignment = .center
        
        // 5. 推荐标签 (右上角)
        addSubview(vipImageView)
        vipImageView.image = UIImage(named: "vip_good_img")
        vipImageView.contentMode = .scaleAspectFill
        vipImageView.clipsToBounds = true // 保持圆角或特定形状（如果需要）
        
        // --- SnapKit 布局 ---
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10) // 留一点边距
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.centerX.equalToSuperview()
        }
        
        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.centerX.equalToSuperview()
        }
        
        dailyLabel.snp.makeConstraints { make in
            make.top.equalTo(priceLabel.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview().offset(-15)
        }
        
        // 标签定位在卡片左上角
        vipImageView.snp.makeConstraints { make in
            make.width.equalTo(56)
            make.height.equalTo(21)
            make.leading.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(-2) // 向上移动 7pt
        }
    }
    
    func configure(with item: PlanItem) {
        titleLabel.text = item.title
        priceLabel.text = "¥\(item.price)"
        dailyLabel.text = item.dailyPrice
        vipImageView.isHidden = !item.isRecommended
        
        if (item.isSeleted){
            containerView.backgroundColor = UIColor(hex: "#FFE5BD")
            containerView.layer.borderWidth = 1
            let gradientColor = UIColor.gradientTextColor(
                size: CGSize(width: 130, height: 130),
                colors: [
                    UIColor(hex: "#FFC98B"),
                    UIColor(hex: "#FFD7A8"),
                    UIColor(hex: "#FFAE51")
                ]
            )
            
            containerView.layer.borderColor = gradientColor.cgColor
        }else {
            containerView.backgroundColor = UIColor.white
            containerView.layer.borderWidth = 0
        }
    }
}
