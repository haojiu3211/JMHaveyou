//
//  GroupPartnerCell.swift
//  haveseeyou
//
//  活动搭子列表 Cell
//

import UIKit
import SnapKit
import Kingfisher

class GroupPartnerCell: UITableViewCell {

    static let identifier = "GroupPartnerCell"

    var onActionTapped: ((Int) -> Void)?

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

    private let signLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = UIColor(hex: "#FF999999")
        return label
    }()

    private let tagsContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.alignment = .center
        return stackView
    }()

    private let chatButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "sy_active_chat"), for: .normal)
        btn.imageView?.contentMode = .scaleAspectFit
        return btn
    }()
    
    private let rightIcon: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "dazi_home_cellicon")
        return iv
    }()

    private var currentUserId: Int = 0

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
        contentView.addSubviews(avatarImageView, nicknameLabel, vipIcon, genderImageView, ageLabel, signLabel, tagsContainer, chatButton, rightIcon)

        avatarImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(70)
        }

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

        signLabel.snp.makeConstraints { make in
            make.left.equalTo(nicknameLabel)
            make.right.equalTo(rightIcon).offset(-18)
            make.top.equalTo(nicknameLabel.snp.bottom).offset(4)
        }

        tagsContainer.snp.makeConstraints { make in
            make.left.equalTo(nicknameLabel)
            make.top.equalTo(signLabel.snp.bottom).offset(4)
            make.right.lessThanOrEqualTo(chatButton.snp.left).offset(-8)
        }

        chatButton.snp.makeConstraints { make in
            make.right.equalTo(rightIcon.snp.left).offset(-10)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 36, height: 36))
        }
        
        rightIcon.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }

        chatButton.addTarget(self, action: #selector(handleChatButton), for: .touchUpInside)
    }

    func configure(model: RelationModel) {
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

        signLabel.text =  (model.arrange_play_city_label ?? "") + " | " + (model.sign ?? "")

        tagsContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let tags = model.label, !tags.isEmpty {
            tags.prefix(3).forEach { tag in
                let tagView = createTagView(text: tag)
                tagsContainer.addArrangedSubview(tagView)
            }
        }
    }

    private func createTagView(text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(hex: "#FFF5F5F5")
        container.layer.cornerRadius = 6
        container.clipsToBounds = true
        
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = UIColor(hex: "#FF666666")
        label.text = text
        label.textAlignment = .center
        
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8))
        }
        
        return container
    }

    @objc private func handleChatButton() {
        onActionTapped?(currentUserId)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = UIImage(named: "sy_delet_account")
        nicknameLabel.text = ""
        signLabel.text = ""
        vipIcon.isHidden = true
        genderImageView.isHidden = true
        ageLabel.isHidden = true
        tagsContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}
