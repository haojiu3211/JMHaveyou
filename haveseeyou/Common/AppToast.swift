//
//  AppToast.swift
//  haveseeyou
//
//  全局Toast提示组件
//

import UIKit

enum AppToast {
    
    /// 显示Toast提示
    /// - Parameters:
    ///   - message: 提示文本
    ///   - duration: 显示时长（秒）
    static func show(_ message: String, duration: TimeInterval = 2.0) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        
        // 创建Toast容器
        let toastView = UIView()
        toastView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastView.layer.cornerRadius = 8
        toastView.clipsToBounds = true
        
        // 创建文本标签
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        
        toastView.addSubview(label)
        window.addSubview(toastView)
        
        // 布局
        label.translatesAutoresizingMaskIntoConstraints = false
        toastView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -12),
            label.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -16),
            
            toastView.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            toastView.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            toastView.leadingAnchor.constraint(greaterThanOrEqualTo: window.leadingAnchor, constant: 40),
            toastView.trailingAnchor.constraint(lessThanOrEqualTo: window.trailingAnchor, constant: -40)
        ])
        
        // 动画显示
        toastView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            toastView.alpha = 1
        }
        
        // 延迟后自动消失
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            UIView.animate(withDuration: 0.3, animations: {
                toastView.alpha = 0
            }) { _ in
                toastView.removeFromSuperview()
            }
        }
    }
}
