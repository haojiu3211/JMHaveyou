//
//  MemberNavView.swift
//  haveseeyou
//
//  Created by admin开发测试 on 2026/6/11.
//

import UIKit
import SnapKit
import Kingfisher

// 定义返回按钮点击的协议（用于监听）
protocol MemberNavViewDelegate: AnyObject {
    func navBarDidClickBackButton()
}

class MemberNavView: UIView {

    weak var delegate: MemberNavViewDelegate?

    // MARK: - UI Elements

    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        // 这里替换成你实际的深色背景图资源名称
        iv.image = UIImage(named: "member_nav_bg")
        iv.contentMode = .scaleAspectFill
        return iv
    }()

    private let backButton: UIButton = {
        let btn = UIButton(type: .custom)
        // 替换成你的白色返回箭头图片
        btn.setImage(UIImage(named: "member_navBack_bg"), for: .normal)
        return btn
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "会员中心"
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let decorationImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "member_center_userinfo_bg")
        iv.contentMode = .scaleToFill
        return iv
    }()
    
    // 1. 定义头像属性
    private let userAvatarImageView: UIImageView = {
        let iv = UIImageView()
        // 设置默认占位图，防止加载前显示空白
        iv.image = UIImage(named: "sy_delet_account")
        iv.contentMode = .scaleAspectFill // 保持比例填充，防止图片变形
        iv.layer.cornerRadius = 24
        iv.clipsToBounds = true
        return iv
    }()
    
    private let userInfoLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1

        // 创建富文本
        let nameStr = "-----"
        let idStr = " ---"

        let attributedString = NSMutableAttributedString(string: nameStr, attributes: [
            .font: UIFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: UIColor.white
        ])

        let idAttribute = NSAttributedString(string: idStr, attributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.6)
        ])

        attributedString.append(idAttribute)
        label.attributedText = attributedString
        label.numberOfLines = 1
        label.lineBreakMode = .byWordWrapping
        

        return label
    }()
    
    private let vipExpireLabel: UILabel = {
        let label = UILabel()
        // 设置默认显示的文本
        label.text = "-----"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = AppColor.vipgold
        label.numberOfLines = 1
        return label
    }()
    

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup UI

    private func setupUI() {
        self.backgroundColor = .clear // 让背景透明，由backgroundImageView控制

        // 添加子视图
        addSubview(backgroundImageView)
        addSubview(backButton)
        addSubview(titleLabel)
        addSubview(decorationImageView)
        addSubview(userAvatarImageView)
        addSubview(userInfoLabel)
        addSubview(vipExpireLabel)

        // 使用 SnapKit 进行布局
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        backButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(44) // 增加点击区域
        }

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset((UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44) + 9)
        }

        decorationImageView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16) // 左右各留 16 的间距
            make.top.equalTo(titleLabel.snp.bottom).offset(22) // 距离 titleLabel 底部 22 个点
            make.height.equalTo(193.5)
        }
        
        // 编写约束
        userAvatarImageView.snp.makeConstraints { make in
            make.bottom.equalTo(self.snp.bottom).offset(-17)
            make.leading.equalToSuperview().offset(34)
            make.width.height.equalTo(48)
        }
        
        userInfoLabel.snp.makeConstraints { make in
            make.leading.equalTo(userAvatarImageView.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(50)
            make.top.equalTo(userAvatarImageView.snp.top).offset(-1)
        }
        
        vipExpireLabel.snp.makeConstraints { make in
            make.top.equalTo(userInfoLabel.snp.bottom).offset(1)
            make.leading.equalTo(userAvatarImageView.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(20)
        }
        
    }

    // MARK: - Actions

    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }

    @objc private func backButtonTapped() {
        // 触发代理方法，通知外部控制器
        delegate?.navBarDidClickBackButton()
    }
    
    // MARK: - Public Methods
    
    /// 设置用户信息
    /// - Parameters:
    ///   - avatar: 头像URL
    ///   - nickname: 昵称
    ///   - usercode: 用户编码
    ///   - vip: VIP等级/状态
    ///   - vipExpireDate: VIP到期时间
    func setUserInfo(avatar: String?, nickname: String?, usercode: String?, vip: Int? = nil, vipExpireDate: String? = nil) {
        // 设置头像
        if let avatarUrl = avatar, !avatarUrl.isEmpty {
            let fullUrlString = avatarUrl.hasPrefix("http") ? avatarUrl : AppConfig.API.fullImageURL(path: avatarUrl)
            if let url = URL(string: fullUrlString) {
                userAvatarImageView.kf.setImage(with: url, placeholder: UIImage(named: "sy_delet_account"))
            } else {
                userAvatarImageView.image = UIImage(named: "sy_delet_account")
            }
        } else {
            userAvatarImageView.image = UIImage(named: "sy_delet_account")
        }
        
        // 设置昵称和ID
        let nameStr = nickname ?? "用户"
        let idStr = " (ID:\(usercode ?? ""))"
        
        let attributedString = NSMutableAttributedString(string: nameStr, attributes: [
            .font: UIFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: UIColor.white
        ])
        
        let idAttribute = NSAttributedString(string: idStr, attributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.6)
        ])
        
        attributedString.append(idAttribute)
        userInfoLabel.attributedText = attributedString
        
        // 设置VIP状态
        if let vipLevel = vip, vipLevel > 0 {
            // 是VIP会员
            if let expireDate = vipExpireDate, !expireDate.isEmpty {
                vipExpireLabel.text = "\(expireDate)"
            } else {
                vipExpireLabel.text = "VIP会员"
            }
        } else {
            // 不是VIP会员
            vipExpireLabel.text = "未开通会员权限"
        }
    }
}
