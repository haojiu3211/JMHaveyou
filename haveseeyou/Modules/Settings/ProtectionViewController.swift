//
//  ProtectionViewController.swift
//  haveseeyou
//
//  Created by admin开发测试 on 2026/6/26.
//

import UIKit
import SnapKit
import Combine

final class ProtectionViewController: BaseViewController {

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.backgroundColor = AppColor.background
        return sv
    }()

    private let contentView = UIView()

    // 第一组容器
    private let firstGroupContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        return view
    }()

    // 隐身访问开关
    private lazy var invisibleVisitCell: SettingsSwitchCell = {
        let cell = SettingsSwitchCell()
        cell.configure(title: "隐身访问", isOn: getInvisibleVisitEnabled(), iconName: "vip_quanyi_icon")
        cell.switchValueChanged = { [weak self] isOn in
            self?.handleInvisibleVisitSwitch(isOn)
        }
        return cell
    }()

    // 第二组容器
    private let secondGroupContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        return view
    }()

    // 离线回复标题
    private let offlineReplyTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "离线回复"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColor.textMain
        return label
    }()

    // 离线回复描述
    private let offlineReplyDescLabel: UILabel = {
        let label = UILabel()
        label.text = "开启后，当您离线时系统将自动回复消息"
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor(hex: "#888888")
        label.numberOfLines = 0
        return label
    }()

    // 离线回复开关
    private let offlineReplySwitch: UISwitch = {
        let sw = UISwitch()
        sw.onTintColor = .black
        return sw
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "隐私保护"
        offlineReplySwitch.isOn = getOfflineReplyEnabled()
        offlineReplySwitch.addTarget(self, action: #selector(offlineReplySwitchChanged), for: .valueChanged)
    }
    


    override func setupUI() {
        super.setupUI()
        view.backgroundColor = AppColor.background

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        setupContentViews()
    }

    private func setupContentViews() {
        contentView.addSubviews(
            firstGroupContainer,
            secondGroupContainer
        )

        // 第一组容器
        firstGroupContainer.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(56)
        }

        firstGroupContainer.addSubviews(invisibleVisitCell)

        invisibleVisitCell.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 第二组容器
        secondGroupContainer.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(firstGroupContainer.snp.bottom).offset(12)
            make.height.equalTo(77)
            make.bottom.equalToSuperview().offset(-20)
        }

        secondGroupContainer.addSubviews(offlineReplyTitleLabel, offlineReplyDescLabel, offlineReplySwitch)

        offlineReplyTitleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(12)
        }

        offlineReplyDescLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(offlineReplyTitleLabel.snp.bottom).offset(4)
        }

        offlineReplySwitch.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
    }

    // MARK: - Actions

    /// 隐身访问开关切换
    private func handleInvisibleVisitSwitch(_ isOn: Bool) {
        // 判断用户是否是 VIP
        let isVip = (UserManager.shared.vip ?? 0) > 0
        
        if isVip {
            // 是 VIP，直接继续执行
            UserDefaults.standard.set(isOn, forKey: "invisible_visit_enabled")
            showToast(isOn ? "已开启隐身访问" : "已关闭隐身访问")
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
    
    // 跳转到会员中心
    private func pushMemberCenter() {
        let vc = MemberCenterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func offlineReplySwitchChanged() {
        let isOn = offlineReplySwitch.isOn
        UserDefaults.standard.set(isOn, forKey: "offline_reply_enabled")
        showToast(isOn ? "已开启离线回复" : "已关闭离线回复")
    }

    // MARK: - Helper Methods

    /// 获取隐身访问开关状态
    private func getInvisibleVisitEnabled() -> Bool {
        return UserDefaults.standard.value(forKey: "invisible_visit_enabled") as? Bool ?? false
    }

    /// 获取离线回复开关状态
    private func getOfflineReplyEnabled() -> Bool {
        return UserDefaults.standard.value(forKey: "offline_reply_enabled") as? Bool ?? false
    }
}
