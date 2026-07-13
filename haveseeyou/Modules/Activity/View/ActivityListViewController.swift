//
//  ActivityListViewController.swift
//  haveseeyou
//
//  活动列表页面 - 展示所有活动，多选，底部悬浮确认按钮
//
//

import UIKit
import SnapKit
import Combine

final class ActivityListViewController: BaseViewController {
    
    /// 子类重写：使用标准返回按钮
    override var useStandardBackButton: Bool { true }
    
    // MARK: - Properties
    
    /// 所有活动列表数据
    private var activities: [PublishModel] = []
    
    /// 外部传入的活动列表（可选）
    var externalActivities: [PublishModel]?
    
    /// 当前选中的索引集合（支持多选）
    private var selectedIndices: Set<Int> = []
    
    /// 确认按钮回调 - 返回所有选中的活动模型数组
    var onActivitiesSelected: (([PublishModel]) -> Void)?
    
    // MARK: - UI Components
    
    /// 主 tableView 展示活动列表
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.separatorStyle = .none
        tv.backgroundColor = AppColor.background
        tv.showsVerticalScrollIndicator = false
        tv.register(SelectActivityCell.self, forCellReuseIdentifier: SelectActivityCell.reuseID)
        tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        return tv
    }()
    

    
    /// 底部确认按钮
    private let confirmButton: UIButton = {
        let btn = UIButton(type: .custom)
        let gradientColor = UIColor.gradientTextColor(size: CGSize(width: 100, height: 48), colors: sy_gradientArr)
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
        title = "选择活动"
        
        // 添加视图层级
        view.addSubview(tableView)
        view.addSubview(confirmButton)
        
        // 设置约束
        setupConstraints()
        
        // 设置代理和数据源
        tableView.dataSource = self
        tableView.delegate = self
        
        // 按钮点击事件
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        
        // 加载数据
        loadData()
    }
    
    /// 设置约束
    private func setupConstraints() {
        // tableView 约束
        tableView.snp.makeConstraints { make in
            make.top.left.right.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(confirmButton.snp.top).offset(-20)
        }
        
        // 确认按钮约束
        confirmButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().offset(-32)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-44)
            make.height.equalTo(48)
        }
    }
    
    // MARK: - Data Loading
    
    /// 加载数据 - 优先使用外部传入的活动列表，否则从服务器获取
    private func loadData() {
        if let external = externalActivities {
            activities = external
            tableView.reloadData()
        } else {
            fetchActivitiesFromServer()
        }
    }
    
    /// 从服务器获取活动列表
    private func fetchActivitiesFromServer() {
        // TODO: 替换为实际的活动列表 API
        // 这里使用模拟数据，你可以根据实际需求修改 API 接口
        NetworkManager.shared
            .request(PublishAPI.myLists(page: 1,
                                        limit: 50,
                                        status: "", // 所有状态的活动
                                        gender: "",
                                        activityType: "",
                                        cityId: ""),
                     as: MyActivityListData.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure = completion {
                    self?.loadFromLocalData()
                }
            }, receiveValue: { [weak self] data in
                guard let self = self else { return }
                let items = data.list ?? []
                if items.isEmpty {
                    self.loadFromLocalData()
                } else {
                    self.activities = items.map { Self.convertActivityItem($0) }
                    self.tableView.reloadData()
                }
            })
            .store(in: &cancellables)
    }
    
    /// 从本地数据加载（兜底方案）
    private func loadFromLocalData() {
        let allActivities = PublishDataManager.shared.getPublishedActivities()
        activities = allActivities
        tableView.reloadData()
    }
    
    /// 将 MyActivityItem 转换为 PublishModel
    private static func convertActivityItem(_ item: MyActivityItem) -> PublishModel {
        var model = PublishModel()
        model.id = item.id.map { "\($0)" }
        model.title = item.title ?? ""
        model.description = item.content ?? ""
        model.coverImages = item.imageList
        model.participantCount = item.peopleNum ?? 1
        
        switch item.gender {
        case 1: model.genderRequirement = .female
        case 2: model.genderRequirement = .male
        default: model.genderRequirement = .unlimited
        }
        
        if (item.isLongTerm ?? 0) == 1 || (item.activityTime ?? 0) <= 0 {
            model.timeType = .longTerm
            model.specificTime = nil
        } else {
            model.timeType = .specific
            model.specificTime = Date(timeIntervalSince1970: TimeInterval(item.activityTime ?? 0))
        }
        
        model.city = item.location ?? ""
        model.category = item.activityTypeNames
        
        switch item.feeType {
        case "free":    model.expenseType = .free
        case "shared":  model.expenseType = .average
        case "you_pay": model.expenseType = .yourBuy
        case "i_pay":   model.expenseType = .myBuy
        default:        model.expenseType = .free
        }
        
        switch item.status {
        case "published": model.status = .ongoing
        case "expired":   model.status = .expired
        default:          model.status = .pending
        }
        
        return model
    }
    
    // MARK: - Actions
    
    @objc private func confirmButtonTapped() {
        guard !selectedIndices.isEmpty else {
            AppToast.show("请至少选择一个活动")
            return
        }
        
        // 收集所有选中的活动
        let selectedActivities = selectedIndices.compactMap { index in
            index >= 0 && index < activities.count ? activities[index] : nil
        }
        
        // 调用回调并返回所有选中的活动
        if let callback = onActivitiesSelected {
            callback(selectedActivities)
            navigationController?.popViewController(animated: true)
        } else {
            // 如果没有设置回调，显示提示 toast（或者你可以添加其他逻辑）
            AppToast.show("已选择 \(selectedActivities.count) 个活动")
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ActivityListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectActivityCell.reuseID, for: indexPath) as! SelectActivityCell
        let model = activities[indexPath.row]
        let isSelected = selectedIndices.contains(indexPath.row)
        cell.configure(with: model, isSelected: isSelected)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180.fit
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 切换选中状态：如果已选中则取消选中，未选中则添加到选中集合
        if selectedIndices.contains(indexPath.row) {
            selectedIndices.remove(indexPath.row)
        } else {
            selectedIndices.insert(indexPath.row)
        }
        // 刷新当前行以更新 UI
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
