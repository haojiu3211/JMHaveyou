//
//  SyNotifNames.swift
//  haveseeyou
//
//  Created by admin on 2026/5/29.
//

import Foundation


// MARK: - 通知名

extension Notification.Name {
    /// 用户退出登录
    static let userDidLogout = Notification.Name("userDidLogout")
    /// 用户登录成功
    static let userDidLogin = Notification.Name("userDidLogin")
    /// 用户资料更新（H5 回传编辑结果）
    static let userInfoDidUpdate = Notification.Name("userInfoDidUpdate")
    /// 云信会话列表变更
    static let imConversationDidChange = Notification.Name("imConversationDidChange")
}
