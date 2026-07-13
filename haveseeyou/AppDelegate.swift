//
//  AppDelegate.swift
//  haveseeyou
//
//  Created by admin on 2026/5/13.
//

import UIKit
import NIMSDK
import UserNotifications // 必须导入此框架
import NTESQuickPass

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 设置 App 默认语言为中文
        UserDefaults.standard.set(["zh-Hans-CN"], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        IMManager.shared.setup()
        
        // 初始化易盾一键登录 SDK
        NTESQuickLoginManager.sharedInstance().register(withBusinessID: AppConfig.ThirdKey.ydLoginBusinessID)
        
        // 1. 初始化 StoreKitHelper 和 PurchaseManager，确保持续监听交易队列（包括自动续费）
        _ = StoreKitHelper.shared
        _ = PurchaseManager.shared
        
        // 2. 获取审核配置
        AuditConfigManager.shared.fetchAuditConfig()
        
        // 3. 预先缓存产品列表，以便自动续费时能快速识别产品类型
        if UserManager.shared.isLoggedIn {
            // 缓存 VIP 产品列表
            PurchaseManager.shared.fetchVipProducts()
            // 缓存钻石产品列表
            PurchaseManager.shared.fetchDiamondProducts()
            // 🔑 关键：检查并处理未完成的交易（如果用户付款后杀掉 App）
            PurchaseManager.shared.checkAndProcessPendingTransactions()
        }
        
        // 3. 请求推送权限（弹窗、声音、角标）
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ 用户已授权接收推送通知")
                // 必须在主线程调用注册方法
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("❌ 用户拒绝了推送权限: \(error?.localizedDescription ?? "未知错误")")
            }
        }
        
        // 【新增】设置代理，这样下面的回调方法才会被触发
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
                return String(format: "%02.2hhx", data)
            }
            let token = tokenParts.joined()
            print("Device Token: \(token)") // 复制这个 Token 用于测试
        NIMSDK.shared().updateApnsToken(deviceToken)
    }
    
    func enableRemoteNotifications(_ enabled: Bool) {
        if enabled {
            UIApplication.shared.registerForRemoteNotifications()
            print("✅ 远程推送已开启")
        } else {
            UIApplication.shared.unregisterForRemoteNotifications()
            print("❌ 远程推送已关闭")
        }
    }
    
    // MARK: - 跳转到通知 Tab
    private func navigateToNotificationTab() {
        // 确保在主线程执行
        DispatchQueue.main.async {
            // 获取 keyWindow
            guard let window = UIApplication.shared.connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows
                .first(where: { $0.isKeyWindow }) else {
                print("⚠️ 无法获取 keyWindow")
                return
            }
            
            // 获取根视图控制器
            guard let rootViewController = window.rootViewController else {
                print("⚠️ 无法获取 rootViewController")
                return
            }
            
            // 如果是 MainTabBarController，直接切换到通知 tab
            if let tabBarController = rootViewController as? MainTabBarController {
                tabBarController.selectedIndex = 3 // 通知 tab 是第 4 个，索引 3
                print("✅ 已跳转到通知页面")
                return
            }
            
            // 如果根视图控制器是导航控制器，查找 MainTabBarController
            if let navController = rootViewController as? UINavigationController {
                if let tabBarController = navController.viewControllers.first as? MainTabBarController {
                    tabBarController.selectedIndex = 3
                    print("✅ 已跳转到通知页面")
                    return
                }
            }
            
            // 如果都找不到，尝试从 presentedViewController
            if let presentedVC = rootViewController.presentedViewController {
                if let tabBarController = presentedVC as? MainTabBarController {
                    tabBarController.selectedIndex = 3
                    print("✅ 已跳转到通知页面")
                    return
                }
            }
            
            print("⚠️ 未找到 MainTabBarController，无法跳转")
        }
    }
}

// 扩展 AppDelegate 以符合 UNUserNotificationCenterDelegate 协议
extension AppDelegate: UNUserNotificationCenterDelegate {


    /// 1. App 在前台时收到推送通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 前台也显示通知
        completionHandler([.alert, .badge, .sound])
    }

    /// 2. 处理用户点击了推送 (无论 App 是在后台还是被杀死了)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // 1. 获取推送内容（可选，用于调试）
        let userInfo = response.notification.request.content.userInfo
        print("📩 用户点击了推送: \(userInfo)")
        
        // 2. 跳转到通知页面
        navigateToNotificationTab()
        
        // 3. 必须调用 completionHandler，告诉系统处理完毕
        completionHandler()
    }
}
