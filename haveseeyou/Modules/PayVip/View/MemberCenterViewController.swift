//
//  MemberCenterViewController.swift
//  haveseeyou
//
//  Created by admin开发测试 on 2026/6/11.
//

import UIKit
import SnapKit
import StoreKit

class MemberCenterViewController: BaseViewController {

    /// 登录页隐藏系统导航栏
    override var prefersNavigationBarHidden: Bool { true }
    /// 不使用标准返回按钮（登录页为根页面，无需返回按钮）
    override var useStandardBackButton: Bool { false }
    
    // MARK: - Properties
    
    // 产品配置：从会员中心接口获取
    private var productIds: Set<String> = []
    
    // StoreKit 产品缓存
    private var iapProducts: [String: IAPProduct] = [:]
    
    // 防止重复购买/恢复的标志位
    private var isProcessingPurchase = false
    
    // 购买流程中保存的订单信息
    private var currentOrderNo: String?
    private var currentProductId: String?
    private var currentVipId: Int?
    private var currentVipGoodsId: String?
    private var currentUserVipInfo: VipUserInfo? // 保存当前用户的 VIP 信息
    
    // 滚动视图
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.bounces = false
        return sv
    }()

    // 自定义导航栏
    private lazy var memberNavView: MemberNavView = {
        let nav = MemberNavView()
        nav.delegate = self
        return nav
    }()
    
   // vip付费中心
    private lazy var menberCenterView: MenberCenterView = {
        let vipCenterView = MenberCenterView()
        vipCenterView.delegate = self
        return vipCenterView
    }()
    
   // vip专属特权列表
    private lazy var memberBottomView: MemberBottom = {
        let vipBottomView = MemberBottom()
        return vipBottomView
    }()

    // 模拟的内容容器（用来撑开 ScrollView）
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupStoreKitHelper()
        setupNotificationObservers()
        // 强制重置所有状态，清理历史遗留问题
        StoreKitHelper.shared.forceResetAllState()
        // 清理积压的旧交易
        StoreKitHelper.shared.cleanUpStaleTransactions()
        fetchMemberCenter()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 页面消失时，清除通知监听
        NotificationCenter.default.removeObserver(self)
        // 页面消失时，清除 StoreKitHelper 的 delegate，让 PurchaseManager 可以继续处理自动续费
        StoreKitHelper.shared.delegate = nil
    }
    
    // MARK: - 通知监听
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRestoreSuccess(_:)),
            name: .IAPDidVerifyRestoreSuccess,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRestoreFail(_:)),
            name: .IAPDidVerifyRestoreFail,
            object: nil
        )
        
        // 监听审核配置变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuditConfigChange),
            name: .auditConfigDidChange,
            object: nil
        )
    }
    
    @objc private func handleRestoreSuccess(_ notification: Notification) {
        print("✅ [MemberCenter] 收到恢复购买成功通知")
        hideLoading()
        isProcessingPurchase = false
        showToast("恢复购买成功！")
        refreshUserInfo()
    }
    
    @objc private func handleRestoreFail(_ notification: Notification) {
        print("❌ [MemberCenter] 收到恢复购买失败通知")
        hideLoading()
        isProcessingPurchase = false
        showToast("恢复购买失败")
    }
    
    @objc private func handleAuditConfigChange() {
        print("🔍 [MemberCenter] 收到审核配置变化通知，刷新 UI")
        memberBottomView.refresh()
    }
    
    override func setupUI() {
        view.addSubview(memberNavView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(menberCenterView)
        contentView.addSubview(memberBottomView)
        
        setupConstraints()
    }
    
    // MARK: - Constraints
    
    private func setupConstraints() {
        // 1. 导航栏布局
        memberNavView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(210 + (UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44))
        }
        
        // 2. ScrollView 布局
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(memberNavView.snp.bottom).offset(-5)
            make.leading.trailing.bottom.equalToSuperview()
        }

        // 1. ContentView 布局（撑开 ScrollView）
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
            make.height.equalToSuperview().priority(.low)
        }

        // 2. menberCenterView 布局
        menberCenterView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(350)
        }

        // 3. memberCenterBottom 布局
        memberBottomView.snp.makeConstraints { make in
            make.left.right.equalTo(menberCenterView)
            make.top.equalTo(menberCenterView.snp.bottom)
            make.bottom.equalToSuperview().offset(50)
        }
    }
    
    // MARK: - StoreKit Setup
    private func setupStoreKitHelper() {
        StoreKitHelper.shared.delegate = self
    }
    
    // MARK: - Network
    
    // MARK: - 生成订单号
    private func generateOrderNo() -> String {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let random = String(format: "%06d", arc4random_uniform(1000000))
        return "iOS\(timestamp)\(random)"
    }
    
    // MARK: - 会员中心接口
    private func fetchMemberCenter() {
        print("🚀 [MemberCenter] 开始请求会员中心接口")
        
        NetworkManager.shared.request(PurchaseAPI.memberCenter, as: MemberCenterResponse.self) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                print("✅ [MemberCenter] 请求成功")
                self.handleMemberCenterResponse(response)
                
            case .failure(let error):
                print("❌ [MemberCenter] 请求失败: \(error.localizedDescription)")
                self.showToast("请求失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 处理会员中心响应
    private func handleMemberCenterResponse(_ response: MemberCenterResponse) {
        // 1. 更新用户信息
        if let info = response.info {
            currentUserVipInfo = info // 保存 VIP 信息
            
            memberNavView.setUserInfo(
                avatar: info.avatar,
                nickname: info.nickname,
                usercode: info.usercode,
                vip: info.vip,
                vipExpireDate: info.expireTime
            )
            
            // 更新本地用户信息
            UserManager.shared.updateUserInfo(
                nickname: info.nickname, avatar: info.avatar,
                vip: info.vip
            )
        } else {
            // 如果接口没有返回用户信息，则使用 UserManager 的数据作为 fallback
            currentUserVipInfo = nil
            
            let user = UserManager.shared
            memberNavView.setUserInfo(
                avatar: user.loginModel?.avatar,
                nickname: user.nickname,
                usercode: user.loginModel?.usercode,
                vip: user.loginModel?.vip
            )
        }
        
        // 2. 更新产品列表
        if let products = response.list, !products.isEmpty {
            menberCenterView.updateWithVipProducts(products)
            
            // 更新产品ID列表用于内购
            productIds.removeAll()
            for product in products {
                if let productId = product.startIosProductId, !productId.isEmpty {
                    productIds.insert(productId)
                }
            }
            
            // 重新获取内购产品
            fetchStoreKitProducts()
        }
    }
    
    private func fetchStoreKitProducts() {
        print("🚀 [IAP] 开始获取 StoreKit 产品")
        StoreKitHelper.shared.fetchProducts(productIds: productIds)
    }
    
    private func refreshUserInfo() {
        // 请求会员中心接口刷新用户信息
        fetchMemberCenter()
    }
}

// MARK: - MemberNavViewDelegate
extension MemberCenterViewController: MemberNavViewDelegate {
    func navBarDidClickBackButton() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - MenberCenterViewDelegate
extension MemberCenterViewController: MenberCenterViewDelegate {
    func memberViewDidClickUpgrade(_ view: MenberCenterView, selectedPlan: PlanItem) {
        guard !isLoading && !isProcessingPurchase else { return }
        
        // 立即设置标志位，防止重复点击
        isProcessingPurchase = true
        
        // 检查是否已是会员
        if let vipInfo = currentUserVipInfo, vipInfo.vip == 1 {
            isProcessingPurchase = false
            if let expireTime = vipInfo.expireTime {
                showToast("您已是会员，\(expireTime)")
            } else {
                showToast("您已是会员，无需再次购买")
            }
            return
        }
        
        guard view.isAgreed else {
            isProcessingPurchase = false
            showToast("请先同意协议")
            return
        }
        
        guard let vipId = selectedPlan.vipId, let vipGoodsId = selectedPlan.vipGoodsId else {
            isProcessingPurchase = false
            showToast("产品信息不完整")
            return
        }
        
        // 第一步：先请求创建 VIP 订单
        createVipOrder(vipId: "\(vipId)", vipGoodsId: vipGoodsId, productId: selectedPlan.productId)
    }
    
    // MARK: - 创建 VIP 订单
    private func createVipOrder(vipId: String, vipGoodsId: String, productId: String) {
        showLoading("获取订单中...")
        
        NetworkManager.shared.request(
            PurchaseAPI.createVipOrder(id: vipId, vipGoodsId: vipGoodsId, type: "none"),
            as: CreateVipOrderData.self
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let orderData):
                self.hideLoading()
                
                if let orderNo = orderData.orderNo {
                    print("✅ [VIP] 获取订单成功: \(orderNo)")
                    
                    // 保存订单信息
                    self.currentOrderNo = orderNo
                    self.currentProductId = productId
                    self.currentVipId = Int(vipId)
                    self.currentVipGoodsId = vipGoodsId
                    
                    // 第二步：发起 Apple Pay 支付
                    print("🚀 [IAP] 发起购买: \(productId)")
                    StoreKitHelper.shared.purchaseProduct(productId: productId)
                } else {
                    self.isProcessingPurchase = false
                    self.showToast("获取订单失败")
                }
                
            case .failure(let error):
                self.hideLoading()
                self.isProcessingPurchase = false
                print("❌ [VIP] 获取订单失败: \(error)")
                self.showToast("获取订单失败")
            }
        }
    }
    
    func memberViewDidClickAgreement(_ view: MenberCenterView) {
        print("📄 [IAP] 点击协议")
        openVipSubscriptionAgreement()
    }
    
    private func openVipSubscriptionAgreement() {
        // 直接加载本地 HTML 文件
        guard let filePath = Bundle.main.path(forResource: "VIP 连续自动订阅服务协议", ofType: "html"),
              let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            // 如果读取失败，尝试使用在线 URL
            let webVC = WebViewController(urlString: webUrlVipSubscription, title: "VIP连续包月服务协议")
            navigationController?.pushViewController(webVC, animated: true)
            return
        }
        
        let webVC = WebViewController(htmlString: content, title: "VIP连续包月服务协议")
        navigationController?.pushViewController(webVC, animated: true)
    }
    
    func memberViewDidToggleAgreement(_ view: MenberCenterView, isAgreed: Bool) {
        print("📋 [IAP] 协议勾选状态: \(isAgreed)")
    }
    
    func memberViewDidClickUserAgreement(_ view: MenberCenterView) {
        print("📄 [IAP] 点击用户服务协议")
        openUserServiceAgreement()
    }
    
    func memberViewDidClickPrivacyAgreement(_ view: MenberCenterView) {
        print("📄 [IAP] 点击隐私协议")
        openPrivacyAgreement()
    }
    
    private func openUserServiceAgreement() {
        let webVC = WebViewController(urlString: webUrlUserPrivacy, title: "用户服务协议")
        navigationController?.pushViewController(webVC, animated: true)
    }
    
    private func openPrivacyAgreement() {
        let webVC = WebViewController(urlString: webUrlPrivacy, title: "隐私协议")
        navigationController?.pushViewController(webVC, animated: true)
    }
}

// MARK: - StoreKitHelperDelegate (购买逻辑)
extension MemberCenterViewController: StoreKitHelperDelegate {
    func storeKitHelper(_ helper: StoreKitHelper, didFetchProducts products: [IAPProduct]) {
        print("✅ [IAP] 收到 \(products.count) 个产品")
        
        for product in products {
            iapProducts[product.productId] = product
        }
        
        var updatedPlans = menberCenterView.plans
        for (index, var plan) in updatedPlans.enumerated() {
            if index < products.count {
                let product = products[index]
            }
        }
        menberCenterView.updatePlans(updatedPlans)
    }
    
    func storeKitHelper(_ helper: StoreKitHelper, didFailFetchProductsWithError error: Error) {
        print("❌ [IAP] 获取产品失败: \(error)")
        showToast("获取产品信息失败")
    }
    
    func storeKitHelper(_ helper: StoreKitHelper, didPurchaseProduct productId: String, receipt: String, transactionId: String) {
        print("✅ [IAP] 苹果支付成功，开始服务器验证")
        
        // 苹果支付成功，先显示"支付处理中"的提示
        showToast("支付处理中，请稍后查看")
        
        // 使用刚才获取的订单号进行验证
        if let orderNo = currentOrderNo {
            verifyApplePayPurchaseWithOrderNo(receipt: receipt, productId: productId, transactionId: transactionId, orderNo: orderNo)
        } else {
            // 备用：重新生成订单号
            verifyApplePayPurchase(receipt: receipt, productId: productId, transactionId: transactionId)
        }
        
        // 清除保存的订单信息
        currentOrderNo = nil
        currentProductId = nil
        currentVipId = nil
        currentVipGoodsId = nil
    }
    
    // MARK: - 使用已有订单号验证 Apple Pay 购买
    private func verifyApplePayPurchaseWithOrderNo(receipt: String, productId: String, transactionId: String, orderNo: String) {
        showLoading("确认订单中...")
        NetworkManager.shared.request(
            PurchaseAPI.applePayVerification(
                receipt: receipt, 
                productId: productId, 
                transactionId: transactionId,
                originalTransactionId: transactionId,
                orderNo: orderNo,
                isRestore: false,
                scene: "vip"
            ),
            as: VerifyPurchaseResponse.self
        ) { [weak self] result in
            guard let self = self else { return }
            self.hideLoading()
            self.isProcessingPurchase = false
            
            switch result {
            case .success(let response):
                print("✅ [Apple Pay] 购买验证成功, orderNo: \(response.orderNo ?? "unknown")")
                // 服务器验证成功后，完成交易
                StoreKitHelper.shared.finishTransaction(transactionId: transactionId)
                self.showToast("购买成功！")
                self.refreshUserInfo()
                
            case .failure(let error):
                print("❌ [Apple Pay] 验证购买失败: \(error)")
                self.showToast("支付处理中，请稍后查看")
                // ⚠️ 注意：验证失败时不要 finishTransaction，让交易留在队列中，下次启动时会再次回调
            }
        }
    }
    
    // MARK: - Apple Pay 验证 (常规购买)
    private func verifyApplePayPurchase(receipt: String, productId: String, transactionId: String) {
        let orderNo = generateOrderNo()
        print("🚀 [Apple Pay] 订单号: \(orderNo)")
        
        showLoading("确认订单中...")
        NetworkManager.shared.request(
            PurchaseAPI.applePayVerification(
                receipt: receipt, 
                productId: productId, 
                transactionId: transactionId,
                originalTransactionId: transactionId,
                orderNo: orderNo,
                isRestore: false,
                scene: "vip"
            ),
            as: VerifyPurchaseResponse.self
        ) { [weak self] result in
            guard let self = self else { return }
            self.hideLoading()
            self.isProcessingPurchase = false
            
            switch result {
            case .success(let response):
                print("✅ [Apple Pay] 购买验证成功, orderNo: \(response.orderNo ?? "unknown")")
                // 服务器验证成功后，完成交易
                StoreKitHelper.shared.finishTransaction(transactionId: transactionId)
                self.showToast("购买成功！")
                self.refreshUserInfo()
                
            case .failure(let error):
                print("❌ [Apple Pay] 验证购买失败: \(error)")
                self.showToast("支付处理中，请稍后查看")
                // ⚠️ 注意：验证失败时不要 finishTransaction，让交易留在队列中，下次启动时会再次回调
            }
        }
    }
    
    func storeKitHelper(_ helper: StoreKitHelper, didFailPurchaseProductWithError error: Error) {
        print("❌ [IAP] 购买失败: \(error)")
        isProcessingPurchase = false
        
        if let nsError = error as NSError?, nsError.code == SKError.Code.paymentCancelled.rawValue {
            showToast("已取消购买")
        } else {
            showToast("购买遇到问题，如已扣款可尝试恢复购买")
        }
    }
    
    func storeKitHelper(_ helper: StoreKitHelper, didSilentRestorePurchases productIds: [String], receipt: String) {
        print("✅ [IAP] 静默恢复购买完成: \(productIds)")
        // PurchaseManager 已经在处理恢复购买的验证，这里不需要再处理
    }
}

// MARK: - StoreKitHelperDelegate (恢复购买逻辑)
extension MemberCenterViewController {
    
    func memberViewDidClickRestore(_ view: MenberCenterView) {
        guard !isLoading && !isProcessingPurchase else { return }
        
        // 立即设置标志位，防止重复点击
        isProcessingPurchase = true
        
        // 检查是否已是会员
        if let vipInfo = currentUserVipInfo, vipInfo.vip == 1 {
            isProcessingPurchase = false
            if let expireTime = vipInfo.expireTime {
                showToast("您已是会员，\(expireTime)")
            } else {
                showToast("您已是会员，无需再次购买")
            }
            return
        }
        
        print("🔄 [IAP] 点击恢复购买")
        showLoading("恢复购买中...")
        StoreKitHelper.shared.restorePurchases()
    }
    
    func storeKitHelper(_ helper: StoreKitHelper, didRestorePurchases productIds: [String]) {
        print("✅ [IAP] 恢复购买完成: \(productIds)")
        
        if productIds.isEmpty {
            hideLoading()
            isProcessingPurchase = false
            showToast("没有可恢复的购买")
        }
        // 有可恢复的产品时，PurchaseManager 会收到通知并处理验证，这里不需要再处理
        // 只需等待 PurchaseManager 的验证结果通知即可
    }
    
    func storeKitHelper(_ helper: StoreKitHelper, didFailRestorePurchasesWithError error: Error) {
        print("❌ [IAP] 恢复购买失败: \(error)")
        hideLoading()
        isProcessingPurchase = false
        showToast("恢复购买失败: \(error.localizedDescription)")
    }
}
