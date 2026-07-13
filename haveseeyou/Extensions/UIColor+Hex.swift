//
//  UIColor+Hex.swift
//  haveseeyou
//
//  颜色工具扩展
//

import UIKit

extension UIColor {
    /// 通过十六进制字符串创建颜色，如 "#CCFF33" 或 "CCFF33"
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexStr = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexStr.hasPrefix("#") { hexStr.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: hexStr).scanHexInt64(&rgb)
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
    
    static func gradientTextColor(
            size: CGSize,
            colors: [UIColor]
        ) -> UIColor {

            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = CGRect(origin: .zero, size: size)

            gradientLayer.colors = colors.map { $0.cgColor }

            // 左 -> 右
            gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)

            UIGraphicsBeginImageContextWithOptions(size, false, 0)

            guard let context = UIGraphicsGetCurrentContext() else {
                return .white
            }

            gradientLayer.render(in: context)

            let image = UIGraphicsGetImageFromCurrentImageContext()

            UIGraphicsEndImageContext()

            return UIColor(patternImage: image!)
        }
    
}
let sy_gradientArr = [UIColor(hex: "#A2EF4D"), UIColor(hex: "#F7FFFF"), UIColor(hex: "#F7FFFF")]
/// 项目通用色板
enum AppColor {
    /// 品牌主色 - 荧光绿
    static let theme = UIColor(hex: "#FF77E400")
    /// 深色按钮
    static let buttonDark = UIColor(hex: "#FF100A1D")
    /// 主文本
    static let textMain = UIColor(hex: "#1F1F1F")
    /// 次级文本
    static let textSecondary = UIColor(hex: "#8A8A8A")
    /// 页面背景
    static let background = UIColor(hex: "#F5F5F5")
    /// 卡片背景
    static let card = UIColor.white
    /// 进行中标签
    static let tagOngoing = UIColor(hex: "#1F1F1F")
    /// 待审核标签
    static let tagPending = UIColor(hex: "#FFE082")
    /// 已过期标签
    static let tagExpired = UIColor(hex: "#D9D9D9")
    /// 金色颜色
    static let vipgold = UIColor(hex: "#D0AC88")
}
