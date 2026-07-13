//
//  PublishImageCell.swift
//  haveseeyou
//
//  Created by admin on 2026/5/27.
//

import UIKit
import SnapKit
import Kingfisher

final class PublishImageCell: UICollectionViewCell {
    static let identifier = "PublishImageCell"
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = UIColor(hex: "#F5F5F5")
        return iv
    }()
    
    private let deleteButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setBackgroundImage(UIImage(named: "app_close"), for: .normal)
//        btn.backgroundImage(UIImage(named: "app_close"))
        btn.backgroundColor = .clear
//        btn.imageView?.contentMode = .scaleAspectFill
        btn.isHidden = true
        return btn
    }()
    
    private let addIconView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()
    
    private let addImageIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "plus")
        iv.tintColor = .lightGray
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let addLabel: UILabel = {
        let label = UILabel()
        label.text = "添加优质图片\n更吸引人"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .lightGray
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()
    
    var onDelete: (() -> Void)?
    
    /// 是否处于编辑状态（控制删除按钮显示）
    var isEditing: Bool = true {
        didSet {
            // 只有当有图片且处于编辑状态时，才显示删除按钮
            if let _ = imageView.image {
                deleteButton.isHidden = !isEditing
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(deleteButton)
        contentView.addSubview(addIconView)
        addIconView.addSubviews(addImageIcon, addLabel)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        deleteButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.right.equalToSuperview().offset(-4)
            make.width.height.equalTo(18)
        }
        
        addIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        addImageIcon.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.height.equalTo(30)
        }
        
        addLabel.snp.makeConstraints { make in
            make.top.equalTo(addImageIcon.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    }
    
    @objc private func deleteTapped() {
        onDelete?()
    }
    
    func configure(with image: UIImage?) {
        if let image = image {
            imageView.image = image
            // 根据编辑状态决定是否显示删除按钮
            deleteButton.isHidden = !isEditing
            addIconView.isHidden = true
        } else {
            imageView.image = nil
            deleteButton.isHidden = true
            addIconView.isHidden = true
        }
    }
    
    func configureAsAddButton() {
        imageView.image = nil
        deleteButton.isHidden = true
        addIconView.isHidden = false
    }
    
    func configure(with imageURL: String?) {
        if let imageURL = imageURL, let url = URL(string: imageURL) {
            imageView.kf.setImage(with: url)
            // 根据编辑状态决定是否显示删除按钮
            deleteButton.isHidden = !isEditing
            addIconView.isHidden = true
        } else {
            imageView.image = nil
            deleteButton.isHidden = true
            addIconView.isHidden = true
        }
    }
}
