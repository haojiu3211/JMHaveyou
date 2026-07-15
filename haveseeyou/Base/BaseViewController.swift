//
//  BaseViewController.swift
//  haveseeyou
//
//  控制器基类：统一导航样式、Combine 订阅容器
//

import UIKit
import Combine
import SnapKit

class BaseViewController: UIViewController {

    /// 通用订阅容器
    var cancellables = Set<AnyCancellable>()

    // MARK: - 导航栏统一配置

    /// 子类重写：是否隐藏系统导航栏（一级页面如 HomeVC 需隐藏，二级页面默认显示）
    var prefersNavigationBarHidden: Bool { false }

    /// 子类重写：是否使用标准返回按钮（默认 true，二级页面自动配置返回按钮+interactivePopGestureRecognizerDelegate标题样式）
    /// 设为 false 则完全自定义导航栏左侧按钮
    var useStandardBackButton: Bool { true }

    /// 保存系统侧滑手势代理，用于恢复侧滑返回功能
    private weak var interactivePopGestureRecognizerDelegate: UIGestureRecognizerDelegate?

    /// 子类重写：返回对应的 ViewModel，BaseViewController 会自动订阅其 loadingState
    /// 不需要 loading 的页面无需重写（默认 nil）
    var baseViewModel: BaseViewModel? { nil }

    // MARK: - Loading HUD

    /// Loading 蒙层
    private lazy var loadingOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.isHidden = true
        return view
    }()

    /// Loading 指示器
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let iv = UIActivityIndicatorView(style: .medium)
        iv.color = .white
        iv.hidesWhenStopped = true
        return iv
    }()

    /// Loading 下方文字
    private lazy var loadingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.text = ""
        label.textAlignment = .center
        return label
    }()

    /// Loading 容器卡片
    private lazy var loadingContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    /// 是否正在 Loading
    var isLoading: Bool {
        return !loadingOverlay.isHidden
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupKeyboardDismiss()
        setupDefaultNavBar()
        setupUI()
        bindViewModel()
        bindBaseLoadingState()

        // 一级页面立即隐藏导航栏，避免闪现
        if prefersNavigationBarHidden {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 保存系统手势代理并恢复侧滑返回功能
        enableInteractivePopGesture()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 离开页面时恢复原始手势代理
        restoreInteractivePopGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(prefersNavigationBarHidden, animated: animated)
        if !prefersNavigationBarHidden && useStandardBackButton {
            configureNavigationBarAppearance()
        }
    }

    // MARK: - 全局点击收起键盘

    /// 点击手势：点击任意位置收起键盘
    private lazy var keyboardDismissTap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        return tap
    }()

    /// 添加全局点击收起键盘手势
    private func setupKeyboardDismiss() {
        view.addGestureRecognizer(keyboardDismissTap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    /// 全局点击空白收起键盘（兼容无子视图遮挡的空白区域）
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }

    /// 子类重写：布局与子视图
    func setupUI() {}

    /// 子类重写：绑定 ViewModel
    func bindViewModel() {}

    /// 自动绑定 baseViewModel 的 loadingState，子类无需手动订阅
    private func bindBaseLoadingState() {
        guard let vm = baseViewModel else { return }
        vm.$loadingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .loading:
                    self?.showLoading()
                case .idle, .success, .failure:
                    self?.hideLoading()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - 通用导航栏配置

    /// 配置标准返回按钮（在 viewDidLoad 中自动调用）
    private func setupDefaultNavBar() {
        guard useStandardBackButton else { return }
        navigationItem.hidesBackButton = true

        
        let backImage = UIImage(named: "app_back")?
            .withRenderingMode(.alwaysTemplate)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: backImage,
            style: .plain,
            target: self,
            action: #selector(standardBackAction)
        )
        navigationItem.leftBarButtonItem?.tintColor = AppColor.textMain
    }

    /// 统一导航栏外观（白底 + 深色标题）
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [
            .foregroundColor: AppColor.textMain,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = AppColor.textMain
    }

    /// 标准返回动作，子类可重写以添加拦截逻辑（如确认弹窗）
    @objc func standardBackAction() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - 侧滑返回支持

    /// 启用侧滑返回手势
    private func enableInteractivePopGesture() {
        guard let navigationController = navigationController,
              navigationController.viewControllers.count > 1 else { return }

        // 保存系统原始代理
        if let delegate = navigationController.interactivePopGestureRecognizer?.delegate {
            interactivePopGestureRecognizerDelegate = delegate
        }

        // 设置代理为 nil 以启用手势（系统内部会处理）
        navigationController.interactivePopGestureRecognizer?.delegate = nil
    }

    /// 恢复原始侧滑手势代理
    private func restoreInteractivePopGesture() {
        guard let navigationController = navigationController else { return }
        navigationController.interactivePopGestureRecognizer?.delegate = interactivePopGestureRecognizerDelegate
    }

    // MARK: - Loading 显示/隐藏

    /// 显示 Loading
    func showLoading(_ message: String = "加载中...") {
        if loadingOverlay.superview == nil {
            view.addSubview(loadingOverlay)
            view.addSubview(loadingContainer)
            loadingContainer.addSubview(loadingIndicator)

            loadingOverlay.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            loadingContainer.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(80)
            }
            loadingIndicator.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }

        loadingOverlay.isHidden = false
        loadingContainer.isHidden = false
        loadingIndicator.startAnimating()
        view.bringSubviewToFront(loadingOverlay)
        view.bringSubviewToFront(loadingContainer)
    }

    /// 隐藏 Loading
    func hideLoading() {
        loadingIndicator.stopAnimating()
        loadingOverlay.isHidden = true
        loadingContainer.isHidden = true
    }

    /// 简单的顶部 Toast
    func showToast(_ message: String, duration: TimeInterval = 1.5) {
        let label = PaddingLabel()
        label.text = message
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        label.numberOfLines = 0
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.alpha = 0
        view.addSubview(label)

        let size = label.sizeThatFits(CGSize(width: view.bounds.width - 80, height: .greatestFiniteMagnitude))
        label.frame = CGRect(
            x: (view.bounds.width - size.width) / 2,
            y:(view.bounds.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
        UIView.animate(withDuration: 0.25, animations: {
            label.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.25, delay: duration, options: [], animations: {
                label.alpha = 0
            }, completion: { _ in
                label.removeFromSuperview()
            })
        }
    }
    
    deinit {
        // 清理 Combine 订阅
        cancellables.removeAll()
        
        #if DEBUG
        print("✅ [BaseViewController] 已释放: \(type(of: self))")
        #endif
    }
}

/// 带内边距的 Label
final class PaddingLabel: UILabel {
    var insets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + insets.left + insets.right,
                      height: s.height + insets.top + insets.bottom)
    }
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let s = super.sizeThatFits(CGSize(width: size.width - insets.left - insets.right,
                                          height: size.height - insets.top - insets.bottom))
        return CGSize(width: s.width + insets.left + insets.right,
                      height: s.height + insets.top + insets.bottom)
    }
}
