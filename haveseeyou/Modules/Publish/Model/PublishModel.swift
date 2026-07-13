//
//  PublishModel.swift
//  haveseeyou
//
//  发布活动数据模型
//

import Foundation

/// 性别要求枚举
enum GenderRequirement: String, Codable {
    case male = "男"
    case female = "女"
    case unlimited = "不限"
}

/// 活动时间类型
enum ActivityTimeType: String, Codable {
    case weekend = "周末假期"        // 周末假期
    case longTerm = "长期有效"       // 长期有效
    case specific = "具体时间"       // 具体时间
}

/// 活动费用类型
enum ActivityExpenseType: String, Codable {
    case free = "免费"              // 免费
    case average = "平摊费用"        // 平摊费用
    case yourBuy = "由你买单"        // 由你买单
    case myBuy = "我买单"            // 我买单
}

/// 活动状态（我的页面展示用）
enum MyActivityStatus: String, Codable {
    case ongoing  = "进行中"        // 进行中
    case pending  = "待审核"        // 待审核
    case expired  = "已过期"        // 已过期
}

/// 发布活动数据模型
struct PublishModel: Codable {
    // MARK: - 基础信息
    var id: String?                          // 活动ID（编辑时使用）
    var coverImages: [String] = []           // 封面图片（本地路径或URL）
    var title: String = ""                   // 活动标题
    var description: String = ""             // 活动正文
    
    // MARK: - 参与信息
    var participantCount: Int = 100            // 活动人数 人数(最少1人）
    var genderRequirement: GenderRequirement = .unlimited  // 性别要求
    
    // MARK: - 时间和地点
    var timeType: ActivityTimeType = .longTerm  // 时间类型
    var specificTime: Date?                  // 具体时间（当 timeType == .specific 时）
    var city: String = ""                    // 城市
    var detailedLocation: String = ""        // 详细地址
    // MARK: - 活动类型
    var category: String = ""                // 活动类型(逗号分隔)
    
    // MARK: - 活动费用
    var expenseType: ActivityExpenseType = .free  // 活动费用类型，默认平摊费用
    
    // MARK: - 其他
    var isAgreedToTerms: Bool = false        // 是否同意条款
    var status: MyActivityStatus = .pending  // 活动状态，默认待审核
    var createdAt: Date = Date()             // 创建时间
    var updatedAt: Date = Date()             // 更新时间
    
    
    
    // MARK: - 计算属性
    /// 检查是否所有必填字段都已填写
    var isComplete: Bool {
        !title.isEmpty &&
        !description.isEmpty &&
        participantCount > 0 &&
        !city.isEmpty &&
        !detailedLocation.isEmpty &&
        !category.isEmpty &&
        isAgreedToTerms
    }
    
    /// 获取时间显示文本
    var timeDisplayText: String {
        switch timeType {
        case .weekend:
            return "周末假期"
        case .longTerm:
            return "长期有效"
        case .specific:
            if let date = specificTime {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm"
                return formatter.string(from: date)
            }
            return "未设置"
        }
    }
    
    /// 获取地点显示文本
    var locationDisplayText: String {
        if city.isEmpty {
            return "未设置"
        }
        return "\(city)"
    }
    
    /// 转换为发布接口所需的参数字典
    func toPublishParams() -> [String: Any] {
        var params: [String: Any] = [:]
        
        // 基础信息
        params["title"] = title
        params["content"] = description
        
        // 图片（逗号分隔）
        params["images"] = coverImages.joined(separator: ",")
        
        // 人数
        params["people_num"] = "\(participantCount)"
        
        // 性别: 0=未知, 1=女, 2=男
        let genderValue: String
        switch genderRequirement {
        case .female:
            genderValue = "1"
        case .male:
            genderValue = "2"
        case .unlimited:
            genderValue = "0"
        }
        params["gender"] = genderValue
        
        // 活动时间: 长期传 permanent，其他传时间戳
        let activityTime: String
        switch timeType {
        case .longTerm:
            activityTime = "permanent"
        case .weekend:
            activityTime = "permanent"
        case .specific:
            if let date = specificTime {
                activityTime = "\(Int(date.timeIntervalSince1970))"
            } else {
                activityTime = "permanent"
            }
        }
        params["activity_time"] = activityTime
        
        // 活动地点
        params["location"] = city

        // 城市ID（根据城市名称获取）
        if let cityId = CityDataManager.cityId(for: city) {
            params["city_id"] = "\(cityId)"
        } else {
            params["city_id"] = ""
        }

        // 活动类型（逗号分隔）
        params["activity_type"] = category

        // 活动费用: free=免费, shared=平摊费用, you_pay=由你买单, i_pay=我买单
        let feeType: String
        switch expenseType {
        case .free:
            feeType = "free"
        case .average:
            feeType = "shared"
        case .yourBuy:
            feeType = "you_pay"
        case .myBuy:
            feeType = "i_pay"
        }
        params["fee_type"] = feeType

        // 状态: draft=草稿, pending=发布
        params["status"] = "pending"
        
        return params
    }
}

// MARK: - Mock 数据
extension PublishModel {
    static let mock = PublishModel(
        id: nil,
        coverImages: [],
        title: "瑜伽健身找搭子",
        description: "想找一个喜欢瑜伽的朋友，一起督促练习瑜伽",
        participantCount: 2,
        genderRequirement: .female,
        timeType: .longTerm,
        city: "深圳",
        detailedLocation: "宝安区",
        category: "#瑜伽",
        isAgreedToTerms: false
    )
}
