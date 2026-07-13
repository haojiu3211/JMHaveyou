//
//  APIResponse.swift
//  haveseeyou
//
//  通用响应数据结构，与后端约定字段可按需调整
//

import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let code: Int
    let message: String?
    let time: String?
    let data: T?

    var isSuccess: Bool { code == 0 || code == 200 }
}
