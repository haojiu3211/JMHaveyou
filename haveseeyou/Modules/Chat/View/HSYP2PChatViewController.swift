//
//  HSYP2PChatViewController.swift
//  haveseeyou
//
//  单聊页：继承 SDK 的 P2PChatViewController，在发送消息前插入服务端校验
//


import UIKit
import NEChatKit
import NEChatUIKit
import NIMSDK
import Combine

final class HSYP2PChatViewController: P2PChatViewController {

    private lazy var precheckService = MessagePrecheckService(host: self)
    var cancellables = Set<AnyCancellable>()
    
    private var customTitle: String?
    private var inputAreaView: UIView?
    
    /// 判断当前视图控制器是否是被 Present 出来的
    private var isPresented: Bool {
        if presentingViewController != nil {
            return true
        }
        if let nav = navigationController, nav.viewControllers.count > 1 {
            return false
        }
        return navigationController?.presentingViewController != nil
    }
    
    /// 设置自定义返回按钮
    private func setupCustomBackButton() {
        // 使用 SDK 的 navigationView 来获取返回按钮
        if let navigationView = self.value(forKey: "navigationView") as? UIView {
            // 递归查找导航栏中的返回按钮
            if let backButton = findBackButton(in: navigationView) {
                // 移除原有的点击事件
                backButton.removeTarget(nil, action: nil, for: .touchUpInside)
                // 添加我们自定义的点击事件
                backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
            }
        } else {
            // 如果无法获取 SDK 导航栏，尝试使用标准方式
            let backImage = UIImage(named: "app_back")?.withRenderingMode(.alwaysTemplate)
            let backButton = UIBarButtonItem(
                image: backImage,
                style: .plain,
                target: self,
                action: #selector(backButtonTapped)
            )
            backButton.tintColor = AppColor.textMain
            navigationItem.leftBarButtonItem = backButton
        }
    }
    
    /// 递归查找导航栏中的返回按钮
    private func findBackButton(in view: UIView) -> UIButton? {
        for subview in view.subviews {
            if let button = subview as? UIButton {
                return button
            }
            // 递归查找子视图
            if let foundButton = findBackButton(in: subview) {
                return foundButton
            }
        }
        return nil
    }
    
    /// 返回按钮点击处理
    @objc private func backButtonTapped() {
        if isPresented {
            // Present 进来的，执行 dismiss
            dismiss(animated: true, completion: nil)
        } else {
            // Push 进来的，执行 pop
            navigationController?.popViewController(animated: true)
        }
    }
    
    override var title: String? {
        didSet {
            // 如果是预设系统账号，始终保持我们设置的 title
            let sessionId = ChatRepo.sessionId
            switch sessionId {
            case "8997904", "8997905", "8997906":
                if title != customTitle {
                    super.title = customTitle
                }
            default:
                break
            }
        }
    }
    
    /// 检查是否是活动公告会话
    private var isActivityAnnouncement: Bool {
        return ChatRepo.sessionId == "8997904"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 在 viewDidLoad 中就提前设置标题
        setupTitle()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 提前设置背景色，防止出现黑色背景
        self.view.backgroundColor = .white
        if let window = view.window {
            window.backgroundColor = .white
        }
        // 再次尝试设置标题
        setupTitle()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 设置自定义返回按钮 - 在 viewDidAppear 中设置，确保 SDK 导航栏已完全加载
        setupCustomBackButton()
        
        // 再次尝试设置标题，并尝试直接修改 SDK 的导航视图
        setupTitle()
        // 延迟再次设置，确保 SDK 完全加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.setupTitle()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.setupTitle()
        }
        
        // 如果是活动公告，隐藏输入框
        if isActivityAnnouncement {
            hideInputArea()
        }
    }
    
    /// 设置标题
    private func setupTitle() {
        // 检查是否是预设系统账号，设置正确的 title
        let sessionId = ChatRepo.sessionId
        switch sessionId {
        case "8997904":
            customTitle = "活动公告"
        case "8997905":
            customTitle = "系统通知"
        case "8997906":
            customTitle = "官方客服"
        default:
            customTitle = nil
        }
        
        guard let title = customTitle else { return }
        
        // 设置标题
        super.title = title
        navigationItem.title = title
    }
    
    /// 隐藏输入框区域的安全方法
    private func hideInputArea() {
        // 设置所有相关视图的背景色为白色，防止出现黑色背景
        self.view.backgroundColor = .white
        if let window = view.window {
            window.backgroundColor = .white
        }
        
        // 查找输入区域
        if inputAreaView == nil {
            inputAreaView = findInputAreaView(in: self.view)
        }
        
        // 隐藏输入区域
        if let inputView = inputAreaView {
            inputView.isHidden = true
            inputView.isUserInteractionEnabled = false
            
            // 尝试将输入区域高度设为 0，避免占据空间
            if let superview = inputView.superview {
                // 查找并更新约束
                for constraint in superview.constraints {
                    if (constraint.firstItem === inputView && constraint.firstAttribute == .height) ||
                       (constraint.secondItem === inputView && constraint.secondAttribute == .height) {
                        constraint.constant = 0
                    }
                }
                
                // 同时也设置 inputView 的自身高度约束
                for constraint in inputView.constraints {
                    if constraint.firstAttribute == .height {
                        constraint.constant = 0
                    }
                }
                
                // 强制布局更新
                UIView.animate(withDuration: 0) {
                    superview.layoutIfNeeded()
                    self.view.layoutIfNeeded()
                }
            }
        }
        
        // 强制结束编辑，防止键盘弹出
        self.view.endEditing(true)
        
        // 延迟再次检查和设置背景色，确保异步操作后也不会出现黑色背景
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.view.backgroundColor = .white
            self?.view.window?.backgroundColor = .white
        }
    }
    
    /// 查找输入区域视图
    private func findInputAreaView(in view: UIView) -> UIView? {
        let className = String(describing: type(of: view))
        
        // 如果是常见的输入容器类名，直接返回
        if className.contains("Input") || className.contains("Bar") ||
           className.contains("Tool") || className.contains("ChatInput") {
            return view
        }
        
        // 递归查找子视图
        for subview in view.subviews {
            if let found = findInputAreaView(in: subview) {
                return found
            }
        }
        
        return nil
    }
    
    /// 点击头像跳转到个人主页
    override func didTapHeadPortrait(model: MessageContentModel?) {
        // 点击自己的头像不处理（或可按需跳转到个人设置页）
        if ChatMessageHelper.isSelf(message: model?.message) {
            return
        }
        guard let uid = ChatMessageHelper.getSenderId(model?.message) else { return }
        pushUserProfile(userId: uid)
    }

    /// 跳转到用户个人主页
    private func pushUserProfile(userId: String) {
        NetworkManager.shared
            .request(ActivityDetailAPI.personalHomepage(userId: userId), as: PersonalHomepageDataModel.self)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case let .failure(error) = completion {
                }
            } receiveValue: { [weak self] model in
                let vc = PersionViewController()
                vc.model = model
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                self?.present(nav, animated: true, completion: nil)
            }
            .store(in: &cancellables)
    }

    // MARK: - 阻止所有消息发送
    
    override func sendContentText(text: String?, attribute: NSAttributedString?) {
        // 如果是活动公告，不允许发送消息
        guard !isActivityAnnouncement else { return }
        
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else {
            // 与 SDK 行为一致：空文本交回父类处理（弹空消息提示）
            super.sendContentText(text: text, attribute: attribute)
            return
        }

        let toUid = ChatRepo.sessionId
        let msgId = UUID().uuidString

        precheckService.precheck(type: 1,
                                 content: trimmed,
                                 msgId: msgId,
                                 toUid: toUid) { [weak self] _ in
            // 校验通过后由 SDK 继续完成真正的发送
            self?.superSendContentText(text: text, attribute: attribute)
        }
    }
    
    /// 包一层，避免在 escaping 闭包中直接引用 super 时的歧义
    private func superSendContentText(text: String?, attribute: NSAttributedString?) {
        super.sendContentText(text: text, attribute: attribute)
    }
    
}
