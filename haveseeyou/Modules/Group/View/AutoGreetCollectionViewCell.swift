//
//  AutoGreetCollectionViewCell.swift
//  haveseeyou
//
//  自动打招呼弹窗 Cell
//

import UIKit
import SnapKit

final class GradientView: UIView {
    private let gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupGradient() {
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.0).cgColor,
            UIColor.black.withAlphaComponent(0.6).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

final class AutoGreetCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "AutoGreetCollectionViewCell"
    
    // MARK: - UI
    
    /// 头像背景视图
    private let avatarContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.backgroundColor = .clear
        return view
    }()
    
    /// 头像图片
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        return imageView
    }()
    
    /// 选中状态图
    private let selectedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "auto_greet_nomal")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    /// 底部容器（渐变背景）
    private let bottomContainerView: GradientView = {
        let view = GradientView()
        return view
    }()
    
    /// 位置图标
    private let locationImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "auto_greet_local")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    /// 昵称标签
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    /// 位置标签
    private let localLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .white
        label.textAlignment = .left
        return label
    }()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    
    // MARK: - Setup
    private func setupUI() {
        contentView.addSubviews(avatarContainerView, nameLabel)
        avatarContainerView.addSubview(avatarImageView)
        avatarContainerView.addSubview(selectedImageView)
        avatarContainerView.addSubview(bottomContainerView)
        bottomContainerView.addSubviews(locationImageView, localLabel)
        
        avatarContainerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(avatarContainerView.snp.width)
        }
        
        avatarImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        selectedImageView.snp.makeConstraints { make in
            make.top.right.equalToSuperview().inset(4)
            make.size.equalTo(CGSize(width: 16, height: 16))
        }
        
        bottomContainerView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(44)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarContainerView.snp.bottom).offset(4)
            make.left.right.equalToSuperview()
        }
        
        locationImageView.snp.makeConstraints { make in
            make.centerY.equalTo(localLabel)
            make.left.equalToSuperview().offset(6)
            make.size.equalTo(CGSize(width: 10, height: 10))
        }
        
        localLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-6)
            make.left.equalTo(locationImageView.snp.right).offset(2)
            make.right.equalToSuperview().offset(-6)
        }
    }
    
    // MARK: - Prepare for Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        nameLabel.text = nil
        localLabel.text = nil
        selectedImageView.image = UIImage(named: "auto_greet_nomal")
    }
    
    // MARK: - Configure
    func configure(with image: UIImage?, name: String, location: String, isSelected: Bool) {
        avatarImageView.image = image
        nameLabel.text = name
        localLabel.text = location
        selectedImageView.image = isSelected ? UIImage(named: "auto_greet_select") : UIImage(named: "auto_greet_nomal")
    }
}
