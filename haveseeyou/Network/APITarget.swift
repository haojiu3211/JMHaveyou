//
//  APITarget.swift
//  haveseeyou
//
//  接口目标协议：每个接口实现该协议即可配置路径/参数/方法
//

import Foundation
import Alamofire

protocol APITarget {
    /// baseURL，通常使用全局默认值
    var baseURL: String { get }
    /// 请求路径
    var path: String { get }
    /// 请求方法
    var method: HTTPMethod { get }
    /// 请求参数
    var parameters: [String: Any]? { get }
    /// 参数编码
    var encoding: ParameterEncoding { get }
    /// 附加 Header
    var headers: HTTPHeaders? { get }
    /// 超时时间（秒）
    var timeout: TimeInterval { get }
}

extension APITarget {
    var baseURL: String { AppConfig.API.baseURL }
    var encoding: ParameterEncoding {
        method == .get ? URLEncoding.default : JSONEncoding.default
    }
    var headers: HTTPHeaders? { nil }
    var timeout: TimeInterval { 15 }

    /// 完整 URL
    var fullURL: String {
        if path.hasPrefix("http") { return path }
        return baseURL + path
    }
}

