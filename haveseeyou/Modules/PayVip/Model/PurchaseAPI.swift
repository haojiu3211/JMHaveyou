//
//  PurchaseAPI.swift
//  haveseeyou
//
//  内购相关接口定义
//

import Foundation
import Alamofire

// MARK: - 解锁类型枚举
enum UnlockType: Int {
    case none = 0
    case message = 1     // 私信
    case wechat = 2      // 微信
    case comment = 3     // 发布动态
    case privacy = 4     // 隐私照片/视频
}

// MARK: - 内购API
enum PurchaseAPI: APITarget {
    /// 获取产品列表
    case getProductList
    /// 验证购买凭证
    case verifyPurchase(receipt: String, productId: String)
    /// 恢复购买验证
    case restoreVerify(receipt: String)
    /// 会员中心
    case memberCenter
    /// Apple Pay 验证常规购买
    case applePayVerification(receipt: String, productId: String?, transactionId: String?, originalTransactionId: String?, orderNo: String?, isRestore: Bool, scene: String?)
    /// 创建 VIP 订单
    case createVipOrder(id: String, vipGoodsId: String, type: String)
    /// 创建活动币订单
    case createCoinOrder(goodsId: String)
    /// 金币列表
    case diamondList(type: String)
    /// 消费记录
    case consumptionRecords(type: String, page: String, limit: String)
    /// 钻石解锁
    case diamondUnlock(type: Int, toUid: Int, decCoin: Int?)
    /// 查询私聊解锁状态
    case unlockPrivateStatus(toUid: Int)
    /// 审核配置
    case auditConfig
    
    var path: String {
        switch self {
        case .getProductList:
            return "/meetv1/vip/product/list"
        case .verifyPurchase:
            return "/meetv1/vip/purchase/verify"
        case .restoreVerify:
            return "/meetv1/vip/purchase/restore"
        case .memberCenter:
            return "/memberCenter"
        case .applePayVerification:
            return "/applePayVerification"
        case .createVipOrder:
            return "/meetv1/goods/vip/order"
        case .createCoinOrder:
            return "/meetv1/goods/coin/order"
        case .diamondList:
            return "/diamondList"
        case .consumptionRecords:
            return "/consumptionRecords"
        case .diamondUnlock:
            return "/diamondUnlock"
        case .unlockPrivateStatus:
            return "/unlockPrivateStatus"
        case .auditConfig:
            return "/meetv1/version/status"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getProductList, .verifyPurchase, .restoreVerify, .memberCenter, .applePayVerification, .createVipOrder, .createCoinOrder, .diamondList, .consumptionRecords, .diamondUnlock, .unlockPrivateStatus, .auditConfig:
            return .post
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .getProductList, .memberCenter:
            return nil
        case .verifyPurchase(let receipt, let productId):
            return [
                "receipt": receipt,
                "product_id": productId
            ]
        case .restoreVerify(let receipt):
            return [
                "receipt": receipt
            ]
        case .applePayVerification(let receipt, let productId, let transactionId, let originalTransactionId, let orderNo, let isRestore, let scene):
            var params: [String: Any] = [:]
            
            // 无论是否恢复购买，都使用 receipt_data
            params["receipt_data"] = receipt
            
            // 可选参数
            if let productId = productId {
                params["product_id"] = productId
            }
            // 分别传两个不同的字段
            if let transactionId = transactionId {
                params["transaction_id"] = transactionId
            }
            if let originalTransactionId = originalTransactionId {
                params["original_transaction_id"] = originalTransactionId
            }
            if let orderNo = orderNo {
                params["order_no"] = orderNo
            }
            // scene 参数 - 常规购买或恢复 VIP 都传
            if let scene = scene {
                params["scene"] = scene
            }
            
            print("📤 [PurchaseAPI] params: \(params)")
            
            return params
        case .createVipOrder(let id, let vipGoodsId, let type):
            return [
                "id": id,
                "vip_goods_id": vipGoodsId,
                "type": type
            ]
        case .diamondList(let type):
            return [
                "type": type
            ]
        case .createCoinOrder(let goodsId):
            return [
                "goods_id": goodsId
            ]
        case .consumptionRecords(let type, let page, let limit):
            return [
                "type": type,
                "page": page,
                "limit": limit
            ]
        case .diamondUnlock(let type, let toUid, let decCoin):
            var params: [String: Any] = [
                "type": type,
                "to_uid": toUid
            ]
            if let decCoin = decCoin {
                params["dec_coin"] = decCoin
            }
            return params
        case .unlockPrivateStatus(let toUid):
            return [
                "to_uid": toUid
            ]
        case .auditConfig:
            return nil
        }
    }
    
    var encoding: ParameterEncoding {
        switch self {
        case .diamondList, .consumptionRecords:
            return URLEncoding.httpBody
        default:
            return JSONEncoding.default
        }
    }
    
    var headers: HTTPHeaders? {
        switch self {
        case .diamondList, .consumptionRecords:
            return ["Content-Type": "application/x-www-form-urlencoded"]
        default:
            return nil
        }
    }
}

// MARK: - 产品模型
struct ProductModel: Decodable {
    let id: Int?
    let productId: String?
    let title: String?
    let price: String?
    let originalPrice: String?
    let duration: Int?
    let durationUnit: String?
    let isRecommend: Bool?
    let tag: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case title
        case price
        case originalPrice = "original_price"
        case duration
        case durationUnit = "duration_unit"
        case isRecommend = "is_recommend"
        case tag
    }
}

struct ProductListResponse: Decodable {
    let list: [ProductModel]?
}

// MARK: - 验证结果模型
struct VerifyPurchaseResponse: Decodable {
    let orderNo: String?
    let success: Bool?
    let vipExpireTime: String?
    let vipLevel: Int?
    
    enum CodingKeys: String, CodingKey {
        case orderNo = "order_no"
        case success
        case vipExpireTime = "vip_expire_time"
        case vipLevel = "vip_level"
    }
}

// MARK: - 会员中心响应模型
struct MemberCenterResponse: Decodable {
    let list: [VipProductItem]?
    let info: VipUserInfo?
    let price: VipPriceInfo?
    let privilege: [VipPrivilegeItem]?
}

// MARK: - VIP产品项
struct VipProductItem: Decodable {
    let id: Int?
    let vipId: Int?
    let price: Int?
    let oldPrice: Int?
    let renewPrice: Int?
    let expire: Int?
    let startIosProductId: String?
    let renewIosProductId: String?
    let platform: Int?
    let desc: String?
    let name: String?
    let superStatus: Int?
    let status: Int?
    let dayDesc: String?
    let nameDesc: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case vipId = "vip_id"
        case price
        case oldPrice = "old_price"
        case renewPrice = "renew_price"
        case expire
        case startIosProductId = "start_ios_product_id"
        case renewIosProductId = "renew_ios_product_id"
        case platform
        case desc
        case name
        case superStatus = "super_status"
        case status
        case dayDesc = "day_desc"
        case nameDesc = "name_desc"
    }
}

// MARK: - VIP用户信息
struct VipUserInfo: Decodable {
    let vip: Int?
    let expireTime: String?
    let userId: Int?
    let usercode: String?
    let nickname: String?
    let gender: Int?
    let avatar: String?
    
    enum CodingKeys: String, CodingKey {
        case vip
        case expireTime = "expire_time"
        case userId = "user_id"
        case usercode
        case nickname
        case gender
        case avatar
    }
}

// MARK: - VIP价格信息
struct VipPriceInfo: Decodable {
    let privatePrice: Int?
    let wechatPrice: Int?
    
    enum CodingKeys: String, CodingKey {
        case privatePrice = "private_price"
        case wechatPrice = "wechat_price"
    }
}

// MARK: - VIP特权项
struct VipPrivilegeItem: Decodable {
    let id: Int?
    let imgHas: String?
    let img: String?
    let name: String?
    let des: String?
    let sort: Int?
    let status: Int?
    let showImg: String?
    let width: String?
    let height: String?
    let isShow: Int?
    let type: Int?
    let gender: Int?
    let fromPackage: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case imgHas = "img_has"
        case img
        case name
        case des
        case sort
        case status
        case showImg = "show_img"
        case width
        case height
        case isShow = "is_show"
        case type
        case gender
        case fromPackage = "from_package"
    }
}

// MARK: - 创建VIP订单响应数据
struct CreateVipOrderData: Decodable {
    let orderNo: String?
    
    enum CodingKeys: String, CodingKey {
        case orderNo = "order_no"
    }
}

// MARK: - 创建活动币订单响应数据
struct CreateCoinOrderData: Decodable {
    let orderNo: String?
    
    enum CodingKeys: String, CodingKey {
        case orderNo = "order_no"
    }
}

// MARK: - 金币列表响应模型
struct DiamondListResponse: Codable {
    let coin: Int?
    let incomeCoin: Int?
    let list: [DiamondItem]?
    
    enum CodingKeys: String, CodingKey {
        case coin
        case incomeCoin = "income_coin"
        case list
    }
}

// MARK: - 金币项
struct DiamondItem: Codable {
    let id: Int?
    let name: String?
    let price: String?
    let amount: Int?
    let reward: Int?
    let remark: String?
    let superStatus: Int?
    let iosProductId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case price
        case amount
        case reward
        case remark
        case superStatus = "super_status"
        case iosProductId = "ios_product_id"
    }
}

// MARK: - 消费记录响应模型
struct ConsumptionRecordsResponse: Decodable {
    let list: [ConsumptionRecordItem]?
    let total: Int?
    let totalPage: Int?
    let page: Int?
    
    enum CodingKeys: String, CodingKey {
        case list
        case total
        case totalPage = "total_page"
        case page
    }
}

// MARK: - 消费记录项
struct ConsumptionRecordItem: Decodable {
    let action: String?
    let project: String?
    let nickname: String?
    let giftImageUrl: String?
    let giftNameNum: String?
    let numStr: String?
    let createTime: String?
    let userId: Int?
    
    enum CodingKeys: String, CodingKey {
        case action
        case project
        case nickname
        case giftImageUrl = "gift_image_url"
        case giftNameNum = "gift_name_num"
        case numStr = "num_str"
        case createTime = "create_time"
        case userId = "user_id"
    }
}

// MARK: - 钻石解锁响应模型
struct DiamondUnlockResponse: Decodable {
    let coin: Int?
    let incomeCoin: Int?
    
    enum CodingKeys: String, CodingKey {
        case coin
        case incomeCoin = "income_coin"
    }
}

// MARK: - 查询私聊解锁状态响应模型
struct UnlockPrivateStatusResponse: Decodable {
    let isUnlocked: Int?
    
    enum CodingKeys: String, CodingKey {
        case isUnlocked = "is_unlocked"
    }
}

// MARK: - 审核配置响应模型
struct AuditConfigResponse: Decodable {
    let versionStatus: String?
    
    enum CodingKeys: String, CodingKey {
        case versionStatus = "version_status"
    }
}
