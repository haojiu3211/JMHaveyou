//
//  CityPickerViewController.swift
//  haveseeyou
//
//  城市选择页面
//  支持搜索、热门城市、字母索引列表
//  选中城市后通过闭包回调返回上一页
//

import UIKit
import SnapKit

final class CityPickerViewController: BaseViewController {
    
    // MARK: - 回调
    
    /// 选中城市后的回调
    var onCitySelected: ((String) -> Void)?
    
    // MARK: - 配置
    
    /// 是否使用 hotCities2（包含"全国"选项）
    var useHotCities2: Bool = true
    
    // MARK: - 数据
    
    private let groupedCities = CityDataManager.groupedCities
    private var searchResults: [CityItem] = []
    private var isSearching = false
    
    
    /// 搜索栏
    private lazy var searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "输入城市名、拼音或首字母查询"
        bar.delegate = self
        bar.backgroundImage = UIImage()
        bar.searchBarStyle = .minimal
        bar.backgroundColor = .white
        
        bar.searchTextField.clearButtonMode = .never
        bar.tintColor = AppColor.textMain
        let tf = bar.searchTextField
        
        tf.font = .systemFont(ofSize: 14)
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 8
        tf.clipsToBounds = true
        tf.textColor = AppColor.textMain
        // placeholder颜色
        tf.attributedPlaceholder = NSAttributedString(
            string: "输入城市名、拼音或首字母查询",
            attributes: [
                .foregroundColor: AppColor.textSecondary
            ]
        )
        let image = UIImage(named: "sy_city_search")?
            .withTintColor(.gray, renderingMode: .alwaysOriginal)

        tf.leftView = UIImageView(image: image)
        bar.setPositionAdjustment(
            UIOffset(horizontal: 8, vertical: 0),
            for: .search
        )
        
        return bar
    }()
    
    /// 主列表
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.dataSource = self
        tv.delegate = self
        tv.separatorInset = UIEdgeInsets(top: 0, left: 38.fit, bottom: 0, right: 0)
        tv.keyboardDismissMode = .onDrag
        tv.sectionIndexColor = AppColor.textSecondary
        tv.backgroundColor = .white
        tv.sectionIndexBackgroundColor = .clear
        tv.register(CityCell.self, forCellReuseIdentifier: "CityCell")
        tv.register(CitySectionHeader.self, forHeaderFooterViewReuseIdentifier: "CitySectionHeader")
        tv.register(HotCityHeaderView.self, forHeaderFooterViewReuseIdentifier: "HotCityHeaderView")
        return tv
    }()
    
    /// 右侧字母索引
    private lazy var alphabetView: CityIndexView = {
        let iv = CityIndexView(titles: CityDataManager.sectionIndexTitles)
        iv.onSelect = { [weak self] index in
            guard let self = self, !self.isSearching else { return }
            if index < self.groupedCities.count {
                // section 0 是热门城市，字母分组从 section 1 开始，需要 +1 偏移
                self.tableView.scrollToRow(
                    at: IndexPath(row: 0, section: index + 1),
                    at: .top,
                    animated: false
                )
            }
        }
        return iv
    }()
    
    // MARK: - Lifecycle
    
    override func setupUI() {
        title = "城市选择"
        view.backgroundColor = .white
        
        view.addSubviews(searchBar, tableView, alphabetView)
        
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.equalToSuperview().offset(14)
            make.right.equalToSuperview().offset(-14)
            make.height.equalTo(50)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.left.bottom.right.equalToSuperview()
        }
        
        alphabetView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-2)
            make.top.equalTo(tableView).offset(30)
            make.bottom.equalTo(tableView).offset(-20)
            make.width.equalTo(20)
        }
    }
    
}

// MARK: - UITableViewDataSource

extension CityPickerViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // 非搜索时：section 0 = 热门城市，section 1~N = 字母分组
        return isSearching ? 1 : groupedCities.count + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return searchResults.count
        }
        // section 0 是热门城市，字母分组从 section 1 开始
        if section == 0 { return 0 }
        return groupedCities[section - 1].cities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath) as! CityCell
        let name: String
        if isSearching {
            name = searchResults[indexPath.row].name
        } else {
            // 字母分组从 section 1 开始，需要 -1 偏移
            name = groupedCities[indexPath.section - 1].cities[indexPath.row].name
        }
        cell.backgroundColor = .white
        cell.separatorInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 0)
        cell.configure(name)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension CityPickerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    
        let name: String
        if isSearching {
            name = searchResults[indexPath.row].name
        } else {
            // 字母分组从 section 1 开始，需要 -1 偏移
            name = groupedCities[indexPath.section - 1].cities[indexPath.row].name
        }
    
        onCitySelected?(name)
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Section Header
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if isSearching {
            return nil
        }

        if section == 0 {
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HotCityHeaderView") as! HotCityHeaderView
            let cities = useHotCities2 ? CityDataManager.hotCities2 : CityDataManager.hotCities
            header.configure(cities: cities) { [weak self] (city: String) in
                self?.onCitySelected?(city)
                self?.navigationController?.popViewController(animated: true)
            }
            return header
        }

        // section 0 是热门城市，字母分组从 section 1 开始，需要 -1 偏移
        let letterSection = section - 1
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "CitySectionHeader") as! CitySectionHeader
        header.configure(groupedCities[letterSection].letter)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if isSearching { return 0 }
        return section == 0 ? HotCityHeaderView.height : CitySectionHeader.height
    }
    
    // MARK: - Section Index（禁用系统自带索引，使用自定义 alphabetView）
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return nil
    }
}

// MARK: - UISearchBarDelegate

extension CityPickerViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let keyword = searchText.trimmingCharacters(in: .whitespaces)
        if keyword.isEmpty {
            isSearching = false
            searchResults = []
        } else {
            isSearching = true
            searchResults = CityDataManager.search(keyword)
        }
        // 搜索时隐藏右侧字母索引
        alphabetView.isHidden = isSearching
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        isSearching = false
        searchResults = []
        searchBar.resignFirstResponder()
        // 恢复右侧字母索引
        alphabetView.isHidden = false
        tableView.reloadData()
    }
}

// MARK: - 城市列表 Cell

private final class CityCell: UITableViewCell {
    
    let titleLb:UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 15)
        lb.textColor = AppColor.textMain
        return lb
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        accessoryType = .none
        contentView.addSubview(titleLb)
        titleLb.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(_ name: String) {
        titleLb.text = name
    }
}

// MARK: - 字母分组 Header

private final class CitySectionHeader: UITableViewHeaderFooterView {
    
    static let height: CGFloat = 30
    
    private let label: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 13, weight: .medium)
        lb.textColor = AppColor.textSecondary
        return lb
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor(hex: "#F8F8F8")
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(_ letter: String) {
        label.text = letter
    }
}

// MARK: - 热门城市 Header

private final class HotCityHeaderView: UITableViewHeaderFooterView {
    
    static let height: CGFloat = 200
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "热门城市"
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = AppColor.textSecondary
        return l
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: 98.fit, height: 32)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(HotCityCell.self, forCellWithReuseIdentifier: "HotCityCell")
        cv.dataSource = self
        cv.delegate = self
        cv.isUserInteractionEnabled = true
        cv.backgroundColor = .clear
        return cv
    }()
    
    private var cities: [String] = []
    private var onSelect: ((String) -> Void)?
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .white
        contentView.addSubviews(titleLabel, collectionView)
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(22)
            make.top.equalToSuperview().offset(10)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(22)
            make.right.equalToSuperview().offset(-28.fit)
            make.bottom.equalToSuperview().offset(-8)
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(cities: [String], onSelect: @escaping (String) -> Void) {
        self.cities = cities
        self.onSelect = onSelect
        collectionView.reloadData()
    }
}

// MARK: - HotCityHeaderView CollectionView

extension HotCityHeaderView: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cities.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "HotCityCell", for: indexPath) as! HotCityCell
        cell.configure(cities[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelect?(cities[indexPath.item])
    }
}

// MARK: - 热门城市 Cell

private final class HotCityCell: UICollectionViewCell {
    
    private let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = AppColor.textMain
        l.textAlignment = .center
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = AppColor.background
        contentView.layer.cornerRadius = 7.fit
        contentView.clipsToBounds = true
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(_ name: String) {
        label.text = name
    }
}

// MARK: - 右侧字母索引视图

private final class CityIndexView: UIView {
    
    var onSelect: ((Int) -> Void)?
    private var titles: [String] = []
    private var itemHeight: CGFloat = 0
    
    init(titles: [String]) {
        self.titles = titles
        super.init(frame: .zero)
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        itemHeight = bounds.height / CGFloat(max(titles.count, 1))
    }
    
    override func draw(_ rect: CGRect) {
        guard itemHeight > 0 else { return }
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: AppColor.textSecondary
        ]
        for (i, title) in titles.enumerated() {
            let y = CGFloat(i) * itemHeight
            let size = title.size(withAttributes: attrs)
            let point = CGPoint(x: (bounds.width - size.width) / 2,
                                y: y + (itemHeight - size.height) / 2)
            title.draw(at: point, withAttributes: attrs)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches)
    }
    
    private func handleTouch(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        let index = Int(point.y / max(itemHeight, 1))
        guard index >= 0, index < titles.count else { return }
        onSelect?(index)
    }
}
