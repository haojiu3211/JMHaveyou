//
//  UITabBar+Extension.swift
//  haveseeyou
//

import UIKit

private let badgeTag = 666

extension UITabBar {
    /// 显示带数量的 badge
    /// - Parameters:
    ///   - index: tabbar 索引
    ///   - count: 未读数量
    ///   - tabbarItemNums: tabbar 总数
    func showBadgeOn(index itemIndex: Int, count: Int, tabbarItemNums: CGFloat = 5.0) {
        hideBadgeOn(index: itemIndex)
        
        let badgeText = count > 99 ? "99+" : "\(count)"
        let font = UIFont.systemFont(ofSize: 10, weight: .bold)
        let textSize = badgeText.size(withAttributes: [.font: font])
        
        let badgeWidth = max(textSize.width + 8, 16)
        let badgeHeight: CGFloat = 16
        
        let tabWidth = bounds.width / tabbarItemNums
        let badgeX = tabWidth * CGFloat(itemIndex) + tabWidth * 0.65
        let badgeY: CGFloat = 3
        
        let badgeView = UIView()
        badgeView.tag = itemIndex + badgeTag
        badgeView.backgroundColor = .red
        badgeView.isUserInteractionEnabled = false
        badgeView.frame = CGRect(x: badgeX, y: badgeY, width: badgeWidth, height: badgeHeight)
        badgeView.layer.cornerRadius = badgeHeight / 2
        
        let badgeLabel = UILabel()
        badgeLabel.text = badgeText
        badgeLabel.font = font
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badgeLabel.frame = badgeView.bounds
        badgeView.addSubview(badgeLabel)
        
        addSubview(badgeView)
        bringSubviewToFront(badgeView)
    }
    
    /// 隐藏 badge
    /// - Parameter index: tabbar 索引
    func hideBadgeOn(index itemIndex: Int) {
        for subview in subviews where subview.tag == itemIndex + badgeTag {
            subview.removeFromSuperview()
        }
    }
}
