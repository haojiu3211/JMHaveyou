//
//  PublishViewModel.swift
//  haveseeyou
//
//  发布页面 ViewModel - 使用 Combine 管理状态
//

import Foundation
import Combine



final class PublishViewModel: BaseViewModel {
    
    // MARK: - 输出（供 View 订阅）
    @Published private(set) var publishData = PublishModel()
    @Published private(set) var isPublishing = false
    @Published private(set) var publishSuccess = false
    @Published private(set) var publishError: String?
    
    // MARK: - 输入（View 更新数据）
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var participantCount: Int = 1
    @Published var genderRequirement: GenderRequirement = .unlimited
    @Published var timeType: ActivityTimeType = .longTerm
    @Published var specificTime: Date?
    @Published var city: String = ""

    @Published var category: String = ""
    @Published var coverImages: [String] = []
    @Published var isAgreedToTerms: Bool = false
    @Published var expenseType: ActivityExpenseType = .average  // 默认平摊费用
    
    // MARK: - 辅助输出
    @Published private(set) var isFormValid: Bool = false
    @Published private(set) var timeDisplayText: String = "长期有效"
    @Published private(set) var locationDisplayText: String = "未设置"
    
    // MARK: - Init
    override init() {
        super.init()
        setupValidationPipeline()
        setupDisplayTextPipeline()
    }
    
    // MARK: - 表单验证管道
    private func setupValidationPipeline() {
        Publishers.CombineLatest3(
            $title,
            $coverImages,
            Publishers.CombineLatest3(
                $city,
                $category,
                $isAgreedToTerms
            )
        )
        .map { title, images, tuple in
            let (city, category, agreed) = tuple
            return !title.isEmpty &&
                   !images.isEmpty &&  // 至少要有一张图片
                   !city.isEmpty &&
                   !category.isEmpty &&
                   agreed
            // 注意：活动人数、性别要求、活动时间、活动费用都有默认值，不需要验证
        }
        .assign(to: &$isFormValid)
    }
    
    // MARK: - 显示文本管道
    private func setupDisplayTextPipeline() {
        // 时间显示文本
        Publishers.CombineLatest($timeType, $specificTime)
            .map { timeType, specificTime -> String in
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
            .assign(to: &$timeDisplayText)
        
        // 地点显示文本
//        $city
//            .map(city -> String in
//                 if city.isEmpty {
//                return "未设置"
//            }
//                 return city
//            ).assign(to: &$locationDisplayText)
        $city
            .map{ city -> String in
                if city.isEmpty{
                    return "未设置"
                }
                return city
            }.assign(to: &$locationDisplayText)
    }
    
    // MARK: - 数据更新方法
    
    /// 更新参与人数
    func updateParticipantCount(_ count: Int) {
        participantCount = max(1, count)
    }
    
    /// 增加参与人数
    func increaseParticipantCount() {
        participantCount += 1
    }
    
    /// 减少参与人数
    func decreaseParticipantCount() {
        if participantCount > 1 {
            participantCount -= 1
        }
    }
    
    /// 更新性别要求
    func updateGenderRequirement(_ requirement: GenderRequirement) {
        genderRequirement = requirement
    }
    
    /// 更新时间类型
    func updateTimeType(_ type: ActivityTimeType) {
        timeType = type
    }
    
    /// 更新具体时间
    func updateSpecificTime(_ date: Date?) {
        specificTime = date
    }
    
    /// 更新城市
    func updateCity(_ city: String) {
        self.city = city
    }
    
   
    
    /// 更新地点（城市）
    func updateLocation(_ city: String) {
        self.city = city
    }
    
    /// 更新活动类型
    func updateCategory(_ category: String) {
        self.category = category
    }
    
    /// 添加封面图片
    func addCoverImage(_ imagePath: String) {
        if !coverImages.contains(imagePath) {
            coverImages.append(imagePath)
        }
    }
    
    /// 移除封面图片
    func removeCoverImage(_ imagePath: String) {
        coverImages.removeAll { $0 == imagePath }
    }

    /// 批量替换封面图片列表（用于上传 OSS 成功后把本地路径替换成远端 key）
    func replaceCoverImages(_ images: [String]) {
        coverImages = images
    }
    
    /// 更新同意条款状态
    func updateAgreedToTerms(_ agreed: Bool) {
        isAgreedToTerms = agreed
    }
    
    /// 更新活动费用类型
    func updateExpenseType(_ type: ActivityExpenseType) {
        expenseType = type
    }
    
    // MARK: - 发布活动
    
    /// 发布活动
    func publishActivity() {
        guard isFormValid else {
            publishError = "请填写所有必填项"
            return
        }
        
        isPublishing = true
        publishError = nil
        
        // 构建发布数据
        var data = PublishModel()
        data.title = title
        data.description = description
        data.participantCount = participantCount
        data.genderRequirement = genderRequirement
        data.timeType = timeType
        data.specificTime = specificTime
        data.city = city
        data.category = category
        data.coverImages = coverImages
        data.isAgreedToTerms = isAgreedToTerms
        data.expenseType = expenseType
        loadingState = .loading
        
        // 真实网络请求
        publishToServer(data)
    }
    
    /// 调用服务器发布接口
    private func publishToServer(_ data: PublishModel) {
        NetworkManager.shared
            .request(PublishAPI.publish(data), as: APIResponse<PublishResultModel>.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isPublishing = false
                self?.loadingState = .success
                
                self?.publishSuccess = true
                self?.publishData = data
//                self?.savePublishData(data)
                if case let .failure(error) = completion {
                    // 解析失败不弹窗，仅打印日志
                    if case .decoding = error {
                        print("⚠️ [Publish] 响应解析失败，已忽略: \(error.localizedDescription)")
                    } else {
                        self?.publishError = error.localizedDescription
                    }
                }
            }, receiveValue: { [weak self] _ in
                
            })
            .store(in: &cancellables)
    }
    
    /// 保存发布数据到本地
    private func savePublishData(_ data: PublishModel) {
        // 这里可以实现本地存储逻辑
        // 例如：保存到 UserDefaults、CoreData 或本地文件
        PublishDataManager.shared.savePublishedActivity(data)
        
    }
    
    /// 真实接口示例
 
    
    /// 重置表单
    func resetForm() {
        title = ""
        description = ""
        participantCount = 1
        genderRequirement = .unlimited
        timeType = .longTerm
        specificTime = nil
        city = ""
        category = ""
        coverImages = []
        isAgreedToTerms = false
        expenseType = .free  // 重置为默认的平摊费用
        publishSuccess = false
        publishError = nil
    }
}
