//
//  TagDisplayComponents.swift
//  haveseeyou
//
//  标签显示通用组件
//

import UIKit
import SnapKit

// 左对齐的标签布局
class LeftAlignedFlowLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        
        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        
        attributes?.forEach { layoutAttribute in
            if layoutAttribute.representedElementCategory == .cell {
                if layoutAttribute.frame.origin.y >= maxY {
                    leftMargin = sectionInset.left
                }
                layoutAttribute.frame.origin.x = leftMargin
                leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
                maxY = max(layoutAttribute.frame.maxY, maxY)
            }
        }
        
        return attributes
    }
}

// 标签显示单元格
final class TagDisplayCell: UICollectionViewCell {
    static let reuseId = "TagDisplayCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#FFF9F9F9")
        view.layer.cornerRadius = 12
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(10)
        }
    }
    
    func configure(with tag: String) {
        // 创建富文本：#号是 #89E325，文字是 #515151
        let attributedText = NSMutableAttributedString(string: "# \(tag)")
        let textColor = UIColor(hex: "#FF515151") ?? .gray
        let hashColor = UIColor(hex: "#FF89E325") ?? .green
        
        // 设置整体文字颜色
        attributedText.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: attributedText.length))
        
        // 设置#号颜色
        attributedText.addAttribute(.foregroundColor, value: hashColor, range: NSRange(location: 0, length: 1))
        
        titleLabel.attributedText = attributedText
    }
}
