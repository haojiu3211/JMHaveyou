//
//  FixedConversationCell.swift
//  haveseeyou
//
//  固定会话列表 cell（系统消息、帮助与反馈）
//

import UIKit
import SnapKit

struct FixedConversationItem {
    let name: String
    let avatar: String
    let lastMessage: String
    let time: String
    let unreadCount: Int
}

final class FixedConversationCell: UITableViewCell {

    static let identifier = "FixedConversationCell"

    // MARK: - UI

    private let avatarView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 24
        iv.backgroundColor = AppColor.background
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = AppColor.textMain
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColor.textSecondary
        return l
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = AppColor.textSecondary
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private let unreadBadge: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .medium)
        l.textColor = .white
        l.textAlignment = .center
        l.backgroundColor = UIColor(hex: "#FF3B30")
        l.layer.cornerRadius = 9
        l.clipsToBounds = true
        l.isHidden = true
        return l
    }()

    private let separatorLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#EEEEEE")
        return v
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = .white
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(unreadBadge)
        contentView.addSubview(separatorLine)

        avatarView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }
        timeLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(avatarView).offset(2)
        }
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.top.equalTo(avatarView).offset(2)
            make.right.lessThanOrEqualTo(timeLabel.snp.left).offset(-8)
        }
        messageLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.right.lessThanOrEqualTo(unreadBadge.snp.left).offset(-8)
            make.bottom.equalTo(avatarView).offset(-2)
        }
        unreadBadge.snp.makeConstraints { make in
            make.right.equalTo(timeLabel)
            make.centerY.equalTo(messageLabel)
            make.height.equalTo(18)
            make.width.greaterThanOrEqualTo(18)
        }
        separatorLine.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    // MARK: - Configure

    func configure(with item: FixedConversationItem) {
        nameLabel.text = item.name
        messageLabel.text = item.lastMessage
        timeLabel.text = item.time
        avatarView.image = UIImage(named: item.avatar) ?? UIImage(named: "app_default_avatar")

        let count = item.unreadCount
        if count > 0 {
            unreadBadge.isHidden = false
            unreadBadge.text = count > 99 ? "99+" : "\(count)"
            unreadBadge.snp.updateConstraints { make in
                make.width.greaterThanOrEqualTo(count > 9 ? 22 : 18)
            }
        } else {
            unreadBadge.isHidden = true
        }
    }
}
