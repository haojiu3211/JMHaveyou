//
//  ActivityCell.swift
//  haveseeyou
//
//  活动卡片 Cell
//

import UIKit
import SnapKit
import Kingfisher

final class ActivityCell: UITableViewCell {

    static let reuseID = "ActivityCell"

    /// 点击"查看活动"按钮回调，携带当前行对应的 ActivityModel
    var onActionTapped: ((ActivityModel) -> Void)?

    // 容器
    private let card: UIView = {
        let v = UIView()
        v.backgroundColor = AppColor.card
        v.layer.cornerRadius = 14
        v.layer.masksToBounds = true
        return v
    }()

    // 封面
    private let coverView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(hex: "#E5E5E5")
        return iv
    }()

    // 地点
    private let locationIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "sy_active_local"))
        iv.tintColor = AppColor.textMain
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    private let locationLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColor.textSecondary
        return l
    }()

    // 状态标签
    private let statusIV: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    // 标题
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = AppColor.textMain
        l.numberOfLines = 1
        return l
    }()

    // 分类
    private let categoryLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColor.textSecondary
        return l
    }()

    // 组队信息
    private let teamLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColor.textSecondary
        return l
    }()

    // 查看活动按钮
    private let actionButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("查看活动", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        b.setTitleColor(AppColor.theme, for: .normal)
        b.backgroundColor = AppColor.buttonDark
        b.layer.cornerRadius = 16
        b.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        return b
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupUI()
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 清理回调，防止循环引用
        onActionTapped = nil
        currentModel = nil
        // 取消图片加载
        coverView.kf.cancelDownloadTask()
        coverView.image = nil
    }

    private func setupUI() {
        contentView.addSubview(card)
        card.addSubviews(coverView, locationIcon, locationLabel, statusIV,
                         titleLabel, categoryLabel, teamLabel, actionButton)

        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
        }
        coverView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(90.fit)
        }
        // 状态
        statusIV.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.width.equalTo(82.fit)
            make.height.equalTo(24.fit)
        }
        // 地点
        locationIcon.snp.makeConstraints { make in
            make.left.equalTo(coverView.snp.right).offset(10)
            make.centerY.equalTo(locationLabel)
            make.size.equalTo(CGSize(width: 10, height: 12))
        }
        locationLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.left.equalTo(locationIcon.snp.right).offset(4)
            make.right.lessThanOrEqualTo(statusIV.snp.left).offset(-8)
        }
        // 标题
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(locationLabel.snp.bottom).offset(8)
            make.left.equalTo(locationIcon)
            make.right.equalToSuperview().inset(12)
        }
        // 分类
        categoryLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.equalTo(locationIcon)
            make.right.equalToSuperview().inset(12)
        }
        // 队伍信息
        teamLabel.snp.makeConstraints { make in
            make.left.equalTo(locationIcon)
            make.bottom.equalToSuperview().inset(18)
        }
        actionButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(10)
            make.height.equalTo(32)
        }
    }

    // MARK: - 按钮事件

    @objc private func actionButtonTapped() {
        guard let model = currentModel else { return }
        onActionTapped?(model)
    }

    // MARK: - 数据绑定

    /// 缓存当前模型，供按钮回调使用
    private var currentModel: ActivityModel?

    func configure(_ model: ActivityModel) {
        currentModel = model
        locationLabel.text = model.location
        titleLabel.text = model.title
        categoryLabel.attributedText = categoryAttr(model.category)
        teamLabel.text = "组队中"//"报名人数: "+model.teamInfo

        
        switch model.status {
        case .ongoing:
            
            statusIV.image = UIImage(named: "sy_active_ing")
            actionButton.isEnabled = true
            let gradientColor = UIColor.gradientTextColor(
                size: CGSize(width: 80, height: 30),
                colors: sy_gradientArr)
            actionButton.backgroundColor = AppColor.buttonDark
            actionButton.setTitleColor(gradientColor, for: .normal)
        case .pending:
            statusIV.image = UIImage(named: "sy_active_wait")
            
            actionButton.isEnabled = true
            actionButton.backgroundColor = AppColor.buttonDark
            actionButton.setTitleColor(AppColor.theme, for: .normal)
        case .expired:
            statusIV.image = UIImage(named: "sy_active_expired")
            
            actionButton.isEnabled = false
            actionButton.backgroundColor = AppColor.tagExpired
            actionButton.setTitleColor(UIColor.white, for: .normal)
        }
        
        let currentUserId = UserManager.shared.userId ?? ""
        if model.userId == currentUserId {
            actionButton.setTitle("查看活动", for: .normal)
        } else {
            actionButton.setTitle("我感兴趣", for: .normal)
        }
        
        // 假设 model.coverURL 是 String 类型
        if !model.coverURL.isEmpty {
            // 此时可以直接使用 model.coverURL
            let full = model.coverURL.hasPrefix("http") ? model.coverURL : AppConfig.API.fullImageURL(path: model.coverURL)

            if let imageURL = URL(string: full) {
                coverView.kf.setImage(with: imageURL, placeholder: UIImage(named: "placeholder")) // 建议填入真实占位图名称
            } else {
                coverView.image = UIImage(named: "placeholder")
            }
        } else {
            coverView.image = UIImage(named: "placeholder")
        }
        
    }

    private func categoryAttr(_ text: String) -> NSAttributedString {
        let prefix = NSMutableAttributedString(
            string: "活动类型： ",
            attributes: [
                .foregroundColor: AppColor.textSecondary,
                .font: UIFont.systemFont(ofSize: 12)
            ])
        let content = NSAttributedString(
            string: text,
            attributes: [
                .foregroundColor: AppColor.textSecondary,
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
            ])
        prefix.append(content)
        return prefix
    }

    private func placeholderCover(for status: ActivityStatus) -> UIImage {
        switch status {
        case .ongoing: return UIImage.image(with: UIColor(hex: "#8AB6D6"), size: CGSize(width: 120, height: 140))
        case .pending: return UIImage.image(with: UIColor(hex: "#D9A28E"), size: CGSize(width: 120, height: 140))
        case .expired: return UIImage.image(with: UIColor(hex: "#B5B5B5"), size: CGSize(width: 120, height: 140))
        }
    }
}
