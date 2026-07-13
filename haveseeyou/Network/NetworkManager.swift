//
//  NetworkManager.swift
//  haveseeyou
//
//  基于 Alamofire + Combine 的全局网络请求框架
//  支持 GET / POST，自动装配 baseURL、headers、超时；
//  统一处理业务 code、错误映射、JSON 解析。
//

import Foundation
import Combine
import Alamofire

final class NetworkManager {

    static let shared = NetworkManager()

    /// 自定义 Session：超时 / 日志拦截等
    private let session: Session

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        session = Session(configuration: config,
                          interceptor: nil,
                          eventMonitors: [NetworkLogger()])
    }

    // MARK: - 基于 APITarget 的请求

    /// 通用请求 - 返回 Publisher
    func request<T: Decodable>(_ target: APITarget,
                               as type: T.Type) -> AnyPublisher<T, APIError> {
        let url = target.fullURL
        guard URL(string: url) != nil else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }

        // 合并 header
        var headers = AppConfig.API.commonHeaders
        target.headers?.forEach { headers.add($0) }

        let publisher = PassthroughSubject<T, APIError>()

        session.request(url,
                        method: target.method,
                        parameters: target.parameters,
                        encoding: target.encoding,
                        headers: headers) { req in
            req.timeoutInterval = target.timeout
        }
        .validate(statusCode: 200..<300)
        .responseData { response in
            switch response.result {
            case .success(let data):
                NetworkManager.handle(data: data, type: type, publisher: publisher)
            case .failure(let err):
                if let status = response.response?.statusCode, !(200..<300).contains(status) {
                    publisher.send(completion: .failure(.httpStatus(code: status, message: err.localizedDescription)))
                } else {
                    publisher.send(completion: .failure(.underlying(err)))
                }
            }
        }

        return publisher.eraseToAnyPublisher()
    }

    // MARK: - 快捷方法

    /// GET 请求
    @discardableResult
    func get<T: Decodable>(_ path: String,
                           parameters: [String: Any]? = nil,
                           headers: HTTPHeaders? = nil,
                           as type: T.Type) -> AnyPublisher<T, APIError> {
        let target = GenericTarget(path: path,
                                   method: .get,
                                   parameters: parameters,
                                   extraHeaders: headers)
        return request(target, as: type)
    }

    /// POST 请求
    @discardableResult
    func post<T: Decodable>(_ path: String,
                            parameters: [String: Any]? = nil,
                            headers: HTTPHeaders? = nil,
                            as type: T.Type) -> AnyPublisher<T, APIError> {
        let target = GenericTarget(path: path,
                                   method: .post,
                                   parameters: parameters,
                                   extraHeaders: headers)
        return request(target, as: type)
    }
    
    /// 传统方式请求 - 使用 completion 回调
    @discardableResult
    func request<T: Decodable>(_ target: APITarget,
                               as type: T.Type,
                               completion: @escaping (Result<T, APIError>) -> Void) -> DataRequest? {
        let url = target.fullURL
        guard URL(string: url) != nil else {
            completion(.failure(.invalidURL))
            return nil
        }
        
        var headers = AppConfig.API.commonHeaders
        target.headers?.forEach { headers.add($0) }
        
        return session.request(url,
                              method: target.method,
                              parameters: target.parameters,
                              encoding: target.encoding,
                              headers: headers) { req in
            req.timeoutInterval = target.timeout
        }
        .validate(statusCode: 200..<300)
        .responseData { response in
            switch response.result {
            case .success(let data):
                NetworkManager.handleTraditionally(data: data, type: type, completion: completion)
            case .failure(let err):
                if let status = response.response?.statusCode, !(200..<300).contains(status) {
                    completion(.failure(.httpStatus(code: status, message: err.localizedDescription)))
                } else {
                    completion(.failure(.underlying(err)))
                }
            }
        }
    }

    // MARK: - 私有解析

    private static func handle<T: Decodable>(data: Data,
                                             type: T.Type,
                                             publisher: PassthroughSubject<T, APIError>) {
        guard !data.isEmpty else {
            publisher.send(completion: .failure(.emptyResponse))
            return
        }

        // 生产环境：若响应顶层是 JSON 字符串则视为加密数据，先解密再解析
        let payload: Data
        switch decryptIfNeeded(data) {
        case .success(let decoded):
            payload = decoded
        case .failure(let err):
            publisher.send(completion: .failure(err))
            return
        }

        do {
            // 首先打印完整的原始JSON数据，确保所有接口都能看到
            #if DEBUG
            if let jsonString = String(data: payload, encoding: .utf8) {
                print("📄 完整原始响应: \(jsonString)")
            }
            #endif
            
            // 先按照统一包裹结构解析
            let decoder = JSONDecoder()
            if let wrapped = try? decoder.decode(APIResponse<T>.self, from: payload) {
                #if DEBUG
                print("📦 [Parse] 成功解析为 APIResponse")
                print("  ├─ code: \(wrapped.code)")
                print("  ├─ message: \(wrapped.message ?? "nil")")
                print("  ├─ data: \(wrapped.data != nil ? "存在" : "nil")")
                #endif
                
                if wrapped.isSuccess, let data = wrapped.data {
                    #if DEBUG
                    print("✅ [Parse] 业务成功，发送数据")
                    #endif
                    publisher.send(data)
                    publisher.send(completion: .finished)
                    return
                }
                if wrapped.isSuccess, wrapped.data == nil {
                    if let empty = EmptyData() as? T {
                        publisher.send(empty)
                        publisher.send(completion: .finished)
                        return
                    }
                }
                
                if wrapped.code == 1001 {
                    DispatchQueue.main.async {
//                        AppAlert.showSingle(title: "登录过期", message: "您的登录已过期，请重新登录")
                        UserManager.shared.logout()
                    }
                }
                
                publisher.send(completion: .failure(
                    .business(code: wrapped.code, message: wrapped.message ?? "业务错误")
                ))
                return
            }
            // 没有包裹结构，直接解析
            #if DEBUG
            print("📦 [Parse] 尝试直接解析")
            #endif
            let value = try decoder.decode(T.self, from: payload)
            publisher.send(value)
            publisher.send(completion: .finished)
        } catch {
            #if DEBUG
            print("❌ [Parse] 解析失败: \(error.localizedDescription)")
            print("  └─ 原始数据前 200 字符: \(String(data: payload.prefix(200), encoding: .utf8) ?? "无法转换")")
            #endif
            publisher.send(completion: .failure(.decoding(error)))
        }
    }
    
    // MARK: - 传统方式解析
    
    private static func handleTraditionally<T: Decodable>(data: Data,
                                                         type: T.Type,
                                                         completion: @escaping (Result<T, APIError>) -> Void) {
        guard !data.isEmpty else {
            completion(.failure(.emptyResponse))
            return
        }
        
        let payload: Data
        switch decryptIfNeeded(data) {
        case .success(let decoded):
            payload = decoded
        case .failure(let err):
            completion(.failure(err))
            return
        }
        
        do {
            #if DEBUG
            if let jsonString = String(data: payload, encoding: .utf8) {
                print("📄 完整原始响应: \(jsonString)")
            }
            #endif
            
            let decoder = JSONDecoder()
            if let wrapped = try? decoder.decode(APIResponse<T>.self, from: payload) {
                #if DEBUG
                print("📦 [Parse] 成功解析为 APIResponse")
                print("  ├─ code: \(wrapped.code)")
                print("  ├─ message: \(wrapped.message ?? "nil")")
                print("  ├─ data: \(wrapped.data != nil ? "存在" : "nil")")
                #endif
                
                if wrapped.isSuccess, let data = wrapped.data {
                    #if DEBUG
                    print("✅ [Parse] 业务成功")
                    #endif
                    completion(.success(data))
                    return
                }
                if wrapped.isSuccess, wrapped.data == nil {
                    if let empty = EmptyData() as? T {
                        completion(.success(empty))
                        return
                    }
                }
                
                if wrapped.code == 1001 {
                    DispatchQueue.main.async {
//                        AppAlert.showSingle(title: "登录过期", message: "您的登录已过期，请重新登录")
                        UserManager.shared.logout()
                    }
                }
                
                completion(.failure(.business(code: wrapped.code, message: wrapped.message ?? "业务错误")))
                return
            }
            
            #if DEBUG
            print("📦 [Parse] 尝试直接解析")
            #endif
            let value = try decoder.decode(T.self, from: payload)
            completion(.success(value))
        } catch {
            #if DEBUG
            print("❌ [Parse] 解析失败: \(error.localizedDescription)")
            print("  └─ 原始数据前 200 字符: \(String(data: payload.prefix(200), encoding: .utf8) ?? "无法转换")")
            #endif
            completion(.failure(.decoding(error)))
        }
    }

    // MARK: - 响应解密

    /// 如果响应 body 不是 JSON 对象/数组（是加密字符串），则解密并返回明文 Data。
    /// 兼容两种后端返回格式：
    ///   1. 带引号的 JSON 字符串："R1Jn...=="
    ///   2. 裸 base64 字符串：R1Jn...==
    private static func decryptIfNeeded(_ data: Data) -> Result<Data, APIError> {
        var cipherText: String? = nil

        // 尝试判断响应顶层是否为 JSON 字符串或对象
        if let topLevel = try? JSONSerialization.jsonObject(
            with: data,
            options: [.allowFragments]
        ) {
            if let str = topLevel as? String {
                // 情况 1：body = "..."（JSON 字符串字面量）
                cipherText = str
            } else {
                // 已是 JSON 对象/数组，无需解密
                #if DEBUG
                print("🔓 [Decrypt] 响应为 JSON 对象，跳过解密")
                #endif
                return .success(data)
            }
        } else if let raw = String(data: data, encoding: .utf8) {
            // 情况 2：body 不是合法 JSON，当作裸 base64 字符串处理
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                cipherText = trimmed
            }
        }

        guard let text = cipherText, !text.isEmpty else {
            #if DEBUG
            print("⚠️ [Decrypt] 未检测到加密字符串，使用原始数据")
            #endif
            return .success(data)
        }

        #if DEBUG
        print("🔐 [Decrypt] 检测到加密响应，长度=\(text.count)，前 80字: \(text.prefix(80))")
        #endif

        guard let plain = AESUtil.aes128Decrypt(text),
              !plain.isEmpty,
              let plainData = plain.data(using: .utf8) else {
            #if DEBUG
            print("❌ [Decrypt] AES 解密失败")
            #endif
            return .failure(.decoding(NSError(
                domain: "AESDecryptError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "响应解密失败"]
            )))
        }

        #if DEBUG
        print("🔓 [Decrypt] 解密成功，明文长度=\(plain.count)")
        print("  └─ 完整明文: \(plain)")
        #endif

        return .success(plainData)
    }
}

// MARK: - 通用 Target

private struct GenericTarget: APITarget {
    let path: String
    let method: HTTPMethod
    let parameters: [String: Any]?
    let extraHeaders: HTTPHeaders?
    var headers: HTTPHeaders? { extraHeaders }
}

/// 无返回数据占位
struct EmptyData: Decodable {}

// MARK: - 请求日志

final class NetworkLogger: EventMonitor {
    let queue = DispatchQueue(label: "com.haveseeyou.network.logger")

    /// URLRequest 创建完成时打印（此时机确保 URL / Headers / Body 都已就绪）
    func request(_ request: Request, didCreateInitialURLRequest urlRequest: URLRequest) {
        #if DEBUG
        let method = urlRequest.httpMethod ?? ""
        let url = urlRequest.url?.absoluteString ?? ""
        print("\n🚀 [REQ] \(method) \(url)")

        // 打印请求头
        if let allHeaders = urlRequest.allHTTPHeaderFields, !allHeaders.isEmpty {
            print("   Headers: ")
            for (key, value) in allHeaders.sorted(by: { $0.key < $1.key }) {
                print("     \(key): \(value)")
            }
        }

        // 打印请求参数（POST body）
        if let body = urlRequest.httpBody,
           let str = String(data: body, encoding: .utf8), !str.isEmpty {
            print("   Body: \(str)")
        }

        // GET 请求参数拼在 URL query 里，直接打印完整 URL 即可
        if method == "GET", let query = urlRequest.url?.query, !query.isEmpty {
            print("   Query: \(query)")
        }
        #endif
    }

    func request(_ request: DataRequest, didParseResponse response: DataResponse<Data?, AFError>) {
        #if DEBUG
        let code = response.response?.statusCode ?? -1
        let url = request.request?.url?.absoluteString ?? ""

        switch response.result {
        case .success(let data):
            print("✅ [RES \(code)] \(url)")
            if let data = data, let str = String(data: data, encoding: .utf8) {
                print("   \(str)")
            }
        case .failure(let error):
            print("❌ [RES \(code)] \(url)")
            print("   Error: \(error.localizedDescription)")
            if let data = response.data, let str = String(data: data, encoding: .utf8), !str.isEmpty {
                print("   Body: \(str)")
            }
        }
        #endif
    }

    /// 网络层失败（如离线 -1009、DNS 解析失败等，未到达服务器）
    func request(_ request: Request, didFailTask task: URLSessionTask, withError error: AFError) {
        #if DEBUG
        let url = request.request?.url?.absoluteString ?? ""
        print("❌ [RES NetworkError] \(url)")
        print("   Error: \(error.localizedDescription)")
        #endif
    }
}
