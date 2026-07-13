//
//  MessagePrecheckService.swift
//  haveseeyou
//
//  发送消息前的服务端校验：统一封装请求 + 状态码分发
//

import UIKit
import Combine
import NECommonUIKit

final class MessagePrecheckService {

    /// 弹窗 / 跳转 / Toast 的宿主视图控制器
    private weak var host: UIViewController?

    private var cancellables = Set<AnyCancellable>()

    init(host: UIViewController) {
        self.host = host
    }

    /// 发送消息前向服务端校验
    /// - Parameters:
    ///   - type: 消息类型 (1=文本, 2=语音, 3=图片, 4=视频, 7=文件)
    ///   - content: 消息内容
    ///   - msgId: 消息 UUID
    ///   - toUid: 目标用户 ID
    ///   - completion: 校验通过 (code == 0) 时回调，附带服务端返回的 remoteExtension；
    ///                 失败时由 service 自行弹窗 / 跳转，不会回调。
    func precheck(type: Int,
                  content: String,
                  msgId: String,
                  toUid: String,
                  completion: @escaping ([String: String]?) -> Void) {
        NetworkManager.shared
            .request(ChatAPI.sendMessageCheck(type: type,
                                              content: content,
                                              msgId: msgId,
                                              toUid: toUid),
                     as: SendMessagePrecheckData.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                guard case let .failure(error) = result else { return }
                if case let .business(code, message) = error {
                    self?.handleBusinessError(code: code, message: message)
                } else {
                    self?.host?.showToast(error.localizedDescription)
                }
            }, receiveValue: { data in
                completion(data.remoteExtension)
            })
            .store(in: &cancellables)
    }

    // MARK: - 状态码分发

    private func handleBusinessError(code: Int, message: String) {
        switch code {
        case 1001:
            // Token 过期 → 退出登录（由 .userDidLogout 全局监听跳登录页）
            UserManager.shared.logout()

        case 1003:
            // 余额不足 → 跳钱包充值
            showAuthAlert(title: "余额不足", message: message, confirm: "去充值") { [weak self] in
                self?.pushWallet()
            }

        case 1007:
            // 需要真人认证
            showAuthAlert(title: "提示", message: message, confirm: "去认证") { [weak self] in
                self?.openOfficialCert()
            }

        case 1008:
            // 需要实名认证
            showAuthAlert(title: "提示", message: message, confirm: "去认证") { [weak self] in
                self?.openRealNameWeb()
            }

        case 1009:
            // VIP 权益次数用完
            showAuthAlert(title: "提示", message: message, confirm: "去充值") { [weak self] in
                self?.pushWallet()
            }

        case 1010:
            // 需要人脸核验
            showAuthAlert(title: "提示", message: message, confirm: "去核验") { [weak self] in
                self?.openOfficialCert()
            }

        case 1014:
            // 仅 VIP 会员可用
            showAuthAlert(title: "会员提示", message: message, confirm: "升级VIP会员") { [weak self] in
                self?.pushMemberCenter()
            }

        case 1015:
            // 真人认证审核中 → 联系客服
            showAuthAlert(title: "提示", message: message, confirm: "联系客服") { [weak self] in
                self?.openCustomerServiceWeb()
            }

        default:
            host?.showToast(message)
        }
    }

    // MARK: - 辅助：弹窗 / 跳转

    private func showAuthAlert(title: String,
                               message: String,
                               confirm: String,
                               onConfirm: @escaping () -> Void) {
        guard let host else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: confirm, style: .default) { _ in onConfirm() })
        host.present(alert, animated: true)
    }

    private func pushWallet() {
        host?.navigationController?.pushViewController(MyWalletViewController(), animated: true)
    }

    private func pushMemberCenter() {
        host?.navigationController?.pushViewController(MemberCenterViewController(), animated: true)
    }

    private func openOfficialCert() {
        host?.showToast("认证地址未配置")
    }

    private func openRealNameWeb() {
        host?.showToast("实名认证地址未配置")
    }

    private func openCustomerServiceWeb() {
        // 客服中心 URL 暂未在 SystemInit 中配置，先 toast 兜底
        host?.showToast("正在为您接通客服…")
    }
}
