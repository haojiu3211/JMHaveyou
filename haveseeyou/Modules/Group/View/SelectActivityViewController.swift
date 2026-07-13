//
//  SelectActivityViewController.swift
//  haveseeyou
//
//  选择活动页面 - 展示所有活动（不含待审核），单选，底部悬浮确认按钮
//

import UIKit
import SnapKit
import Combine

final class SelectActivityViewController: BaseViewController {

    /// 子类重写：使用标准返回按钮
    override var useStandardBackButton: Bool { true }

    // MARK: - Properties

    /// 所有可选活动（不含待审核）
    private var activities: [PublishModel] = []

    /// 外部传入的活动列表
    var externalActivities: [PublishModel]?

    /// 当前选中的索引
    private var selectedIndex: Int = 0

    /// 确认按钮回调 - 返回选中的活动模型
    var onActivitySelected: ((PublishModel) -> Void)?

    // MARK: - UI Components

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.separatorStyle = .none
        tv.backgroundColor = AppColor.background
        tv.showsVerticalScrollIndicator = false
        tv.register(SelectActivityCell.self, forCellReuseIdentifier: SelectActivityCell.reuseID)
        tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
        return tv
    }()

    /// 底部确认按钮容器（悬浮在 tableView 之上）
    private let bottomContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    /// 确认按钮
    private let confirmButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("确认", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        let gradientColor = UIColor.gradientTextColor(size: CGSize(width: 100, height: 48), colors: sy_gradientArr)
        btn.setTitleColor(gradientColor, for: .normal)
        btn.backgroundColor = AppColor.buttonDark
        btn.layer.cornerRadius = 24
        btn.clipsToBounds = true
        return btn
    }()

    // MARK: - Lifecycle

    override func setupUI() {
        view.backgroundColor = AppColor.background
        title = "选择活动"

        view.addSubview(tableView)
        view.addSubview(bottomContainer)
        bottomContainer.addSubview(confirmButton)

        tableView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(bottomContainer.snp.top)
        }

        bottomContainer.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(88)
        }

        confirmButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
            make.height.equalTo(48)
        }

        // 代理 & 数据源
        tableView.dataSource = self
        tableView.delegate = self

        // 按钮事件
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        // 加载数据
        loadData()
    }

    // MARK: - Data

    private func loadData() {
        if let external = externalActivities {
            activities = external
            selectedIndex = activities.isEmpty ? -1 : 0
            tableView.reloadData()
        } else {
            fetchMyListsFromServer()
        }
    }

    private func fetchMyListsFromServer() {
        NetworkManager.shared
            .request(PublishAPI.myLists(page: 1,
                                        limit: 20,
                                        status: "published",
                                        gender: "",
                                        activityType: "",
                                        cityId: ""),
                     as: MyActivityListData.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure = completion {
                    self?.loadFromLocal()
                }
            }, receiveValue: { [weak self] data in
                guard let self = self else { return }
                let items = data.list ?? []
                if items.isEmpty {
                    self.loadFromLocal()
                } else {
                    self.activities = items.map { Self.convert($0) }
                    self.selectedIndex = self.activities.isEmpty ? -1 : 0
                    self.tableView.reloadData()
                }
            })
            .store(in: &cancellables)
    }

    private func loadFromLocal() {
        let allActivities = PublishDataManager.shared.getPublishedActivities()
        activities = allActivities.filter { $0.status != .pending }
        selectedIndex = activities.isEmpty ? -1 : 0
        tableView.reloadData()
    }

    private static func convert(_ item: MyActivityItem) -> PublishModel {
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

    @objc private func confirmTapped() {
        guard selectedIndex >= 0 && selectedIndex < activities.count else {
            AppToast.show("请选择一个活动")
            return
        }

        let selectedActivity = activities[selectedIndex]

        // 如果有回调，走回调
        if let callback = onActivitySelected {
            callback(selectedActivity)
            navigationController?.popViewController(animated: true)
        } else {
            // 没有回调，push 到 CallRespondViewController
            let callRespondVC = CallRespondViewController(activity: selectedActivity)
            navigationController?.pushViewController(callRespondVC, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension SelectActivityViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectActivityCell.reuseID, for: indexPath) as! SelectActivityCell
        let model = activities[indexPath.row]
        cell.configure(with: model, isSelected: indexPath.row == selectedIndex)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180.fit
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        tableView.reloadData()
    }
}
