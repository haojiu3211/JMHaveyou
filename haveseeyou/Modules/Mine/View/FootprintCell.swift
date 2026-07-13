//
//  FootprintCell.swift
//  haveseeyou
//
//  足迹列表单元格
//

import UIKit
import SnapKit
import Kingfisher

class FootprintCell: UICollectionViewCell {

    static let identifier = "FootprintCell"

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = UIColor(white: 0.9, alpha: 1)
        iv.image = UIImage(named: "sy_delet_account")
        return iv
    }()

    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = .black
        return label
    }()

    private let genderImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    private let otherInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor(hex: "#FF999999")
        return label
    }()

    private var currentUserId: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let ageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private func setupUI() {
        contentView.addSubviews(avatarImageView, nicknameLabel, genderImageView, ageLabel, otherInfoLabel)

        // 第一行：头像
        avatarImageView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(contentView.snp.width)
        }

        // 第二行：昵称 + 性别 + 年龄
        nicknameLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(avatarImageView.snp.bottom).offset(8)
        }

        genderImageView.snp.makeConstraints { make in
            make.left.equalTo(nicknameLabel.snp.right).offset(4)
            make.centerY.equalTo(nicknameLabel)
            make.size.equalTo(CGSize(width: 32, height: 14))
        }

        ageLabel.snp.makeConstraints { make in
            make.left.equalTo(genderImageView.snp.right).offset(-16)
            make.centerY.equalTo(nicknameLabel)
            make.height.equalTo(14)
        }

        // 第三行：其他信息
        otherInfoLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(nicknameLabel.snp.bottom).offset(4)
            make.right.lessThanOrEqualToSuperview()
        }
    }

    func config(model: FootprintModel) {
        currentUserId = model.userid ?? 0

        if let avatar = model.avatar, !avatar.isEmpty {
            let fullUrl = AppConfig.API.fullImageURL(path: avatar)
            if let url = URL(string: fullUrl) {
                avatarImageView.kf.setImage(with: url, placeholder: UIImage(named: "sy_delet_account"))
            }
        }

        nicknameLabel.text = model.nickname ?? ""

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

        // 第三行：用户其他信息（您可以自定义这部分内容）
        var infoParts: [String] = []
        if let sign = model.sign, !sign.isEmpty {
            infoParts.append(sign)
        }
        otherInfoLabel.text = infoParts.joined(separator: " | ")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = UIImage(named: "sy_delet_account")
        nicknameLabel.text = ""
        ageLabel.text = ""
        otherInfoLabel.text = ""
        genderImageView.isHidden = true
        ageLabel.isHidden = true
    }
}
