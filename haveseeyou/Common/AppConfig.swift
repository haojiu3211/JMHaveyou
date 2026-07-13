//
//  AppConfig.swift
//  haveseeyou
//
//  全局应用配置入口
//  集中管理环境变量、第三方 Key、接口地址、应用常量等
//  使用方式：AppConfig.Environment.current / AppConfig.API.baseURL 等
//

import Foundation
import Alamofire


let privateKey = "R1JnaHVwT2ROMlVweUhobw=="

/// AES 密钥（原始 16 字节字符串）
let aesKey = "LTeMFNXEfwzKPzrr"

// MARK: - 全局配置入口

enum AppConfig {

    // MARK: - 当前环境（切换环境只需改这一行）

    /// ⚠️ 切换环境时修改此值即可，所有 URL / Key 自动适配
    static var current: AppEnvironment = .test

    // MARK: - 应用常量（App Constant）

    enum App {
        /// 应用名称
        static let appName = "haveseeyou"
        /// 应用包名（Bundle Identifier）
        static let packageName = "com.makeFriends.jianlema"//com.yuanyu.chase
        /// 是否开启日志（DEBUG 模式自动开启）
        static var isOpenLog: Bool {
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
        /// 分页加载条数
        static let limitPage = 16
    }

    // MARK: - 第三方 Key（Third-party Keys）

    enum ThirdKey {
        /// 友盟 AppKey（需在 AppDelegate 中初始化）
        static let umAppKey = ""

        /// 云信 AppKey
        static let nimAppKey = "fd539d4a6ea966c6e8cc7787932df73d"
        
        /// 易盾产品 ID
        static let ydProductID = ""
        /// 易盾 - 一键登录易盾 注册登录检测业务 ID
        static let ydLoginBusinessID = "c4eb5260562443ffa772b0cc805b0a26"

        /// 推送证书名（APNs）
        static var apnsName: String {
            switch AppConfig.current {
            case .dev, .test:
                return "push12"
            case .prod:
                return "makeFriendsPush"
            }
        }

        /// IM 环境标识
        static var imEnv: String = ""

        /// 微信 AppID
        static let wxAppID = ""
        /// 微信 AppSecret
        static let wxAppSecret = ""

        /// 高德地图 iOS Key
        static let gdMapIOSKey = ""
        /// 高德地图 Web iOS Key
        static let gdMapWebIOSKey = ""
    }

    // MARK: - 接口地址配置（API Config）

    enum API {
        /// 接口地址前缀（根据当前环境自动选择）
        static var baseURL: String {
            switch current {
            case .dev:  return devBaseURL
            case .test: return testBaseURL
            case .prod: return prodBaseURL
            }
        }

        /// 图片地址前缀
        static var imageBaseUrl: String {
            switch current {
            case .dev:  return devImageURL
            case .test: return testImageURL
            case .prod: return prodImageURL
            }
        }

        /// 拼接完整图片 URL
        /// - Parameter path: 图片相对路径或完整 URL
        /// - Returns: 完整的图片 URL
        static func fullImageURL(path: String) -> String {
            if path.isEmpty { return path }
            if path.hasPrefix("http") { return path }
            return imageBaseUrl + path
        }

        /// H5 页面地址前缀
        static var h5BaseUrl: String {
            switch current {
            case .dev:  return devH5URL
            case .test: return testH5URL
            case .prod: return prodH5URL
            }
        }

        // MARK: - 生产环境 URL

        private static let prodBaseURL  = "https://apipro.szyuany.com/api"
        private static let prodImageURL = "https://asset.szyuany.com/"
        private static let prodH5URL    = "https://h5web.szyuany.com/"

        // MARK: - 测试环境 URL

        private static let testBaseURL  = "https://api.test.szyuany.com/api"
        private static let testImageURL = "https://asset.szyuany.com/"
        private static let testH5URL    = "https://h5web.szyuany.com/"

        // MARK: - 开发环境 URL

        private static let devBaseURL  = "http://192.168.10.140:100/api"
        private static let devImageURL = "http://dev.assets.nnxqn.com/"
        private static let devH5URL    = "http://dev.h5.nnxqn.com/"

        // MARK: - 全局默认请求 Header

        static var commonHeaders: HTTPHeaders {
            var h: HTTPHeaders = [
                "Content-Type":  "application/json",
                "Accept":        "application/json",
                "uuid":          DeviceInfo.uuid,
                "channel":       DeviceInfo.channel,
                "package-name":  DeviceInfo.packageName,
                "version":       DeviceInfo.version,
                "ver-code":      DeviceInfo.verCode,
                "source-id":     DeviceInfo.sourceId,
                "oaid":          DeviceInfo.uuid,
                "Phone-Brand":   DeviceInfo.getDeviceModel(),
                "Idfa":          DeviceInfo.idfa,
                "Idfv":          DeviceInfo.idfv
            ]
            // token：已登录时携带
            if let token = UserManager.shared.token, !token.isEmpty {
                h.add(name: "token", value: token)
                h.add(name: "Authorization", value: "Bearer \(token)")
            }
            return h
        }
    }
}
// MARK: - 环境枚举

enum AppEnvironment {
    /// 开发环境
    case dev
    /// 测试环境
    case test
    /// 生产环境
    case prod

    /// 环境描述
    var description: String {
        switch self {
        case .dev:  return "开发者"
        case .test: return "测试"
        case .prod: return "生产"
        }
    }
}

