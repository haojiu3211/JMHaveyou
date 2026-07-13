//
//  SceneDelegate.swift
//  haveseeyou
//
//  Created by admin on 2026/5/13.
//

import UIKit
import NIMSDK
import AppTrackingTransparency

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    // 是否需要跳转到通知页面的标志
    private var shouldNavigateToNotificationTab = false


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // 根据登录状态选择根控制器
        setupRootViewController()
        window.makeKeyAndVisible()

        

        // 已登录用户：用缓存的 imToken 自动登录云信
        if UserManager.shared.isLoggedIn,
           let userId = UserManager.shared.loginModel?.userId,
           let imToken = UserManager.shared.imToken,
           !userId.isEmpty, !imToken.isEmpty {
            IMManager.shared.login(accountId: userId, token: imToken)
        }

        // 监听登录/退出通知，动态切换根控制器
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleLogin),
                                               name: .userDidLogin,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleLogout),
                                               name: .userDidLogout,
                                               object: nil)
        
        // 检查是否有通知响应
        if let notificationResponse = connectionOptions.notificationResponse {
            print("📩 通过推送通知启动 App (SceneDelegate): \(notificationResponse.notification.request.content.userInfo)")
            shouldNavigateToNotificationTab = true
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            DeviceInfo.requestTrackingAuthorization()
        }
        
        // 检查是否需要跳转到通知页面
        if shouldNavigateToNotificationTab {
            shouldNavigateToNotificationTab = false
            navigateToNotificationTab()
        }
    }

    // MARK: - Root ViewController

    /// 根据登录状态设置根控制器
    private func setupRootViewController() {
        if UserManager.shared.isLoggedIn {
            window?.rootViewController = MainTabBarController()
        } else {
            let loginVC = LoginViewController()
            loginVC.onLoginSuccess = { [weak self] in
                self?.switchToMain()
            }
            window?.rootViewController = UINavigationController(rootViewController: loginVC)
        }
    }

    /// 切换到主界面
    private func switchToMain() {
        let tabBarController = MainTabBarController()
        window?.rootViewController = tabBarController
        
        // 如果需要跳转到通知页面，延迟执行
        if shouldNavigateToNotificationTab {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.shouldNavigateToNotificationTab = false
                self?.navigateToNotificationTab()
            }
        }
    }

    /// 切换到登录页面
    private func switchToLogin() {
        let loginVC = LoginViewController()
        loginVC.onLoginSuccess = { [weak self] in
            self?.switchToMain()
        }
        let nav = UINavigationController(rootViewController: loginVC)
        window?.rootViewController = nav
    }
    
    // MARK: - 跳转到通知 Tab
    private func navigateToNotificationTab() {
        guard let window = window else { return }
        
        DispatchQueue.main.async {
            if let tabBarController = window.rootViewController as? MainTabBarController {
                tabBarController.selectedIndex = 3 // 通知 tab 是第 4 个，索引 3
                print("✅ 已跳转到通知页面 (SceneDelegate)")
            } else if let navController = window.rootViewController as? UINavigationController,
                      let tabBarController = navController.viewControllers.first as? MainTabBarController {
                tabBarController.selectedIndex = 3
                print("✅ 已跳转到通知页面 (SceneDelegate)")
            } else {
                print("⚠️ 未找到 MainTabBarController (SceneDelegate)")
            }
        }
    }

    // MARK: - Notifications

    @objc private func handleLogin() {
        switchToMain()
    }

    @objc private func handleLogout() {
        switchToLogin()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        DeviceInfo.requestTrackingAuthorization()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

