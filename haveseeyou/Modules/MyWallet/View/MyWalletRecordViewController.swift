//
//  MyWalletRecordViewController.swift
//  haveseeu
//
//  消费记录页面
//

import UIKit
import SnapKit
import Kingfisher
import Combine

class MyWalletRecordViewController: BaseViewController {
    
    private var dataList: [ConsumptionRecordItem] = []
    private var currentPage = 1
    private var pageSize = 10
    private var hasMore = true
    private var isLoadingA = false
//    private var cancellables = Set<AnyCancellable>()
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = AppColor.background
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.register(MyWalletRecordCell.self, forCellReuseIdentifier: MyWalletRecordCell.identifier)
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
        iv.image = UIImage(named: "sy_delet_account")
        return iv
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = AppColor.textSecondary
        label.textAlignment = .center
        label.text = "暂无消费记录"
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    override func setupUI() {
        view.backgroundColor = AppColor.background
        title = "消费记录"
        
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
    }
    
    private func loadData() {
        guard !isLoadingA else { return }
        isLoadingA = true
        
        NetworkManager.shared.request(
            PurchaseAPI.consumptionRecords(
                type: "4", 
                page: "\(currentPage)", 
                limit: "\(pageSize)"
            ),
            as: ConsumptionRecordsResponse.self
        ) { [weak self] result in
            guard let self = self else { return }
            self.isLoadingA = false
            self.refreshControl.endRefreshing()
            
            switch result {
            case .success(let response):
                if let list = response.list {
                    if self.currentPage == 1 {
                        self.dataList = list
                    } else {
                        self.dataList.append(contentsOf: list)
                    }
                }
                
                if let totalPage = response.totalPage {
                    self.hasMore = self.currentPage < totalPage
                } else {
                    self.hasMore = false
                }
                
                self.updateEmptyState()
                self.tableView.reloadData()
                
            case .failure(let error):
                print("❌ 获取消费记录失败: \(error)")
                self.showToast("获取数据失败")
            }
        }
    }
    
    private func updateEmptyState() {
        let isEmpty = dataList.isEmpty
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
    @objc private func handleRefresh() {
        currentPage = 1
        loadData()
    }
}

extension MyWalletRecordViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MyWalletRecordCell.identifier, for: indexPath) as! MyWalletRecordCell
        let item = dataList[indexPath.row]
        cell.configure(with: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == dataList.count - 1 && hasMore && !isLoadingA {
            currentPage += 1
            loadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = dataList[indexPath.row]
        
        guard let userId = item.userId else {
            print("❌ [消费记录] 后台没有返回UID")
            return
        }
        pushUserProfile(userId: "\(userId)")
    }
    
    private func pushUserProfile(userId: String) {
        NetworkManager.shared
            .request(ActivityDetailAPI.personalHomepage(userId: userId), as: PersonalHomepageDataModel.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                if case let .failure(error) = completion {
                    print("❌ [消费记录] 个人主页请求失败: \(error.localizedDescription)")
                    self.showToast("获取用户信息失败")
                }
            } receiveValue: { [weak self] model in
                guard let self = self else { return }
                let vc = PersionViewController()
                vc.model = model
                self.navigationController?.pushViewController(vc, animated: true)
            }
            .store(in: &cancellables)
    }
    
}

// 消费记录Cell
class MyWalletRecordCell: UITableViewCell {
    
    static let identifier = "MyWalletRecordCell"
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 24
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(hex: "#E5E5E5")
        return iv
    }()
    
    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColor.textMain
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = AppColor.textSecondary
        return label
    }()
    
    private let coinLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(hex: "#F7B500")
        label.textAlignment = .right
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
        backgroundColor = .white
        selectionStyle = .gray
        
        contentView.addSubviews(avatarImageView, nicknameLabel, timeLabel, coinLabel)
        
        avatarImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }
        
        nicknameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView.snp.right).offset(12)
            make.top.equalTo(avatarImageView)
            make.right.equalTo(coinLabel.snp.left).offset(-8)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(nicknameLabel)
            make.top.equalTo(nicknameLabel.snp.bottom).offset(4)
            make.right.equalTo(nicknameLabel)
        }
        
        coinLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    func configure(with item: ConsumptionRecordItem) {
        // 使用 giftImageUrl 作为头像
        if let avatarUrl = item.giftImageUrl, let fullUrl = URL(string: AppConfig.API.fullImageURL(path: avatarUrl)) {
            avatarImageView.kf.setImage(with: fullUrl)
        } else {
            avatarImageView.image = nil
        }
        
        nicknameLabel.text = item.nickname ?? "用户"
        timeLabel.text = item.createTime
        
        // 使用 numStr 显示金额，活动币文字单独设置样式
        if let numStr = item.numStr {
            let amountString: String
            let amountColor: UIColor
            
            if numStr.hasPrefix("-") {
                amountString = numStr
                amountColor = UIColor(hex: "#F7B500")
            } else {
                amountString = "+\(numStr)"
                amountColor = UIColor(hex: "#77E400")
            }
            
            let attributedString = NSMutableAttributedString(
                string: "\(amountString) 活动币"
            )
            
            // 金额部分样式
            attributedString.addAttribute(
                .font,
                value: UIFont.systemFont(ofSize: 16, weight: .medium),
                range: NSRange(location: 0, length: amountString.count)
            )
            attributedString.addAttribute(
                .foregroundColor,
                value: amountColor,
                range: NSRange(location: 0, length: amountString.count)
            )
            
            // 活动币部分样式
            let coinRange = NSRange(
                location: amountString.count + 1,
                length: "活动币".count
            )
            attributedString.addAttribute(
                .font,
                value: UIFont.systemFont(ofSize: 11),
                range: coinRange
            )
            attributedString.addAttribute(
                .foregroundColor,
                value: UIColor(hex: "#888888"),
                range: coinRange
            )
            
            coinLabel.attributedText = attributedString
        }
    }
}
