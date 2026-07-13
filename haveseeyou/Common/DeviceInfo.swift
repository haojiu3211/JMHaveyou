//
//  DeviceInfo.swift
//  haveseeyou
//
//  设备与应用信息工具类
//  提供请求头所需的 uuid、channel、package-name、version、ver-code、source-id、oaid 等
//

import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency


let kScreenWidth = UIScreen.main.bounds.width






enum DeviceInfo {

    // MARK: - UUID（设备唯一标识）

    private static let uuidKey = "device_uuid"

    /// 设备唯一标识，首次生成后持久化到 UserDefaults
    static var uuid: String {
        if let stored = UserDefaults.standard.string(forKey: uuidKey), !stored.isEmpty {
            return stored
        }
        let newUUID: String
        if let vendor = UIDevice.current.identifierForVendor?.uuidString {
            newUUID = vendor
        } else {
            newUUID = UUID().uuidString
        }
        UserDefaults.standard.set(newUUID, forKey: uuidKey)
        UserDefaults.standard.synchronize()
        return newUUID
    }

    // MARK: - 渠道

    private static let channelKey = "app_channel"

    /// 应用分发渠道（默认 AppStore，可通过 setChannel 修改）
    static var channel: String {
//        if let stored = UserDefaults.standard.string(forKey: channelKey), !stored.isEmpty {
//            return stored
//        }
        return "650"
    }

    /// 设置渠道（可在初始化接口返回后调用）
    static func setChannel(_ value: String) {
        UserDefaults.standard.set(value, forKey: channelKey)
        UserDefaults.standard.synchronize()
    }

    // MARK: - 包名

    /// 应用包名（Bundle Identifier）
    static var packageName: String {
        "com.makeFriends.jianlema"
//        Bundle.main.bundleIdentifier ?? "com.yuanyu.chase" com.makeFriends.jianlema
    }

    // MARK: - 版本号

    /// 应用版本号（如 1.0.0）
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    // MARK: - 版本编码

    /// 应用构建版本号（如 1）
    static var verCode: String {
        "100"
//        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "100"
    }

    // MARK: - Source ID


    /// 来源 ID（默认空，可通过 setSourceId 修改）
    static var sourceId: String {
        return "2"
    }

    // MARK: - OAID

    private static let oaidKey = "device_oaid"

    /// OAID（开放匿名设备标识符）
    /// 注意：真实 OAID 需集成移动安全联盟 SDK 获取，此处提供存储和默认值
    static var oaid: String {
        if let stored = UserDefaults.standard.string(forKey: oaidKey), !stored.isEmpty {
            return stored
        }
        return ""
    }

    /// 设置 OAID（在 SDK 获取到真实值后调用）
    static func setOAID(_ value: String) {
        UserDefaults.standard.set(value, forKey: oaidKey)
        UserDefaults.standard.synchronize()
    }

    // MARK: - IDFA

    private static let idfaKey = "device_idfa"
    private static let trackingAuthorizedKey = "tracking_authorized"

    /// IDFA（广告标识符）
    /// 注意：需要用户授权后才能获取，未授权时返回空字符串
    /// 同时需要在 Info.plist 中添加 NSUserTrackingUsageDescription 权限说明
    static var idfa: String {
        if let stored = UserDefaults.standard.string(forKey: idfaKey), !stored.isEmpty {
            return stored
        }
        let idfaValue: String
        if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
            idfaValue = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        } else {
            idfaValue = ""
        }
        UserDefaults.standard.set(idfaValue, forKey: idfaKey)
        UserDefaults.standard.synchronize()
        return idfaValue
    }

    /// 设置 IDFA（在用户授权后调用更新）
    static func setIDFA(_ value: String) {
        UserDefaults.standard.set(value, forKey: idfaKey)
        UserDefaults.standard.synchronize()
    }

    /// 请求用户授权追踪（显示系统弹窗）
    /// - Parameter completion: 授权结果回调
    static func requestTrackingAuthorization(completion: ((Bool) -> Void)? = nil) {
        #if !targetEnvironment(simulator)
        let alreadyRequested = UserDefaults.standard.bool(forKey: trackingAuthorizedKey)
        print("🔍 requestTrackingAuthorization - alreadyRequested: \(alreadyRequested), current idfa: \(idfa.isEmpty ? "empty" : idfa.prefix(8) + "...")")
        
        guard !alreadyRequested else {
            print("🔍 已请求过授权，跳过")
            completion?(idfa.isEmpty == false)
            return
        }

        let currentStatus = ATTrackingManager.trackingAuthorizationStatus
        print("🔍 当前授权状态: \(currentStatus.rawValue) (\(statusDescription(currentStatus)))")
        
        guard currentStatus == .notDetermined else {
            UserDefaults.standard.set(true, forKey: trackingAuthorizedKey)
            UserDefaults.standard.synchronize()
            if currentStatus == .authorized {
                let newIdfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                setIDFA(newIdfa)
            }
            completion?(currentStatus == .authorized)
            return
        }

        // 注意：不要再用 ASIdentifierManager.isAdvertisingTrackingEnabled 来判断系统全局
        // “允许 App 请求追踪”开关 —— 那是 iOS 14 之前的 API，在 iOS 14+ 上恒为 false，
        // 会让本方法永远走不到 ATT 弹窗。系统全局关闭时 ATT 内部会自动静默返回 .denied，
        // 不需要也无法可靠地提前判断。
        print("🔍 调用 ATTrackingManager.requestTrackingAuthorization...")
        ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
            print("🔍 授权结果: \(status.rawValue) (\(statusDescription(status)))")
            if status == .authorized {
                let newIdfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                print("🔍 获取到 IDFA: \(newIdfa.prefix(8))...")
                setIDFA(newIdfa)
            }
            // 仅在 ATT 真的拿到用户终态时才置位，避免系统开关关闭时把“已请求”写死、
            // 导致用户回去打开开关后本 App 再也不弹窗。
            if status != .notDetermined {
                UserDefaults.standard.set(true, forKey: trackingAuthorizedKey)
                UserDefaults.standard.synchronize()
            }
            completion?(status == .authorized)
        })
        #else
        let simulatedIdfa = UIDevice.current.identifierForVendor?.uuidString ?? ""
        setIDFA(simulatedIdfa)
        completion?(true)
        #endif
    }

    private static func statusDescription(_ status: ATTrackingManager.AuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorized: return "authorized"
        @unknown default: return "unknown"
        }
    }
    
    // MARK: - IDFV

    private static let idfvKey = "device_idfv"

    /// IDFV（供应商标识符）
    /// 同一开发者的所有应用在同一设备上共享同一个 IDFV
    /// 不需要用户授权，可直接获取
    static var idfv: String {
        if let stored = UserDefaults.standard.string(forKey: idfvKey), !stored.isEmpty {
            return stored
        }
        let idfvValue = UIDevice.current.identifierForVendor?.uuidString ?? ""
        UserDefaults.standard.set(idfvValue, forKey: idfvKey)
        UserDefaults.standard.synchronize()
        return idfvValue
    }
    

    static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
