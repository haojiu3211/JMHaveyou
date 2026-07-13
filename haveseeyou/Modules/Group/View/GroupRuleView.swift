//
//  GroupRuleView.swift
//  haveseeyou
//
//  活动规则弹框 - 自定义UIView，从底部往上弹
//

import UIKit
import SnapKit

final class GroupRuleView: UIView {

    // MARK: - UI

    private let backgroundView = UIView()
    private let containerView = UIView()

    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "rule_view_bg")
        iv.contentMode = .scaleToFill
        iv.clipsToBounds = true
        return iv
    }()

    private let titleImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "rule_title")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    let titleLb: UILabel={
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .bold)
        l.text = "规则须知"
        l.textColor = AppColor.textMain
        return l
    }()
    
    private let contentLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        return l
    }()

    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
        btn.tintColor = AppColor.textSecondary
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupContent()
        setupGestures()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        // 背景蒙层
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 标题图
        addSubview(titleImageView)
        
        titleImageView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(180.fit)
            make.left.equalToSuperview().offset(4)
            make.height.equalTo(190)
            make.width.equalTo(258)
        }
        addSubview(containerView)
        containerView.backgroundColor = .clear
       

        containerView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(310)
        }

        // 背景图
        containerView.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        containerView.addSubview(titleLb)
        titleLb.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(50)
        }
        
        // 内容文字
        containerView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLb.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.lessThanOrEqualToSuperview().inset(20)
        }

        // 关闭按钮
//        containerView.addSubview(closeButton)
//        closeButton.snp.makeConstraints { make in
//            make.top.right.equalToSuperview().inset(12)
//            make.width.height.equalTo(24)
//        }
    }

    private func setupContent() {
        let attributedString = NSMutableAttributedString()

        // 创建段落样式，设置行间距
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6 // 行间距为6pt

        // 第一条规则
        let rule1Title = NSAttributedString(
            string: "1.发起者需要首先发布一场活动，并且活动需要平台审核通过；\n\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: AppColor.textMain,
                .paragraphStyle:paragraphStyle
            ]
        )
        attributedString.append(rule1Title)

        // 第二条规则
        let rule2Title = NSAttributedString(
            string: "2.您可以选择该活动指定的特定地区、性别及人数进行报名邀请。\n\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: AppColor.textMain,
                .paragraphStyle: paragraphStyle
            ]
        )
        attributedString.append(rule2Title)

        // 注意事项
        let noteTitle = NSAttributedString(
            string: "注意：",
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: UIColor(hex: "#FFC12828"),
                .paragraphStyle: paragraphStyle
            ]
        )
        attributedString.append(noteTitle)

        let noteContent = NSAttributedString(
            string: "发送后你将收获获指定区域用户的在线咨询，请及时回复！",
            attributes: [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor(hex: "#FFC12828"),
                .paragraphStyle: paragraphStyle
            ]
        )
        attributedString.append(noteContent)

        contentLabel.attributedText = attributedString
    }

    private func setupGestures() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(tapGesture)
    }

    @objc private func closeTapped() {
        dismiss()
    }

    @objc private func backgroundTapped() {
        dismiss()
    }

    // MARK: - 显示弹框

    func show() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first else { return }

        frame = window.bounds
        window.addSubview(self)

        // 从底部往上弹的动画
        animatePresentation()
    }

    private func dismiss() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            var frame1 = self.containerView.frame
            frame1.origin.y = self.bounds.height
            self.containerView.frame = frame1
            
            var frame2 = self.titleImageView.frame
            frame2.origin.y = self.bounds.height
            self.titleImageView.frame = frame2
            
            self.backgroundView.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }

    private func animatePresentation() {
        let finalFrame1 = containerView.frame
        var startFrame1 = finalFrame1
        startFrame1.origin.y = bounds.height
        containerView.frame = startFrame1
        
        let finalFrame2 = titleImageView.frame
        var startFrame2 = finalFrame2
        startFrame2.origin.y = bounds.height
        titleImageView.frame = startFrame2
        
        backgroundView.alpha = 0

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.containerView.frame = finalFrame1
            self.titleImageView.frame = finalFrame2
            self.backgroundView.alpha = 1
        })
    }
}
