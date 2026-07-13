//
//  GroupCardView.swift
//  haveseeyou
//
//  搭子卡片视图 - 简化版，只显示背景图、活动规则和马上发起按钮
//

import UIKit
import SnapKit

final class GroupCardView: UIView {

    // MARK: - 回调

    /// 点击"马上发起"按钮回调
    var onLaunchTapped: (() -> Void)?

    /// 点击活动规则按钮回调
    var onRuleTapped: (() -> Void)?

    // MARK: - UI

    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "group_bg")
        iv.contentMode = .scaleAspectFill // 保持 aspect fill，配合固定宽高比，不会被奇怪拉伸
        iv.clipsToBounds = true
        return iv
    }()

   

    // 中间描述文字
    private let descriptionLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.numberOfLines = 1
        return l
    }()

    // 底部"马上发起"按钮
    private let launchButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("马上发起", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        let grad = UIColor.gradientTextColor(size: CGSizeMake(100, 20), colors: sy_gradientArr)
        btn.setTitleColor(grad, for: .normal)
        btn.backgroundColor = AppColor.buttonDark
        btn.layer.cornerRadius = 24
        btn.clipsToBounds = true
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGestures()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        layer.cornerRadius = 20
        clipsToBounds = true

        addSubviews(backgroundImageView, descriptionLabel, launchButton)

        // 背景图
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

      

        // 中间描述文字 - 使用比例约束，不使用 fit
        descriptionLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(146) // 不使用 fit，保持固定值
        }

        // 底部"马上发起"按钮 - 不使用 fit，保持固定尺寸
        launchButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-40)
            make.width.equalTo(216)
            make.height.equalTo(50)
        }
    }

    private func setupGestures() {
        launchButton.addTarget(self, action: #selector(launchTapped), for: .touchUpInside)
        
    }

    // MARK: - 配置

    func configure() {
        // 创建富文本：前半部分白色，后半部分theme颜色
        let attributedString = NSMutableAttributedString()

        let firstPart = NSAttributedString(
            string: "让你的活动不再无人问津  ",
            attributes: [
                .font: UIFont.systemFont(ofSize: 16,weight: .bold),
                .foregroundColor: UIColor.white
            ]
        )

        let secondPart = NSAttributedString(
            string: "快速爆火",
            attributes: [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: AppColor.theme
            ]
        )

        attributedString.append(firstPart)
        attributedString.append(secondPart)

        descriptionLabel.attributedText = attributedString
    }

    // MARK: - 按钮事件

    @objc private func launchTapped() {
        onLaunchTapped?()
    }

  
}
