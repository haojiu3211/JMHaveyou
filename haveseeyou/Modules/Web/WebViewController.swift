//
//  WebViewController.swift
//  haveseeyou
//
//  通用的 H5 页面展示控制器
//  支持加载 URL、显示进度条、返回按钮、JS 交互
//

import UIKit
import WebKit
import SnapKit
import YPImagePicker

final class WebViewController: BaseViewController {
    
    // MARK: - 全局共享 WKProcessPool
    // 所有 WebViewController 共用同一个 XPC进程，防止反復 push/pop 后进程数超限被系统强杀
    private static let sharedProcessPool = WKProcessPool()
    
    // MARK: - Properties
    
    /// WebView 配置
    var configuration: WebViewConfiguration!
    
    /// JS 桥接器
    private var jsBridge: WebViewJSBridge?
    
    /// 页面加载完成回调（外部可设置，在 didFinish 后触发）
    var onPageLoaded: ((WebViewController) -> Void)?

    /// 活动类型选择回调（供 PublishViewController 等页面关联使用）
    var onActivityTypesSelected: (([String]) -> Void)?
    
    // MARK: - BaseViewController Override
    
    /// 全屏模式隐藏导航栏
    override var prefersNavigationBarHidden: Bool {
        return configuration?.isFullScreen ?? false
    }
    
    /// 非全屏模式使用标准返回按钮
    override var useStandardBackButton: Bool {
        return !(configuration?.isFullScreen ?? false)
    }
    
    // MARK: - UI Components
    
    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        // 共享进程池，所有 WebView 复用同一个 WebContent XPC 进程
        config.processPool = WebViewController.sharedProcessPool
        
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = self
        wv.uiDelegate = self
        wv.allowsBackForwardNavigationGestures = configuration.allowsBackForwardGestures
        // 防止 WKWebView XPC 进程冷启动期间显示黑屏
        wv.isOpaque = false
        wv.backgroundColor = .white
        wv.scrollView.backgroundColor = .white
        wv.scrollView.showsVerticalScrollIndicator = false
        wv.scrollView.showsHorizontalScrollIndicator = false
        return wv
    }()
    
    private lazy var progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.tintColor = AppColor.textMain
        pv.trackTintColor = .clear
        pv.isHidden = !configuration.showProgressBar
        return pv
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var closeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("✕", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 24, weight: .light)
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        btn.layer.cornerRadius = 20
        btn.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        btn.isHidden = true  // 全屏模式由 H5 自己处理返回
        return btn
    }()
    
    // MARK: - 便捷初始化
    
    /// 使用配置初始化
    convenience init(configuration: WebViewConfiguration) {
        self.init()
        self.configuration = configuration
    }
    
    /// 使用 URL 字符串初始化（使用默认配置）
    convenience init(urlString: String, title: String? = nil) {
        self.init()
        self.configuration = .standard(urlString: urlString, title: title)
    }
    
    /// 使用 HTML 字符串初始化
    convenience init(htmlString: String, title: String? = nil) {
        self.init()
        self.configuration = WebViewConfiguration(
            htmlString: htmlString,
            navigationTitle: title
        )
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 确保配置已设置
        if configuration == nil {
            configuration = .standard(urlString: "")
        }
        
        setupUI()
        setupJSBridge()
        loadWebPage()
        
        // 设置标题
        if let navigationTitle = configuration.navigationTitle, !navigationTitle.isEmpty {
            title = navigationTitle
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // BaseViewController 会自动处理导航栏的显示/隐藏
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // BaseViewController 会自动恢复导航栏状态
    }
    
    @MainActor
    deinit {
        // 移除 KVO 观察
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        if configuration.useWebTitle {
            webView.removeObserver(self, forKeyPath: "title")
        }
        print("🗑️ WebViewController 已释放")
    }
    
    // MARK: - Setup
    
    override func setupUI() {
        view.backgroundColor = .white
        
        view.addSubviews(webView, progressView, loadingIndicator)
        
        // WebView 布局
        webView.snp.makeConstraints { make in
            if configuration.isFullScreen {
                make.edges.equalToSuperview()
            } else {
                make.top.equalTo(view.safeAreaLayoutGuide)
                make.left.right.bottom.equalToSuperview()
            }
        }

        // 全屏模式禁止安全区域自动内缩，让网页内容真正充满全屏
        if configuration.isFullScreen {
            webView.scrollView.contentInsetAdjustmentBehavior = .never
        }
        
        // 进度条布局
        progressView.snp.makeConstraints { make in
            if configuration.isFullScreen {
                make.top.equalToSuperview()
            } else {
                make.top.equalTo(view.safeAreaLayoutGuide)
            }
            make.left.right.equalToSuperview()
            make.height.equalTo(2)
        }
        
        // 加载指示器布局
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        // 添加 KVO 观察进度
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        // 如果需要使用网页标题，添加 title 观察
        if configuration.useWebTitle {
            webView.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        }
    }
    
    private func setupJSBridge() {
        jsBridge = WebViewJSBridge(webView: webView)
        jsBridge?.delegate = self
    }
    
    private func loadWebPage() {
        if let htmlString = configuration.htmlString, !htmlString.isEmpty {
            // 优先加载 HTML 字符串
            loadingIndicator.startAnimating()
            webView.loadHTMLString(htmlString, baseURL: nil)
            print("🌐 开始加载 HTML 字符串")
            return
        }
        
        guard !configuration.urlString.isEmpty, 
              let url = URL(string: configuration.urlString) else {
            showError("无效的 URL")
            return
        }
        
        loadingIndicator.startAnimating()
        
        // 如果禁用缓存，先清除相关缓存并添加时间戳
        var finalUrl = url
        if !configuration.useCache {
            // 清除 WKWebView 的缓存
            clearWebViewCache()
            // 添加时间戳参数，确保每次请求都是唯一的
            finalUrl = appendTimestamp(to: url)
        }
        
        let request = URLRequest(url: finalUrl, timeoutInterval: 30)
        webView.load(request)
        
        print("🌐 开始加载: \(finalUrl.absoluteString) (缓存: \(configuration.useCache ? "启用" : "禁用"))")
    }
    
    /// 清除 WKWebView 的缓存
    private func clearWebViewCache() {
        let dataStore = WKWebsiteDataStore.default()
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        
        dataStore.removeData(ofTypes: types, modifiedSince: Date.distantPast) {
            print("🗑️ WebView 缓存已清除")
        }
    }
    
    /// 为 URL 添加时间戳参数
    private func appendTimestamp(to url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        
        var queryItems = components.queryItems ?? []
        // 添加或更新时间戳参数
        let timestampItem = URLQueryItem(name: "_t", value: String(Date().timeIntervalSince1970))
        
        // 如果已存在时间戳参数，替换它
        if let index = queryItems.firstIndex(where: { $0.name == "_t" }) {
            queryItems[index] = timestampItem
        } else {
            queryItems.append(timestampItem)
        }
        
        components.queryItems = queryItems
        return components.url ?? url
    }
    
    // MARK: - KVO
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "estimatedProgress" {
            // 更新进度条
            progressView.progress = Float(webView.estimatedProgress)
            
            // 加载完成后隐藏进度条
            if webView.estimatedProgress >= 1.0 {
                UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseOut) {
                    self.progressView.alpha = 0
                } completion: { _ in
                    self.progressView.progress = 0
                    self.progressView.alpha = 1
                }
            }
        } else if keyPath == "title" {
            // 如果没有设置标题且允许使用网页标题，使用网页标题
            if configuration.useWebTitle,
               (configuration.navigationTitle?.isEmpty ?? true),
               let webTitle = webView.title,
               !webTitle.isEmpty {
                title = webTitle
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        if let navigationController = navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    // MARK: - Public Methods
    
    /// 调用 JS 方法
    /// - Parameters:
    ///   - functionName: JS 函数名
    ///   - parameters: 参数
    ///   - completion: 完成回调
    func callJavaScript(
        functionName: String,
        parameters: [String: Any]? = nil,
        completion: ((Result<Any?, Error>) -> Void)? = nil
    ) {
        jsBridge?.callJavaScript(
            functionName: functionName,
            parameters: parameters,
            completion: completion
        )
    }
    
    /// 重新加载页面
    func reload() {
        webView.reload()
    }
    
    /// 返回上一页
    func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    /// 前进到下一页
    func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    // MARK: - Helper
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            if let navigationController = self?.navigationController {
                navigationController.popViewController(animated: true)
            } else {
                self?.dismiss(animated: true)
            }
        })
        present(alert, animated: true)
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingIndicator.startAnimating()
        print("🔄 开始加载页面")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
        print("✅ 页面加载完成")
        onPageLoaded?(self)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.stopAnimating()
        print("❌ 页面加载失败: \(error.localizedDescription)")
    }
    
    /// WebContent XPC 进程被系统强杀时（内存压力或进程超限）自动重载防止白屏
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("⚠️ WebContent XPC 进程已被系统终止，自动重载页面")
        webView.reload()
    }
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let url = navigationAction.request.url {
            print("🔗 即将加载: \(url.absoluteString)")
            
            // 可以在这里拦截特定的 URL scheme
            // 例如：myapp://action
            if let scheme = url.scheme, scheme == "myapp" {
                handleCustomScheme(url: url)
                decisionHandler(.cancel)
                return
            }
        }
        
        decisionHandler(.allow)
    }
    
    /// 处理自定义 URL Scheme
    private func handleCustomScheme(url: URL) {
        print("🔧 处理自定义 Scheme: \(url.absoluteString)")
        // 在这里处理自定义 scheme 的逻辑
    }
}

// MARK: - WKUIDelegate

extension WebViewController: WKUIDelegate {
    
    // 处理 JS 的 alert
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completionHandler()
        })
        present(alert, animated: true)
    }
    
    // 处理 JS 的 confirm
    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
            completionHandler(false)
        })
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completionHandler(true)
        })
        present(alert, animated: true)
    }
    
    // 处理 JS 的 prompt
    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = defaultText
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
            completionHandler(nil)
        })
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        present(alert, animated: true)
    }
}

// MARK: - WebViewJSBridgeDelegate

extension WebViewController: WebViewJSBridgeDelegate {
    
    //打开一个新的web
    func jsCallOpenPage(parameters: [String : Any]?) {
        
        guard let params = parameters, !params.isEmpty else {
            print("⚠️ jsCallUpdateUser: 参数为空，放弃更新")
            return
        }
        
        let  web  = WebViewController(urlString: params["url"] as! String)
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.pushViewController(web, animated: true)
        }
        
    }
    
    
    //H5 回传选择后的活动类型
    func jsCallChooseActivityType(parameters: [String]?) {
        print("🎯 JS 调用了 chooseActivityType 方法")
        print("📦 选中的活动类型: \(parameters ?? [])")

        let types = parameters ?? []
        // 回调给上一个页面（如 PublishViewController）
        onActivityTypesSelected?(types)
        // 标记正在执行活动类型选择返回，防止后续 goBack 重复 pop
        
        // 返回上一页
//        DispatchQueue.main.async { [weak self] in
//            self?.navigationController?.popViewController(animated: true)
//        }
    }
    

    
    
    /// H5 回传编辑后的用户资料
    func jsCallUpdateUser(parameters: [String: Any]?) {
        print("🎯 JS 调用了 UpdateUser 方法")
        print("📦 参数: \(String(describing: parameters))")

        guard let params = parameters, !params.isEmpty else {
            print("⚠️ jsCallUpdateUser: 参数为空，放弃更新")
            return
        }

        // 取各字段（空字符串视为 nil，保留当前值）
        let nickname   = (params["nickname"]   as? String).flatMap { $0.isEmpty ? nil : $0 }
        let avatar     = (params["avatar"]     as? String).flatMap { $0.isEmpty ? nil : $0 }
        let age        = (params["age"]        as? String).flatMap { $0.isEmpty ? nil : $0 }
        let gender     = (params["gender"]     as? String).flatMap { $0.isEmpty ? nil : $0 }
        let city       = (params["city"]       as? String).flatMap { $0.isEmpty ? nil : $0 }
        let bio        = (params["bio"]        as? String).flatMap { $0.isEmpty ? nil : $0 }
        let avatarLocalPath = (params["avatarLocalPath"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let tags       = params["tags"]                as? [String]
        let favoriteActivityTypes = params["favoriteActivityTypes"] as? [String]

        // 基于当前模型做增量更新（保留 token/userId/phone 不变）
        UserManager.shared.updateUserInfo(
            nickname: nickname,
            avatar: avatar,
            age: age,
            gender: gender,
            city: city,
            bio: bio,
            tags: tags,
            favoriteActivityTypes: favoriteActivityTypes,
            avatarLocalPath: avatarLocalPath
        )

        print("✅ 用户资料已更新")

        // 发送通知，通知 MineViewController 刷新展示
        NotificationCenter.default.post(name: .userInfoDidUpdate, object: nil)
    }
    
    /// JS 调用返回方法（用于全屏 H5 页面）
    func jsCallGoBack(parameters: [String: Any]?) {
        print("🎯 JS 调用了 goBack 方法")
        print("📦 参数: \(String(describing: parameters))")
        
        
        // 执行返回操作
        if let navigationController = navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    func jsCallcloseAccount(parameters: [String : Any]?) {
        print("🎯 JS 调用了 closeAccount 方法")

        AccountDeletionAlertView.show(
            onConfirmDeletion: { [weak self] in
                guard let self else { return }
                // 显示注销中 loading
                self.showLoading("注销中...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    guard let self else { return }
                    self.hideLoading()
                    // 清除全部用户数据（内部会发送 .userDidLogout 通知，全局监听跳转登录页）
                    UserManager.shared.deleteAccount()
                }
            },
            onExitAccount: { [weak self] in
                guard self != nil else { return }
                // 仅退出登录，保留用户数据
                UserManager.shared.logout()
            }
        )
    }

    func jsCallgoMainPage(parameters: [String : Any]?) {
        print("🎯 JS 调用了 goMainPage 方法")
        // 已注册 -> 直接登录成功，跳转首页
        NotificationCenter.default.post(name: .userDidLogin, object: nil)
        
    }

    /// JS 调用选择头像：弹出原生图片选择器，选完后将 base64 回传给 JS
    func jsCallChooseAvatar(parameters: [String: Any]?) {
        print("🎯 JS 调用了 chooseAvatar 方法")

        var pickerConfig = PhotoPickerConfig()
        pickerConfig.showsCrop = true
        pickerConfig.cropType = .rectangle(ratio: 1.0)
        pickerConfig.singlePhoto = true

        PhotoPicker.show(from: self, config: pickerConfig) { [weak self] image in
            guard let self = self else { return }

            // 1. 保存到本地，更新 UserManager
            if let localPath = image.saveToLocal() {
                UserManager.shared.avatarLocalPath = localPath
            }

            // 2. 转 Base64（web 可直接用作 img src 或上传服务器）
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("❌ 图片转 JPEG 数据失败")
                return
            }
            let base64String = imageData.base64EncodedString()
            let localPath = UserManager.shared.avatarLocalPath ?? ""

            // 3. 回传给 JS：onAvatarSelected({ base64, mimeType, localPath })
            self.callJavaScript(
                functionName: "onAvatarSelected",
                parameters: [
                    "base64": base64String,
                    "mimeType": "image/jpeg",
                    "localPath": localPath
                ]
            ) { result in
                switch result {
                case .success:
                    print("✅ onAvatarSelected 调用成功")
                case .failure(let error):
                    print("❌ onAvatarSelected 调用失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    // 可以继续添加更多 JS 调用的方法实现
    // func jsCallTest2(parameters: [String: Any]?) {
    //     print("🎯 JS 调用了 test2 方法")
    // }
}
