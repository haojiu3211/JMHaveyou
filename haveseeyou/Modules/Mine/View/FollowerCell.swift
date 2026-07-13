//
//  FollowerCell.swift
//  haveseeyou
//
//  粉丝/关注/访客列表单元格
//

import UIKit
import SnapKit
import Kingfisher

class FollowerCell: UITableViewCell {

    static let identifier = "FollowerCell"

    enum ActionType {
        case viewProfile
        case follow
        case unfollow
        case unlock
    }

    var onAction: ((Int, ActionType) -> Void)?

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 24
        iv.backgroundColor = UIColor(white: 0.9, alpha: 1)
        iv.image = UIImage(named: "sy_delet_account")
        return iv
    }()

    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        return label
    }()

    private let vipIcon: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    private let genderImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    private let ageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let followStatusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = UIColor(hex: "#FF999999")
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor(hex: "#FFBBBBBB")
        return label
    }()

    private let actionButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.layer.cornerRadius = 16
        btn.clipsToBounds = true
        return btn
    }()

    private var currentUserId: Int = 0
    private var currentIsFollow: Bool = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white
        selectionStyle = .none
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubviews(avatarImageView, nicknameLabel, vipIcon, genderImageView, ageLabel, followStatusLabel, timeLabel, actionButton)

        avatarImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
        }
        
        avatarImageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        avatarImageView.addGestureRecognizer(tapGesture)

        nicknameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView.snp.right).offset(12)
            make.top.equalToSuperview().offset(18)
        }

        vipIcon.snp.makeConstraints { make in
            make.left.equalTo(nicknameLabel.snp.right).offset(4)
            make.centerY.equalTo(nicknameLabel)
            make.size.equalTo(0)
        }

        genderImageView.snp.makeConstraints { make in
            make.left.equalTo(vipIcon.snp.right).offset(4)
            make.centerY.equalTo(nicknameLabel)
            make.size.equalTo(CGSize(width: 32, height: 14))
        }

        ageLabel.snp.makeConstraints { make in
            make.left.equalTo(genderImageView.snp.right).offset(-16)
            make.centerY.equalTo(nicknameLabel)
            make.height.equalTo(14)
        }

        followStatusLabel.snp.makeConstraints { make in
            make.left.equalTo(nicknameLabel)
            make.top.equalTo(nicknameLabel.snp.bottom).offset(4)
            make.right.equalToSuperview().offset(-100)
        }

        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(nicknameLabel)
            make.top.equalTo(followStatusLabel.snp.bottom).offset(4)
        }

        actionButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
            make.width.greaterThanOrEqualTo(80)
        }

        actionButton.addTarget(self, action: #selector(handleActionButton), for: .touchUpInside)
    }

    func configRelation(model: RelationModel, type: FollowerType) {
        currentUserId = model.userid ?? 0

        if let avatar = model.avatar, !avatar.isEmpty {
            let fullUrl = AppConfig.API.fullImageURL(path: avatar)
            if let url = URL(string: fullUrl) {
                avatarImageView.kf.setImage(with: url, placeholder: UIImage(named: "sy_delet_account"))
            }
        }

        nicknameLabel.text = model.nickname ?? ""

        if let vipIconUrl = model.vipIcon, !vipIconUrl.isEmpty {
            vipIcon.isHidden = false
            let fullUrl = AppConfig.API.fullImageURL(path: vipIconUrl)
            if let url = URL(string: fullUrl) {
                vipIcon.kf.setImage(with: url)
            }
        } else if model.vip == 1 {
            vipIcon.isHidden = false
            vipIcon.image = UIImage(named: "vip_icon")
        } else {
            vipIcon.isHidden = true
        }

        if let gender = model.gender {
            genderImageView.isHidden = false
            genderImageView.image = UIImage(named: gender == 1 ? "me_girl" : "me_boy")
        } else {
            genderImageView.isHidden = true
        }

        if let age = model.age {
            ageLabel.isHidden = false
            ageLabel.text = "\(age)"
            ageLabel.textColor = UIColor(hex: model.gender == 1 ? "#FFFF67A9" : "#FF037BFF")
        } else {
            ageLabel.isHidden = true
        }

        if type == .fans {
            followStatusLabel.text = model.sign
            actionButton.setTitle("查看对方", for: .normal)
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.backgroundColor = .black
        } else {
            followStatusLabel.text = model.sign

            let isFollow = model.isFollow == 1
            currentIsFollow = isFollow
            if isFollow {
                setButton(title: "已关注", titleColor: .white, backgroundColor: .black)
            } else {
                setButton(title: "关注", titleColor: .white, backgroundColor: .black)
            }
        }

        timeLabel.text = model.addTime ?? ""
    }

    func configVisitor(model: VisitorModel, type: FollowerType) {
        currentUserId = model.userid ?? 0

        if let avatar = model.avatar, !avatar.isEmpty {
            let fullUrl = AppConfig.API.fullImageURL(path: avatar)
            if let url = URL(string: fullUrl) {
                avatarImageView.kf.setImage(with: url, placeholder: UIImage(named: "sy_head_2"))
            }
        }

        nicknameLabel.text = model.nickname ?? ""
        
        // VIP 图标
        if let vipIconUrl = model.vipIcon, !vipIconUrl.isEmpty {
            vipIcon.isHidden = false
            let fullUrl = AppConfig.API.fullImageURL(path: vipIconUrl)
            if let url = URL(string: fullUrl) {
                vipIcon.kf.setImage(with: url)
            }
        } else if model.vip == 1 {
            vipIcon.isHidden = false
            vipIcon.image = UIImage(named: "vip_icon")
        } else {
            vipIcon.isHidden = true
        }
        
        // 性别图标
        if let gender = model.gender {
            genderImageView.isHidden = false
            genderImageView.image = UIImage(named: gender == 1 ? "me_girl" : "me_boy")
        } else {
            genderImageView.isHidden = true
        }
        
        // 年龄
        if let age = model.age {
            ageLabel.isHidden = false
            ageLabel.text = "\(age)"
            ageLabel.textColor = UIColor(hex: model.gender == 1 ? "#FFFF67A9" : "#FF037BFF")
        } else {
            ageLabel.isHidden = true
        }
        
        // 签名
        followStatusLabel.text = model.sign
        
        // 时间
        timeLabel.text = model.addTime ?? ""
        
        // 访客按钮显示"查看对方"
        setButton(title: "查看对方", titleColor: .white, backgroundColor: .black)
    }

    private func setButton(title: String, titleColor: UIColor, backgroundColor: UIColor) {
        actionButton.setTitle(title, for: .normal)
        actionButton.setTitleColor(titleColor, for: .normal)
        actionButton.backgroundColor = backgroundColor
    }

    @objc private func handleActionButton() {
        guard let title = actionButton.title(for: .normal) else { return }

        switch title {
        case "关注":
            onAction?(currentUserId, .follow)
        case "添加关注":
            onAction?(currentUserId, .follow)
        case "查看对方":
            onAction?(currentUserId, .viewProfile)
        case "立即解锁":
            onAction?(currentUserId, .unlock)
        case "已关注":
            onAction?(currentUserId, .unfollow)
        default:
            break
        }
    }
    
    @objc private func avatarTapped() {
        onAction?(currentUserId, .viewProfile)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = UIImage(named: "sy_delet_account")
        nicknameLabel.text = ""
        followStatusLabel.text = ""
        timeLabel.text = ""
        vipIcon.isHidden = true
        genderImageView.isHidden = true
        ageLabel.isHidden = true
    }
}
