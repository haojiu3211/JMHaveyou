//
//  MyActivityCardCell.swift
//  haveseeyou
//
//  我的页面 - 我发起的活动卡片 Cell
//

import UIKit
import SnapKit
import Kingfisher

final class MyActivityCardCell: UITableViewCell {

    static let reuseID = "MyActivityCardCell"

    /// "一呼百应"按钮点击回调
    var onActionTapped: (() -> Void)?

    /// 删除按钮点击回调
    var onDeleteTapped: (() -> Void)?

    // MARK: - UI Components

    /// 白色圆角卡片容器
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.layer.masksToBounds = true
        v.layer.borderColor = UIColor(hex: "#FFE2E5F2").cgColor
        v.layer.borderWidth = 1
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

    /// 报名人数 & 性别要求
    private let participantLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColor.textSecondary
        return l
    }()

    /// 删除按钮（右上角）
    private let deleteButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "me_del"), for: .normal)
        return btn
    }()

    /// 状态图片（右侧垂直居中）
    private let statusImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    /// "一呼百应"按钮
    private let actionButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("一呼百应", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        btn.setTitleColor(AppColor.textMain, for: .normal)
        btn.backgroundColor = UIColor(hex: "#F5F5F5")
        btn.layer.cornerRadius = 15
        return btn
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupUI()
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup UI

    private func setupUI() {
        contentView.addSubview(cardView)
        cardView.addSubviews(
            coverImageView,
            titleLabel,
            categoryLabel,
            timeIcon, timeLabel,
            expenseIcon, expenseLabel,
            locationIcon, locationLabel,
            participantLabel,
            deleteButton,
            statusImageView,
            actionButton
        )

        // 卡片
        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-6)
        }

        // 封面图
        coverImageView.snp.makeConstraints { make in
            make.top.left.bottom.equalToSuperview()
            make.width.equalTo(91.fit)
        }

        // 删除按钮 - 右上角
        deleteButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(9)
            make.right.equalToSuperview().offset(-10)
            make.size.equalTo(20)
        }

        // 状态图片 - 右侧垂直居中
        statusImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-10)
            make.width.equalTo(50)
            make.height.equalTo(50)
        }

        // 标题
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalTo(coverImageView.snp.right).offset(10)
            make.right.equalTo(deleteButton.snp.left).offset(-4)
        }

        // 类型
        categoryLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(1)
            make.left.equalTo(titleLabel)
            make.right.equalToSuperview().offset(-20)
        }

        // 时间
        timeIcon.snp.makeConstraints { make in
            make.top.equalTo(categoryLabel.snp.bottom).offset(6)
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
        // 一呼百应按钮
        actionButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-8)
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(30)
            make.width.equalTo(80)
        }
        // 报名人数 & 性别
        participantLabel.snp.makeConstraints { make in
//            make.bottom.equalToSuperview().offset(-8)
            make.centerY.equalTo(actionButton)
            make.left.equalTo(titleLabel)
            make.right.equalTo(actionButton.snp.left).offset(-8)
        }

        
    }

    // MARK: - Actions

    @objc private func actionTapped() {
        onActionTapped?()
    }

    @objc private func deleteTapped() {
        onDeleteTapped?()
    }

    // MARK: - Configure

    private var currentModel: PublishModel?

    func configure(with model: PublishModel) {
        currentModel = model

        // 封面图
    
        
        if let url = model.coverImages.first, !url.isEmpty {
             let full = url.hasPrefix("http") ? url : AppConfig.API.fullImageURL(path: url)
             if let imageURL = URL(string: full) {
                 coverImageView.kf.setImage(with: imageURL, placeholder: UIImage(named: ""))
             } else {
                 coverImageView.image = UIImage(named: "")
             }
         } else {
             coverImageView.image = UIImage(named: "")
         }
        

        // 标题
        titleLabel.text = model.title

        // 类型
        categoryLabel.text = "#\(model.category)"

        // 时间
        timeLabel.text = "活动时间：\(model.timeDisplayText)"

        // 费用
        expenseLabel.text = "活动费用：\(model.expenseType.rawValue)"

        // 地址
        locationLabel.text = "活动地址：\(model.locationDisplayText)"

        // 人数 & 性别
        let genderText = model.genderRequirement == .unlimited ? "" : " 只限\(model.genderRequirement.rawValue)生"
        participantLabel.text = "报名人数：\(model.participantCount)人\(genderText)"
        //按钮状态
        makeActionButton(model.status)
        // 状态图片
        configureStatusImage(model.status)
        // 一呼百应按钮状态
        actionButton.isEnabled = model.status == .ongoing
        actionButton.alpha = model.status == .ongoing ? 1.0 : 0.4
        
        
    }
    private func makeActionButton(_ status: MyActivityStatus){
        switch status {
        case .ongoing:
            let grad = UIColor.gradientTextColor(size: CGSize(width: 80, height: 30), colors: sy_gradientArr)
            actionButton.setTitleColor(grad, for: .normal)
            actionButton.backgroundColor = AppColor.buttonDark
        case .pending,.expired:
            actionButton.setTitleColor(UIColor(hex: "#FF484848"), for: .normal)
            actionButton.backgroundColor = UIColor(hex: "#FFB2B2B2")
                
            
        }
    }
    private func configureStatusImage(_ status: MyActivityStatus) {
        switch status {
        case .ongoing:
            statusImageView.isHidden = true
            statusImageView.image = nil
        case .pending:
            statusImageView.isHidden = false
            statusImageView.image = UIImage(named: "status_wating")
        case .expired:
            statusImageView.isHidden = false
            statusImageView.image = UIImage(named: "status_expire")
        }
    }

    private func placeholderCover(for status: MyActivityStatus) -> UIImage {
        switch status {
        case .ongoing:
            return UIImage.image(with: UIColor(hex: "#8AB6D6"), size: CGSize(width: 110, height: 160))
        case .pending:
            return UIImage.image(with: UIColor(hex: "#D9A28E"), size: CGSize(width: 110, height: 160))
        case .expired:
            return UIImage.image(with: UIColor(hex: "#B5B5B5"), size: CGSize(width: 110, height: 160))
        }
    }
}
