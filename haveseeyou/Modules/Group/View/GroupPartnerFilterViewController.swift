//
//  GroupPartnerFilterViewController.swift
//  haveseeyou
//
//  搭子筛选页面
//
//

import UIKit
import SnapKit

// MARK: - TagFlowView

/// 标签流式布局视图，支持单选
final class PartnerTagFlowView: UIView {

    var onSelectionChanged: ((Int) -> Void)?

    private(set) var selectedIndex: Int = 0

    private var tags: [UIButton] = []

    private let tagHeight: CGFloat = 34
    private let hSpacing: CGFloat = 10
    private let vSpacing: CGFloat = 10
    private let hPadding: CGFloat = 18
    

    private var heightConstraint: Constraint?



    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(titles: [String], selectedIndex: Int = -1) {
        self.selectedIndex = selectedIndex
        tags.forEach { $0.removeFromSuperview() }
        tags.removeAll()


        for (index, title) in titles.enumerated() {
            let btn = makeTagButton(title: title, selected: index == selectedIndex)
            btn.tag = index
            btn.addTarget(self, action: #selector(tagTapped(_:)), for: .touchUpInside)
            addSubview(btn)
            tags.append(btn)
        }

        setNeedsLayout()
    }

    func updateSelectedIndex(_ index: Int) {
        selectedIndex = index
       
        tags.forEach { $0.isHidden = false }

        for (i, tag) in tags.enumerated() {
            updateAppearance(tag, selected: i == selectedIndex)
        }

        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        relayoutTags()
    }

    private func relayoutTags() {
        guard selectedIndex != -1 else { return }

        var x: CGFloat = 0
        var y: CGFloat = 0
        let maxWidth = bounds.width

        for tag in tags {
            let intrinsicW = tag.titleLabel?.intrinsicContentSize.width ?? 0
            let w = intrinsicW + hPadding * 2

            if x + w > maxWidth, x > 0 {
                x = 0
                y += tagHeight + vSpacing
            }

            tag.frame = CGRect(x: x, y: y, width: w, height: tagHeight)
            x += w + hSpacing
        }

        let totalHeight = tags.isEmpty ? tagHeight : (y + tagHeight)
        heightConstraint?.update(offset: totalHeight)
    }

    func makeHeightConstraint(_ maker: ConstraintMaker) {
        heightConstraint = maker.height.equalTo(tagHeight).constraint
    }

    // MARK: - Tag Button Style

    private func makeTagButton(title: String, selected: Bool) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.layer.cornerRadius = tagHeight / 2
        btn.clipsToBounds = true
        updateAppearance(btn, selected: selected)
        return btn
    }

    private func updateAppearance(_ btn: UIButton, selected: Bool) {
        if selected {
            let gtc = UIColor.gradientTextColor(size: CGSizeMake(90.fit, 34), colors: [UIColor(hex: "#FFA2EF4D"),UIColor(hex: "#FFC2FF7F")])
            btn.setTitleColor(AppColor.textMain, for: .normal)
            btn.backgroundColor = gtc
            btn.layer.borderWidth = 0
        } else {
            btn.backgroundColor = .white
            btn.setTitleColor(AppColor.textSecondary, for: .normal)
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor(hex: "#FFB9B9B9").cgColor
        }
    }

    @objc private func tagTapped(_ sender: UIButton) {
        selectedIndex = sender.tag
        
        for (i, tag) in tags.enumerated() {
            tag.isHidden = false
            updateAppearance(tag, selected: i == selectedIndex)
        }
        onSelectionChanged?(selectedIndex)
    }
}

// MARK: - CategoryTagContainerView

/// 类别标签容器视图：最多展示 maxVisible 个标签，超出显示 "..."，右侧箭头可点击跳转
final class PartnerCategoryTagContainerView: UIView {

    /// 最多展示的标签数量
    private let maxVisible = 4

    /// 点击回调（跳转 H5 选择页）
    var onTapped: (() -> Void)?

    /// 当前已选类别
    var selectedCategories: [String] = [] {
        didSet { renderTags() }
    }

    // 子视图
    /// 缺省提示标签
    let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "请选择筛选条件"
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor(hex: "#FFB9B9B9")
        return label
    }()
    private let tagContainer = UIView()
    private let arrowImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "app_right"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    private var tagPills: [UIView] = []
    private let ellipsisLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = AppColor.textMain
        l.text = "..."
        l.isHidden = true
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        layer.cornerRadius = 12.fit
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor(hex: "#FFB9B9B9").cgColor
        backgroundColor = .white
        addSubview(placeholderLabel)
        addSubview(tagContainer)
        addSubview(ellipsisLabel)
        addSubview(arrowImageView)

        // 点击手势
        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(containerTapped)))

        placeholderLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(10)
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(10)
            make.size.equalTo(CGSize(width: 14, height: 14))
        }

        tagContainer.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.right.equalTo(arrowImageView.snp.left).offset(-6)
        }

        ellipsisLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(arrowImageView.snp.left).offset(-6)
        }
    }

    // MARK: - 渲染标签

    private func renderTags() {
        tagPills.forEach { $0.removeFromSuperview() }
        tagPills.removeAll()
        
        //计算是否超出一行
        let maxWidth: CGFloat = kScreenWidth - 20.fit - 20 - 30
        let horizontalSpacing: CGFloat = 10.fit
        let horizontalPadding: CGFloat = 20.fit
        
        let font = UIFont.systemFont(
            ofSize: 13,
            weight: .medium
        )
        
        var displayCategories: [String] = []
        var hasMore = false
        var totalWidth: CGFloat = 0
        
        placeholderLabel.isHidden = false
        if(selectedCategories.count > 0){
            placeholderLabel.isHidden = true
        }
        
        for category in selectedCategories {
            
            let textWidth = category.size(
                withAttributes: [
                    .font: font
                ]
            ).width
            
            let tagWidth = textWidth + horizontalPadding
            
            let spacing = displayCategories.isEmpty
            ? 0
            : horizontalSpacing
            
            if totalWidth + spacing + tagWidth > maxWidth {
                hasMore = true
                break
            }
            
            totalWidth += spacing + tagWidth
            
            displayCategories.append(category)
        }
        

//         = Array(selectedCategories.prefix(maxVisible))
//        let hasMore = selectedCategories.count > maxVisible
        
        var lastView: UIView?
        for (_,category) in displayCategories.enumerated() {
            let pill = makeTagPill(category)
            tagContainer.addSubview(pill) 
            pill.snp.makeConstraints { make in
                
                make.centerY.equalToSuperview()
                if let lastView {
                    make.left.equalTo(lastView.snp_rightMargin).offset(10)
                }else{
                    make.left.equalToSuperview()
                }
                
            }
            tagPills.append(pill)
           lastView = pill
        }
        

        ellipsisLabel.isHidden = !hasMore
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutTagPills()
    }

    private func layoutTagPills() {
        let pillH: CGFloat = 28.fit
        let pillY = (bounds.height - pillH) / 2
        let spacing: CGFloat = 6.fit
        let hPadding: CGFloat = 10.fit
        var x: CGFloat = 0

        for pill in tagPills {
            let textW = pill.subviews.compactMap { $0 as? UILabel }.first?.intrinsicContentSize.width ?? 0
            let pillW = textW + hPadding * 2
            pill.frame = CGRect(x: x, y: pillY, width: pillW, height: pillH)
            x += pillW + spacing
        }
    }

    // MARK: - 创建标签胶囊

    private func makeTagPill(_ text: String) -> UIView {
        let container = UIView()
        container.layer.cornerRadius = 14.fit
        container.layer.masksToBounds = true

        // 渐变背景
        let gtc = UIColor.gradientTextColor(
            size: CGSize(width: 90.fit, height: 28.fit),
            colors: [UIColor(hex: "#FFA2EF4D"), UIColor(hex: "#FFC2FF7F")]
        )
        container.backgroundColor = gtc

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = AppColor.textMain
        label.sizeToFit()
        container.addSubview(label)

        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(10.fit)
            make.right.equalToSuperview().offset(-10.fit)
        }

        container.snp.makeConstraints { make in
            make.height.equalTo(28.fit)
            
        }

        return container
    }

    @objc private func containerTapped() {
        onTapped?()
    }
}

// MARK: - GroupPartnerFilterViewController

final class GroupPartnerFilterViewController: BaseViewController {

    /// 筛选结果回调（返回 [String: String] map）
    var onFilterApplied: (([String: String]) -> Void)?

    // MARK: - 数据源

    /// 性别选项（显示文本）
    private let genderOptions = ["不限性别", "只限男生", "只限女生"]
    /// 性别选项对应值（nil = 不筛选）
    private let genderValues: [String?] = [nil, "2", "1"]

    /// 专区选项（显示文本）
    private let zoneOptions = ["全部","推荐","同城", "新人"]
    /// 专区选项对应值（nil = 不筛选）
    private let zoneValues: [String?] = [nil, "recommend", "sameCity", "newbie"]

    /// 当前已选类别（高级VIP筛选）（默认全部选中，即不筛选）
    private var categoryOptions: [String] = []
    

    /// 当前已选城市（默认 nil，即不筛选）
    private var selectedCity: String? = nil

    // MARK: - 选中状态

    private var selectedGenderIndex: Int = 0
    private var selectedZoneIndex: Int = 0
    private var selectedTagIndex: Int = 0

    // MARK: - UI

    private let contentView = UIView()

    // 性别
    private let genderHeader = GroupPartnerFilterViewController.makeSectionHeader("性别")
    private let genderTagView = PartnerTagFlowView()

    // 专区
    private let zoneHeader = GroupPartnerFilterViewController.makeSectionHeader("专区")
    private let zoneTagView = PartnerTagFlowView()

    // 城市
    private let cityHeader = GroupPartnerFilterViewController.makeSectionHeader("城市（高级VIP筛选）")
    private let cityTagView = PartnerCategoryTagContainerView()
    
    // 类别（高级VIP筛选）
    private let categoryHeader = GroupPartnerFilterViewController.makeSectionHeader("类别（高级VIP筛选）")
    private let categoryTagView = PartnerCategoryTagContainerView()
    
    
    
    // 提交按钮
    private let submitButton: UIButton = {
        let btn = UIButton(type: .custom)
        let gtc = UIColor.gradientTextColor(size: CGSizeMake(100, 48), colors: sy_gradientArr)
        btn.setTitle("提交", for: .normal)
        btn.setTitleColor(gtc, for: .normal)
        btn.backgroundColor = AppColor.buttonDark
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btn.layer.cornerRadius = 24
   
        btn.clipsToBounds = true
        return btn
    }()

    // MARK: - Init

    init(currentGender: String? = nil, currentZone: String? = nil, currentCity: String? = nil) {
        super.init(nibName: nil, bundle: nil)
        // 预选性别
        if let gender = currentGender,
           let idx = genderValues.firstIndex(of: gender) {
            selectedGenderIndex = idx
        }
        // 预选专区
        if let zone = currentZone,
           let idx = zoneValues.firstIndex(of: zone) {
            selectedZoneIndex = idx
        }
        // 预选城市
        if let city = currentCity, !city.isEmpty {
            selectedCity = city
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func setupUI() {
        view.backgroundColor = .white
        title = "搭子筛选"

        view.addSubviews(contentView, submitButton)

        contentView.addSubviews(genderHeader, genderTagView, zoneHeader, zoneTagView, cityHeader, cityTagView, categoryHeader, categoryTagView)

        submitButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().offset(-32)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-44)
            make.height.equalTo(48)
        }

        contentView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(submitButton.snp.top).offset(-20)
        }

        // 性别
        genderHeader.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(20)
        }

        genderTagView.snp.makeConstraints { make in
            make.top.equalTo(genderHeader.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(20)
            genderTagView.makeHeightConstraint(make)
        }

        // 专区
        zoneHeader.snp.makeConstraints { make in
            make.top.equalTo(genderTagView.snp.bottom).offset(28)
            make.left.right.equalToSuperview().inset(20)
        }

        zoneTagView.snp.makeConstraints { make in
            make.top.equalTo(zoneHeader.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(20)
            zoneTagView.makeHeightConstraint(make)
        }

        // 城市
        cityHeader.snp.makeConstraints { make in
            make.top.equalTo(zoneTagView.snp.bottom).offset(28)
            make.left.right.equalToSuperview().inset(20)
        }
        cityTagView.placeholderLabel.text = "请选择搭子所在城市"
        cityTagView.snp.makeConstraints { make in
            make.top.equalTo(cityHeader.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(40.fit)
        }

        // 类别（高级VIP筛选）
        categoryHeader.snp.makeConstraints { make in
            make.top.equalTo(cityTagView.snp.bottom).offset(28)
            make.left.right.equalToSuperview().inset(20)
        }

        categoryTagView.snp.makeConstraints { make in
            make.top.equalTo(categoryHeader.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(40.fit)
        }


        // 配置性别标签
        genderTagView.configure(titles: genderOptions, selectedIndex: selectedGenderIndex)
        genderTagView.onSelectionChanged = { [weak self] index in
            self?.selectedGenderIndex = index
        }

        // 配置专区标签
        zoneTagView.configure(titles: zoneOptions, selectedIndex: selectedZoneIndex)
        zoneTagView.onSelectionChanged = { [weak self] index in
            self?.selectedZoneIndex = index
        }

        // 配置城市标签容器
        cityTagView.selectedCategories = selectedCity.map { [$0] } ?? []
        cityTagView.onTapped = { [weak self] in
            self?.cityTapped()
        }

        // 配置类别标签容器
        categoryTagView.selectedCategories = categoryOptions
        categoryTagView.onTapped = { [weak self] in
            self?.pushCategoryH5()
        }

        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
    }

    // MARK: - 类别选择

    private func pushCategoryH5() {
        
        // 判断用户是否是 VIP
        let isVip = (UserManager.shared.vip ?? 0) > 0
        
        if !isVip {
            // 不是 VIP，弹窗提示
            AppAlert.showSingle(
                title: "提示",
                message: "你暂无权限解锁VIP搭子筛选，请选择以下权益进行开通。",
                confirmText: "开通会员",
                messageAlignment: .center
            ) { [weak self] in
                // 点击开通会员，跳转到会员中心
                self?.pushMemberCenter()
            }

        }else {
            
            
            let vc = ActivityTypeListViewController()
            
            // 1. 正向传值：把当前已选择的标签传入
            vc.initialSelectedTags = categoryOptions
            
            // 2. 反向传值：接收用户选择的标签
            vc.onTagsSelected = { [weak self] selectedTags in
                guard let self = self else { return }
                self.categoryOptions = selectedTags
                self.categoryTagView.selectedCategories = selectedTags
            }
            
            navigationController?.pushViewController(vc, animated: true)
        }
       
    }

    /// H5 页面选择完成后调用，更新已选类别
    func updateSelectedCategories(_ categories: [String]) {
        categoryOptions = categories
        categoryTagView.selectedCategories = categoryOptions
    }
    
    // MARK: - 城市选择
    
    @objc private func cityTapped() {
        
        // 判断用户是否是 VIP
        let isVip = (UserManager.shared.vip ?? 0) > 0
        
        if !isVip {
            // 不是 VIP，弹窗提示
            AppAlert.showSingle(
                title: "提示",
                message: "你暂无权限解锁VIP搭子筛选，请选择以下权益进行开通。",
                confirmText: "开通会员",
                messageAlignment: .center
            ) { [weak self] in
                // 点击开通会员，跳转到会员中心
                self?.pushMemberCenter()
            }

        }else {
            
            
            let cityVC = CityPickerViewController()
            cityVC.onCitySelected = { [weak self] cityName in
                self?.selectedCity = cityName
                self?.cityTagView.selectedCategories = [cityName]
            }
            navigationController?.pushViewController(cityVC, animated: true)
            
        }
        
  
    }

    // MARK: - 提交
    
    private func pushMemberCenter() {
        print("🚀 [ActivityDetail] 跳转到会员中心页面")
        let vc = MemberCenterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func submitTapped() {
        
        
    
        var result: [String: String] = [:]

        // 性别
        if let gender = genderValues[selectedGenderIndex] {
            result["gender"] = gender
        }

        // 专区
        if let zone = zoneValues[selectedZoneIndex] {
            result["zone"] = zone
        }

        // 城市：单选
        if let city = selectedCity {
            result["city"] = city
        }

        // 类别：仅在选了部分类别时才筛选（全选 = 不筛选）
        if let first = categoryOptions.first {
            // 多个类别用逗号拼接返回
            result["category"] = categoryOptions.joined(separator: ",")
        }

        onFilterApplied?(result)
        navigationController?.popViewController(animated: true)
        
      
    }

    // MARK: - Section Header 工厂方法

    private static func makeSectionHeader(_ title: String) -> UILabel {
        let l = UILabel()
        l.text = title
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = AppColor.textMain
        return l
    }
}
