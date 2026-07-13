//
//  ActivityTypeListViewController.swift
//  haveseeyou
//
//  活动类型标签列表页面 - 分组展示，一行最多4个标签，大小自适应
//
//

import UIKit
import SnapKit

/// 活动类型分组模型
struct ActivityTypeGroup {
    let title: String       // 分组标题
    let items: [String]     // 分组下的标签列表
}

/// 标签cell - 支持选中状态
final class ActivityTypeTagCell: UICollectionViewCell {
    
    static let reuseID = "ActivityTypeTagCell"
    
    /// 标签按钮
    private let tagButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.layer.cornerRadius = 16
        btn.layer.masksToBounds = true
        btn.layer.borderWidth = 1
        btn.isUserInteractionEnabled = false
        return btn
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(tagButton)
        tagButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(32)
        }
    }
    
    /// 配置cell
    /// - Parameters:
    ///   - title: 标签标题
    ///   - isSelected: 是否选中
    func configure(with title: String, isSelected: Bool) {
        tagButton.setTitle(title, for: .normal)
        
        if isSelected {
            // 选中状态 - 渐变背景
            let gradientColor = UIColor.gradientTextColor(
                size: CGSize(width: 120, height: 32),
                colors: [UIColor(hex: "#FFA2EF4D"), UIColor(hex: "#FFC2FF7F")]
            )
            tagButton.backgroundColor = gradientColor
            tagButton.setTitleColor(AppColor.textMain, for: .normal)
            tagButton.layer.borderColor = UIColor.clear.cgColor
        } else {
            // 未选中状态 - 白色背景
            tagButton.backgroundColor = .white
            tagButton.setTitleColor(AppColor.textSecondary, for: .normal)
            tagButton.layer.borderColor = UIColor(hex: "#FFB9B9B9").cgColor
        }
    }
}

/// 分组header view
final class ActivityTypeHeaderView: UICollectionReusableView {
    
    static let reuseID = "ActivityTypeHeaderView"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = AppColor.textMain
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-8)
        }
    }
    
    func configure(with title: String) {
        titleLabel.text = title
    }
}

/// 活动类型标签列表页面
final class ActivityTypeListViewController: BaseViewController {
    
    /// 子类重写：使用标准返回按钮
    override var useStandardBackButton: Bool { true }
    
    // MARK: - Properties
    
    /// 所有分组数据
    private var groups: [ActivityTypeGroup] = []
    
    /// 外部传入的已选中标签
    var initialSelectedTags: [String] = []
    
    /// 已选中的标签集合
    private var selectedTags: Set<String> = []
    
    /// 确认选择回调
    var onTagsSelected: (([String]) -> Void)?
    
    // MARK: - UI Components
    
    /// 主 collectionView
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 20, right: 16)
        layout.headerReferenceSize = CGSize(width: kScreenWidth, height: 48)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.showsVerticalScrollIndicator = false
        cv.register(ActivityTypeTagCell.self, forCellWithReuseIdentifier: ActivityTypeTagCell.reuseID)
        cv.register(ActivityTypeHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ActivityTypeHeaderView.reuseID)
        return cv
    }()
    

    
    /// 确认按钮
    private let confirmButton: UIButton = {
        let btn = UIButton(type: .custom)
        let gradientColor = UIColor.gradientTextColor(
            size: CGSize(width: 100, height: 48),
            colors: sy_gradientArr
        )
        btn.setTitle("确认选择", for: .normal)
        btn.setTitleColor(gradientColor, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.backgroundColor = AppColor.buttonDark
        btn.layer.cornerRadius = 24
        btn.clipsToBounds = true
        return btn
    }()
    
    // MARK: - Lifecycle
    
    override func setupUI() {
        view.backgroundColor = AppColor.background
        title = "选择活动类型"
        
        // 添加导航栏右上角的清空按钮
        let clearButton = UIBarButtonItem(
            title: "清空",
            style: .plain,
            target: self,
            action: #selector(clearButtonTapped)
        )
        navigationItem.rightBarButtonItem = clearButton
        
        // 添加视图
        view.addSubview(collectionView)
        view.addSubview(confirmButton)
        
        // 设置约束
        setupConstraints()
        
        // 设置代理
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // 按钮点击
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        
        // 加载模拟数据
        loadMockData()
    }
    
    private func setupConstraints() {
        collectionView.snp.makeConstraints { make in
            make.top.left.right.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(confirmButton.snp.top).offset(-20)
        }
        
        confirmButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().offset(-32)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-44)
            make.height.equalTo(48)
        }
    }
    
    // MARK: - Data
    
    /// 加载模拟数据 - 根据截图中的内容
    private func loadMockData() {
        groups = [
            ActivityTypeGroup(
                title: "运动健康",
                items: ["徒步", "羽毛球", "网球", "骑行", "瑜伽", "游泳", "健身", "跑步", "高尔夫", "篮球", "足球", "滑雪", "台球"]
            ),
            ActivityTypeGroup(
                title: "休闲娱乐",
                items: ["脱口秀", "喝茶", "K歌", "蹦迪", "麻将", "电影", "游戏陪玩", "电视剧", "livehouse", "约饭", "探店打卡", "棋牌", "按摩"]
            ),
            ActivityTypeGroup(
                title: "户外游玩",
                items: ["周边游", "露营", "野餐", "citywalk", "海外游", "同城伴游"]
            ),
            ActivityTypeGroup(
                title: "社交脱单",
                items: ["单身派对", "同城约会", "相亲会", "青年联谊"]
            ),
            ActivityTypeGroup(
                title: "文艺生活",
                items: ["艺术展", "音乐会", "舞台剧", "博物馆", "心理沙龙"]
            ),
            ActivityTypeGroup(
                title: "学习成长",
                items: ["读书会", "行业交流", "创业分享", "学习搭子", "技能培训"]
            ),
            ActivityTypeGroup(
                title: "其他类型",
                items: ["其他", "新人报道"]
            )
        ]
        
        // 初始化已选中的标签
        selectedTags = Set(initialSelectedTags)
        
        collectionView.reloadData()
    }
    
    // MARK: - Actions
    
    @objc private func clearButtonTapped() {
        // 清空选中的标签
        selectedTags.removeAll()
        // 刷新整个 collectionView
        collectionView.reloadData()
    }
    
    @objc private func confirmButtonTapped() {
        let selectedArray = Array(selectedTags)
        if let callback = onTagsSelected {
            callback(selectedArray)
            navigationController?.popViewController(animated: true)
        } else {
            AppToast.show("已选择 \(selectedArray.count) 个标签")
        }
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegateFlowLayout

extension ActivityTypeListViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return groups.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groups[section].items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ActivityTypeTagCell.reuseID,
            for: indexPath
        ) as! ActivityTypeTagCell
        
        let tag = groups[indexPath.section].items[indexPath.row]
        let isSelected = selectedTags.contains(tag)
        cell.configure(with: tag, isSelected: isSelected)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: ActivityTypeHeaderView.reuseID,
            for: indexPath
        ) as! ActivityTypeHeaderView
        
        header.configure(with: groups[indexPath.section].title)
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 计算每个标签的宽度：一行最多4个，减去间距
        let totalWidth = collectionView.bounds.width - 32 // 左右各16
        let itemSpacing: CGFloat = 10
        let itemWidth = (totalWidth - 3 * itemSpacing) / 4 // 4个标签，3个间距
        
        return CGSize(width: itemWidth, height: 32)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tag = groups[indexPath.section].items[indexPath.row]
        
        // 切换选中状态
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
        
        // 刷新当前单元格
        collectionView.reloadItems(at: [indexPath])
    }
}
