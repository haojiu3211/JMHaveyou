//
//  APIError.swift
//  haveseeyou
//
//  网络层错误定义
//

import Foundation

enum APIError: Error, LocalizedError {
    /// 无网络或底层错误
    case underlying(Error)
    /// HTTP 状态码非 2xx
    case httpStatus(code: Int, message: String?)
    /// 业务错误（后端 code != 0）
    case business(code: Int, message: String)
    /// 解析失败
    case decoding(Error)
    /// 响应为空
    case emptyResponse
    /// 无效 URL
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .underlying(let err):
            return err.localizedDescription
        case .httpStatus(let code, let message):
            return message ?? "HTTP 错误 (\(code))"
        case .business(_, let message):
            return message
        case .decoding:
            return "数据解析失败"
        case .emptyResponse:
            return "响应数据为空"
        case .invalidURL:
            return "无效的请求地址"
        }
    }
}
