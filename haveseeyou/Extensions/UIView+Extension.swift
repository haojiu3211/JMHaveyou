//
//  UIView+Extension.swift
//  haveseeyou
//

import UIKit

extension UIView {
    /// 链式添加多个子视图
    func addSubviews(_ views: UIView...) {
        views.forEach { addSubview($0) }
    }

    /// 设置部分圆角
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

extension UIImage {
    /// 通过纯色生成 1x1 图片
    static func image(with color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return img
    }

    /// 保存图片到本地 Documents 目录，返回文件名（相对路径）
    /// - Parameter fileName: 文件名，默认 "avatar.png"
    /// - Returns: 保存成功返回文件名（如 "avatar.png"），失败返回 nil
    func saveToLocal(fileName: String = "avatar.png") -> String? {
        guard let data = jpegData(compressionQuality: 0.8) ?? pngData() else { return nil }
        let documentsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let filePath = documentsDir + "/" + fileName
        do {
            try data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }

    /// 从本地路径加载图片（支持文件名或绝对路径，自动兼容旧数据）
    static func loadFromLocal(path: String) -> UIImage? {
        guard !path.isBlank else { return nil }
        // 如果是 http/https 开头，说明是远程 URL，本地无法直接加载
        if path.hasPrefix("http") { return nil }
        // 如果已经是绝对路径且文件存在，直接加载（兼容旧数据）
        if path.hasPrefix("/") {
            if FileManager.default.fileExists(atPath: path) {
                return UIImage(contentsOfFile: path)
            }
            // 绝对路径失效（沙盒 UUID 变化），尝试提取文件名重新拼接
            let fileName = (path as NSString).lastPathComponent
            let documentsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let newPath = documentsDir + "/" + fileName
            return UIImage(contentsOfFile: newPath)
        }
        // 相对路径（文件名），拼接当前沙盒目录
        let documentsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fullPath = documentsDir + "/" + path
        return UIImage(contentsOfFile: fullPath)
    }
    
    /// 对图片应用高斯模糊
    func blurred(radius: CGFloat) -> UIImage {
        let context = CIContext(options: nil)
        guard let ciImage = CIImage(image: self) else { return self }
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)
        guard let output = filter?.outputImage else { return self }
        if let cgImage = context.createCGImage(output, from: ciImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return self
    }
}
