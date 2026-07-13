//
//  PurchaseManager.swift
//  haveseeyou
//
//  全局购买管理 - 确保续费交易无论何时收到都能通知服务器
//

import Foundation
import StoreKit

class PurchaseManager: NSObject {
    
    static let shared = PurchaseManager()
    
    // 缓存 VIP 产品 ID 列表
    private var vipProductIds: Set<String> = []
    // 缓存钻石产品 ID 列表
    private var diamondProductIds: Set<String> = []
    // 保存当前正在处理的 transactionId，以便验证成功后 finishTransaction
    private var currentTransactionId: String?
    
    private override init() {
        super.init()
        // 监听 StoreKit 通知
        addNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 通知监听
    private func addNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidPurchaseProduct(_:)),
            name: .IAPDidPurchaseProduct,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidRestorePurchases(_:)),
            name: .IAPDidRestorePurchases,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidSilentRestorePurchases(_:)),
            name: .IAPDidSilentRestorePurchases,
            object: nil
        )
    }
    
    @objc private func handleDidPurchaseProduct(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let productId = userInfo[IAPNotificationKey.productId.rawValue] as? String,
              let receipt = userInfo[IAPNotificationKey.receipt.rawValue] as? String,
              let transactionId = userInfo[IAPNotificationKey.transactionId.rawValue] as? String,
              let originalTransactionId = userInfo[IAPNotificationKey.originalTransactionId.rawValue] as? String else {
            return
        }
        
        print("✅ [PurchaseManager] 收到购买/续费交易: \(productId)")
        
        // 保存 transactionId，以便验证成功后调用 finishTransaction
        currentTransactionId = transactionId
        
        // 🔑 关键：先检查是否有持久化的钻石订单
        if let pendingTransaction = PendingTransactionManager.shared.fetchTransaction(byProductId: productId) {
            print("🚀 [PurchaseManager] 找到持久化的钻石订单，使用该订单号验证")
            // 更新持久化的订单信息
            PendingTransactionManager.shared.updateTransaction(
                productId: productId,
                transactionId: transactionId,
                receipt: receipt
            )
            // 使用持久化的订单号验证
            verifyCoinPurchaseWithPendingTransaction(
                pendingTransaction: pendingTransaction,
                receipt: receipt,
                transactionId: transactionId,
                originalTransactionId: originalTransactionId
            )
            return
        }
        
        // 判断是否是会员产品，如果是则先获取产品列表再创建订单验证
        if !vipProductIds.isEmpty {
            // 已有缓存的产品列表，直接判断
            if vipProductIds.contains(productId) {
                print("🚀 [PurchaseManager] 识别为VIP产品续费，先获取产品信息")
                fetchProductListAndVerifyPurchase(
                    productId: productId,
                    transactionId: transactionId,
                    originalTransactionId: originalTransactionId,
                    receipt: receipt,
                    isRenewal: true
                )
            } else {
                // 非会员产品，直接验证
                verifyPurchase(receipt: receipt, productId: productId, transactionId: transactionId, originalTransactionId: originalTransactionId, isRenewal: true)
            }
        } else {
            // 没有缓存，先获取产品列表
            print("🚀 [PurchaseManager] 产品列表未缓存，先获取产品信息")
            fetchProductListAndVerifyPurchase(
                productId: productId,
                transactionId: transactionId,
                originalTransactionId: originalTransactionId,
                receipt: receipt,
                isRenewal: true
            )
        }
    }
    
    @objc private func handleDidRestorePurchases(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let productIds = userInfo[IAPNotificationKey.productIds.rawValue] as? [String],
              let productId = userInfo[IAPNotificationKey.productId.rawValue] as? String,
              let transactionId = userInfo[IAPNotificationKey.transactionId.rawValue] as? String,
              let originalTransactionId = userInfo[IAPNotificationKey.originalTransactionId.rawValue] as? String else {
            return
        }
        
        print("✅ [PurchaseManager] 收到恢复购买: \(productIds)")
        
        // 保存 transactionId，以便验证成功后调用 finishTransaction
        currentTransactionId = transactionId
        
        if let receiptURL = Bundle.main.appStoreReceiptURL,
           let receiptData = try? Data(contentsOf: receiptURL) {
            // 先获取产品列表，匹配后再验证
            fetchProductListAndVerifyRestore(
                productId: productId,
                transactionId: transactionId,
                originalTransactionId: originalTransactionId,
                receipt: receiptData.base64EncodedString(),
                isRenewal: true
            )
        }
    }
    
    @objc private func handleDidSilentRestorePurchases(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let productIds = userInfo[IAPNotificationKey.productIds.rawValue] as? [String],
              let receipt = userInfo[IAPNotificationKey.receipt.rawValue] as? String,
              let productId = userInfo[IAPNotificationKey.productId.rawValue] as? String,
              let transactionId = userInfo[IAPNotificationKey.transactionId.rawValue] as? String,
              let originalTransactionId = userInfo[IAPNotificationKey.originalTransactionId.rawValue] as? String else {
            return
        }
        
        print("✅ [PurchaseManager] 收到静默恢复购买: \(productIds)")
        
        // 保存 transactionId，以便验证成功后调用 finishTransaction
        currentTransactionId = transactionId
        
        // 先获取产品列表，匹配后再验证
        fetchProductListAndVerifyRestore(
            productId: productId,
            transactionId: transactionId,
            originalTransactionId: originalTransactionId,
            receipt: receipt,
            isRenewal: true
        )
    }
    
    // MARK: - 获取产品列表并匹配产品（用于购买/续费）
    private func fetchProductListAndVerifyPurchase(productId: String, transactionId: String, originalTransactionId: String, receipt: String, isRenewal: Bool = false) {
        print("🚀 [PurchaseManager] 获取产品列表匹配购买/续费的产品")
        
        NetworkManager.shared.request(PurchaseAPI.memberCenter, as: MemberCenterResponse.self) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                // 缓存 VIP 产品 ID
                self.vipProductIds.removeAll()
                if let products = response.list, !products.isEmpty {
                    for product in products {
                        if let productId = product.startIosProductId, !productId.isEmpty {
                            self.vipProductIds.insert(productId)
                        }
                    }
                    print("✅ [PurchaseManager] 缓存 VIP 产品列表成功: \(self.vipProductIds)")
                    
                    // 找到匹配的产品
                    if let matchedProduct = products.first(where: { 
                        $0.startIosProductId == productId 
                    }) {
                        print("✅ [PurchaseManager] 找到匹配的产品: \(productId), vipId: \(matchedProduct.vipId ?? 0), vipGoodsId: \(matchedProduct.id ?? 0)")
                        // 获取订单号后验证
                        self.createVipOrderAndVerify(
                            productId: productId,
                            transactionId: transactionId,
                            originalTransactionId: originalTransactionId,
                            vipId: "\(matchedProduct.vipId ?? 0)",
                            vipGoodsId: "\(matchedProduct.id ?? 0)",
                            receipt: receipt,
                            isRenewal: isRenewal
                        )
                        return
                    }
                    print("⚠️ [PurchaseManager] 未找到匹配的产品，直接验证")
                    self.verifyPurchase(receipt: receipt, productId: productId, transactionId: transactionId, originalTransactionId: originalTransactionId, isRenewal: isRenewal)
                } else {
                    print("⚠️ [PurchaseManager] 产品列表为空，直接验证")
                    self.verifyPurchase(receipt: receipt, productId: productId, transactionId: transactionId, originalTransactionId: originalTransactionId, isRenewal: isRenewal)
                }
                
            case .failure(let error):
                print("❌ [PurchaseManager] 获取产品列表失败: \(error), 直接验证")
                self.verifyPurchase(receipt: receipt, productId: productId, transactionId: transactionId, originalTransactionId: originalTransactionId, isRenewal: isRenewal)
            }
        }
    }
    
    // MARK: - 获取产品列表并匹配产品（用于恢复购买）
    private func fetchProductListAndVerifyRestore(productId: String, transactionId: String, originalTransactionId: String, receipt: String, isRenewal: Bool = false) {
        print("🚀 [PurchaseManager] 获取产品列表匹配恢复的产品")
        
        NetworkManager.shared.request(PurchaseAPI.memberCenter, as: MemberCenterResponse.self) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                // 缓存 VIP 产品 ID
                self.vipProductIds.removeAll()
                if let products = response.list, !products.isEmpty {
                    for product in products {
                        if let productId = product.startIosProductId, !productId.isEmpty {
                            self.vipProductIds.insert(productId)
                        }
                    }
                    print("✅ [PurchaseManager] 缓存 VIP 产品列表成功: \(self.vipProductIds)")
                    
                    // 找到匹配的产品
                    if let matchedProduct = products.first(where: { 
                        $0.startIosProductId == productId 
                    }) {
                        print("✅ [PurchaseManager] 找到匹配的产品: \(productId), vipId: \(matchedProduct.vipId ?? 0), vipGoodsId: \(matchedProduct.id ?? 0)")
                        // 获取订单号后验证
                        self.createVipOrderAndVerify(
                            productId: productId,
                            transactionId: transactionId,
                            originalTransactionId: originalTransactionId,
                            vipId: "\(matchedProduct.vipId ?? 0)",
                            vipGoodsId: "\(matchedProduct.id ?? 0)",
                            receipt: receipt,
                            isRenewal: isRenewal
                        )
                        return
                    }
                    print("⚠️ [PurchaseManager] 未找到匹配的产品，直接验证")
                    self.verifyRestoreWithGeneratedOrderNo(
                        productId: productId,
                        transactionId: transactionId,
                        originalTransactionId: originalTransactionId,
                        receipt: receipt,
                        isRenewal: isRenewal
                    )
                } else {
                    print("⚠️ [PurchaseManager] 产品列表为空，直接验证")
                    self.verifyRestoreWithGeneratedOrderNo(
                        productId: productId,
                        transactionId: transactionId,
                        originalTransactionId: originalTransactionId,
                        receipt: receipt,
                        isRenewal: isRenewal
                    )
                }
                
            case .failure(let error):
                print("❌ [PurchaseManager] 获取产品列表失败: \(error), 直接验证")
                self.verifyRestoreWithGeneratedOrderNo(
                    productId: productId,
                    transactionId: transactionId,
                    originalTransactionId: originalTransactionId,
                    receipt: receipt,
                    isRenewal: isRenewal
                )
            }
        }
    }
    
    // MARK: - 创建VIP订单后验证
    private func createVipOrderAndVerify(productId: String, transactionId: String, originalTransactionId: String, vipId: String, vipGoodsId: String, receipt: String, isRenewal: Bool = false) {
        print("🚀 [PurchaseManager] 为恢复购买创建订单, isRenewal: \(isRenewal)")
        
        let orderType = isRenewal ? "start" : "none"
        print("📝 [PurchaseManager] 创建订单 type: \(orderType)")
        
        NetworkManager.shared.request(
            PurchaseAPI.createVipOrder(id: vipId, vipGoodsId: vipGoodsId, type: orderType),
            as: CreateVipOrderData.self
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let orderData):
                if let orderNo = orderData.orderNo {
                    print("✅ [PurchaseManager] 获取订单成功: \(orderNo)")
                    self.verifyRestoreWithOrderNo(
                        receipt: receipt,
                        orderNo: orderNo,
                        productId: productId,
                        transactionId: transactionId,
                        originalTransactionId: originalTransactionId,
                        isRenewal: isRenewal
                    )
                } else {
                    print("⚠️ [PurchaseManager] 获取订单失败，用生成的订单号验证")
                    self.verifyRestoreWithGeneratedOrderNo(
                        productId: productId,
                        transactionId: transactionId,
                        originalTransactionId: originalTransactionId,
                        receipt: receipt,
                        isRenewal: isRenewal
                    )
                }
                
            case .failure(let error):
                print("❌ [PurchaseManager] 创建订单失败: \(error), 用生成的订单号验证")
                self.verifyRestoreWithGeneratedOrderNo(
                    productId: productId,
                    transactionId: transactionId,
                    originalTransactionId: originalTransactionId,
                    receipt: receipt,
                    isRenewal: isRenewal
                )
            }
        }
    }
    
    // MARK: - 带订单号验证恢复购买
    private func verifyRestoreWithOrderNo(receipt: String, orderNo: String, productId: String, transactionId: String, originalTransactionId: String, isRenewal: Bool = false) {
        print("🚀 [PurchaseManager] 验证恢复购买 - 订单号: \(orderNo)")
        
        // 发送开始验证通知
        if isRenewal {
            NotificationCenter.default.post(
                name: .IAPDidStartVerification,
                object: self,
                userInfo: [IAPNotificationKey.isRenewal.rawValue: true]
            )
        }
        
        NetworkManager.shared.request(
            PurchaseAPI.applePayVerification(
                receipt: receipt,
                productId: productId,
                transactionId: transactionId,
                originalTransactionId: originalTransactionId,
                orderNo: orderNo,
                isRestore: true,
                scene: self.scene(for: productId)
            ),
            as: VerifyPurchaseResponse.self
        ) { [weak self] result in
            guard let self = self else { return }
            // 发送结束验证通知
            if isRenewal {
                NotificationCenter.default.post(
                    name: .IAPDidFinishVerification,
                    object: self,
                    userInfo: [IAPNotificationKey.isRenewal.rawValue: true]
                )
            }
            self.handleVerifyResult(result)
        }
    }
    
    // MARK: - 带生成的订单号验证恢复购买（备用）
    private func verifyRestoreWithGeneratedOrderNo(productId: String, transactionId: String, originalTransactionId: String, receipt: String, isRenewal: Bool = false) {
        let orderNo = generateOrderNo()
        print("🚀 [PurchaseManager] 验证恢复购买 - 生成订单号: \(orderNo)")
        
        // 发送开始验证通知
        if isRenewal {
            NotificationCenter.default.post(
                name: .IAPDidStartVerification,
                object: self,
                userInfo: [IAPNotificationKey.isRenewal.rawValue: true]
            )
        }
        
        NetworkManager.shared.request(
            PurchaseAPI.applePayVerification(
                receipt: receipt,
                productId: productId,
                transactionId: transactionId,
                originalTransactionId: originalTransactionId,
                orderNo: orderNo,
                isRestore: true,
                scene: self.scene(for: productId)
            ),
            as: VerifyPurchaseResponse.self
        ) { [weak self] result in
            guard let self = self else { return }
            // 发送结束验证通知
            if isRenewal {
                NotificationCenter.default.post(
                    name: .IAPDidFinishVerification,
                    object: self,
                    userInfo: [IAPNotificationKey.isRenewal.rawValue: true]
                )
            }
            self.handleVerifyResult(result)
        }
    }
    
    // MARK: - 处理验证结果
    private func handleVerifyResult(_ result: Result<VerifyPurchaseResponse, APIError>) {
        switch result {
        case .success(let response):
            // 只要 NetworkManager 返回了 .success，就表示验证成功（因为 code == 0 已在 NetworkManager 中校验）
            print("✅ [PurchaseManager] 恢复购买验证成功, orderNo: \(response.orderNo ?? "unknown")")
            
            // 服务器验证成功后，完成交易
            if let transactionId = currentTransactionId {
                StoreKitHelper.shared.finishTransaction(transactionId: transactionId)
                currentTransactionId = nil
            }
            
            // 发送验证成功通知，由 ViewController 负责刷新用户信息
            NotificationCenter.default.post(name: .IAPDidVerifyRestoreSuccess, object: self)
            
        case .failure(let error):
            print("❌ [PurchaseManager] 恢复购买验证失败: \(error)")
            // ⚠️ 注意：验证失败时不要 finishTransaction，让交易留在队列中，下次启动时会再次回调
            
            // 发送验证失败通知
            NotificationCenter.default.post(name: .IAPDidVerifyRestoreFail, object: self)
        }
    }
    
    // MARK: - 验证购买（常规购买）
    private func verifyPurchase(receipt: String, productId: String, transactionId: String, originalTransactionId: String, isRenewal: Bool = false) {
        let orderNo = generateOrderNo()
        print("🚀 [PurchaseManager] 验证购买 - 订单号: \(orderNo)")
        
        // 发送开始验证通知（只在自动续费时发送）
        if isRenewal {
            NotificationCenter.default.post(
                name: .IAPDidStartVerification,
                object: self,
                userInfo: [IAPNotificationKey.isRenewal.rawValue: true]
            )
        }
        
        NetworkManager.shared.request(
            PurchaseAPI.applePayVerification(
                receipt: receipt,
                productId: productId,
                transactionId: transactionId,
                originalTransactionId: originalTransactionId,
                orderNo: orderNo,
                isRestore: false,
                scene: self.scene(for: productId)
            ),
            as: VerifyPurchaseResponse.self
        ) { [weak self] result in
            guard let self = self else { return }
            
            // 发送结束验证通知（只在自动续费时发送）
            if isRenewal {
                NotificationCenter.default.post(
                    name: .IAPDidFinishVerification,
                    object: self,
                    userInfo: [IAPNotificationKey.isRenewal.rawValue: true]
                )
            }
            
            switch result {
            case .success(let response):
                print("✅ [PurchaseManager] 购买验证成功, orderNo: \(response.orderNo ?? "unknown")")
                
                // 服务器验证成功后，完成交易
                if let transactionId = self.currentTransactionId {
                    StoreKitHelper.shared.finishTransaction(transactionId: transactionId)
                    self.currentTransactionId = nil
                }
                
                // 静默刷新用户信息
                self.refreshMemberCenter()
                
            case .failure(let error):
                print("❌ [PurchaseManager] 验证购买失败: \(error)")
                // ⚠️ 注意：验证失败时不要 finishTransaction，让交易留在队列中，下次启动时会再次回调
            }
        }
    }
    
    // MARK: - 刷新会员中心（用于验证成功后更新用户信息）
    private func refreshMemberCenter() {
        NetworkManager.shared.request(PurchaseAPI.memberCenter, as: MemberCenterResponse.self) { result in
            switch result {
            case .success(let response):
                print("✅ [PurchaseManager] 会员信息刷新成功")
                // 更新本地用户信息
                if let info = response.info {
                    UserManager.shared.updateUserInfo(
                        nickname: info.nickname,
                        avatar: info.avatar,
                        vip: info.vip
                    )
                }
            case .failure(let error):
                print("❌ [PurchaseManager] 会员信息刷新失败: \(error)")
            }
        }
    }
    
    // MARK: - 获取 VIP 产品列表
    func fetchVipProducts() {
        NetworkManager.shared.request(PurchaseAPI.memberCenter, as: MemberCenterResponse.self) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                if let products = response.list, !products.isEmpty {
                    self.vipProductIds.removeAll()
                    for product in products {
                        if let productId = product.startIosProductId, !productId.isEmpty {
                            self.vipProductIds.insert(productId)
                        }
                    }
                    print("✅ [PurchaseManager] 缓存 VIP 产品列表成功: \(self.vipProductIds)")
                }
            case .failure(let error):
                print("❌ [PurchaseManager] 获取 VIP 产品列表失败: \(error)")
            }
        }
    }
    
    // MARK: - 获取钻石产品列表
    func fetchDiamondProducts() {
        NetworkManager.shared.request(PurchaseAPI.diamondList(type: "4"), as: DiamondListResponse.self) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                if let products = response.list, !products.isEmpty {
                    self.diamondProductIds.removeAll()
                    for product in products {
                        if let productId = product.iosProductId, !productId.isEmpty {
                            self.diamondProductIds.insert(productId)
                        }
                    }
                    print("✅ [PurchaseManager] 缓存钻石产品列表成功: \(self.diamondProductIds)")
                }
            case .failure(let error):
                print("❌ [PurchaseManager] 获取钻石产品列表失败: \(error)")
            }
        }
    }
    
    // MARK: - 更新钻石产品缓存（从外部传入）
    func updateDiamondProductCache(with products: [DiamondItem]) {
        self.diamondProductIds.removeAll()
        for product in products {
            if let productId = product.iosProductId, !productId.isEmpty {
                self.diamondProductIds.insert(productId)
            }
        }
        print("✅ [PurchaseManager] 更新钻石产品缓存成功: \(self.diamondProductIds)")
    }
    
    // MARK: - 根据产品 ID 确定 scene
    private func scene(for productId: String) -> String {
        if vipProductIds.contains(productId) {
            return "vip"
        }
        if diamondProductIds.contains(productId) {
            return ""
        }
        // 默认返回空字符串
        return ""
    }
    
    // MARK: - 生成订单号
    private func generateOrderNo() -> String {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let random = String(format: "%06d", arc4random_uniform(1000000))
        return "iOS\(timestamp)\(random)"
    }
    
    // MARK: - 使用持久化的订单验证钻石购买
    private func verifyCoinPurchaseWithPendingTransaction(
        pendingTransaction: PendingTransaction,
        receipt: String,
        transactionId: String,
        originalTransactionId: String
    ) {
        print("🚀 [PurchaseManager] 验证钻石购买 - 持久化订单号: \(pendingTransaction.orderNo)")
        
        NetworkManager.shared.request(
            PurchaseAPI.applePayVerification(
                receipt: receipt,
                productId: pendingTransaction.productId,
                transactionId: transactionId,
                originalTransactionId: originalTransactionId,
                orderNo: pendingTransaction.orderNo,
                isRestore: false,
                scene: ""
            ),
            as: VerifyPurchaseResponse.self
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                print("✅ [PurchaseManager] 钻石购买验证成功, orderNo: \(response.orderNo ?? "unknown")")
                
                // 服务器验证成功后，完成交易
                if let transactionId = self.currentTransactionId {
                    StoreKitHelper.shared.finishTransaction(transactionId: transactionId)
                    self.currentTransactionId = nil
                }
                
                // 🔑 关键：移除持久化的交易记录
                PendingTransactionManager.shared.removeTransaction(orderNo: pendingTransaction.orderNo)
                
                // 静默刷新钻石余额
                self.refreshDiamondList()
                
            case .failure(let error):
                print("❌ [PurchaseManager] 钻石购买验证失败: \(error)")
                // ⚠️ 注意：验证失败时不要 finishTransaction，让交易留在队列中，下次启动时会再次回调
            }
        }
    }
    
    // MARK: - 刷新钻石列表
    private func refreshDiamondList() {
        NetworkManager.shared.request(PurchaseAPI.diamondList(type: "4"), as: DiamondListResponse.self) { result in
            switch result {
            case .success(let response):
                print("✅ [PurchaseManager] 钻石余额刷新成功")
                // 更新本地缓存
                if let coin = response.coin {
                    UserDefaults.standard.set(coin, forKey: "mine_coin")
                }
            case .failure(let error):
                print("❌ [PurchaseManager] 钻石余额刷新失败: \(error)")
            }
        }
    }
    
    // MARK: - 检查并处理未完成的交易（启动时调用）
    func checkAndProcessPendingTransactions() {
        print("🔍 [PurchaseManager] 检查未完成的交易...")
        
        // 先清理过期交易
        PendingTransactionManager.shared.cleanUpExpiredTransactions()
        
        let pendingTransactions = PendingTransactionManager.shared.fetchAllPendingTransactions()
        print("🔍 [PurchaseManager] 找到 \(pendingTransactions.count) 笔待处理交易")
        
        // 因为 StoreKit 会在启动时自动回调未 finish 的交易，我们不需要主动做什么
        // 只需要确保 productIds 缓存是最新的即可
        fetchDiamondProducts()
        fetchVipProducts()
    }
}
