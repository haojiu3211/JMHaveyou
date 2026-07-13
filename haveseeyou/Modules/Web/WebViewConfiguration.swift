//
//  WebViewConfiguration.swift
//  haveseeyou
//
//  WebView 配置类
//  用于配置 WebViewController 的显示样式和行为
//

import Foundation

/// WebView 显示配置
struct WebViewConfiguration {
    
    /// 要加载的 URL 字符串
    var urlString: String
    
    /// 要直接加载的 HTML 字符串（如果设置了，则优先使用而不是 urlString）
    var htmlString: String?
    
    /// 导航栏标题（为空时使用网页标题）
    var navigationTitle: String?
    
    /// 是否全屏显示（隐藏导航栏，H5 自己处理返回）
    var isFullScreen: Bool
    
    /// 是否显示进度条
    var showProgressBar: Bool
    
    /// 是否允许手势返回
    var allowsBackForwardGestures: Bool
    
    /// 是否使用网页标题作为导航栏标题
    var useWebTitle: Bool
    
    /// 是否允许使用缓存（默认 true，设为 false 时强制从网络加载）
    var useCache: Bool
    
    // MARK: - 初始化
    
    /// 默认配置初始化
    /// - Parameters:
    ///   - urlString: URL 字符串
    ///   - htmlString: 要直接加载的 HTML 字符串（可选）
    ///   - navigationTitle: 导航栏标题
    ///   - isFullScreen: 是否全屏，默认 false（非全屏会显示原生导航栏和返回按钮）
    ///   - showProgressBar: 是否显示进度条，默认 true
    ///   - allowsBackForwardGestures: 是否允许手势返回，默认 true
    ///   - useWebTitle: 是否使用网页标题，默认 true
    ///   - useCache: 是否允许使用缓存，默认 true
    init(
        urlString: String = "",
        htmlString: String? = nil,
        navigationTitle: String? = nil,
        isFullScreen: Bool = false,
        showProgressBar: Bool = true,
        allowsBackForwardGestures: Bool = true,
        useWebTitle: Bool = true,
        useCache: Bool = true
    ) {
        self.urlString = urlString
        self.htmlString = htmlString
        self.navigationTitle = navigationTitle
        self.isFullScreen = isFullScreen
        self.showProgressBar = showProgressBar
        self.allowsBackForwardGestures = allowsBackForwardGestures
        self.useWebTitle = useWebTitle
        self.useCache = useCache
    }

    
    // MARK: - 便捷构造方法
    
    /// 创建标准配置（带导航栏和返回按钮）
    static func standard(urlString: String, title: String? = nil) -> WebViewConfiguration {
        return WebViewConfiguration(
            urlString: urlString,
            navigationTitle: title,
            isFullScreen: false
        )
    }
    
    /// 创建全屏配置（无导航栏，H5 自己处理返回）
    static func fullScreen(urlString: String) -> WebViewConfiguration {
        return WebViewConfiguration(
            urlString: urlString,
            isFullScreen: true
        )
    }
}
