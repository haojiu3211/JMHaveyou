//
//  WebViewJSBridge.swift
//  haveseeyou
//
//  WebView 与 JavaScript 交互桥接器
//  负责处理原生和 JS 之间的方法调用
//

import Foundation
import WebKit

/// JS 调用原生方法的协议
protocol WebViewJSBridgeDelegate: AnyObject {
    
    /// JS 调用返回方法
    func jsCallGoBack(parameters: [String: Any]?)
    
    func jsCallUpdateUser(parameters: [String: Any]?)
    
    func jsCallgoMainPage(parameters: [String: Any]?)
    
    func jsCallcloseAccount(parameters: [String: Any]?)

    /// JS 调用选择头像（原生弹出图片选择器，选完后回传 base64）
    func jsCallChooseAvatar(parameters: [String: Any]?)
    
    func jsCallChooseActivityType(parameters: [String]?)
    
    func jsCallOpenPage(parameters: [String: Any]?)
    
    // 可以继续添加更多 JS 调用的方法
    // func jsCallTest2(parameters: [String: Any]?)
}

/// WKUserContentController 对 add(self, name:) 的 handler 持有强引用，
/// 用弱引用代理包装打破 WebViewJSBridge 的隐性保留环
private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var handler: WKScriptMessageHandler?
    init(_ handler: WKScriptMessageHandler) { self.handler = handler }
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        handler?.userContentController(userContentController, didReceive: message)
    }
}

/// WebView JS 桥接管理器
final class WebViewJSBridge: NSObject {
    
    // MARK: - Properties
    
    weak var delegate: WebViewJSBridgeDelegate?
    private weak var webView: WKWebView?
    
    // MARK: - 初始化
    
    init(webView: WKWebView) {
        self.webView = webView
        super.init()
        setupMessageHandlers()
    }
    
    deinit {
        removeMessageHandlers()
    }
    
    // MARK: - Setup
    
    /// 设置消息处理器（使用弱引用包装，防止 userContentController 强持有 self）
    private func setupMessageHandlers() {
        guard let webView = webView else { return }
        
        let userContentController = webView.configuration.userContentController
        let weakHandler = WeakScriptMessageHandler(self)
        
        // 注册 JS 调用的方法名（通过弱引用代理，打破强持有循环）
        userContentController.add(weakHandler, name: "updateUser")
        userContentController.add(weakHandler, name: "goBack")
        userContentController.add(weakHandler, name: "goMainPage")
        userContentController.add(weakHandler, name: "closeAccount")
        userContentController.add(weakHandler, name: "chooseAvatar")
        userContentController.add(weakHandler, name: "chooseActivityType")
        userContentController.add(weakHandler, name: "openPage")
        
        
        // 可以继续注册更多方法
        // userContentController.add(self, name: "test2")
        
        print("✅ WebView JS Bridge 已初始化")
    }
    
    /// 移除消息处理器
    private func removeMessageHandlers() {
        guard let webView = webView else { return }
        
        let userContentController = webView.configuration.userContentController
        userContentController.removeScriptMessageHandler(forName: "updateUser")
        userContentController.removeScriptMessageHandler(forName: "goBack")
        userContentController.removeScriptMessageHandler(forName: "goMainPage")
        userContentController.removeScriptMessageHandler(forName: "closeAccount")
        userContentController.removeScriptMessageHandler(forName: "chooseAvatar")
        userContentController.removeScriptMessageHandler(forName: "chooseActivityType")
        userContentController.removeScriptMessageHandler(forName: "openPage")
        
        
        
        print("🗑️ WebView JS Bridge 已清理")
    }
    
    // MARK: - 原生调用 JS 方法
    
    /// 调用 JS 方法
    /// - Parameters:
    ///   - functionName: JS 函数名
    ///   - parameters: 参数（可选）
    ///   - completion: 完成回调，返回结果或错误
    func callJavaScript(
        functionName: String,
        parameters: [String: Any]? = nil,
        completion: ((Result<Any?, Error>) -> Void)? = nil
    ) {
        guard let webView = webView else {
            completion?(.failure(JSBridgeError.webViewNotAvailable))
            return
        }
        
        // 构建 JS 调用脚本
        var script = "\(functionName)("
        
        if let parameters = parameters {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    script += jsonString
                }
            } catch {
                completion?(.failure(error))
                return
            }
        }
        
        script += ")"
        
        print("📤 原生调用 JS: \(script)")
        
        // 执行 JS 脚本
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ JS 调用失败: \(error.localizedDescription)")
                completion?(.failure(error))
            } else {
                print("✅ JS 调用成功，返回: \(String(describing: result))")
                completion?(.success(result))
            }
        }
    }
    
    /// 便捷方法：调用无参数的 JS 方法
    func callJavaScript(functionName: String, completion: ((Result<Any?, Error>) -> Void)? = nil) {
        callJavaScript(functionName: functionName, parameters: nil, completion: completion)
    }
    
    // MARK: - 示例方法
    
    /// 示例：调用 JS 的 test 方法
    func callJSTest(message: String, completion: ((Result<Any?, Error>) -> Void)? = nil) {
        let parameters: [String: Any] = ["message": message]
        callJavaScript(functionName: "test", parameters: parameters, completion: completion)
    }
}

// MARK: - WKScriptMessageHandler

extension WebViewJSBridge: WKScriptMessageHandler {
    
    /// 接收来自 JS 的消息
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        print("📥 收到 JS 消息: \(message.name)")
        print("📦 消息内容: \(message.body)")
        
        // 解析参数 - 通用转换，支持字典/JSON字符串/数组等多种格式
        var parameters: [String: Any]?
        if let body = message.body as? [String: Any] {
            // JS 直接传入对象，本身就是字典
            parameters = body
        } else if let bodyString = message.body as? String {
            // JS 传入 JSON 字符串，尝试解析为字典
            parameters = WebViewJSBridge.parseJSONStringToDict(bodyString)
        }
        
        // 根据消息名称分发到对应的处理方法
        switch message.name {
        case "updateUser":
            delegate?.jsCallUpdateUser(parameters: parameters)
            
        case "goBack":
            delegate?.jsCallGoBack(parameters: parameters)
            
        case "goMainPage":
            delegate?.jsCallgoMainPage(parameters: parameters)
            
        case "closeAccount":
            delegate?.jsCallcloseAccount(parameters: parameters)

        case "chooseAvatar":
            delegate?.jsCallChooseAvatar(parameters: parameters)
            
        case "chooseActivityType":
            delegate?.jsCallChooseActivityType(parameters: message.body as? [String])
            
        case "openPage":
            delegate?.jsCallOpenPage(parameters: parameters)
            
        // 可以继续添加更多方法
        // case "test2":
        //     delegate?.jsCallTest2(parameters: parameters)
            
        default:
            print("⚠️ 未处理的 JS 消息: \(message.name)")
        }
    }
}

// MARK: - 通用参数解析工具

extension WebViewJSBridge {

    /// 将 JS 传入的参数统一转换为 [String: Any] 字典
    ///
    /// 支持的输入格式：
    /// 1. 已经是 [String: Any] → 直接返回
    /// 2. JSON 字符串 → 解析为字典
    /// 3. 其他类型 → 返回 nil
    ///
    /// - Parameter body: JS message.body 原始值
    /// - Returns: 转换后的字典，失败返回 nil
    static func parseParameters(_ body: Any?) -> [String: Any]? {
        guard let body = body else { return nil }

        // 1. 已经是字典，直接返回
        if let dict = body as? [String: Any] {
            return dict
        }

        // 2. JSON 字符串，尝试解析
        if let jsonString = body as? String {
            return parseJSONStringToDict(jsonString)
        }

        // 3. 其他类型无法转为字典
        print("⚠️ JS 参数无法解析为字典: \(type(of: body))")
        return nil
    }

    /// 将 JSON 字符串解析为 [String: Any] 字典
    ///
    /// - Parameter jsonString: JSON 格式的字符串
    /// - Returns: 解析成功返回字典，失败返回 nil
    static func parseJSONStringToDict(_ jsonString: String) -> [String: Any]? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return parseJSONDataToDict(data)
    }

    /// 将 JSON Data 解析为 [String: Any] 字典
    ///
    /// - Parameter data: JSON 格式的 Data
    /// - Returns: 解析成功返回字典，失败返回 nil
    static func parseJSONDataToDict(_ data: Data) -> [String: Any]? {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.mutableContainers, .allowFragments])
            if let dict = jsonObject as? [String: Any] {
                return dict
            } else {
                print("⚠️ JSON 解析成功但不是字典格式: \(type(of: jsonObject))")
                return nil
            }
        } catch {
            print("❌ JSON 字符串解析失败: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Error

enum JSBridgeError: LocalizedError {
    case webViewNotAvailable
    case invalidParameters
    
    var errorDescription: String? {
        switch self {
        case .webViewNotAvailable:
            return "WebView 不可用"
        case .invalidParameters:
            return "参数无效"
        }
    }
}
