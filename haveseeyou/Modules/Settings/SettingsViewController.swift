//
//  SettingsViewController.swift
//  haveseeyou
//
//  系统设置页面
//

import UIKit
import SnapKit
import Combine

final class SettingsViewController: BaseViewController {

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.backgroundColor = AppColor.background
        return sv
    }()

    private let contentView = UIView()

    // 第一组容器（消息通知 + 帮助反馈）
    private let firstGroupContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        return view
    }()

    // 消息通知开关
    private lazy var notificationCell: SettingsSwitchCell = {
        let cell = SettingsSwitchCell()
        cell.configure(title: "消息通知", isOn: getNotificationEnabled())
        cell.switchValueChanged = { [weak self] isOn in
            self?.handleNotificationSwitch(isOn)
        }
        return cell
    }()

    // 分隔线1
    private let separatorLine1: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#FFF5F5F5")
        return view
    }()

    // 帮助反馈
    private lazy var helpCell: SettingsArrowCell = {
        let cell = SettingsArrowCell()
        cell.configure(title: "问题反馈")
        cell.onTap = { [weak self] in
            self?.handleHelpFeedback()
        }
        return cell
    }()

    // 第二组容器（账号安全 + 清理缓存 + 关于我们）
    private let secondGroupContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        return view
    }()

    // 账号安全
    private lazy var securityCell: SettingsArrowCell = {
        let cell = SettingsArrowCell()
        cell.configure(title: "账号安全")
        cell.onTap = { [weak self] in
            self?.handleAccountSecurity()
        }
        return cell
    }()

    // 隐私保护
    private lazy var privacyCell: SettingsArrowCell = {
        let cell = SettingsArrowCell()
        cell.configure(title: "隐私保护")
        cell.onTap = { [weak self] in
            self?.handlePrivacyProtection()
            
        }
        return cell
    }()
    
    // 分隔线4
    private let separatorLine4: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#FFF5F5F5")
        return view
    }()
    
    // 相关协议
    private lazy var agreementCell: SettingsArrowCell = {
        let cell = SettingsArrowCell()
        cell.configure(title: "相关协议")
        cell.onTap = { [weak self] in
            self?.handleAgreement()
        }
        return cell
    }()
    
    // 分隔线2
    private let separatorLine2: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#FFF5F5F5")
        return view
    }()

    // 清理缓存
    private lazy var cacheCell: SettingsArrowCell = {
        let cell = SettingsArrowCell()
        cell.configure(title: "清理缓存", rightText: CacheManager.shared.calculateCacheSize())
        cell.onTap = { [weak self] in
            self?.handleClearCache()
        }
        return cell
    }()

    // 分隔线3
    private let separatorLine3: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#FFF5F5F5")
        return view
    }()

    // 关于我们
    private lazy var aboutCell: SettingsArrowCell = {
        let cell = SettingsArrowCell()
        cell.configure(title: "关于我们")
        cell.onTap = { [weak self] in
            self?.handleAboutUs()
        }
        return cell
    }()
    
    // 分隔线6
    private let separatorLine6: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#FFF5F5F5")
        return view
    }()

    // 退出当前账号按钮
    private let logoutButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("退出当前账号", for: .normal)
        btn.setTitleColor(UIColor(hex: "#FFFF4D4D"), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 8
        return btn
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "系统设置"
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
            secondGroupContainer,
            logoutButton
        )

        // 第一组容器
        firstGroupContainer.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(112) // 56 * 2
        }

        firstGroupContainer.addSubviews(notificationCell, separatorLine1, helpCell)

        notificationCell.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(56)
        }

        separatorLine1.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(notificationCell.snp.bottom)
            make.height.equalTo(1)
        }

        helpCell.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(separatorLine1.snp.bottom)
            make.height.equalTo(56)
        }

        // 第二组容器
        secondGroupContainer.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(firstGroupContainer.snp.bottom).offset(12)
            make.height.equalTo(168 + 112) // 56 * 5
        }

        secondGroupContainer.addSubviews(securityCell, separatorLine2, privacyCell, separatorLine4, cacheCell, separatorLine3, aboutCell, separatorLine6, agreementCell)

        securityCell.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(56)
        }

        separatorLine2.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(securityCell.snp.bottom)
            make.height.equalTo(1)
        }

        privacyCell.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(separatorLine2.snp.bottom)
            make.height.equalTo(56)
        }

        separatorLine4.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(privacyCell.snp.bottom)
            make.height.equalTo(1)
        }

        cacheCell.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(separatorLine4.snp.bottom)
            make.height.equalTo(56)
        }

        separatorLine3.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(cacheCell.snp.bottom)
            make.height.equalTo(1)
        }

        aboutCell.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(separatorLine3.snp.bottom)
            make.height.equalTo(56)
        }
        
        separatorLine6.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(aboutCell.snp.bottom)
            make.height.equalTo(1)
        }
        
        agreementCell.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(separatorLine6.snp.bottom)
            make.height.equalTo(56)
        }

        // 退出当前账号按钮
        logoutButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(secondGroupContainer.snp.bottom).offset(40)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-40)
        }

        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
    }

    // MARK: - Actions


    
    /// 消息通知开关切换
    private func handleNotificationSwitch(_ isOn: Bool) {
        UserDefaults.standard.set(isOn, forKey: "notification_enabled")
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.enableRemoteNotifications(isOn)
        }
    }

    /// 帮助反馈
    private func handleHelpFeedback() {
        let vc = HelpFeedbackViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    /// 账号安全
    private func handleAccountSecurity() {
        let vc = AccountSecurityViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// 隐私保护
    private func handlePrivacyProtection() {
        let vc = ProtectionViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// 相关协议
    private func handleAgreement() {
        let alert = UIAlertController(
            title: "相关协议",
            message: "请选择要查看的协议",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "用户服务协议", style: .default) { [weak self] _ in
            let web = WebViewController(urlString: webUrlUserPrivacy, title: "用户服务协议")
            self?.navigationController?.pushViewController(web, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "隐私协议", style: .default) { [weak self] _ in
            let web = WebViewController(urlString: webUrlPrivacy, title: "隐私协议")
            self?.navigationController?.pushViewController(web, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "活动须知", style: .default) { [weak self] _ in
            let web = WebViewController(urlString: webUrlActivityNotice, title: "活动须知")
            self?.navigationController?.pushViewController(web, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "发布准则", style: .default) { [weak self] _ in
            let web = WebViewController(urlString: webUrlReleaseGuidelines, title: "发布准则")
            self?.navigationController?.pushViewController(web, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "充值协议", style: .default) { [weak self] _ in
            // 直接加载本地 HTML 文件
            guard let filePath = Bundle.main.path(forResource: "活动币充值协议", ofType: "html"),
                  let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
                // 如果读取失败，尝试使用在线 URL
                let webVC = WebViewController(urlString: webUrlCoinRecharge, title: "活动币充值协议")
                self?.navigationController?.pushViewController(webVC, animated: true)
                return
            }
        
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = view.bounds
        }
        
        present(alert, animated: true)
    }

    /// 清理缓存
    private func handleClearCache() {
        let alert = UIAlertController(
            title: "清理缓存",
            message: "确定要清理缓存吗？",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { [weak self] _ in
            self?.performClearCache()
        })
        present(alert, animated: true)
    }

    /// 执行清理缓存
    private func performClearCache() {
        showLoading("清理中...")
        
        // 延迟2秒后执行清理
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            CacheManager.shared.clearCache { success, clearedSize in
                self.hideLoading()
                
                if success {
                    self.showToast("清理成功，已清理 \(clearedSize)")
                    // 更新缓存大小显示
                    self.updateCacheSize()
                } else {
                    self.showToast("清理完成，部分文件无法清理")
                    self.updateCacheSize()
                }
            }
        }
    }
    
    /// 更新缓存大小显示
    private func updateCacheSize() {
        let newSize = CacheManager.shared.calculateCacheSize()
        cacheCell.configure(title: "清理缓存", rightText: newSize)
    }

    /// 关于我们
    private func handleAboutUs() {
        let web = WebViewController(urlString: webUrlAboutUs)
        navigationController?.pushViewController(web, animated: true)
    }

    /// 退出登录
    @objc private func logoutTapped() {
        AppAlert.showDouble(title: "确定退出登录吗？",message: "退出登录后，会无法及时收到活动消息哦",onConfirm: {
            [weak self] in
            self?.performLogout()
        })

    }

    /// 执行退出登录
    private func performLogout() {
        IMManager.shared.logout()
        UserManager.shared.deleteAccount()
        self.navigationController?.popToRootViewController(animated: true)
 
        
        // TODO: 跳转到登录页面
        // 这里需要根据你的项目结构来实现跳转逻辑
        // 例如：切换到登录页面或者返回到根视图控制器
        print("已退出登录")
        
        // 示例：返回到根视图控制器
       
    }

    // MARK: - Helper Methods

    /// 获取消息通知开关状态
    private func getNotificationEnabled() -> Bool {
        return UserDefaults.standard.value(forKey: "notification_enabled") as? Bool ?? true
    }
}

// MARK: - 设置项带开关的Cell

final class SettingsSwitchCell: UIView {

    var switchValueChanged: ((Bool) -> Void)?

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColor.textMain
        return label
    }()

    private let switchControl: UISwitch = {
        let sw = UISwitch()
        sw.onTintColor = .black
        return sw
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubviews(titleLabel, iconImageView, switchControl)

        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }

        iconImageView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(8)
            make.centerY.equalToSuperview()
            make.size.equalTo(26)
        }

        switchControl.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }

        switchControl.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
    }

    func configure(title: String, isOn: Bool, iconName: String? = nil) {
        titleLabel.text = title
        titleLabel.isHidden = title.isEmpty
        switchControl.isOn = isOn
        
        if let iconName = iconName {
            iconImageView.image = UIImage(named: iconName)
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }
    }

    @objc private func switchChanged() {
        switchValueChanged?(switchControl.isOn)
    }
}

// MARK: - 设置项带箭头的Cell

final class SettingsArrowCell: UIView {

    var onTap: (() -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColor.textMain
        return label
    }()

    private let rightLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor(hex: "#FF999999")
        return label
    }()

    private let arrowImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")
        iv.tintColor = UIColor(hex: "#FFCCCCCC")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubviews(titleLabel, rightLabel, arrowImageView)

        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }

        arrowImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }

        rightLabel.snp.makeConstraints { make in
            make.right.equalTo(arrowImageView.snp.left).offset(-8)
            make.centerY.equalToSuperview()
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        addGestureRecognizer(tapGesture)
    }

    func configure(title: String, rightText: String? = nil, rightTextColor: UIColor? = nil) {
        titleLabel.text = title
        rightLabel.text = rightText
        rightLabel.isHidden = rightText == nil
        if let color = rightTextColor {
            rightLabel.textColor = color
        }
    }

    @objc private func cellTapped() {
        onTap?()
    }
}

// MARK: - 账号安全页

final class AccountSecurityViewController: BaseViewController {

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        return view
    }()

    private let phoneCell: SettingsArrowCell = {
        let cell = SettingsArrowCell()
        cell.configure(title: "手机号", rightText: UserManager.shared.phone ?? "")
        return cell
    }()
    
    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#FFF5F5F5")
        return view
    }()
    
    private lazy var deleteAccountCell: SettingsArrowCell = {
        let cell = SettingsArrowCell()
        cell.configure(title: "注销账号", rightText: "请谨慎", rightTextColor: .red)
        cell.onTap = { [weak self] in
            self?.closeAccount()
        }
        return cell
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "账号安全"
        phoneCell.onTap = { [weak self] in
            let vc = BindMobileViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        phoneCell.configure(title: "手机号", rightText: UserManager.shared.phone ?? "")
    }

    override func setupUI() {
        super.setupUI()
        view.backgroundColor = AppColor.background

        view.addSubview(containerView)
        containerView.addSubviews(phoneCell, separatorLine, deleteAccountCell)

        containerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(112)
        }

        phoneCell.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(56)
        }
        
        separatorLine.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(phoneCell.snp.bottom)
            make.height.equalTo(1)
        }
        
        deleteAccountCell.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(separatorLine.snp.bottom)
            make.height.equalTo(56)
        }
    }
    
    //注销账号弹框
    private func closeAccount(){
        AccountDeletionAlertView.show(
            onConfirmDeletion: { [weak self] in
                self?.performDeleteAccount()
            },
            onExitAccount: { [weak self] in
                self?.performLogout()
            }
        )
    }

    /// 执行注销账号
    private func performDeleteAccount() {
        showLoading("注销中...")

        NetworkManager.shared
            .request(LoginAPI.deregisterAccount(userId: UserManager.shared.userId ?? ""), as: EmptyData.self)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.hideLoading()

                switch completion {
                case .failure(let error):
                    #if DEBUG
                    print("❌ [Account] 注销失败: \(error.localizedDescription)")
                    #endif
                    self.showToast("注销失败，请稍后重试")

                case .finished:
                    #if DEBUG
                    print("✅ [Account] 注销成功")
                    #endif

                    // 退出云信 IM
                    IMManager.shared.logout { _ in
                        // 清除所有用户数据
                        UserManager.shared.deleteAccount()
                    }
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    /// 执行退出登录
    private func performLogout() {
        IMManager.shared.logout()
        UserManager.shared.deleteAccount()
    }
}
