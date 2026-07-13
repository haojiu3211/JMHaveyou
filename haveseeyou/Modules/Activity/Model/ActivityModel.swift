//
//  ActivityModel.swift
//  haveseeyou
//
//  首页活动数据模型
//

import Foundation

/// 活动状态
enum ActivityStatus: String, Codable {
    case ongoing    // 进行中
    case pending    // 待审核
    case expired    // 已过期

//    var title: String {
//        switch self {
//        case .ongoing: return "进行中"
//        case .pending: return "待审核"
//        case .expired: return "已过期"
//        }
//    }
}

/// 活动卡片模型
struct ActivityModel: Codable, Hashable {
    let id: String
    let coverURL: String        // 封面图
    let userId: String          // 发布者用户ID
    let avatarUrl: String       // 发布者头像
    let nickName:String
    let gender:Int  //1女 2男
    let age:String
    let constellation: String//星座
    let status: ActivityStatus  // 状态
    let title: String            // 标题
    let announcements:String //注意事项
    let teamInfo: String        // 组队中 / 报名人数：1
    let genderRequirement:String//性别要求
    let isInterested: Bool      // 是否已感兴趣
    let isFollowed: Bool        // 是否已关注
    let time:String//活动时间
    let location: String        // 地点，如"深圳市-宝安区"

    let category: String        // 活动类型，如"#运动健康-篮球"
    let descriptionFees:String//活动费用

    /// 将 ActivityModel 转换为 ActivityDetailModel，供详情页使用
    func toDetailModel() -> ActivityDetailModel {
        return ActivityDetailModel(
            id: id,
            imageUrls: [coverURL],
            publisher: ActivityPublisher(
                userId: userId,
                avatarUrl: avatarUrl,
                nickName: nickName,
                age: age,
                constellation: constellation,
                gender: gender
            ),
            isFollowed: false,
            status: status,
            title: title,
            category: category,
            genderRequirement: genderRequirement,
            teamCount: teamInfo,
            activityTime: time,
            fee: descriptionFees,
            location: location,
            notice: announcements,
            isInterested: isInterested
        )
    }

    /// 从 MyActivityItem 转换为 ActivityModel
    static func from(_ item: MyActivityItem) -> ActivityModel {
        let status: ActivityStatus = {
            switch item.status {
            case "published", "ongoing": return .ongoing
            case "pending": return .pending
            case "expired", "rejected", "draft": return .expired
            default: return .ongoing
            }
        }()
        return ActivityModel(
            id: item.id.map { "\($0)" } ?? UUID().uuidString,
            coverURL: item.imageList.first ?? "",
            userId: item.user?.id.map { "\($0)" } ?? "",
            avatarUrl: item.user?.avatar ?? "",
            nickName: item.user?.nickname ?? "",
            gender: item.gender ?? 0,
            age: item.user?.age.map { "\($0)" } ?? "",
            constellation: item.user?.constellation ?? "",
            status: status,
            title: item.title ?? "",
            announcements: item.content ?? "",
            teamInfo: "\(item.peopleNum ?? 0)",
            genderRequirement: {
                switch item.gender {
                case 0: return "不限男女"
                case 1: return "只限女性"
                case 2: return "只限男性"
                default: return "不限男女"
                }
            }(),
            isInterested: (item.isInterested ?? 0) == 1,
            isFollowed: item.user?.isFollow ?? false,
            time: {
                if (item.isLongTerm ?? 0) == 1 || (item.activityTime ?? 0) <= 0 {
                    return "长期有效"
                } else {
                    let date = Date(timeIntervalSince1970: TimeInterval(item.activityTime ?? 0))
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm"
                    return formatter.string(from: date)
                }
            }(),
            location: item.location ?? "",
            category: "#\(item.activityTypeNames)",
            descriptionFees: item.feeType ?? "免费"
        )
    }
}

/// Banner 模型
struct BannerModel: Decodable, Hashable {
    let id: String
    let imageURL: String
    let linkURL: String?
}

/// 首页整体数据
struct HomeBundle: Decodable {
    let banners: [BannerModel]
    let activities: [ActivityModel]
}

// MARK: - Mock 数据（接入真实接口后可删除）
extension ActivityModel {
   
}

extension BannerModel {
    static let mock: [BannerModel] = [
        BannerModel(id: "b1", imageURL: "sy_banner_1", linkURL: webUrlBanner1),
        BannerModel(id: "b2", imageURL: "sy_banner_2", linkURL: webUrlBanner2),
        BannerModel(id: "b3", imageURL: "sy_banner_3", linkURL: webUrlBanner3)
    ]
}
