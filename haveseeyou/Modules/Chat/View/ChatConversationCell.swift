//
//  ChatConversationCell.swift
//  haveseeyou
//
//  会话列表 cell
//

import UIKit
import SnapKit
import Kingfisher
import NIMSDK
import NECoreIM2Kit

final class ChatConversationCell: UITableViewCell {

    static let identifier = "ChatConversationCell"

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

    private var currentAccountId: String?

    /// 预设系统会话（官方客服 / 活动公告 / 系统通知）：使用固定的展示名，
    /// 头像优先使用 IM 平台上的真实头像，未取到时回落到本地占位图；
    /// 同时复用真实会话的未读数 / 最近消息 / 时间字段。
    /// - Parameter conversation: 对应的真实 IM 会话；为 nil 时只展示占位文案。
    func configurePreset(accountId: String,
                         name: String,
                         avatar: String,
                         conversation: V2NIMBaseConversation?) {
        // 名称强制使用预设展示名；头像允许 IM 远端覆盖，所以把 currentAccountId 设上
        currentAccountId = accountId

        nameLabel.text = name
        // 占位：本地兜底头像，IM 拉到后由 applyPresetAvatar 覆盖
        avatarView.image = UIImage(named: avatar) ?? UIImage(named: "app_default_avatar")

        if let conv = conversation {
            if (accountId == "8997905"){//系统通知
                let preview = lastMessagePreview(conv.lastMessage)
                messageLabel.text = preview.isEmpty ? "暂无通知" : preview
            }else if (accountId == "8997906"){//官方客服
                messageLabel.text = "您好,很高兴为您服务。"
            }else {
                messageLabel.text = lastMessagePreview(conv.lastMessage)
            }

            timeLabel.text = formatTime(conv.updateTime)
            let count = conv.unreadCount
            if count > 0 {
                unreadBadge.isHidden = false
                unreadBadge.text = count > 99 ? "99+" : "\(count)"
                unreadBadge.snp.updateConstraints { make in
                    make.width.greaterThanOrEqualTo(count > 9 ? 22 : 18)
                }
            } else {
                unreadBadge.isHidden = true
            }
        } else {
            messageLabel.text = ""
            timeLabel.text = ""
            unreadBadge.isHidden = true
        }

        // 拉取 IM 上的真实头像覆盖占位图（名称保持预设值不变）
        loadPresetAvatar(accountId: accountId)
    }

    /// 仅拉取并应用 IM 用户头像，名称由预设强制
    private func loadPresetAvatar(accountId: String) {
        guard !accountId.isEmpty else { return }
        NIMUserInfoLoader.shared.fetch(accountId: accountId) { [weak self] user in
            guard let self = self,
                  self.currentAccountId == accountId,
                  let user = user,
                  let avatar = user.avatar, !avatar.isEmpty else { return }
            let full = avatar.hasPrefix("http") ? avatar : AppConfig.API.fullImageURL(path: avatar)
            guard let url = URL(string: full) else { return }
            self.avatarView.kf.setImage(with: url, placeholder: self.avatarView.image)
        }
    }

    func configure(with conversation: V2NIMBaseConversation) {
        let targetId = conversationTargetId(conversation)
        currentAccountId = targetId

        // 先用会话本身字段兜底显示
        nameLabel.text = conversation.name ?? targetId
        messageLabel.text = lastMessagePreview(conversation.lastMessage)
        timeLabel.text = formatTime(conversation.updateTime)

        if let url = conversation.avatar, !url.isEmpty {
            let full = url.hasPrefix("http") ? url : AppConfig.API.fullImageURL(path: url)
            if let imageURL = URL(string: full) {
                avatarView.kf.setImage(with: imageURL, placeholder: UIImage(named: "app_default_avatar"))
            } else {
                avatarView.image = UIImage(named: "app_default_avatar")
            }
        } else {
            avatarView.image = UIImage(named: "app_default_avatar")
        }

        let count = conversation.unreadCount
        if count > 0 {
            unreadBadge.isHidden = false
            unreadBadge.text = count > 99 ? "99+" : "\(count)"
            unreadBadge.snp.updateConstraints { make in
                make.width.greaterThanOrEqualTo(count > 9 ? 22 : 18)
            }
        } else {
            unreadBadge.isHidden = true
        }

        // 只有 P2P 会话才需要拉用户资料覆盖
        if conversation.type.rawValue == 1 {
            loadUserInfo(accountId: targetId)
        }
    }

    /// 拉取目标用户资料，回填昵称/头像（先查本地，本地缺失会拉云端）
    private func loadUserInfo(accountId: String) {
        guard !accountId.isEmpty else { return }
        NIMUserInfoLoader.shared.fetch(accountId: accountId) { [weak self] user in
            guard let self = self,
                  self.currentAccountId == accountId,
                  let user = user else { return }
            self.apply(user: user, for: accountId)
        }
    }

    private func apply(user: V2NIMUser, for accountId: String) {
        guard currentAccountId == accountId else { return }
        if let name = user.name, !name.isEmpty {
            nameLabel.text = name
        }
        if let avatar = user.avatar, !avatar.isEmpty {
            // 兼容其它端存的相对路径：没有 scheme 就用业务 imageBaseUrl 兜底拼接
            let full = avatar.hasPrefix("http") ? avatar : AppConfig.API.fullImageURL(path: avatar)
            if let url = URL(string: full) {
                avatarView.kf.setImage(with: url, placeholder: UIImage(named: "app_default_avatar"))
            }
        }
    }

    // MARK: - Helpers

    private func conversationTargetId(_ conv: V2NIMBaseConversation) -> String {
        return V2NIMConversationIdUtil.conversationTargetId(conv.conversationId) ?? conv.conversationId
    }

    private func lastMessagePreview(_ last: V2NIMLastMessage?) -> String {
        guard let last = last else { return "" }
        if last.lastMessageState.rawValue == 1 { return "[消息已撤回]" }
        switch last.messageType.rawValue {
        case 0:   return last.text ?? ""           // TEXT
        case 1:   return "[图片]"                   // IMAGE
        case 2:   return "[语音]"                   // AUDIO
        case 3:   return "[视频]"                   // VIDEO
        case 4:   return "[位置]"                   // LOCATION
        case 5:   return last.text ?? "[通知]"      // NOTIFICATION
        case 6:   return "[文件]"                   // FILE
        case 7:   return "[音视频通话]"             // AVCHAT
        case 10:  return last.text ?? "[提示]"      // TIP
        case 12:  return "[通话]"                   // CALL
        case 100: return customMessagePreview(last)  // CUSTOM
        default:  return last.text ?? ""
        }
    }

    /// 自定义消息列表预览：解析 SystemAttachment，按 type 选择最有信息量的文本
    /// - 10001：使用 data.title （例：已关注了你）
    /// - 11：    优先 data.txt1，否则 data.title
    /// - 位置：  顶层 title 或 address
    /// - 其它：  回落 [自定义消息]
    private func customMessagePreview(_ last: V2NIMLastMessage) -> String {
        guard let dict = NECustomUtils.attachmentOfCustomMessage(last.attachment) else {
            return "[自定义消息]"
        }
        // 位置消息
        if dict["lat"] != nil, dict["lng"] != nil {
            if let t = dict["title"] as? String, !t.isEmpty { return t }
            if let a = dict["address"] as? String, !a.isEmpty { return a }
            return "[位置]"
        }
        let type = (dict["type"] as? Int) ?? ((dict["type"] as? NSNumber)?.intValue ?? 0)
        let data = dict["data"] as? [String: Any] ?? [:]
        let title = (data["title"] as? String) ?? ""
        let txt1 = (data["txt1"] as? String) ?? ""
        switch type {
        case 10001:
            let nickname = (data["nickname"] as? String) ?? ""
            if !title.isEmpty { return nickname+" "+title }
        case 11:
            if !txt1.isEmpty { return txt1 }
            if !title.isEmpty { return title }
        default:
            if !title.isEmpty { return title }
            if !txt1.isEmpty { return txt1 }
        }
        return "[自定义消息]"
    }

    private func formatTime(_ timestamp: TimeInterval) -> String {
        guard timestamp > 0 else { return "" }
        let date = Date(timeIntervalSince1970: timestamp)
        let calendar = Calendar.current
        let formatter = DateFormatter()
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else if let week = calendar.dateInterval(of: .weekOfYear, for: Date()),
                  week.contains(date) {
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "zh_CN")
        } else {
            formatter.dateFormat = "MM/dd"
        }
        return formatter.string(from: date)
    }
}
