//
//  PublishDataManager.swift
//  haveseeyou
//
//  发布数据本地存储管理器
//

import Foundation

/// 发布数据管理器 - 负责本地存储和检索发布的活动数据
final class PublishDataManager {
    
    static let shared = PublishDataManager()
    
    private let userDefaults = UserDefaults.standard
    private let publishedActivitiesKey = "publishedActivities"
    private let draftActivitiesKey = "draftActivities"
    
    private init() {}
    
    // MARK: - 已发布活动管理
    
    /// 保存已发布的活动
    func savePublishedActivity(_ activity: PublishModel) {
        var activities = getPublishedActivities()
        var mutableActivity = activity
        mutableActivity.id = UUID().uuidString
        mutableActivity.createdAt = Date()
        activities.append(mutableActivity)
        
        if let encoded = try? JSONEncoder().encode(activities) {
            userDefaults.set(encoded, forKey: publishedActivitiesKey)
            userDefaults.synchronize()
            print("✅ 已发布活动已保存: \(mutableActivity.id ?? "")")
        }
    }
    
    /// 获取所有已发布的活动
    func getPublishedActivities() -> [PublishModel] {
        guard let data = userDefaults.data(forKey: publishedActivitiesKey),
              let activities = try? JSONDecoder().decode([PublishModel].self, from: data) else {
            return []
        }
        return activities
    }
    
    /// 获取指定ID的已发布活动
    func getPublishedActivity(by id: String) -> PublishModel? {
        return getPublishedActivities().first { $0.id == id }
    }
    
    /// 删除已发布的活动
    func deletePublishedActivity(by id: String) {
        var activities = getPublishedActivities()
        activities.removeAll { $0.id == id }
        
        if let encoded = try? JSONEncoder().encode(activities) {
            userDefaults.set(encoded, forKey: publishedActivitiesKey)
            userDefaults.synchronize()
            print("✅ 已发布活动已删除: \(id)")
        }
    }
    
    /// 更新已发布的活动
    func updatePublishedActivity(_ activity: PublishModel) {
        guard let id = activity.id else { return }
        
        var activities = getPublishedActivities()
        if let index = activities.firstIndex(where: { $0.id == id }) {
            var updatedActivity = activity
            updatedActivity.updatedAt = Date()
            activities[index] = updatedActivity
            
            if let encoded = try? JSONEncoder().encode(activities) {
                userDefaults.set(encoded, forKey: publishedActivitiesKey)
                userDefaults.synchronize()
                print("✅ 已发布活动已更新: \(id)")
            }
        }
    }
    
    // MARK: - 草稿活动管理
    
    /// 保存草稿活动
    func saveDraftActivity(_ activity: PublishModel) {
        var activities = getDraftActivities()
        var mutableActivity = activity
        
        if mutableActivity.id == nil {
            mutableActivity.id = UUID().uuidString
            mutableActivity.createdAt = Date()
        }
        mutableActivity.updatedAt = Date()
        
        // 如果已存在相同ID的草稿，则更新；否则添加
        if let index = activities.firstIndex(where: { $0.id == mutableActivity.id }) {
            activities[index] = mutableActivity
        } else {
            activities.append(mutableActivity)
        }
        
        if let encoded = try? JSONEncoder().encode(activities) {
            userDefaults.set(encoded, forKey: draftActivitiesKey)
            userDefaults.synchronize()
            print("✅ 草稿活动已保存: \(mutableActivity.id ?? "")")
        }
    }
    
    /// 获取所有草稿活动
    func getDraftActivities() -> [PublishModel] {
        guard let data = userDefaults.data(forKey: draftActivitiesKey),
              let activities = try? JSONDecoder().decode([PublishModel].self, from: data) else {
            return []
        }
        return activities
    }
    
    /// 获取指定ID的草稿活动
    func getDraftActivity(by id: String) -> PublishModel? {
        return getDraftActivities().first { $0.id == id }
    }
    
    /// 删除草稿活动
    func deleteDraftActivity(by id: String) {
        var activities = getDraftActivities()
        activities.removeAll { $0.id == id }
        
        if let encoded = try? JSONEncoder().encode(activities) {
            userDefaults.set(encoded, forKey: draftActivitiesKey)
            userDefaults.synchronize()
            print("✅ 草稿活动已删除: \(id)")
        }
    }
    
    /// 将草稿转换为已发布
    func publishDraft(by id: String) {
        guard let draft = getDraftActivity(by: id) else { return }
        
        savePublishedActivity(draft)
        deleteDraftActivity(by: id)
        print("✅ 草稿已发布: \(id)")
    }
    
    // MARK: - 清空数据
    
    /// 清空所有已发布活动
    func clearPublishedActivities() {
        userDefaults.removeObject(forKey: publishedActivitiesKey)
        userDefaults.synchronize()
        print("✅ 已发布活动已清空")
    }
    
    /// 清空所有草稿活动
    func clearDraftActivities() {
        userDefaults.removeObject(forKey: draftActivitiesKey)
        userDefaults.synchronize()
        print("✅ 草稿活动已清空")
    }
    
    /// 清空所有数据
    func clearAllData() {
        clearPublishedActivities()
        clearDraftActivities()
        print("✅ 所有数据已清空")
    }
}
