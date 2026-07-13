//
//  StoreKitHelper.swift
//  haveseeyou
//
//  内购核心管理器 - 负责 StoreKit 相关操作
//

import StoreKit
import Foundation

// MARK: - 通知名称
extension Notification.Name {
    static let IAPDidFetchProducts = Notification.Name("IAPDidFetchProducts")
    static let IAPDidFailFetchProducts = Notification.Name("IAPDidFailFetchProducts")
    static let IAPDidPurchaseProduct = Notification.Name("IAPDidPurchaseProduct")
    static let IAPDidFailPurchaseProduct = Notification.Name("IAPDidFailPurchaseProduct")
    static let IAPDidRestorePurchases = Notification.Name("IAPDidRestorePurchases")
    static let IAPDidFailRestorePurchases = Notification.Name("IAPDidFailRestorePurchases")
    static let IAPDidSilentRestorePurchases = Notification.Name("IAPDidSilentRestorePurchases")
    static let IAPDidVerifyRestoreSuccess = Notification.Name("IAPDidVerifyRestoreSuccess")
    static let IAPDidVerifyRestoreFail = Notification.Name("IAPDidVerifyRestoreFail")
    static let IAPDidStartVerification = Notification.Name("IAPDidStartVerification")
    static let IAPDidFinishVerification = Notification.Name("IAPDidFinishVerification")
}

// MARK: - 通知 UserInfo Keys
enum IAPNotificationKey: String {
    case products
    case error
    case productId
    case receipt
    case transactionId
    case originalTransactionId
    case productIds
    case isRenewal
}

// MARK: - 内购产品模型
struct IAPProduct {
    let productId: String
    let title: String
    let price: String
    let priceLocale: Locale
    let product: SKProduct
    
    init(product: SKProduct) {
        self.product = product
        self.productId = product.productIdentifier
        self.title = product.localizedTitle
        self.price = IAPProduct.formatPrice(product.price, locale: product.priceLocale)
        self.priceLocale = product.priceLocale
    }
    
    private static func formatPrice(_ price: NSDecimalNumber, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: price) ?? "\(price)"
    }
}

// MARK: - 内购代理（保留向后兼容）
protocol StoreKitHelperDelegate: AnyObject {
    func storeKitHelper(_ helper: StoreKitHelper, didFetchProducts products: [IAPProduct])
    func storeKitHelper(_ helper: StoreKitHelper, didFailFetchProductsWithError error: Error)
    func storeKitHelper(_ helper: StoreKitHelper, didPurchaseProduct productId: String, receipt: String, transactionId: String)
    func storeKitHelper(_ helper: StoreKitHelper, didFailPurchaseProductWithError error: Error)
    func storeKitHelper(_ helper: StoreKitHelper, didRestorePurchases productIds: [String])
    func storeKitHelper(_ helper: StoreKitHelper, didFailRestorePurchasesWithError error: Error)
    func storeKitHelper(_ helper: StoreKitHelper, didSilentRestorePurchases productIds: [String], receipt: String)
}

// MARK: - StoreKitHelperDelegate 默认实现（使方法可选）
extension StoreKitHelperDelegate {
    func storeKitHelper(_ helper: StoreKitHelper, didFetchProducts products: [IAPProduct]) {}
    func storeKitHelper(_ helper: StoreKitHelper, didFailFetchProductsWithError error: Error) {}
    func storeKitHelper(_ helper: StoreKitHelper, didPurchaseProduct productId: String, receipt: String, transactionId: String) {}
    func storeKitHelper(_ helper: StoreKitHelper, didFailPurchaseProductWithError error: Error) {}
    func storeKitHelper(_ helper: StoreKitHelper, didRestorePurchases productIds: [String]) {}
    func storeKitHelper(_ helper: StoreKitHelper, didFailRestorePurchasesWithError error: Error) {}
    func storeKitHelper(_ helper: StoreKitHelper, didSilentRestorePurchases productIds: [String], receipt: String) {}
}

// MARK: - StoreKitHelper 主类
class StoreKitHelper: NSObject {
    
    static let shared = StoreKitHelper()
    
    weak var delegate: StoreKitHelperDelegate?
    
    private var productsRequest: SKProductsRequest?
    private var products: [String: IAPProduct] = [:]
    private var isPurchasing = false
    private var isSilentRestore = false
    private var purchasingProductId: String? // 当前正在购买的产品ID
    private var purchaseTimeoutTimer: Timer? // 购买超时计时器
    private var pendingTransactions: [String: SKPaymentTransaction] = [:] // 缓存待验证的交易
    
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    // MARK: - 重置购买状态
    private func resetPurchaseState() {
        purchaseTimeoutTimer?.invalidate()
        purchaseTimeoutTimer = nil
        isPurchasing = false
        purchasingProductId = nil
    }
    
    // MARK: - 强制重置所有状态（包括清理 pendingTransactions）
    func forceResetAllState() {
        print("🧹 [IAP] 强制重置所有状态")
        purchaseTimeoutTimer?.invalidate()
        purchaseTimeoutTimer = nil
        isPurchasing = false
        purchasingProductId = nil
        isSilentRestore = false
        
        // 清理 pendingTransactions 中所有的交易
        for (transactionId, _) in pendingTransactions {
            print("🧹 [IAP] 从 pendingTransactions 中移除: \(transactionId)")
        }
        pendingTransactions.removeAll()
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    // MARK: - 获取产品信息
    func fetchProducts(productIds: Set<String>) {
        guard !productIds.isEmpty else {
            delegate?.storeKitHelper(self, didFetchProducts: [])
            return
        }
        
        productsRequest?.cancel()
        productsRequest = SKProductsRequest(productIdentifiers: productIds)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    // MARK: - 购买产品
    func purchaseProduct(productId: String) {
        // 用户显式点击购买时，先强制重置一下状态！
        // 防止历史交易或异常状态导致无法购买
        if isPurchasing {
            print("⚠️ [IAP] 发现购买状态异常，强制重置")
            forceResetAllState()
        }
        
        guard SKPaymentQueue.canMakePayments() else {
            let error = NSError(domain: "StoreKitError", code: -1, userInfo: [NSLocalizedDescriptionKey: "设备不允许内购"])
            delegate?.storeKitHelper(self, didFailPurchaseProductWithError: error)
            return
        }
        
        guard let product = products[productId] else {
            let error = NSError(domain: "StoreKitError", code: -2, userInfo: [NSLocalizedDescriptionKey: "未找到产品信息"])
            delegate?.storeKitHelper(self, didFailPurchaseProductWithError: error)
            return
        }
        
        isPurchasing = true
        purchasingProductId = productId // 记录当前正在购买的产品ID
        
        // 添加超时机制，30秒后自动重置状态（防止沙盒环境异常导致卡死）
        purchaseTimeoutTimer?.invalidate()
        purchaseTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            print("⚠️ [IAP] 购买超时，自动重置状态")
            self.resetPurchaseState()
        }
        
        let payment = SKPayment(product: product.product)
        SKPaymentQueue.default().add(payment)
        print("🚀 [IAP] 开始购买产品: \(productId)")
    }
    
    // MARK: - 恢复购买
    func restorePurchases() {
        isSilentRestore = false
        SKPaymentQueue.default().restoreCompletedTransactions()
        print("🔄 [IAP] 开始恢复购买")
    }
    
    // MARK: - 静默恢复购买（App启动时调用，不显示UI）
    func silentRestorePurchases() {
        isSilentRestore = true
        SKPaymentQueue.default().restoreCompletedTransactions()
        print("🔄 [IAP] 开始静默恢复购买")
    }
    
    // MARK: - 完成交易（服务器验证成功后调用）
    func finishTransaction(transactionId: String) {
        if let transaction = pendingTransactions[transactionId] {
            SKPaymentQueue.default().finishTransaction(transaction)
            pendingTransactions.removeValue(forKey: transactionId)
            print("✅ [IAP] 完成交易: \(transactionId)")
        } else {
            print("⚠️ [IAP] 未找到待完成的交易: \(transactionId)")
        }
    }
    
    // MARK: - 验证收据
    private func fetchReceipt() -> String? {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: receiptURL.path) else {
            return nil
        }
        
        do {
            let receiptData = try Data(contentsOf: receiptURL)
            return receiptData.base64EncodedString()
        } catch {
            print("❌ [IAP] 读取收据失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 清理积压的交易（只 finish 非 purchasing 状态的旧交易）
    func cleanUpStaleTransactions() {
        let transactions = SKPaymentQueue.default().transactions
        print("🧹 [IAP] 检查积压交易，共 \(transactions.count) 笔")
        
        for transaction in transactions {
            let transactionId = transaction.transactionIdentifier ?? "unknown"
            
            switch transaction.transactionState {
            case .purchased, .failed, .restored:
                // 对于这些状态的交易，如果不在 pendingTransactions 中，说明是旧交易，直接 finish
                if pendingTransactions[transactionId] == nil {
                    print("🧹 [IAP] 清理积压交易: \(transactionId), state: \(transaction.transactionState.rawValue)")
                    SKPaymentQueue.default().finishTransaction(transaction)
                }
            case .purchasing, .deferred:
                // 正在处理的交易，跳过
                print("⏳ [IAP] 跳过正在处理的交易: \(transactionId)")
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - 刷新收据（如果没有收据）
    private func refreshReceipt() {
        let request = SKReceiptRefreshRequest()
        request.delegate = self
        request.start()
    }
}

// MARK: - SKProductsRequestDelegate
extension StoreKitHelper: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("✅ [IAP] 获取产品列表成功")
        
        var fetchedProducts: [IAPProduct] = []
        for product in response.products {
            let iapProduct = IAPProduct(product: product)
            fetchedProducts.append(iapProduct)
            products[iapProduct.productId] = iapProduct
            print("  - \(iapProduct.productId): \(iapProduct.title) - \(iapProduct.price)")
        }
        
        if !response.invalidProductIdentifiers.isEmpty {
            print("⚠️ [IAP] 无效产品ID: \(response.invalidProductIdentifiers)")
        }
        
        DispatchQueue.main.async {
            // 发送通知
            NotificationCenter.default.post(
                name: .IAPDidFetchProducts,
                object: self,
                userInfo: [IAPNotificationKey.products.rawValue: fetchedProducts]
            )
            // 调用 delegate（向后兼容）
            self.delegate?.storeKitHelper(self, didFetchProducts: fetchedProducts)
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("❌ [IAP] 请求失败: \(error)")
        
        DispatchQueue.main.async {
            if request is SKProductsRequest {
                NotificationCenter.default.post(
                    name: .IAPDidFailFetchProducts,
                    object: self,
                    userInfo: [IAPNotificationKey.error.rawValue: error]
                )
                self.delegate?.storeKitHelper(self, didFailFetchProductsWithError: error)
            } else {
                NotificationCenter.default.post(
                    name: .IAPDidFailRestorePurchases,
                    object: self,
                    userInfo: [IAPNotificationKey.error.rawValue: error]
                )
                self.delegate?.storeKitHelper(self, didFailRestorePurchasesWithError: error)
            }
        }
    }
}

// MARK: - SKPaymentTransactionObserver
extension StoreKitHelper: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                handlePurchased(transaction: transaction)
            case .failed:
                handleFailed(transaction: transaction)
            case .restored:
                handleRestored(transaction: transaction)
            case .deferred:
                print("⏳ [IAP] 交易延期: \(transaction.payment.productIdentifier)")
            case .purchasing:
                print("🛒 [IAP] 正在购买: \(transaction.payment.productIdentifier)")
            @unknown default:
                break
            }
        }
    }
    
    private func handlePurchased(transaction: SKPaymentTransaction) {
        let transactionId = transaction.transactionIdentifier ?? UUID().uuidString
        let productId = transaction.payment.productIdentifier
        
        // 检查是否正在处理这个交易（防止重复处理）
        guard pendingTransactions[transactionId] == nil else {
            print("⚠️ [IAP] 交易正在处理中，跳过: \(transactionId)")
            return
        }
        
        // 提取两个交易 ID
        let originalTransactionId = transaction.original?.transactionIdentifier ?? transactionId
        
        // 判断是否是自动续费：如果有 original 并且与当前不同，很可能是续费
        let isRenewal = (transaction.original != nil && originalTransactionId != transactionId)
        
        print("✅ [IAP] 购买成功: \(productId), transactionId: \(transactionId), isRenewal: \(isRenewal)")
        
        // 如果用户正在购买某个产品，只处理匹配的那个产品，其他的直接 finish
        if let purchasingProductId = self.purchasingProductId {
            guard productId == purchasingProductId else {
                print("⚠️ [IAP] 不匹配当前购买的产品，跳过: \(productId)，期望: \(purchasingProductId)")
                SKPaymentQueue.default().finishTransaction(transaction)
                return
            }
        }
        
        // 缓存交易
        pendingTransactions[transactionId] = transaction
        
        if let receipt = fetchReceipt() {
            DispatchQueue.main.async {
                // 如果有 delegate（用户在购买页面），只调用 delegate，不发送通知
                if let delegate = self.delegate {
                    print("✅ [IAP] 有 delegate，调用 delegate 处理")
                    delegate.storeKitHelper(
                        self,
                        didPurchaseProduct: productId,
                        receipt: receipt,
                        transactionId: transactionId
                    )
                } else {
                    // 没有 delegate，发送通知让 PurchaseManager 处理（用于自动续费）
                    print("✅ [IAP] 无 delegate，发送通知让 PurchaseManager 处理")
                    NotificationCenter.default.post(
                        name: .IAPDidPurchaseProduct,
                        object: self,
                        userInfo: [
                            IAPNotificationKey.productId.rawValue: productId,
                            IAPNotificationKey.receipt.rawValue: receipt,
                            IAPNotificationKey.transactionId.rawValue: transactionId,
                            IAPNotificationKey.originalTransactionId.rawValue: originalTransactionId,
                            IAPNotificationKey.isRenewal.rawValue: isRenewal
                        ]
                    )
                }
            }
        } else {
            refreshReceipt()
        }
        
        // ⚠️ 注意：这里不要立即 finishTransaction，等服务器验证成功后再 finish！
        resetPurchaseState() // 统一重置购买状态
    }
    
    private func handleFailed(transaction: SKPaymentTransaction) {
        print("❌ [IAP] 购买失败: \(transaction.payment.productIdentifier), Error: \(String(describing: transaction.error))")
        
        let error = transaction.error ?? NSError(domain: "StoreKitError", code: -3, userInfo: [NSLocalizedDescriptionKey: "购买失败"])
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .IAPDidFailPurchaseProduct,
                object: self,
                userInfo: [IAPNotificationKey.error.rawValue: error]
            )
            self.delegate?.storeKitHelper(self, didFailPurchaseProductWithError: error)
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
        resetPurchaseState() // 统一重置购买状态
    }
    
    private func handleRestored(transaction: SKPaymentTransaction) {
        let transactionId = transaction.transactionIdentifier ?? UUID().uuidString
        
        // 检查是否正在处理这个交易（防止重复处理）
        guard pendingTransactions[transactionId] == nil else {
            print("⚠️ [IAP] 恢复交易正在处理中，跳过: \(transactionId)")
            return
        }
        
        print("🔄 [IAP] 恢复购买: \(transaction.payment.productIdentifier)")
        
        // 缓存交易
        pendingTransactions[transactionId] = transaction
        
        // ⚠️ 注意：这里不要立即 finishTransaction，等服务器验证成功后再 finish！
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("✅ [IAP] 恢复购买完成")
        
        // 去重处理恢复的产品，只取第一个交易的productId（去重）
        var processedProductIds = Set<String>()
        var uniqueRestoredTransactions: [(productId: String, transactionId: String, originalTransactionId: String)] = []
        
        for (index, transaction) in queue.transactions.enumerated() {
            guard transaction.transactionState == .restored else {
                continue
            }
            
            let originalTransactionId = transaction.original?.transactionIdentifier
            let currentTransactionId = transaction.transactionIdentifier
            
            print("🔄 [IAP] 交易 \(index):")
            print("   - productId: \(transaction.payment.productIdentifier)")
            print("   - original.transactionId: \(originalTransactionId ?? "nil")")
            print("   - transaction.transactionId: \(currentTransactionId ?? "nil")")
            
            guard let safeTransactionId = currentTransactionId,
                  let safeOriginalTransactionId = originalTransactionId ?? currentTransactionId,
                  !processedProductIds.contains(transaction.payment.productIdentifier) else {
                continue
            }
            
            let productId = transaction.payment.productIdentifier
            processedProductIds.insert(productId)
            uniqueRestoredTransactions.append((productId: productId, transactionId: safeTransactionId, originalTransactionId: safeOriginalTransactionId))
        }
        
        let uniqueProductIds = uniqueRestoredTransactions.map { $0.productId }
        
        print("✅ [IAP] 恢复了 \(queue.transactions.filter { $0.transactionState == .restored }.count) 笔交易，去重后 \(uniqueProductIds.count) 个产品")
        
        DispatchQueue.main.async {
            if self.isSilentRestore {
                if let receipt = self.fetchReceipt(), !uniqueProductIds.isEmpty {
                    // 对于静默恢复，我们取第一个产品和对应的两个transactionId
                    let firstTransaction = uniqueRestoredTransactions[0]
                    NotificationCenter.default.post(
                        name: .IAPDidSilentRestorePurchases,
                        object: self,
                        userInfo: [
                            IAPNotificationKey.productIds.rawValue: uniqueProductIds,
                            IAPNotificationKey.receipt.rawValue: receipt,
                            IAPNotificationKey.productId.rawValue: firstTransaction.productId,
                            IAPNotificationKey.transactionId.rawValue: firstTransaction.transactionId,
                            IAPNotificationKey.originalTransactionId.rawValue: firstTransaction.originalTransactionId
                        ]
                    )
                    self.delegate?.storeKitHelper(self, didSilentRestorePurchases: uniqueProductIds, receipt: receipt)
                }
            } else {
                // 对于主动恢复，我们取第一个产品和对应的两个transactionId
                if !uniqueProductIds.isEmpty {
                    let firstTransaction = uniqueRestoredTransactions[0]
                    NotificationCenter.default.post(
                        name: .IAPDidRestorePurchases,
                        object: self,
                        userInfo: [
                            IAPNotificationKey.productIds.rawValue: uniqueProductIds,
                            IAPNotificationKey.productId.rawValue: firstTransaction.productId,
                            IAPNotificationKey.transactionId.rawValue: firstTransaction.transactionId,
                            IAPNotificationKey.originalTransactionId.rawValue: firstTransaction.originalTransactionId
                        ]
                    )
                } else {
                    NotificationCenter.default.post(
                        name: .IAPDidRestorePurchases,
                        object: self,
                        userInfo: [IAPNotificationKey.productIds.rawValue: uniqueProductIds]
                    )
                }
                self.delegate?.storeKitHelper(self, didRestorePurchases: uniqueProductIds)
            }
            self.isSilentRestore = false
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print("❌ [IAP] 恢复购买失败: \(error)")
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .IAPDidFailRestorePurchases,
                object: self,
                userInfo: [IAPNotificationKey.error.rawValue: error]
            )
            self.delegate?.storeKitHelper(self, didFailRestorePurchasesWithError: error)
        }
    }
}

// MARK: - SKRequestDelegate (收据刷新)
extension StoreKitHelper: SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        print("✅ [IAP] 收据刷新完成")
        
        if let receipt = fetchReceipt() {
            print("📄 [IAP] 已获取收据")
        }
    }
}
