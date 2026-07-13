//
//  CallRespondModel.swift
//  haveseeyou
//
//  一呼百应 - 发起配置数据模型
//

import Foundation

/// 性别筛选类型
enum CallGenderFilter: String {
    case male = "男"
    case female = "女"
    case unlimited = "不限"
}

/// 一呼百应发起配置模型
struct CallRespondConfig {
    /// 关联的活动
    var activity: PublishModel
    /// 活动地点
    var location: String = ""
    /// 城市ID
    var cityId: String = ""
    /// 年龄区间 - 最小
    var ageMin: Int = 18
    /// 年龄区间 - 最大
    var ageMax: Int = 25
    /// 性别筛选
    var genderFilter: CallGenderFilter = .unlimited
    /// 邀请人数
    var inviteCount: Int = 100
}
