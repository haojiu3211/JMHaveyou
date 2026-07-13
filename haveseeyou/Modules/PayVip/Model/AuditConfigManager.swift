//
//  AuditConfigManager.swift
//  haveseeyou
//
//  审核配置管理器 - 处理审核时的 UI 变化
//

import Foundation

extension Notification.Name {
    static let auditConfigDidChange = Notification.Name("AuditConfigDidChange")
}

class AuditConfigManager {
    
    static let shared = AuditConfigManager()
    
    private var _isAudit: Bool = false
    
    private init() {}
    
    /// 获取是否处于审核模式
    var isAudit: Bool {
        return _isAudit
    }
    
    /// 保存审核状态到内存
    func saveAuditStatus(_ versionStatus: String) {
        let oldValue = _isAudit
        _isAudit = (versionStatus == "audit")
        print("🔍 [AuditConfig] 保存审核状态: \(_isAudit), versionStatus: \(versionStatus)")
        
        // 如果状态变化，发送通知
        if oldValue != _isAudit {
            NotificationCenter.default.post(name: .auditConfigDidChange, object: nil)
        }
    }
    
    /// 从服务器获取审核配置
    func fetchAuditConfig(completion: ((Bool) -> Void)? = nil) {
        NetworkManager.shared.request(PurchaseAPI.auditConfig, as: AuditConfigResponse.self) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                if let versionStatus = response.versionStatus {
                    self.saveAuditStatus(versionStatus)
                    completion?(true)
                } else {
                    print("⚠️ [AuditConfig] 审核配置响应数据为空")
                    completion?(false)
                }
            case .failure(let error):
                print("❌ [AuditConfig] 获取审核配置失败: \(error)")
                completion?(false)
            }
        }
    }
}
