//
//  MainTabBarController.swift
//  haveseeyou
//
//  主 TabBar：活动 / 搭子 / 发布 / 我的
//

import UIKit
import NEChatKit

// MARK: - 自定义导航控制器：push 非 root 时自动隐藏底部 TabBar

final class BaseNavigationController: UINavigationController {
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        // 非 root（即二级及以下页面）自动隐藏底部 TabBar
        if viewControllers.count >= 1 {
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }
}

// MARK: - 主 TabBar

final class MainTabBarController: UITabBarController {

    // 需要拦截的 TabBarItem 索引（例如：发布按钮在第 2 位，索引为 2）
    private let interceptedIndex = 2
    // 通知 tabbar 的索引（第 4 个，索引为 3）
    private let notificationTabIndex = 3

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBarAppearance()
        setupChildren()
        setupNotificationObservers()

        // 设置 delegate 来拦截点击事件
        delegate = self
        
        // 立即更新一次 badge
        updateNotificationBadge()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 延迟一小会儿，确保数据和布局都准备好
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.updateNotificationBadge()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNotificationObservers() {
        // 监听会话变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateNotificationBadge),
            name: .imConversationDidChange,
            object: nil
        )
        // 监听用户登录
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateNotificationBadge),
            name: .userDidLogin,
            object: nil
        )
        // App 回到前台后再同步一次，避免自定义 badge 因异步登录或前后台切换未刷新
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateNotificationBadge),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func updateNotificationBadge() {
        let tabBarItemCount = CGFloat(tabBar.items?.count ?? 0)
        guard tabBarItemCount > 0 else { return }

        guard IMManager.shared.isLoggedIn else {
            tabBar.hideBadgeOn(index: notificationTabIndex)
            UIApplication.shared.applicationIconBadgeNumber = 0
            return
        }
        
        let unreadCount = IMManager.shared.totalUnreadCount()
        if unreadCount > 0 {
            tabBar.showBadgeOn(index: notificationTabIndex, count: unreadCount, tabbarItemNums: tabBarItemCount)
            UIApplication.shared.applicationIconBadgeNumber = unreadCount
        } else {
            tabBar.hideBadgeOn(index: notificationTabIndex)
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = UIColor(hex: "#E5E5E5")

        // 选中/未选中文字颜色
        let selectedColor = AppColor.textMain
        let normalColor = AppColor.textSecondary

        [appearance.stackedLayoutAppearance,
         appearance.inlineLayoutAppearance,
         appearance.compactInlineLayoutAppearance].forEach { item in
            item.normal.iconColor = normalColor
            item.selected.iconColor = selectedColor
            item.normal.titleTextAttributes = [
                .foregroundColor: normalColor,
                .font: UIFont.systemFont(ofSize: 11)
            ]
            item.selected.titleTextAttributes = [
                .foregroundColor: selectedColor,
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
            ]
        }

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        tabBar.tintColor = selectedColor
    }

    private func setupChildren() {
        let home = ActivityViewController()
        let group = GroupViewController()
        let publish = PublishViewController()
        let imchat = ConversationListViewController()
        let mine = MineViewController()

        viewControllers = [
            wrap(group,   title: "搭子", icon: "tab_dazi"),
            wrap(home,    title: "活动", icon: "tab_activity"),
            wrap(publish, title: "", icon: "tab_ceter_publish"),
            wrap(imchat, title: "通知", icon: "tab_msg"),
            wrap(mine,    title: "我的", icon: "tab_me")
        ]
    }

    private func wrap(_ vc: UIViewController, title: String, icon: String) -> UINavigationController {
        vc.title = title
        let nav = BaseNavigationController(rootViewController: vc)
        nav.navigationBar.isHidden = true
        let image = UIImage(named: icon)?.withRenderingMode(.alwaysOriginal)
        let imageSel = UIImage(named: icon+"_sel")?.withRenderingMode(.alwaysOriginal)
        nav.tabBarItem = UITabBarItem(title: title,
                                      image: image,
                                      selectedImage: imageSel)
        return nav
    }
    
    // MARK: - 自定义点击处理
    
    private func handleInterceptedTabTap() {
        // 这里是你想要执行的自定义事件
        print("🎯 拦截了第 \(interceptedIndex) 个 TabBarItem 的点击")
        
        // 示例：弹出发布界面
//        let publishVC = PublishViewController()
//        present(publishVC, animated: true)
        
        // 示例：或者做其他操作
        // showToast(message: "发布功能开发中")
    }
}

// MARK: - UITabBarControllerDelegate

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // 获取被点击的 TabBarItem 索引
//        if let index = viewControllers?.firstIndex(of: viewController) {
//            // 如果是需要拦截的索引
//            if index == interceptedIndex {
//                // 执行自定义事件
//                handleInterceptedTabTap()
//                // 返回 false 阻止默认切换行为
//                return false
//            }
//        }
        // 其他 TabBarItem 正常处理
        return true
    }
}
