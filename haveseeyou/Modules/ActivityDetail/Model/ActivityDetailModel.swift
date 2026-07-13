//
//  ActivityDetailModel.swift
//  haveseeyou
//
//  活动详情数据模型
//

import Foundation

/// 活动详情 - 包含完整信息
struct ActivityDetailModel: Decodable, Hashable {
    let id: String
    /// 活动图片列表（轮播）
    let imageUrls: [String]
    /// 发布者信息
    let publisher: ActivityPublisher
    /// 当前用户是否已关注发布者
    var isFollowed: Bool
    /// 活动状态
    let status: ActivityStatus
    /// 活动标题
    let title: String
    /// 活动类型，如"#休闲娱乐–livehouse"
    let category: String
    /// 性别要求
    let genderRequirement: String
    /// 组队人数
    let teamCount: String
    /// 活动时间
    let activityTime: String
    /// 活动费用
    let fee: String
    /// 活动地址
    let location: String
    /// 注意事项
    let notice: String
    /// 当前用户是否已感兴趣
    var isInterested: Bool

    /// 费用类型映射
    enum FeeType: String {
        case free = "free"
        case shared = "shared"
        case youPay = "you_pay"
        case iPay = "i_pay"

        var displayName: String {
            switch self {
            case .free: return "免费"
            case .shared: return "平摊费用"
            case .youPay: return "由你买单"
            case .iPay: return "我买单"
            }
        }
    }
}

/// 发布者信息
struct ActivityPublisher: Decodable, Hashable {
    let userId: String
    let avatarUrl: String
    let nickName: String
    let age: String
    let constellation: String
    let gender: Int  // 1女 2男
}

// MARK: - 从 MyActivityItem 转换

extension ActivityDetailModel {
    /// 从 MyActivityItem 转换为 ActivityDetailModel
    static func from(_ item: MyActivityItem) -> ActivityDetailModel {
        let status: ActivityStatus = {
            switch item.status {
            case "published", "ongoing": return .ongoing
            case "pending": return .pending
            case "expired", "rejected", "draft": return .expired
            default: return .ongoing
            }
        }()

        let feeType = FeeType(rawValue: item.feeType ?? "free") ?? .free

        return ActivityDetailModel(
            id: item.id.map { "\($0)" } ?? "",
            imageUrls: item.imageList,
            publisher: ActivityPublisher(
                userId: item.user?.id.map { "\($0)" } ?? "",
                avatarUrl: item.user?.avatar ?? "",
                nickName: item.user?.nickname ?? "",
                age: item.user?.age.map { "\($0)" } ?? "",
                constellation: item.user?.constellation ?? "",
                gender: item.user?.gender ?? item.gender ?? 0
            ),
            isFollowed: item.user?.isFollow ?? false,
            status: status,
            title: item.title ?? "",
            category: "#\(item.activityTypeNames)",
            genderRequirement: {
                switch item.gender {
                case 0: return "不限男女"
                case 1: return "只限女性"
                case 2: return "只限男性"
                default: return "不限男女"
                }
            }(),
            teamCount: "\(item.peopleNum ?? 0)人",
            activityTime: {
                if (item.isLongTerm ?? 0) == 1 || (item.activityTime ?? 0) <= 0 {
                    return "长期有效"
                } else {
                    let date = Date(timeIntervalSince1970: TimeInterval(item.activityTime ?? 0))
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm"
                    return formatter.string(from: date)
                }
            }(),
            fee: feeType.displayName,
            location: item.location ?? "",
            notice: item.content ?? "",
            isInterested: (item.isInterested ?? 0) == 1
        )
    }
}

// MARK: - Mock 数据

extension ActivityDetailModel {
//    static let mock = ActivityDetailModel(
//        id: "1",
//        imageUrls: ["ac_fm_1", "ac_fm_1_1", "ac_fm_1_2"],
//        publisher: ActivityPublisher(
//            userId: "u1",
//            avatarUrl: "avatar_girl_1",
//            nickName: "林妹妹",
//            age: "21",
//            constellation: "处女座",
//            gender: 1
//        ),
//        isFollowed: false,
//        status: .ongoing,
//        title: "约喝茶的有吗",
//        category: "#休闲娱乐–livehouse",
//        genderRequirement: "只限男性",
//        teamCount: "1人",
//        activityTime: "2026.03.15–2026.05.23",
//        fee: "由你买单",
//        location: "深圳市-龙岗区",
//        notice: "鸽子勿扰。",
//        isInterested: false
//    )
}
