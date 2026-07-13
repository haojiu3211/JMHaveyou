//
//  SelectOptionPicker.swift
//  haveseeyou
//
//  通用选项选择器 - 底部弹框形式
//  使用方式：SelectOptionPicker.show(title: "...", options: [...], from: self) { selectedIndex in ... }
//

import UIKit
import SnapKit

// MARK: - 通用选项模型

struct SelectOptionItem {
    let title: String
    let value: Any?
    
    init(title: String, value: Any? = nil) {
        self.title = title
        self.value = value
    }
}

// MARK: - 配置模型

struct SelectOptionConfig {
    /// 弹框标题
    var title: String = ""
    /// 选项列表
    var options: [SelectOptionItem] = []
    /// 已选索引（默认不选中任何）
    var selectedIndex: Int? = nil
    /// 取消按钮文案
    var cancelText: String = "取消"
    /// 确认按钮文案
    var confirmText: String = "确定"
}

// MARK: - 全局调用入口

enum SelectOptionPicker {
    
    /// 弹出通用选项选择器
    static func show(
        title: String,
        options: [String],
        selectedIndex: Int? = nil,
        from viewController: UIViewController,
        onSelected: @escaping (Int, String) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        let items = options.map { SelectOptionItem(title: $0) }
        var config = SelectOptionConfig()
        config.title = title
        config.options = items
        config.selectedIndex = selectedIndex
        
        let picker = SelectOptionPickerController(
            config: config,
            onSelected: { index, _ in
                onSelected(index, options[index])
            },
            onCancel: onCancel
        )
        picker.modalPresentationStyle = .overFullScreen
        picker.modalTransitionStyle = .crossDissolve
        viewController.present(picker, animated: true)
    }
    
    /// 弹出通用选项选择器（带 value）
    static func show(
        config: SelectOptionConfig,
        from viewController: UIViewController,
        onSelected: @escaping (Int, Any?) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        let picker = SelectOptionPickerController(
            config: config,
            onSelected: onSelected,
            onCancel: onCancel
        )
        picker.modalPresentationStyle = .overFullScreen
        picker.modalTransitionStyle = .crossDissolve
        viewController.present(picker, animated: true)
    }
}

// MARK: - 选择器控制器

final class SelectOptionPickerController: UIViewController {

    private let config: SelectOptionConfig
    private let onSelected: ((Int, Any?) -> Void)?
    private let onCancel: (() -> Void)?
    
    private var currentSelectedIndex: Int?
    
    // MARK: - UI

    /// 半透明蒙层
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        return view
    }()

    /// 底部容器卡片
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16.fit
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()

    /// 标题
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = AppColor.textMain
        label.textAlignment = .center
        return label
    }()

    /// 取消按钮
    private let cancelButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("取消", for: .normal)
        btn.setTitleColor(AppColor.textSecondary, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return btn
    }()

    /// 确定按钮
    private let confirmButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("确定", for: .normal)
        btn.setTitleColor(UIColor(hex: "#100A1D"), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return btn
    }()
    
    /// 选项表格
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.backgroundColor = .white
        tableView.register(SelectOptionCell.self, forCellReuseIdentifier: SelectOptionCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.alwaysBounceVertical = false
        return tableView
    }()
    
    /// 顶部分割线
    private let topSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#F5F5F5")
        return view
    }()
    
    /// 底部分割线
    private let bottomSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#F5F5F5")
        return view
    }()

    // MARK: - Init

    init(
        config: SelectOptionConfig,
        onSelected: ((Int, Any?) -> Void)?,
        onCancel: (() -> Void)?
    ) {
        self.config = config
        self.onSelected = onSelected
        self.onCancel = onCancel
        if let selectedIndex = config.selectedIndex {
            self.currentSelectedIndex = selectedIndex
        } else if !config.options.isEmpty {
            // 选中中间位置
            self.currentSelectedIndex = 2
        } else {
            self.currentSelectedIndex = nil
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        configureContent()
        addSubviews()
        setupConstraints()
        bindActions()
    }

    // MARK: - Configure

    private func configureContent() {
        titleLabel.text = config.title
        cancelButton.setTitle(config.cancelText, for: .normal)
        confirmButton.setTitle(config.confirmText, for: .normal)
    }

    private func addSubviews() {
        view.addSubviews(overlayView, cardView)
        cardView.addSubviews(cancelButton, titleLabel, confirmButton, topSeparatorView, tableView, bottomSeparatorView)
    }

    // MARK: - Constraints

    private func setupConstraints() {
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let maxTableHeight = min(CGFloat(config.options.count) * 50, 300)
        
        cardView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }

        cancelButton.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
            make.width.equalTo(80)
            make.height.equalTo(60)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(60)
        }
        
        confirmButton.snp.makeConstraints { make in
            make.top.right.equalToSuperview()
            make.width.equalTo(80)
            make.height.equalTo(60)
        }
        
        topSeparatorView.snp.makeConstraints { make in
            make.top.equalTo(cancelButton.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(topSeparatorView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(maxTableHeight)
        }
        
        bottomSeparatorView.snp.makeConstraints { make in
            make.top.equalTo(tableView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(1)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    // MARK: - Actions

    private func bindActions() {
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        
        let overlayTap = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
        overlayView.addGestureRecognizer(overlayTap)
        
        tableView.delegate = self
        tableView.dataSource = self
    }

    @objc private func cancelTapped() {
        dismiss(animated: true) {
            self.onCancel?()
        }
    }
    
    @objc private func confirmTapped() {
        guard let index = currentSelectedIndex, index < config.options.count else {
            dismiss(animated: true)
            return
        }
        let value = config.options[index].value
        dismiss(animated: true) {
            self.onSelected?(index, value)
        }
    }
}

// MARK: - UITableViewDelegate & DataSource

extension SelectOptionPickerController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return config.options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectOptionCell.reuseIdentifier, for: indexPath) as! SelectOptionCell
        let item = config.options[indexPath.row]
        let isSelected = currentSelectedIndex == indexPath.row
        cell.configure(with: item.title, isSelected: isSelected)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        currentSelectedIndex = indexPath.row
        tableView.reloadData()
    }
}

// MARK: - 选项 Cell

final class SelectOptionCell: UITableViewCell {
    
    static let reuseIdentifier = "SelectOptionCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColor.textMain
        label.textAlignment = .center
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = .white
        contentView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(20)
        }
    }
    
    func configure(with title: String, isSelected: Bool) {
        titleLabel.text = title
        if isSelected {
            titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
            titleLabel.textColor = UIColor(hex: "#100A1D")
        } else {
            titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
            titleLabel.textColor = UIColor(hex: "#C3C3C3")
        }
    }
}
