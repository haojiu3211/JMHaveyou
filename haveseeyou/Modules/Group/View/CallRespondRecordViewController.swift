import UIKit
import SnapKit
import Combine

class CallRespondRecordViewController: BaseViewController {

    private var records: [InformRecordItem] = []
    private var currentPage = 1
    private let pageSize = 9
    private var isLoadinga = false
    private var hasMore = true

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .white
        tv.separatorStyle = .singleLine
        tv.register(InformRecordCell.self, forCellReuseIdentifier: InformRecordCell.identifier)
        tv.separatorStyle = .none
        return tv
    }()

    private let refreshControl = UIRefreshControl()

    private let emptyStateView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    private let emptyImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "group_defalut")
        return iv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = AppColor.textSecondary
        l.text = "暂未发起活动哦，快去看看把~"
        l.textAlignment = .center
        return l
    }()

    override func setupUI() {
        view.backgroundColor = .white
        view.addSubviews(tableView, emptyStateView)
        emptyStateView.addSubviews(emptyImageView, emptyLabel)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.bottom.equalToSuperview()
            
        }

        emptyStateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        emptyImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(120)
        }

        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyImageView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }

        tableView.dataSource = self
        tableView.delegate = self

        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        navigationItem.title = "发起记录"
        loadRecords()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }

    private func loadRecords() {
        currentPage = 1
        fetchRecords(page: currentPage)
    }

    @objc private func handleRefresh() {
        currentPage = 1
        hasMore = true
        fetchRecords(page: currentPage)
    }

    private func fetchRecords(page: Int) {
        guard !isLoadinga else { return }
        isLoadinga = true

        NetworkManager.shared
            .request(PublishAPI.informMyLists(page: page, limit: pageSize),
                     as: InformRecordListData.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoadinga = false
                self.refreshControl.endRefreshing()
                #if DEBUG
                if case let .failure(error) = completion {
                    print("❌ [CallRespond] 我的记录请求失败: \(error.localizedDescription)")
                }
                #endif
            }, receiveValue: { [weak self] data in
                guard let self = self else { return }
                self.isLoadinga = false
                self.refreshControl.endRefreshing()
                
                if page == 1 {
                    self.records = data.list ?? []
                } else {
                    self.records.append(contentsOf: data.list ?? [])
                }
                
                if let list = data.list, list.count < self.pageSize {
                    self.hasMore = false
                }
                
                self.tableView.reloadData()
                self.updateEmptyState()
            })
            .store(in: &cancellables)
    }

    private func updateEmptyState() {
        emptyStateView.isHidden = !records.isEmpty
    }
}

extension CallRespondRecordViewController: UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InformRecordCell.identifier, for: indexPath) as? InformRecordCell else {
            return UITableViewCell()
        }
        cell.configure(with: records[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 220
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !isLoadinga, hasMore else { return }

        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.height

        if offsetY > 0 && offsetY > contentHeight - frameHeight - 100 {
            currentPage += 1
            fetchRecords(page: currentPage)
        }
    }
}

class InformRecordCell: UITableViewCell {
    static let identifier = "InformRecordCell"

    private let bgView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.05
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 4
        return v
    }()

    private let activityTypeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = AppColor.textMain
        return l
    }()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColor.textSecondary
        l.textAlignment = .right
        return l
    }()

    private let cityLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = AppColor.textMain
        return l
    }()

    private let ageLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = AppColor.textMain
        return l
    }()

    private let genderLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = AppColor.textMain
        return l
    }()

    private let inviteCountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = AppColor.textMain
        return l
    }()

    private let coinLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = AppColor.textMain
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = AppColor.textMain
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.addSubview(bgView)
//        bgView.addSubviews(activityTypeLabel, statusLabel, cityLabel, ageLabel, genderLabel, inviteCountLabel, coinLabel, timeLabel)
        bgView.addSubviews(activityTypeLabel, statusLabel, cityLabel, ageLabel, genderLabel, inviteCountLabel, timeLabel)

        bgView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-8)
        }

        activityTypeLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
        }

        statusLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(16)
        }

        cityLabel.snp.makeConstraints { make in
            make.left.equalTo(activityTypeLabel)
            make.top.equalTo(activityTypeLabel.snp.bottom).offset(12)
        }

        ageLabel.snp.makeConstraints { make in
            make.left.equalTo(activityTypeLabel)
            make.top.equalTo(cityLabel.snp.bottom).offset(12)
        }

        genderLabel.snp.makeConstraints { make in
            make.left.equalTo(activityTypeLabel)
            make.top.equalTo(ageLabel.snp.bottom).offset(12)
        }

        inviteCountLabel.snp.makeConstraints { make in
            make.left.equalTo(activityTypeLabel)
            make.top.equalTo(genderLabel.snp.bottom).offset(12)
        }

//        coinLabel.snp.makeConstraints { make in
//            make.left.equalTo(activityTypeLabel)
//            make.top.equalTo(inviteCountLabel.snp.bottom).offset(12)
//        }

        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(activityTypeLabel)
            make.top.equalTo(inviteCountLabel.snp.bottom).offset(12)
        }
    }

    func configure(with record: InformRecordItem) {
        activityTypeLabel.text = "活动类型: \(record.activityType ?? "")"
        statusLabel.text = record.statusText
        statusLabel.textColor = record.statusColor
        cityLabel.text = "选择城市: \(record.cityName ?? "")"
        ageLabel.text = "年龄区间: \(record.ageMin ?? 0)-\(record.ageMax ?? 0)岁"
        genderLabel.text = "性别选择: \(record.genderText)"
        
        // 根据状态显示邀请人数
        if record.status == "2" {
            inviteCountLabel.text = "邀请人数: \(record.inviteCount ?? "")人（已邀请)"
        }else {
            inviteCountLabel.text = "邀请人数: \(record.inviteCount ?? "")人"
        }
        
        
//        coinLabel.text = "消耗活动金币: 0枚"
        timeLabel.text = "活动邀请时间: \(record.formatTime())"
    }
}

struct InformRecordListData: Decodable {
    let list: [InformRecordItem]?
    let total: Int?
    let page: Int?
    let totalPage: Int?

    enum CodingKeys: String, CodingKey {
        case list, total, page
        case totalPage = "total_page"
    }
}

struct InformRecordItem: Decodable {
    let id: Int?
    let meetActivityId: Int?
    let ageMin: Int?
    let ageMax: Int?
    let gender: String?
    let inviteCount: String?
    let cityId: Int?
    let status: String?
    let createtime: Int?
    let meetActivity: MeetActivityItem?

    enum CodingKeys: String, CodingKey {
        case id, gender, status, createtime
        case meetActivityId = "meet_activity_id"
        case ageMin = "age_min"
        case ageMax = "age_max"
        case inviteCount = "invite_count"
        case cityId = "city_id"
        case meetActivity = "meet_activity"
    }

    var cityName: String? {
        guard let cityId = cityId else { return nil }
        return CityDataManager.cityName(for: cityId)
    }

    var activityType: String? {
        meetActivity?.title
    }

    var statusText: String {
        switch status {
        case "0": return "待邀请"
        case "1": return "邀请中"
        case "2": return "已邀请"
        case "3": return "邀请失败"
        default: return "未知"
        }
    }

    var statusColor: UIColor {
        switch status {
        case "1": return UIColor(hex: "#80DE19")
        default: return UIColor(hex: "#A6A6A6")
        }
    }

    var genderText: String {
        switch gender {
        case "0": return "不限"
        case "1": return "女"
        case "2": return "男"
        default: return "不限"
        }
    }

    func formatTime() -> String {
        guard let ts = createtime else { return "" }
        let date = Date(timeIntervalSince1970: TimeInterval(ts))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

struct MeetActivityItem: Decodable {
    let id: Int?
    let title: String?
}
