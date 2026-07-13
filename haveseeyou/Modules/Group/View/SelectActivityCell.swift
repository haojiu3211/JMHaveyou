//
//  SelectActivityCell.swift
//  haveseeyou
//
//  选择活动页面 - 活动卡片 Cell（含单选指示器 + 状态图片）
//

import UIKit
import SnapKit
import Kingfisher

final class SelectActivityCell: UITableViewCell {

    static let reuseID = "SelectActivityCell"

    // MARK: - UI Components

    /// 白色圆角卡片容器
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.layer.masksToBounds = true
        v.layer.borderWidth = 1.5
        return v
    }()

    /// 封面图
    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(hex: "#E5E5E5")
        return iv
    }()

    /// 活动标题
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = AppColor.textMain
        l.numberOfLines = 1
        return l
    }()
    
    private let descriptionLb: UILabel = {
        let l = UILabel()
        
        l.font = .systemFont(ofSize: 12)
        l.textColor = UIColor(hex: "#FF333333")
        l.numberOfLines = 2
        return l
    }()

    /// 活动类型
    private let categoryLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColor.textSecondary
        return l
    }()

    /// 活动时间图标
    private let timeIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "publish_ic_time"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    /// 活动时间
    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColor.textSecondary
        return l
    }()

    /// 活动费用图标
    private let expenseIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "publish_ic_expense"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    /// 活动费用
    private let expenseLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColor.textSecondary
        return l
    }()

    /// 活动地址图标
    private let locationIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "sy_detai_local"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    /// 活动地址
    private let locationLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColor.textSecondary
        return l
    }()

    /// 报名人数
    private let participantLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = UIColor(hex: "#FF5F5F5F")
        return l
    }()
    // 性别要求
    private let genderLb: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = UIColor(hex: "#FF333333")
        return l
    }()
    /// 右上角状态图片（76x24）
    private let statusImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    /// 单选按钮
//    private let radioButton: UIButton = {
//        let btn = UIButton(type: .custom)
//        btn.setImage(UIImage(named: "sy_unselect"), for: .normal)
//        btn.setImage(UIImage(named: "sy_selected"), for: .selected)
//        btn.isUserInteractionEnabled = false
//        return btn
//    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup UI

    private func setupUI() {
        contentView.addSubview(cardView)
        cardView.addSubviews(
            coverImageView,
            titleLabel,
            descriptionLb,
            categoryLabel,
            timeIcon, timeLabel,
            expenseIcon, expenseLabel,
            locationIcon, locationLabel,
            participantLabel,genderLb,
            statusImageView,
            
        )

        // 卡片
        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12.fit)
            make.left.right.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(2)
        }

        // 封面图
        coverImageView.snp.makeConstraints { make in
            make.top.left.bottom.equalToSuperview()
            make.width.equalTo(124)
        }

        // 状态图片 - 右上角 (76x24)
        statusImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.width.equalTo(76)
            make.height.equalTo(24)
        }

        

        // 标题
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalTo(coverImageView.snp.right).offset(10)
            make.right.equalTo(statusImageView.snp.left).offset(-4)
        }
        //注意事项
        descriptionLb.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.right.equalToSuperview().inset(10)
        }
        // 类型
        categoryLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLb.snp.bottom).offset(10)
            make.left.equalTo(titleLabel)
            make.right.equalToSuperview().offset(-20)
        }

        // 时间
        timeIcon.snp.makeConstraints { make in
            make.top.equalTo(categoryLabel.snp.bottom).offset(10)
            make.left.equalTo(titleLabel)
            make.size.equalTo(CGSize(width: 14, height: 14))
        }
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(timeIcon.snp.right).offset(4)
            make.centerY.equalTo(timeIcon)
            make.right.equalToSuperview().offset(-10)
        }

        // 费用
        expenseIcon.snp.makeConstraints { make in
            make.top.equalTo(timeIcon.snp.bottom).offset(6)
            make.left.equalTo(titleLabel)
            make.size.equalTo(CGSize(width: 14, height: 14))
        }
        expenseLabel.snp.makeConstraints { make in
            make.left.equalTo(expenseIcon.snp.right).offset(4)
            make.centerY.equalTo(expenseIcon)
            make.right.equalToSuperview().offset(-10)
        }

        // 地址
        locationIcon.snp.makeConstraints { make in
            make.top.equalTo(expenseIcon.snp.bottom).offset(6)
            make.left.equalTo(titleLabel)
            make.size.equalTo(CGSize(width: 14, height: 14))
        }
        locationLabel.snp.makeConstraints { make in
            make.left.equalTo(locationIcon.snp.right).offset(4)
            make.centerY.equalTo(locationIcon)
            make.right.equalToSuperview().offset(-10)
        }

        // 报名人数
        participantLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalTo(titleLabel)
            
        }
        //性别要求
        genderLb.snp.makeConstraints { make in
            make.centerY.equalTo(participantLabel)
            make.left.equalTo(participantLabel.snp.right).offset(14)
            
        }
    }

    // MARK: - Configure

    func configure(with model: PublishModel, isSelected: Bool) {
        // 封面图
            if let firstPath = model.coverImages.first, !firstPath.isEmpty {
                // 判断是否已经是完整的 http 链接，如果不是则拼接完整路径
                let fullURL = firstPath.hasPrefix("http")
                    ? firstPath
                    : AppConfig.API.fullImageURL(path: firstPath)
                
                if let imageURL = URL(string: fullURL) {
                    // 使用 Kingfisher 加载网络图片，并设置占位图
                    coverImageView.kf.setImage(
                        with: imageURL,
                        placeholder: UIImage(named: "app_default_avatar") // 建议替换为封面图专用的占位图
                    )
                } else {
                    // URL 字符串转 URL 对象失败时的兜底
                    coverImageView.image = UIImage(named: "app_default_avatar")
                }
            } else {
                // 没有封面图数据时的兜底
                coverImageView.image = UIImage(named: "app_default_avatar")
            }

        // 标题
        titleLabel.text = model.title
        descriptionLb.text = model.description
        // 类型
        categoryLabel.text = "活动类型：#\(model.category)"

        // 时间
        timeLabel.text = "活动时间：\(model.timeDisplayText)"

        // 费用
        expenseLabel.text = "活动费用：\(model.expenseType.rawValue)"

        // 地址
        locationLabel.text = "活动地址：\(model.locationDisplayText)"

        // 人数 & 性别
        participantLabel.text = "报名人数：\(model.participantCount)人"
        var genderText = "性别不限"
        switch model.genderRequirement {
        case .female:
            genderText = "只限女生"
        case .male:
            genderText = "只限男生"
        case .unlimited:
            genderText = "性别不限"
        }
        genderLb.text = genderText
        
        // 状态图片
        configureStatusImage(model.status)

        // 选中状态
        if isSelected {
            cardView.layer.borderColor = UIColor(hex: "#FF86FF00").cgColor
        } else {
            cardView.layer.borderColor = UIColor.white.cgColor
        }

    }

    private func configureStatusImage(_ status: MyActivityStatus) {
        switch status {
        case .ongoing:
            statusImageView.isHidden = false
            statusImageView.image = UIImage(named: "sy_active_ing")
        case .expired:
            statusImageView.isHidden = false
            statusImageView.image = UIImage(named: "sy_active_expire")
        case .pending:
            // 待审核不显示状态图片（且此页面不包含待审核活动）
            statusImageView.isHidden = true
            statusImageView.image = nil
        }
    }

    private func placeholderCover(for status: MyActivityStatus) -> UIImage {
        switch status {
        case .ongoing:
            return UIImage.image(with: UIColor(hex: "#8AB6D6"), size: CGSize(width: 91, height: 140))
        case .expired:
            return UIImage.image(with: UIColor(hex: "#B5B5B5"), size: CGSize(width: 91, height: 140))
        case .pending:
            return UIImage.image(with: UIColor(hex: "#D9A28E"), size: CGSize(width: 91, height: 140))
        }
    }
}
