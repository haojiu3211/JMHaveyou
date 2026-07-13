//
//  ChatSystemNotifiViewController.swift
//  haveseeyou
//
//  Created by admin开发测试 on 2026/6/15.
//


import UIKit
import SnapKit
import Combine

class ChatSystemNotifiViewController: BaseViewController {

    // MARK: - UI

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = UIColor(hex: "#F5F5F5")
        tv.separatorStyle = .none
        return tv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "暂无系统通知"
        l.textColor = UIColor(hex: "#999999")
        l.font = .systemFont(ofSize: 14)
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()

    // MARK: - State

    private var notifications: [SystemNotification] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "系统通知"
        setupUI()
    }

    override func setupUI() {
        view.backgroundColor = UIColor(hex: "#F5F5F5")
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.bottom.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(20)
        }

        tableView.register(SystemNotificationCell.self, forCellReuseIdentifier: SystemNotificationCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
    }

    /// 由 ConversationListViewController 解析自定义消息后注入
    func update(notifications: [SystemNotification]) {
        self.notifications = notifications
        emptyLabel.isHidden = !notifications.isEmpty
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource / Delegate

extension ChatSystemNotifiViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SystemNotificationCell.identifier, for: indexPath) as! SystemNotificationCell
        let item = notifications[indexPath.row]
        cell.configure(with: item)
        cell.onActionTapped = { [weak self] in
            self?.handleAction(for: item)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = notifications[indexPath.row]
        let isVip = (UserManager.shared.vip ?? 0) > 0
        if isVip {
            // 是 VIP，直接继续执行
            handleAction(for: item)
        } else {
            // 不是 VIP，弹窗提示
            AppAlert.showSingle(
                title: "提示",
                message: String(format: "你暂无权限查看谁%@，请选择以下权益进行开通。", item.content),
                confirmText: "开通会员",
                messageAlignment: .center
            ) { [weak self] in
                // 点击开通会员，跳转到会员中心
                let vc = MemberCenterViewController()
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        
    }

    /// 跳转分发：
    /// - 10001(用户操作) → 个人主页（按 user_id 拉取）
    /// - 11(系统消息)    → link_url 打开 H5
    /// - 其它            → 有 link_url 就开 H5，无则忽略
    private func handleAction(for item: SystemNotification) {
        switch item.kind {
        case .userAction:
            if let uid = item.userId {
                pushUserProfile(userId: String(uid))
            } else {
                openLink(item.linkUrl)
            }
        case .system, .unknown:
            openLink(item.linkUrl)
        case .location:
            // 位置消息暂不跳转
            break
        }
    }

    private func openLink(_ url: String?) {
        guard let url = url, !url.isEmpty else { return }
        let web = WebViewController(urlString: url)
        navigationController?.pushViewController(web, animated: true)
    }

    private func pushUserProfile(userId: String) {
        NetworkManager.shared
            .request(ActivityDetailAPI.personalHomepage(userId: userId), as: PersonalHomepageDataModel.self)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("❌ [SystemNotifi] 个人主页请求失败: \(error)")
                }
            } receiveValue: { [weak self] model in
                let vc = PersionViewController()
                vc.model = model
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                self?.present(nav, animated: true, completion: nil)
            }
            .store(in: &cancellables)
    }
}
