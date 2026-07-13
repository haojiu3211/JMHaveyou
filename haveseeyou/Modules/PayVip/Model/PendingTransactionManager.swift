//
//  PendingTransactionManager.swift
//  haveseeyou
//
//  未完成交易持久化管理 - 确保即使App被杀掉，付款凭证和订单信息也不会丢失
//

import Foundation

// MARK: - 待处理交易模型
struct PendingTransaction: Codable {
    let orderNo: String
    let productId: String
    let goodsId: String?
    let createTime: TimeInterval
    var transactionId: String?
    var receipt: String?
    
    enum CodingKeys: String, CodingKey {
        case orderNo
        case productId
        case goodsId
        case createTime
        case transactionId
        case receipt
    }
}

// MARK: - 待处理交易管理器
class PendingTransactionManager {
    
    static let shared = PendingTransactionManager()
    
    private let userDefaults = UserDefaults.standard
    private let pendingTransactionsKey = "pending_coin_transactions"
    
    private init() {}
    
    // MARK: - 保存待处理交易
    func savePendingTransaction(orderNo: String, productId: String, goodsId: String?) {
        var transactions = fetchAllPendingTransactions()
        
        // 先移除同 productId 的旧交易（防止重复）
        transactions.removeAll { $0.productId == productId }
        
        let transaction = PendingTransaction(
            orderNo: orderNo,
            productId: productId,
            goodsId: goodsId,
            createTime: Date().timeIntervalSince1970,
            transactionId: nil,
            receipt: nil
        )
        
        transactions.append(transaction)
        saveTransactions(transactions)
        
        print("💾 [PendingTransaction] 保存待处理交易: orderNo=\(orderNo), productId=\(productId)")
    }
    
    // MARK: - 更新交易信息（收到苹果回调后）
    func updateTransaction(productId: String, transactionId: String, receipt: String) {
        var transactions = fetchAllPendingTransactions()
        
        if let index = transactions.firstIndex(where: { $0.productId == productId }) {
            var transaction = transactions[index]
            transaction.transactionId = transactionId
            transaction.receipt = receipt
            transactions[index] = transaction
            saveTransactions(transactions)
            print("💾 [PendingTransaction] 更新交易信息: productId=\(productId), transactionId=\(transactionId)")
        }
    }
    
    // MARK: - 移除已完成的交易
    func removeTransaction(orderNo: String) {
        var transactions = fetchAllPendingTransactions()
        transactions.removeAll { $0.orderNo == orderNo }
        saveTransactions(transactions)
        print("💾 [PendingTransaction] 移除交易: orderNo=\(orderNo)")
    }
    
    // MARK: - 移除已完成的交易（通过 productId）
    func removeTransaction(byProductId productId: String) {
        var transactions = fetchAllPendingTransactions()
        transactions.removeAll { $0.productId == productId }
        saveTransactions(transactions)
        print("💾 [PendingTransaction] 移除交易: productId=\(productId)")
    }
    
    // MARK: - 获取所有待处理交易
    func fetchAllPendingTransactions() -> [PendingTransaction] {
        guard let data = userDefaults.data(forKey: pendingTransactionsKey),
              let transactions = try? JSONDecoder().decode([PendingTransaction].self, from: data) else {
            return []
        }
        return transactions
    }
    
    // MARK: - 根据 productId 获取待处理交易
    func fetchTransaction(byProductId productId: String) -> PendingTransaction? {
        return fetchAllPendingTransactions().first { $0.productId == productId }
    }
    
    // MARK: - 私有方法：保存交易列表
    private func saveTransactions(_ transactions: [PendingTransaction]) {
        if let data = try? JSONEncoder().encode(transactions) {
            userDefaults.set(data, forKey: pendingTransactionsKey)
        }
    }
    
    // MARK: - 清理过期交易（超过24小时的）
    func cleanUpExpiredTransactions() {
        let now = Date().timeIntervalSince1970
        let twentyFourHours: TimeInterval = 24 * 60 * 60
        
        var transactions = fetchAllPendingTransactions()
        let originalCount = transactions.count
        
        transactions.removeAll { now - $0.createTime > twentyFourHours }
        
        if transactions.count != originalCount {
            saveTransactions(transactions)
            print("🧹 [PendingTransaction] 清理了 \(originalCount - transactions.count) 笔过期交易")
        }
    }
}
