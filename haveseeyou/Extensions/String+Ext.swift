//
//  string+ext.swift
//  haveseeyou
//
//  Created by admin on 2026/5/21.
//

import Foundation


extension String {
    /// 是否为空（自动去掉首尾空格和换行）
    var isBlank: Bool {
        trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
    }
    /// 根据 yyyy-MM-dd 格式计算年龄
    var age: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let birthDate = formatter.date(from: self) else {
            return "20"
        }

        let age = Calendar.current
            .dateComponents([.year], from: birthDate, to: Date())
            .year ?? 0
        return "\(age)"
    }
}

extension Optional where Wrapped == String {
    /// 可选字符串是否为空（nil 或空字符串都返回 true）
    var isBlank: Bool {
        self?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
    }
}


