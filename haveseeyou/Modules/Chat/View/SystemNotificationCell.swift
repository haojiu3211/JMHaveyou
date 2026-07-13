//
//  SystemNotificationCell.swift
//  haveseeyou
//
//  系统通知列表 cell
//


import UIKit
import SnapKit
import Kingfisher

final class SystemNotificationCell: UITableViewCell {

    static let identifier = "SystemNotificationCell"

    /// 点击右侧 jump 按钮回调
    var onActionTapped: (() -> Void)?

    // MARK: - UI

    private let avatarView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 22
        iv.backgroundColor = AppColor.background
        return iv
    }()

    private let userNameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.textColor = AppColor.textMain
        return l
    }()

    private let contentLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = AppColor.textSecondary
        l.numberOfLines = 2
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = UIColor(hex: "#CCCCCC")
        return l
    }()

    private let actionButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitleColor(UIColor(hex: "#100A1D"), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.layer.borderColor = UIColor(hex: "#100A1D").cgColor
        btn.layer.borderWidth = 1
        btn.layer.cornerRadius = 16
        btn.isEnabled = false
        return btn
    }()

    private let separatorLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F5F5F5")
        return v
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = .white
        setupUI()
//        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.addSubview(avatarView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(actionButton)
        contentView.addSubview(separatorLine)

        avatarView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
            make.width.height.equalTo(44)
        }

        userNameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.top.equalTo(avatarView)
            make.right.lessThanOrEqualTo(actionButton.snp.left).offset(-12)
        }

        contentLabel.snp.makeConstraints { make in
            make.left.equalTo(userNameLabel)
            make.top.equalTo(userNameLabel.snp.bottom).offset(4)
            make.right.lessThanOrEqualTo(actionButton.snp.left).offset(-12)
        }

        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(userNameLabel)
            make.top.equalTo(contentLabel.snp.bottom).offset(8)
        }

        actionButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(avatarView)
            make.width.equalTo(88)
            make.height.equalTo(32)
        }

        separatorLine.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(10)
        }
    }

    @objc private func actionTapped() {
        onActionTapped?()
    }

    // MARK: - Configure

    func configure(with notification: SystemNotification) {
        userNameLabel.text = notification.userName
        contentLabel.text = notification.content
        timeLabel.text = notification.time

        // 判断是否是 VIP
        let isVip = notification.vip == 1
        
        // 头像
        if let url = notification.userAvatar, !url.isEmpty {
            let full = url.hasPrefix("http") ? url : AppConfig.API.fullImageURL(path: url)
            if let imageURL = URL(string: full) {
                if isVip {
                    // VIP 直接显示
                    avatarView.kf.setImage(with: imageURL, placeholder: UIImage(named: "app_default_avatar"))
                } else {
                    // 非 VIP 高斯模糊
                    avatarView.kf.setImage(with: imageURL, placeholder: UIImage(named: "app_default_avatar")) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let imageResult):
                            let blurredImage = imageResult.image.blurred(radius: 50)
                            self.avatarView.image = blurredImage
                        case .failure:
                            self.avatarView.image = UIImage(named: "app_default_avatar")
                        }
                    }
                }
            } else {
                avatarView.image = UIImage(named: "app_default_avatar")
                if !isVip, let defaultImage = UIImage(named: "app_default_avatar") {
                    avatarView.image = defaultImage.blurred(radius: 50)
                }
            }
        } else {
            avatarView.image = UIImage(named: "app_default_avatar")
            if !isVip, let defaultImage = UIImage(named: "app_default_avatar") {
                avatarView.image = defaultImage.blurred(radius: 50)
            }
        }
        
    
        // 跳转按钮：优先 jump_obj.name，缺省按 type 兜底；都拿不到则隐藏
        if let title = notification.actionTitle {
            actionButton.isHidden = false
            actionButton.setTitle(title, for: .normal)
            
            if isVip {
                // VIP 按钮可用状态
//                actionButton.isEnabled = true
                let color = UIColor(hex: notification.jumpColor ?? "#100A1D")
                actionButton.setTitleColor(UIColor(hex: "#100A1D"), for: .normal)
                actionButton.layer.borderColor = color.cgColor
                actionButton.backgroundColor = .clear
            } else {
                // 非 VIP 按钮不可用状态
//                actionButton.isEnabled = false
                let disabledColor = UIColor(hex: "#CCCCCC")
                actionButton.setTitleColor(disabledColor, for: .disabled)
                actionButton.layer.borderColor = disabledColor.cgColor
                actionButton.backgroundColor = UIColor(hex: "#F5F5F5")
            }
        } else {
            actionButton.isHidden = true
        }
        
        if (notification.type == 11){
            userNameLabel.text = "系统消息"
            contentLabel.text = notification.txt1
            avatarView.image = UIImage(named: "chat_sys_icon")
            actionButton.isHidden = true
        }
    }
}
