//
//  ActivityFilterViewController.swift
//  haveseeyou
//
//  活动筛选页面 - 时效 + 类别
//

import UIKit
import SnapKit

// MARK: - TagFlowView

/// 标签流式布局视图，支持单选
final class TagFlowView: UIView {

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
final class CategoryTagContainerView: UIView {

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
        label.text = "请选择筛选活动类型"
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

// MARK: - ActivityFilterViewController

final class ActivityFilterViewController: BaseViewController {

    /// 筛选结果回调（返回 [String: String] map）
    var onFilterApplied: (([String: String]) -> Void)?

    // MARK: - 数据源

    /// 性别选项（显示文本）
    private let genderOptions = ["不限性别", "只限男生", "只限女生"]
    /// 性别选项对应值（nil = 不筛选）
    private let genderValues: [String?] = [nil, "2", "1"]

    /// 时效选项（显示文本）
    private let durationOptions = ["不限", "进行中", "已过期"]
    /// 时效选项对应值（nil = 不筛选）
    private let durationValues: [String?] = [nil, "published", "expired"]


    /// 当前已选类别（默认全部选中，即不筛选）
    private var categoryOptions: [String] = []
    

    /// 当前已选城市（默认 nil，即不筛选）
    private var selectedCity: String? = nil

    // MARK: - 选中状态

    private var selectedGenderIndex: Int = 0
    private var selectedDurationIndex: Int = 0
    private var selectedCategoryIndex: Int = 0

    // MARK: - UI

    private let contentView = UIView()

    // 性别
    private let genderHeader = ActivityFilterViewController.makeSectionHeader("性别")
    private let genderTagView = TagFlowView()

    // 时效
    private let durationHeader = ActivityFilterViewController.makeSectionHeader("时效")
    private let durationTagView = TagFlowView()

    // 城市
    private let cityHeader = ActivityFilterViewController.makeSectionHeader("城市（高级VIP筛选）")
    private let cityTagView = CategoryTagContainerView()
    
    // 活动类型
    private let categoryHeader = ActivityFilterViewController.makeSectionHeader("活动类型（高级VIP筛选）")
    private let categoryTagView = CategoryTagContainerView()
    
    
    
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

    init(currentStatus: String? = nil, currentCategory: String? = nil, currentGender: String? = nil, currentCity: String? = nil) {
        super.init(nibName: nil, bundle: nil)
        // 预选性别
        if let gender = currentGender,
           let idx = genderValues.firstIndex(of: gender) {
            selectedGenderIndex = idx
        }
        // 预选时效
        if let status = currentStatus,
           let idx = durationValues.firstIndex(of: status) {
            selectedDurationIndex = idx
        }
        // 预选城市
        if let city = currentCity, !city.isEmpty {
            selectedCity = city
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func setupUI() {
        view.backgroundColor = .white
        title = "活动筛选"

        view.addSubviews(contentView, submitButton)

        contentView.addSubviews(genderHeader, genderTagView, durationHeader, durationTagView, cityHeader, cityTagView, categoryHeader, categoryTagView)

        submitButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(32)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.height.equalTo(48)
        }

        contentView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(submitButton.snp.top).offset(-16)
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

        // 时效
        durationHeader.snp.makeConstraints { make in
            make.top.equalTo(genderTagView.snp.bottom).offset(28)
            make.left.right.equalToSuperview().inset(20)
        }

        durationTagView.snp.makeConstraints { make in
            make.top.equalTo(durationHeader.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(20)
            durationTagView.makeHeightConstraint(make)
        }

        // 城市
        cityHeader.snp.makeConstraints { make in
            make.top.equalTo(durationTagView.snp.bottom).offset(28)
            make.left.right.equalToSuperview().inset(20)
        }
        cityTagView.placeholderLabel.text = "请选择活动的城市"
        cityTagView.snp.makeConstraints { make in
            make.top.equalTo(cityHeader.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(40.fit)
        }

        // 类别
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

        // 配置时效标签
        durationTagView.configure(titles: durationOptions, selectedIndex: selectedDurationIndex)
        durationTagView.onSelectionChanged = { [weak self] index in
            self?.selectedDurationIndex = index
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
        
        if isVip {
            // 是 VIP，直接继续执行
            // 创建 ActivityTypeListViewController
            let activityTypeVC = ActivityTypeListViewController()
            
            // 正向传值：把当前已选择的类型传进去
            if !categoryOptions.isEmpty {
                activityTypeVC.initialSelectedTags = categoryOptions
            }
            
            // 反向传值：接收用户选择的活动类型
            activityTypeVC.onTagsSelected = { [weak self] selectedTypes in
                guard let self = self else { return }
                // 更新数据和 UI
                self.categoryOptions = selectedTypes
                self.categoryTagView.selectedCategories = categoryOptions
            }

            navigationController?.pushViewController(activityTypeVC, animated: true)
        } else {
            // 不是 VIP，弹窗提示
            AppAlert.showSingle(
                title: "提示",
                message: "你暂无权限解锁高级 VIP 筛选，请选择以下权益进行开通。",
                confirmText: "开通会员",
                messageAlignment: .center
            ) { [weak self] in
                // 点击开通会员，跳转到会员中心
                self?.pushMemberCenter()
            }
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
        
        if isVip {
            // 是 VIP，直接继续执行
            let cityVC = CityPickerViewController()
            cityVC.onCitySelected = { [weak self] cityName in
                self?.selectedCity = cityName
                self?.cityTagView.selectedCategories = [cityName]
            }
            navigationController?.pushViewController(cityVC, animated: true)
        } else {
            // 不是 VIP，弹窗提示
            AppAlert.showSingle(
                title: "提示",
                message: "你暂无权限解锁高级 VIP 筛选，请选择以下权益进行开通。",
                confirmText: "开通会员",
                messageAlignment: .center
            ) { [weak self] in
                // 点击开通会员，跳转到会员中心
                self?.pushMemberCenter()
            }
        }
        

    }

    // MARK: - 提交

    @objc private func submitTapped() {
        applyFilterAndPop()
    }
    
    // 实际应用筛选并返回的方法
    private func applyFilterAndPop() {
        var result: [String: String] = [:]

        // 性别
        if let gender = genderValues[selectedGenderIndex] {
            result["gender"] = gender
        }

        // 时效
        if let status = durationValues[selectedDurationIndex] {
            result["status"] = status
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
    
    // 跳转到会员中心
    private func pushMemberCenter() {
        let vc = MemberCenterViewController()
        navigationController?.pushViewController(vc, animated: true)
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
