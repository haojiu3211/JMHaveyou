//
//  MenberCenterView.swift
//  haveseeyou
//
//  Created by admin开发测试 on 2026/6/12.
//

import UIKit
import SnapKit

// MARK: - MenberCenterView 代理
protocol MenberCenterViewDelegate: AnyObject {
    func memberViewDidClickUpgrade(_ view: MenberCenterView, selectedPlan: PlanItem)
    func memberViewDidClickAgreement(_ view: MenberCenterView)
    func memberViewDidClickRestore(_ view: MenberCenterView)
    func memberViewDidToggleAgreement(_ view: MenberCenterView, isAgreed: Bool)
    func memberViewDidClickUserAgreement(_ view: MenberCenterView)
    func memberViewDidClickPrivacyAgreement(_ view: MenberCenterView)
}

class MenberCenterView: UIView {
    
    weak var delegate: MenberCenterViewDelegate?
    
    private var selectedPlan: PlanItem?
    
    // 模拟数据
    var plans = [
        PlanItem(title: "加载中...", price: "---", dailyPrice: "--元/天", isRecommended: true, isSeleted:true, productId: "com.defult_vip", vipId: -1000, vipGoodsId: "-1111")
    ]
    let agreementBtn = UIButton(type: .system)
    let restoreBtn = UIButton(type: .system)
    

    
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        // 这里替换成你实际的深色背景图资源名称
        iv.image = UIImage(named: "member_center_bg")
//        iv.contentMode = .scaleToFill®
        return iv
    }()
    
    private lazy var collectionView: UICollectionView = {
            let layout = createLayout()
            let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
            cv.backgroundColor = .clear // 透明背景，透出底下的图片
            cv.dataSource = self
            cv.delegate = self
            cv.isScrollEnabled = false // 禁用滚动
            cv.register(MenberCenterViewCell.self, forCellWithReuseIdentifier: "menbercentercell")
            cv.showsHorizontalScrollIndicator = false // 隐藏滚动条
            return cv
        }()
    
    private let disclaimerLabel: UILabel = {
        let label = UILabel()
        label.text = "所有订阅都会自动续订,直到您在付费期结束前至少24小时取消请阅为止。账户将在当期结束前的24小时内收取继续订阅费用,并显示续订金额。购买订阅后,您可以对其进行管理并在iTunes账户的设置中关闭自动续订。"
        label.numberOfLines = 0 // 允许无限换行
        label.alpha = 1
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = UIColor.white
        label.textAlignment = .left
        return label
    }()
    
    // 1. 创建按钮
    private let upgradeButton: UIButton = {
        let button = UIButton(type: .system)
        let gradientColor = UIColor.gradientTextColor(
            size: CGSize(width: kScreenWidth-62, height: 50),
            colors: [
                UIColor(hex: "#FFE8C1"),
                UIColor(hex: "#FFC25B")
            ]
        )
        button.backgroundColor = gradientColor
        // 设置圆角（高度的一半即可变成胶囊状，这里假设高度约为 48-50）
        button.layer.cornerRadius = 24
        button.setTitle("¥ 198 升级VIP特权", for: .normal)
        // 设置文字颜色和大小
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.isEnabled = false // 默认不可用
        button.alpha = 0.4 // 默认半透明
        return button
    }()
    

    
    // 2. 封装一个设置下划线的方法，避免重复代码
    func setupUnderlineButton(_ btn: UIButton, title: String) {
        let attrString = NSAttributedString(
            string: title,
            attributes: [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor(hex: "#999999")
            ]
        )
        btn.alpha = 0.7
        btn.setAttributedTitle(attrString, for: .normal)
    }
    
    private lazy var agreementContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// 协议文本
    private let agreementLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .white.withAlphaComponent(0.6)
        label.textAlignment = .center
        label.numberOfLines = 0
        
        let fullText = "购买即同意《连续包月服务协议》《用户服务协议》《隐私协议》"
        let attrStr = NSMutableAttributedString(string: fullText)
        let fullRange = NSRange(location: 0, length: fullText.count)
        attrStr.addAttribute(.foregroundColor, value: UIColor.white.withAlphaComponent(0.6), range: fullRange)
        
        // 高亮协议链接
        let textRange = (fullText as NSString).range(of:"《连续包月服务协议》")
        attrStr.addAttribute(.foregroundColor, value: UIColor(hex: "#F6D242"), range: textRange)
        
        let textRange1 = (fullText as NSString).range(of:"《用户服务协议》")
        attrStr.addAttribute(.foregroundColor, value: UIColor(hex: "#F6D242"), range: textRange1)
        
        let textRange2 = (fullText as NSString).range(of:"《隐私协议》")
        attrStr.addAttribute(.foregroundColor, value: UIColor(hex: "#F6D242"), range: textRange2)

        
        label.attributedText = attrStr
        label.isUserInteractionEnabled = true
        label.textAlignment = .left
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    /// 协议勾选按钮
    private let agreementCheckbox: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "member_check_no"), for: .normal)
        btn.setImage(UIImage(named: "member_check_yes"), for: .selected)
        btn.contentMode = .scaleAspectFit
        return btn
    }()
    
    
    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
       
        upgradeButton.addTarget(self, action: #selector(upgradeTapped), for: .touchUpInside)
        agreementBtn.addTarget(self, action: #selector(payTextDelegateTapped), for: .touchUpInside)
        restoreBtn.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
        let agreementTap = UITapGestureRecognizer(target: self, action: #selector(agreementTapped(_:)))
        agreementLabel.addGestureRecognizer(agreementTap)
        agreementCheckbox.addTarget(self, action: #selector(checkboxToggled), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup UI

    private func setupUI() {
        self.backgroundColor = UIColor.clear//UIColor(hex: "#18181A")
        
        self.setupUnderlineButton(restoreBtn, title: "恢复内购")
        
        // 添加子视图
        addSubview(backgroundImageView)
        addSubview(collectionView)
        addSubview(disclaimerLabel)
        addSubview(upgradeButton)
        addSubview(restoreBtn)
        addSubview(agreementContainerView)
        addSubview(agreementLabel)
        addSubview(agreementCheckbox)
        
        // 使用 SnapKit 进行布局
        backgroundImageView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
//            make.height.equalTo(340)
        }
        collectionView.snp.makeConstraints { make in
              make.top.equalTo(backgroundImageView.snp.top).offset(10)
              make.left.equalToSuperview().offset(0) // 左边距
              make.right.equalToSuperview().offset(0) // 右边距
              make.height.equalTo(130) // 卡片高度
              make.bottom.lessThanOrEqualToSuperview() // 防止超出父视图
          }
        
        // 使用 SnapKit 设置约束
        disclaimerLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)   // 距离左边 16
            make.trailing.equalToSuperview().offset(-16) // 距离右边 16
            make.top.equalTo(collectionView.snp.bottom).offset(16) // 距离 collectionView 底部 16 (可根据需要调整)
            // 注意：不需要设置 height 约束，numberOfLines = 0 会让 label 根据文字内容自动撑开高度
        }
        
        upgradeButton.snp.makeConstraints { make in
                make.top.equalTo(disclaimerLabel.snp.bottom).offset(18)
                make.left.equalToSuperview().offset(31)
                make.right.equalToSuperview().offset(-31)
                make.height.equalTo(50)
                make.bottom.lessThanOrEqualToSuperview().offset(-30)
            }
        
        addSubview(restoreBtn)

        restoreBtn.snp.makeConstraints { make in
            make.top.equalTo(upgradeButton.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        
        // 协议勾选 + 协议文本：整体距离左右各 10，文本换行；勾选框与第一行文字对齐
        agreementCheckbox.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(38)
            make.top.equalTo(restoreBtn.snp.bottom).offset(12)
            make.width.height.equalTo(20)
        }

        agreementLabel.snp.makeConstraints { make in
            make.left.equalTo(agreementCheckbox.snp.right).offset(6)
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalTo(agreementCheckbox)
        }
        
        
    }
    
}

// MARK: - 事件处理
extension MenberCenterView {
    @objc private func upgradeTapped() {
        guard let plan = selectedPlan ?? plans.first(where: { $0.isSeleted }) else {
            return
        }
        delegate?.memberViewDidClickUpgrade(self, selectedPlan: plan)
    }
    
    @objc private func payTextDelegateTapped() {
        delegate?.memberViewDidClickAgreement(self)
    }
    
    @objc private func restoreTapped() {
        delegate?.memberViewDidClickRestore(self)
    }
    
    @objc private func agreementTapped(_ gesture: UITapGestureRecognizer) {
        guard let text = agreementLabel.text else { return }
        let nsText = text as NSString
        
        // 检测各个协议的点击范围
        let continuousRange = nsText.range(of: "《连续包月服务协议》")
        let userRange = nsText.range(of: "《用户服务协议》")
        let privacyRange = nsText.range(of: "《隐私协议》")
        
        let location = gesture.location(in: agreementLabel)
        
        // 判断点击的是哪个协议
        if let continuousRect = rectFor(range: continuousRange), continuousRect.contains(location) {
            // 点击连续包月协议
            print("连续包月服务协议")
            delegate?.memberViewDidClickAgreement(self)
        } else if let userRect = rectFor(range: userRange), userRect.contains(location) {
            // 点击用户服务协议
            print("用户服务协议")
            delegate?.memberViewDidClickUserAgreement(self)
        } else if let privacyRect = rectFor(range: privacyRange), privacyRect.contains(location) {
            // 点击隐私协议
            print("隐私协议")
            delegate?.memberViewDidClickPrivacyAgreement(self)
        } else {
            // 点击非链接区域，切换勾选状态
            checkboxToggled()
        }
    }
    
    private func rectFor(range: NSRange) -> CGRect? {
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: agreementLabel.bounds.size)
        let textStorage = NSTextStorage(attributedString: agreementLabel.attributedText ?? NSAttributedString(string: ""))
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }
    
    @objc private func checkboxToggled() {
        agreementCheckbox.isSelected = !agreementCheckbox.isSelected
        
        UIView.animate(withDuration: 0.2) {
            if self.agreementCheckbox.isSelected {
                // 勾选后，按钮可用
                self.upgradeButton.isEnabled = true
                self.upgradeButton.alpha = 1.0
            } else {
                // 取消勾选，按钮不可用
                self.upgradeButton.isEnabled = false
                self.upgradeButton.alpha = 0.4
            }
        }
        
        delegate?.memberViewDidToggleAgreement(self, isAgreed: agreementCheckbox.isSelected)
    }
}

// MARK: - Public Methods
extension MenberCenterView {
    /// 更新产品列表
    func updatePlans(_ newPlans: [PlanItem]) {
        for (index, plan) in newPlans.enumerated() {
            if index < plans.count {
                plans[index] = plan
            } else {
                plans.append(plan)
            }
        }
        collectionView.reloadData()
    }
    
    /// 从VIP产品数据更新产品列表
    func updateWithVipProducts(_ products: [VipProductItem]) {
        var newPlans: [PlanItem] = []
        
        // 先创建所有产品
        for (index, product) in products.enumerated() {
            let plan = PlanItem(
                title: product.name ?? "VIP",
                price: "\(product.price ?? 0)",
                dailyPrice: product.dayDesc ?? "",
                isRecommended: false, // 先默认不推荐
                isSeleted: index == 0, // 默认选中第一个
                productId: product.startIosProductId ?? "",
                vipId: product.vipId,
                vipGoodsId: "\(product.id ?? 0)"
            )
            newPlans.append(plan)
        }
        
        // 找出单价最低的产品
        if !newPlans.isEmpty {
            var lowestPriceIndex = 0
            var lowestPrice: Double = Double.greatestFiniteMagnitude
            
            for (index, plan) in newPlans.enumerated() {
                // 从 dailyPrice 中提取数字，比如 "6.6元/天" -> 6.6
                if let priceValue = extractPrice(from: plan.dailyPrice) {
                    if priceValue < lowestPrice {
                        lowestPrice = priceValue
                        lowestPriceIndex = index
                    }
                }
            }
            
            // 将单价最低的产品设置为推荐
            newPlans[lowestPriceIndex].isRecommended = true
        }
        
        self.plans = newPlans
        
        // 设置默认选中项
        if let firstPlan = plans.first {
            selectedPlan = firstPlan
            updateUpgradeButton(with: firstPlan)
        }
        
        collectionView.reloadData()
    }
    
    /// 从字符串中提取价格数字
    private func extractPrice(from text: String) -> Double? {
        // 使用正则表达式匹配数字
        let pattern = "\\d+(\\.\\d+)?"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        
        let range = Range(match.range, in: text)!
        let numberString = String(text[range])
        return Double(numberString)
    }
    
    /// 获取当前勾选状态
    var isAgreed: Bool {
        return agreementCheckbox.isSelected
    }
}

extension MenberCenterView {
   
}

extension MenberCenterView:UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // MARK: - Layout (关键：创建横向滚动布局)
    private func createLayout() -> UICollectionViewCompositionalLayout {
      
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(115),
            heightDimension: .absolute(135)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        item.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 0, trailing: 0)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(115),
            heightDimension: .absolute(135)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous

        return UICollectionViewCompositionalLayout(section: section)
    }
       // MARK: - DataSource
       func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
           return plans.count
       }
       
       func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
           let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "menbercentercell", for: indexPath) as! MenberCenterViewCell
           cell.configure(with: plans[indexPath.item])
           return cell
       }
    
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 1. 将所有项的选中状态设为 false
        for i in 0..<plans.count {
            plans[i].isSeleted = false
        }
        
        // 2. 将当前点击的项设为 true
        plans[indexPath.item].isSeleted = true
        selectedPlan = plans[indexPath.item]
        
        // 3. 刷新整个列表以更新 UI（或者使用 reloadItems 刷新可见的 Cell）
        collectionView.reloadData()
        
        // 4. 更新按钮显示
        updateUpgradeButton(with: selectedPlan)
    }
    
    private func updateUpgradeButton(with plan: PlanItem?) {
        guard let plan = plan else { return }
        upgradeButton.setTitle("¥ \(plan.price) 升级VIP特权", for: .normal)
    }
    
}
