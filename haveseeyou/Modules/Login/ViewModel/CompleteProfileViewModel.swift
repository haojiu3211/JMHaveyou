//
//  CompleteProfileViewModel.swift
//  haveseeyou
//
//  完善资料页 ViewModel
//

import UIKit
import Combine


final class CompleteProfileViewModel: BaseViewModel {

    // MARK: - Input

    /// 手机号
    let phoneNumber: String

    /// 昵称
    @Published var nickname: String = ""

    /// 性别：0-未选择 1-女 2-男 "female" : "male"
    @Published var gender: Int = 1

    /// 生日（2000-01-01）
    @Published var birthday: String = ""

    /// 城市
    @Published var city: String = ""

    /// 社媒账号：0-未选择 1-微信 2-QQ
    @Published var socialMedia: Int = 1

    /// 社媒账号号码（微信/QQ号）
    @Published var socialAccount: String = ""

    /// 头像 URL
    @Published var avatarURL: String = ""

    /// 头像图片（本地选择后暂存，上传后转为 URL）
    var avatarImage: UIImage?

    // MARK: - Output

    /// 是否可以提交
    var isSubmittable: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(
            Publishers.CombineLatest($nickname, $avatarURL),
            Publishers.CombineLatest($city, $birthday)
        )
        .map { (pair1, pair2) in
            let (nickname, avatarURL) = pair1
            let (city, birthday) = pair2
            return !nickname.isBlank && !avatarURL.isBlank && !city.isBlank && !birthday.isBlank
        }
        .eraseToAnyPublisher()
    }

    /// 注册成功
    let registerSuccess = PassthroughSubject<Void, Never>()

    // MARK: - Init

    init(phoneNumber: String) {
        self.phoneNumber = phoneNumber
        super.init()
    }

    // MARK: - Methods

    /// 提交注册
    func submit() {
        loadingState = .loading

        // 获取 usercode（从已登录用户信息中获取）
        guard let usercode = UserManager.shared.usercode else {
            handle(error: APIError.business(code: -1, message: "用户编码为空"))
            return
        }

        // 将生日格式化为 YYYY-MM-DD
        let birthdayForAPI: String
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        if let date = formatter.date(from: birthday) {
            formatter.dateFormat = "yyyy-MM-dd"
            birthdayForAPI = formatter.string(from: date)
        } else {
            birthdayForAPI = birthday
        }

        // 打印请求参数日志
        #if DEBUG
        print("📤 [Register] 开始提交注册资料")
        print("  ├─ usercode: \(usercode)")
        print("  ├─ nickname: \(nickname)")
        print("  ├─ gender: \(gender) (\(gender == 1 ? "女" : "男"))")
        print("  ├─ birthday: \(birthdayForAPI)")
  
        print("  ├─ city: \(city.isEmpty ? "未填写" : city)")
        print("  ├─ socialMedia: \(socialMedia == 1 ? "微信" : socialMedia == 2 ? "QQ" : "未选择")")
        print("  └─ avatarURL: \(avatarURL.isEmpty ? "未上传" : avatarURL.prefix(50) + "...")")
        #endif

        NetworkManager.shared
            .request(LoginAPI.appendUserData(
                avatar: avatarURL,
                nickname: nickname,
                gender: gender,
                birthday: birthdayForAPI,
                city: city,
                socialMedia: socialMedia,
                socialAccount: socialAccount
            ), as: EmptyData.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    #if DEBUG
                    print("❌ [Register] 注册失败: \(error.localizedDescription)")
                    #endif
                    self?.handle(error: error)
                }
            } receiveValue: { [weak self] _ in
                #if DEBUG
                print("✅ [Register] 注册成功")
                print("  ├─ 更新本地用户信息")
                print("  ├─ nickname: \(self?.nickname ?? "")")
                print("  ├─ gender: \(self?.gender == 1 ? "female" : "male")")
                print("  ├─ city: \(self?.city ?? "")")
                #endif
                
                // 更新本地用户信息（包含 finishStatus = 1，表示资料已完善）
                UserManager.shared.updateUserInfo(
                    nickname: self?.nickname,
                    age: self?.calculateAge(from: self?.birthday ?? ""),
                    gender: self?.gender == 1 ? "female" : "male",
                    city: self?.city,
                    finishStatus: 1
                )
                
                #if DEBUG
                print("  └─ 本地用户信息更新完成")
                #endif
                
                self?.loadingState = .success
                self?.registerSuccess.send()
            }
            .store(in: &cancellables)
    }

    /// 计算年龄（返回 String，用于本地存储）
    private func calculateAge(from birthday: String) -> String? {
        guard !birthday.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let birthDate = formatter.date(from: birthday) {
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
            return "\(ageComponents.year ?? 0)"
        }
        return nil
    }

    /// 计算年龄（返回 Int，用于接口传参）
    private func calculateAgeInt(from birthday: String) -> Int? {
        guard !birthday.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let birthDate = formatter.date(from: birthday) {
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
            return ageComponents.year
        }
        return nil
    }

    func formattedBirthday(_ date: String) -> String {
        return date
            .replacingOccurrences(of: "年", with: "-")
            .replacingOccurrences(of: "月", with: "-")
            .replacingOccurrences(of: "日", with: "")
    }
}
