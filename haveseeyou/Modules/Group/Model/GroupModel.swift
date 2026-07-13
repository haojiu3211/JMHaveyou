//
//  GroupModel.swift
//  haveseeyou
//
//  搭子数据模型
//

import Foundation

/// 搭子卡片模型
struct GroupModel: Decodable, Hashable {
    let id: String
    let coverURL: String        // 封面图
    let userId: String          // 发布者用户ID
    let avatarUrl: String       // 发布者头像
    let nickName: String
    let gender: Int             // 1女 2男
    let age: String
    let constellation: String   // 星座
    let title: String           // 标题
    let description: String     // 描述
    let tags: [String]          // 标签
    let location: String        // 地点
    let joinCount: Int          // 加入人数
    let isFollowed: Bool        // 是否已关注
    let isInterested: Bool      // 是否已感兴趣
}

// MARK: - Mock 数据
extension GroupModel {
    static let mock: [GroupModel] = [
        GroupModel(
            id: "g1",
            coverURL: "ac_fm_1_1",
            userId: "1",
            avatarUrl: "sy_head_1",
            nickName: "小瑞",
            gender: 1,
            age: "22",
            constellation: "狮子座",
            title: "一呼百应",
            description: "让你的活动不再无人问津，快速爆火",
            tags: ["瑜伽", "健身", "交友"],
            location: "广州",
            joinCount: 128,
            isFollowed: false,
            isInterested: false
        ),
        GroupModel(
            id: "g2",
            coverURL: "ac_fm_2_1",
            userId: "2",
            avatarUrl: "sy_head_2",
            nickName: "冰激凌",
            gender: 1,
            age: "24",
            constellation: "双鱼座",
            title: "一呼百应",
            description: "让你的活动不再无人问津，快速爆火",
            tags: ["露营", "户外", "冒险"],
            location: "深圳",
            joinCount: 256,
            isFollowed: false,
            isInterested: false
        ),
        GroupModel(
            id: "g3",
            coverURL: "ac_fm_3_1",
            userId: "3",
            avatarUrl: "sy_head_3",
            nickName: "芯芯",
            gender: 1,
            age: "26",
            constellation: "处女座",
            title: "一呼百应",
            description: "让你的活动不再无人问津，快速爆火",
            tags: ["公益", "动物", "爱心"],
            location: "北京",
            joinCount: 89,
            isFollowed: false,
            isInterested: false
        ),
        GroupModel(
            id: "g4",
            coverURL: "ac_fm_4_1",
            userId: "4",
            avatarUrl: "sy_head_4",
            nickName: "乖乖",
            gender: 1,
            age: "21",
            constellation: "金牛座",
            title: "一呼百应",
            description: "让你的活动不再无人问津，快速爆火",
            tags: ["社交", "聚会", "朋友"],
            location: "邵阳",
            joinCount: 342,
            isFollowed: false,
            isInterested: false
        ),
        GroupModel(
            id: "g5",
            coverURL: "ac_fm_5_1",
            userId: "5",
            avatarUrl: "sy_head_5",
            nickName: "大碗宽面",
            gender: 1,
            age: "19",
            constellation: "天蝎座",
            title: "一呼百应",
            description: "让你的活动不再无人问津，快速爆火",
            tags: ["美食", "探店", "约饭"],
            location: "天津",
            joinCount: 167,
            isFollowed: false,
            isInterested: false
        )
    ]
}
