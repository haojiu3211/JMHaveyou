//
//  EditProfileController.swift
//  haveseeyou
//
//  编辑资料页面
//

import UIKit
import SnapKit
import Combine
import Kingfisher
import Alamofire

// MARK: - MultiSelectTagFlowView

/// 支持多选的标签流式布局视图
final class MultiSelectTagFlowView: UIView {

    var onSelectionChanged: (([Int]) -> Void)?

    private(set) var selectedIndices: Set<Int> = []

    private var tags: [UIButton] = []
    private var tagTitles: [String] = []

    private let tagHeight: CGFloat = 42.fit
    private let hSpacing: CGFloat = 10.fit
    private let vSpacing: CGFloat = 10.fit
    private let hPadding: CGFloat = 16.fit

    private var heightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(titles: [String], selectedIndices: Set<Int> = []) {
        self.tagTitles = titles
        self.selectedIndices = selectedIndices
        tags.forEach { $0.removeFromSuperview() }
        tags.removeAll()

        for (index, title) in titles.enumerated() {
            let btn = makeTagButton(title: title, selected: selectedIndices.contains(index))
            btn.tag = index
            btn.addTarget(self, action: #selector(tagTapped(_:)), for: .touchUpInside)
            addSubview(btn)
            tags.append(btn)
        }

        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        relayoutTags()
    }

    private func relayoutTags() {
        var x: CGFloat = 0
        var y: CGFloat = 0
        let maxWidth = bounds.width

        for tag in tags {
            let intrinsicW = tag.titleLabel?.intrinsicContentSize.width ?? 0
            let w = intrinsicW + hPadding * 2

            if x + w > maxWidth, x > 0 {
                x = 0
                y += tagHeight + vSpacing
            }

            tag.frame = CGRect(x: x, y: y, width: w, height: tagHeight)
            x += w + hSpacing
        }

        let totalHeight = tags.isEmpty ? tagHeight : (y + tagHeight)
        heightConstraint?.update(offset: totalHeight)
    }

    func makeHeightConstraint(_ maker: ConstraintMaker) {
        heightConstraint = maker.height.equalTo(tagHeight).constraint
    }

    // MARK: - Tag Button Style

    private func makeTagButton(title: String, selected: Bool) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.layer.cornerRadius = tagHeight / 2
        btn.clipsToBounds = true
        updateAppearance(btn, selected: selected)
        return btn
    }

    private func updateAppearance(_ btn: UIButton, selected: Bool) {
        if selected {
            // 渐变背景颜色
            let gtc = UIColor.gradientTextColor(
                size: CGSize(width: 200, height: 42.fit),
                colors: [UIColor(hex: "#FFA2EF4D"), UIColor(hex: "#FFC2FF7F")]
            )
            btn.setTitleColor(AppColor.textMain, for: .normal)
            btn.backgroundColor = gtc
            btn.layer.borderWidth = 0
        } else {
            btn.backgroundColor = .white
            btn.setTitleColor(UIColor(hex: "#888888"), for: .normal)
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor(hex: "#E0E0E0").cgColor
        }
    }

    @objc private func tagTapped(_ sender: UIButton) {
        let index = sender.tag
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }

        for (i, tag) in tags.enumerated() {
            updateAppearance(tag, selected: selectedIndices.contains(i))
        }

        onSelectionChanged?(Array(selectedIndices))
        setNeedsLayout()
    }
}

// MARK: - ActivityTagContainerView

/// 活动类型标签容器视图：最多展示 maxVisible 个标签，超出显示 "..."，右侧箭头可点击跳转
final class ActivityTagContainerView: UIView {

    /// 最多展示的标签数量
    private let maxVisible = 4

    /// 点击回调（跳转 H5 选择页）
    var onTapped: (() -> Void)?

    /// 当前已选类别
    var selectedCategories: [String] = [] {
        didSet { renderTags() }
    }

    // 子视图
    /// 缺省提示标签
    let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "请选择感兴趣的活动类型"
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor(hex: "#FFB9B9B9")
        return label
    }()
    private let tagContainer = UIView()
    private let arrowImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "app_right"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    private var tagPills: [UIView] = []
    private let ellipsisLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = AppColor.textMain
        l.text = "..."
        l.isHidden = true
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupView() {
        layer.cornerRadius = 12.fit
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor(hex: "#FFB9B9B9").cgColor
        backgroundColor = .white
        addSubview(placeholderLabel)
        addSubview(tagContainer)
        addSubview(ellipsisLabel)
        addSubview(arrowImageView)

        // 点击手势
        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(containerTapped)))

        placeholderLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(10)
        }

        arrowImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(10)
            make.size.equalTo(CGSize(width: 14, height: 14))
        }

        tagContainer.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.right.equalTo(arrowImageView.snp.left).offset(-6)
        }

        ellipsisLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(arrowImageView.snp.left).offset(-6)
        }
    }

    // MARK: - 渲染标签

    private func renderTags() {
        tagPills.forEach { $0.removeFromSuperview() }
        tagPills.removeAll()

        //计算是否超出一行
        let maxWidth: CGFloat = kScreenWidth - 20.fit - 20 - 30
        let horizontalSpacing: CGFloat = 10.fit
        let horizontalPadding: CGFloat = 20.fit

        let font = UIFont.systemFont(
            ofSize: 13,
            weight: .medium
        )

        var displayCategories: [String] = []
        var hasMore = false
        var totalWidth: CGFloat = 0

        placeholderLabel.isHidden = false
        if selectedCategories.count > 0 {
            placeholderLabel.isHidden = true
        }

        for category in selectedCategories {

            let textWidth = category.size(
                withAttributes: [
                    .font: font
                ]
            ).width

            let tagWidth = textWidth + horizontalPadding

            let spacing = displayCategories.isEmpty ? 0 : horizontalSpacing

            if totalWidth + spacing + tagWidth > maxWidth {
                hasMore = true
                break
            }

            totalWidth += spacing + tagWidth
            displayCategories.append(category)
        }

        var lastView: UIView?
        for (_, category) in displayCategories.enumerated() {
            let pill = makeTagPill(category)
            tagContainer.addSubview(pill)
            pill.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                if let lastView {
                    make.left.equalTo(lastView.snp.right).offset(10)
                } else {
                    make.left.equalToSuperview()
                }
            }
            tagPills.append(pill)
            lastView = pill
        }

        ellipsisLabel.isHidden = !hasMore
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutTagPills()
    }

    private func layoutTagPills() {
        let pillH: CGFloat = 28.fit
        let pillY = (bounds.height - pillH) / 2
        let spacing: CGFloat = 6.fit
        let hPadding: CGFloat = 10.fit
        var x: CGFloat = 0

        for pill in tagPills {
            let textW = pill.subviews.compactMap { $0 as? UILabel }.first?.intrinsicContentSize.width ?? 0
            let pillW = textW + hPadding * 2
            pill.frame = CGRect(x: x, y: pillY, width: pillW, height: pillH)
            x += pillW + spacing
        }
    }

    // MARK: - 创建标签胶囊

    private func makeTagPill(_ text: String) -> UIView {
        let container = UIView()
        container.layer.cornerRadius = 14.fit
        container.layer.masksToBounds = true

        // 渐变背景
        let gtc = UIColor.gradientTextColor(
            size: CGSize(width: 90.fit, height: 28.fit),
            colors: [UIColor(hex: "#FFA2EF4D"), UIColor(hex: "#FFC2FF7F")]
        )
        container.backgroundColor = gtc

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = AppColor.textMain
        label.sizeToFit()
        container.addSubview(label)

        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(10.fit)
            make.right.equalToSuperview().offset(-10.fit)
        }

        container.snp.makeConstraints { make in
            make.height.equalTo(28.fit)
        }

        return container
    }

    @objc private func containerTapped() {
        onTapped?()
    }
}

final class EditProfileController: BaseViewController {

    // MARK: - UI Components

    private let tableView = UITableView(frame: .zero, style: .grouped)

    // MARK: - Data

    private var userInfo: LoginModel? {
        return UserManager.shared.loginModel
    }
    
    // MARK: - Date Picker
    
    private lazy var datePicker: DatePickerPicker = {
        let picker = DatePickerPicker()
        picker.dateFormat = "yyyy年MM月dd日"
        return picker
    }()
    
    // MARK: - Options
    
    private let incomeOptions = ["10w以下", "10w-30w", "30w-50w", "50w-100w", "100w以上"]
    private let educationOptions = ["高中", "大专", "本科", "研究生", "博士", "博士后"]
    
    // 女性职业选项
    private let femaleOccupationOptions = ["主播", "网红", "白领", "模特", "美容师", "个体", "学生", "游戏主播", "舞蹈", "其他"]
    // 男性职业选项
    private let maleOccupationOptions = ["程序员", "摄影师", "健身教练", "设计师", "销售经理", "白领", "管理者", "自由职业", "技术宅", "CEO", "专业玩家", "壕", "金融投资", "个体", "其他"]
    
    // 职业选项：根据性别返回对应的选项
    private var occupationOptions: [String] {
        let isMale = userInfo?.genderRaw == 2
        return isMale ? maleOccupationOptions : femaleOccupationOptions
    }
    private let tagOptions = ["认识新朋友", "找同好搭子", "寻找恋爱/脱单", "体验新鲜事物", "满足兴趣爱好", "学习新技能", "向上社交资源", "朋友一起娱乐", "打发枯燥生活"]
    private var selectedTagIndices: Set<Int> = []
    private var selectedActivityCategories: [String] = []
    private var selectedSocialMedia: Int = 1
    private var socialAccount: String = ""
//    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "编辑资料"
        
        // 初始化数据
        initializeData()
        registerKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterKeyboardNotifications()
    }
    
    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        ) 
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        
        // 滚动到签名单元格
        let signatureIndexPath = IndexPath(row: 0, section: 2)
        tableView.scrollToRow(at: signatureIndexPath, at: .bottom, animated: true)
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        tableView.contentInset = .zero
        tableView.scrollIndicatorInsets = .zero
    }
    
    private func initializeData() {
        // 初始化选中的标签（初心）
        if let initialHeart = userInfo?.initialHeart, !initialHeart.isEmpty {
            let selectedTags = initialHeart.split(separator: ",").map(String.init)
            selectedTagIndices = Set(selectedTags.compactMap { tag in
                tagOptions.firstIndex(of: tag)
            })
        }
        
        // 初始化选中的活动
        if let activity = userInfo?.activity, !activity.isEmpty {
            selectedActivityCategories = activity.split(separator: ",").map(String.init)
        }
        
        // 初始化社媒账号
        if (userInfo?.isWx == 1 || userInfo?.isWx == 0){
            selectedSocialMedia = 1
            socialAccount = userInfo?.wechatAccount ?? "正在审核中..."
        }else if (userInfo?.isQq == 1 || userInfo?.isQq == 0){
            selectedSocialMedia = 2
            socialAccount = userInfo?.qqAccount ?? "正在审核中..."
        }else {
            selectedSocialMedia = 1
        }
    }
    
    /// 将生日格式转换为显示格式（yyyy年MM月dd日）
    private func formatBirthdayForDisplay(_ birthday: String) -> String {
        let formatter = DateFormatter()
        // 先尝试用 yyyy-MM-dd 格式解析
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: birthday) {
            formatter.dateFormat = "yyyy年MM月dd日"
            return formatter.string(from: date)
        }
        // 如果解析失败，返回原字符串
        return birthday
    }
    
    // MARK: - 保存用户信息
    
    private func saveUserInfo(field: String, value: String) {
        // 处理生日格式转换
        var apiValue = value
        if field == "birthday" {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月dd日"
            if let date = formatter.date(from: value) {
                formatter.dateFormat = "yyyy-MM-dd"
                apiValue = formatter.string(from: date)
            }
        }
        
        // 构建请求参数 - 只提交修改的字段
        let params = buildParams(field: field, value: apiValue)
        
        NetworkManager.shared
            .request(
                MineAPI.saveUserInfo(params: params),
                as: APIResponse<EmptyData>.self
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.showToast("保存失败，请重试")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                if response.code == 0 {
                    // 显示成功提示
                    let message = self.getSuccessMessage(for: field)
                    self.showToast(message)
                    // 更新本地数据（保持原格式用于显示）
                    self.updateLocalData(field: field, value: value)
                    // 刷新 UI
                    self.tableView.reloadData()
                } else {
                    self.showToast(response.message ?? "保存失败")
                }
            }
            .store(in: &cancellables)
    }
    
    private func buildParams(field: String, value: String) -> [String: String] {
        var params: [String: String] = [:]
        
        switch field {
        case "nickname":
            params["nickname"] = value
        case "birthday":
            params["birthday"] = value
        case "city":
            params["arrange_play_city_label"] = value
        case "income":
            params["annual_income"] = value
        case "education":
            params["education"] = value
        case "occupation":
            params["occupation"] = value
        case "sign":
            params["sign"] = value
        case "wechat":
            params["wechat_account"] = value
        case "qq":
            params["qq_account"] = value
        case "initialHeart":
            params["initial_heart"] = value
        case "activity":
            params["activity"] = value
        case "avatar":
            params["avatar"] = value
        default: break
        }
        
        return params
    }
    
    private func getSuccessMessage(for field: String) -> String {
        switch field {
        case "nickname": return "昵称更换成功"
        case "birthday": return "生日更新成功"
        case "city": return "城市更新成功"
        case "income": return "年收入更新成功"
        case "education": return "教育经历更新成功"
        case "occupation": return "职业更新成功"
        case "sign": return "签名更新成功"
        case "wechat": return "微信号提交审核成功"
        case "qq": return "QQ号提交审核成功"
        case "initialHeart": return "初心更新成功"
        case "activity": return "活动更新成功"
        case "avatar": return "头像更换成功"
        default: return "更新成功"
        }
    }
    
    private func updateLocalData(field: String, value: String) {
        switch field {
        case "nickname":
            UserManager.shared.updateUserInfo(nickname: value, shouldNotify: false)
        case "birthday":
            UserManager.shared.updateUserInfo(birthday: value, shouldNotify: false)
        case "city":
            UserManager.shared.updateUserInfo(city: value, arrangePlayCityLabel: value, shouldNotify: false)
        case "income":
            UserManager.shared.updateUserInfo(income: value, annualIncome: value, shouldNotify: false)
        case "education":
            UserManager.shared.updateUserInfo(education: value, shouldNotify: false)
        case "occupation":
            UserManager.shared.updateUserInfo(profession: value, occupation: value, shouldNotify: false)
        case "sign":
            UserManager.shared.updateUserInfo(sign: value, shouldNotify: false)
        case "wechat":
            // 更新微信账号，并设置为审核中状态
            UserManager.shared.updateUserInfo(wechatAccount: value, isWx: 0, shouldNotify: false)
        case "qq":
            // 更新QQ账号，并设置为审核中状态
            UserManager.shared.updateUserInfo(qqAccount: value, isQq: 0, shouldNotify: false)
        case "initialHeart":
            UserManager.shared.updateUserInfo(initialHeart: value, shouldNotify: false)
        case "activity":
            UserManager.shared.updateUserInfo(activity: value, shouldNotify: false)
        case "avatar":
            UserManager.shared.updateUserInfo(avatar: value, shouldNotify: false)
        default:
            break
        }
    }

    override func setupUI() {
        view.backgroundColor = AppColor.background

        view.addSubview(tableView)
        tableView.backgroundColor = AppColor.background
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(EditProfileAvatarCell.self, forCellReuseIdentifier: EditProfileAvatarCell.reuseId)
        tableView.register(EditProfileInfoCell.self, forCellReuseIdentifier: EditProfileInfoCell.reuseId)
        tableView.register(EditProfileSignatureCell.self, forCellReuseIdentifier: EditProfileSignatureCell.reuseId)
        tableView.register(EditProfileTagsCell.self, forCellReuseIdentifier: EditProfileTagsCell.reuseId)
        tableView.register(EditProfileActivityCell.self, forCellReuseIdentifier: EditProfileActivityCell.reuseId)
        tableView.register(EditProfileSocialMediaCell.self, forCellReuseIdentifier: EditProfileSocialMediaCell.reuseId)

        setupConstraints()
    }

    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension EditProfileController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 7
        case 2:
            return 4
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: EditProfileAvatarCell.reuseId, for: indexPath) as! EditProfileAvatarCell
            cell.configure(with: userInfo?.avatar)
            cell.onAvatarTapped = { [weak self] in
                self?.handleAvatarTapped()
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: EditProfileInfoCell.reuseId, for: indexPath) as! EditProfileInfoCell
            let info = getInfoItem(at: indexPath.row)
            cell.configure(with: info)
            return cell
        case 2:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: EditProfileSignatureCell.reuseId, for: indexPath) as! EditProfileSignatureCell
                cell.configure(with: userInfo?.sign)
                cell.onSignatureChanged = { [weak self] text in
                    self?.saveUserInfo(field: "sign", value: text)
                }
                cell.onSignatureBeginEditing = { [weak self] in
                    guard let self = self else { return }
                    self.tableView.scrollToRow(at: indexPath, at: .none, animated: true)
                }
                return cell
            } else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: EditProfileTagsCell.reuseId, for: indexPath) as! EditProfileTagsCell
                cell.configure(titles: tagOptions, selectedIndices: selectedTagIndices)
                cell.onSelectionChanged = { [weak self] indices in
                    guard let self = self else { return }
                    self.selectedTagIndices = Set(indices)
                    // 保存初心（用逗号分隔）
                    let selectedTags = indices.sorted().map { self.tagOptions[$0] }
                    let initialHeart = selectedTags.joined(separator: ",")
                    self.saveUserInfo(field: "initialHeart", value: initialHeart)
                }
                return cell
            } else if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: EditProfileActivityCell.reuseId, for: indexPath) as! EditProfileActivityCell
                cell.configure(selectedCategories: selectedActivityCategories)
                cell.onTapped = { [weak self] in
                    // Handle activity type selection
                    self?.showActivityTypeSelection()
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: EditProfileSocialMediaCell.reuseId, for: indexPath) as! EditProfileSocialMediaCell
                let wechatStatus = userInfo?.isWx ?? -1
                let qqStatus = userInfo?.isQq ?? -1
                cell.configure(selectedSocialMedia: selectedSocialMedia, socialAccount: socialAccount, wechatStatus: wechatStatus, qqStatus: qqStatus)
                cell.onWechatSelected = { [weak self] in
                    guard let self = self else { return }
                    self.selectedSocialMedia = self.selectedSocialMedia == 1 ? 0 : 1
                }
                cell.onQQSelected = { [weak self] in
                    guard let self = self else { return }
                    self.selectedSocialMedia = self.selectedSocialMedia == 2 ? 0 : 2
                }
                cell.onSocialMediaInputTapped = { [weak self] in
                    self?.showSocialMediaInput()
                }
                return cell
            }
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 1 else { return nil }
        let header = UIView()
        header.backgroundColor = AppColor.background

        let label = UILabel()
        label.text = "基本信息"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColor.textMain

        header.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 10
        case 1:
            return 40
        case 2:
            return 10
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0
        
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 150
        case 1:
            return 56
        case 2:
            if indexPath.row == 0 {
                return 200
            } else if indexPath.row == 1 {
                return UITableView.automaticDimension
            } else if indexPath.row == 2 {
                return UITableView.automaticDimension
            } else {
                return 140
            }
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        handleItemSelected(at: indexPath)
    }

    // MARK: - Private Methods

    private func getInfoItem(at index: Int) -> EditProfileInfoItem {
        switch index {
        case 0:
            return EditProfileInfoItem(title: "昵称", value: userInfo?.nickname ?? "")
        case 1:
            let genderText = userInfo?.genderRaw == 2 ? "男" : "女"
            return EditProfileInfoItem(title: "性别", value: genderText, showArrow: false, isEditable: false)
        case 2:
            let birthdayValue = userInfo?.birthday ?? ""
            return EditProfileInfoItem(title: "生日", value: formatBirthdayForDisplay(birthdayValue))
        case 3:
            let city = userInfo?.arrangePlayCityLabel ?? ""
            return EditProfileInfoItem(title: "生活城市", value: city.hasSuffix("市") ? String(city.dropLast()) : city)
        case 4:
            return EditProfileInfoItem(title: "年收入", value: userInfo?.annualIncome ?? "", placeholder: "请您按真实情况选择", showArrow: true)
        case 5:
            return EditProfileInfoItem(title: "教育经历", value: userInfo?.education ?? "", placeholder: "您所获得的最高学历", showArrow: true)
        case 6:
            return EditProfileInfoItem(title: "我的职业", value: userInfo?.occupation ?? "", placeholder: "您目前所从事的工作", showArrow: true)
        default:
            return EditProfileInfoItem(title: "", value: "")
        }
    }

    private func handleItemSelected(at indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }

        switch indexPath.row {
        case 0:
            // 编辑昵称
            showEditAlert(title: "修改昵称", placeholder: "请输入昵称", defaultValue: userInfo?.nickname ?? "", field: "nickname")
        case 1:
            // 性别不可修改
            break
        case 2:
            // 选择生日
            showDatePicker()
        case 3:
            // 选择城市
            showCityPicker()
        case 4:
            // 选择年收入
            showIncomePicker()
        case 5:
            // 选择教育经历
            showEducationPicker()
        case 6:
            // 选择职业
            showOccupationPicker()
        default:
            break
        }
    }

    private func handleAvatarTapped() {
        var pickerConfig = PhotoPickerConfig()
        pickerConfig.showsCrop = true
        pickerConfig.singlePhoto = true

        PhotoPicker.show(from: self, config: pickerConfig) { [weak self] image in
            guard let self = self else { return }
            
            // 立即更新UI显示选择的图片
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? EditProfileAvatarCell {
                cell.setImage(image)
            }
            
            // 保存图片到本地
            if let localPath = image.saveToLocal() {
                UserManager.shared.avatarLocalPath = localPath
            }
            
            // 上传到OSS
            self.uploadAvatarToOSS(image: image)
        }
    }
    
    /// 上传头像到OSS
    private func uploadAvatarToOSS(image: UIImage) {
        // 显示加载
        self.showLoading("上传中...")
        
        // 先将图片保存到临时目录获取文件路径
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            self.hideLoading()
            self.showToast("图片处理失败")
            return
        }

        let tempDir = NSTemporaryDirectory()
        let fileName = "avatar_\(Int(Date().timeIntervalSince1970)).jpg"
        let filePath = (tempDir as NSString).appendingPathComponent(fileName)
        let fileURL = URL(fileURLWithPath: filePath)

        do {
            try imageData.write(to: fileURL)
        } catch {
            #if DEBUG
            print("❌ [Avatar] 保存临时文件失败: \(error.localizedDescription)")
            #endif
            self.hideLoading()
            self.showToast("图片保存失败")
            return
        }

        #if DEBUG
        print("📤 [Avatar] 开始上传头像到OSS")
        #endif

        // 1. 获取STS凭证
        OssUploadUtil.getSTS(type: "avatar") { [weak self] sts in
            guard let self = self, let sts = sts else {
                #if DEBUG
                print("❌ [Avatar] 获取STS凭证失败")
                #endif
                self?.hideLoading()
                self?.showToast("获取上传凭证失败")
                return
            }

            // 2. 上传到OSS
            OssUploadUtil.uploadToOSS(sts: sts, filePaths: [filePath]) { [weak self] keys in
                guard let self = self else { return }
                self.hideLoading()
                
                guard let keys = keys, let firstKey = keys.first else {
                    #if DEBUG
                    print("❌ [Avatar] 上传到OSS失败")
                    #endif
                    self.showToast("头像上传失败")
                    return
                }

                #if DEBUG
                print("✅ [Avatar] 上传成功，key: \(firstKey)")
                #endif

                // 3. 调用接口更新头像
                self.saveUserInfo(field: "avatar", value: firstKey)
            }
        }
    }

    private func showEditAlert(title: String, placeholder: String, defaultValue: String, field: String) {
        AppAlert.showInput(
            title: title,
            placeholder: placeholder,
            defaultValue: defaultValue,
            confirmText: "确认",
            onConfirm: { [weak self] text in
                guard let self = self, !text.isEmpty else { return }
                self.saveUserInfo(field: field, value: text)
            }
        )
    }

    private func showGenderSelector() {
        // 可以弹出性别选择器
    }

    private func showDatePicker() {
        if let birthday = userInfo?.birthday, !birthday.isEmpty {
            let formatter = DateFormatter()
            // 先尝试用 yyyy年MM月dd日 格式解析
            formatter.dateFormat = "yyyy年MM月dd日"
            if let date = formatter.date(from: birthday) {
                datePicker.defaultDate = date
            } else {
                // 如果解析失败，尝试用 yyyy-MM-dd 格式解析
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: birthday) {
                    datePicker.defaultDate = date
                }
            }
        }
        datePicker.onCancel = { [weak self] in
            self?.view.endEditing(true)
        }
        datePicker.onConfirm = { [weak self] dateString, _ in
            guard let self = self else { return }
            self.saveUserInfo(field: "birthday", value: dateString)
        }
        datePicker.show(on: view)
    }

    private func showCityPicker() {
        let cityVC = CityPickerViewController()
        cityVC.useHotCities2 = false
        cityVC.onCitySelected = { [weak self] cityName in
            guard let self = self else { return }
            self.saveUserInfo(field: "city", value: cityName)
        }
        navigationController?.pushViewController(cityVC, animated: true)
    }
    
    private func showIncomePicker() {
        let currentValue = userInfo?.income ?? ""
        let selectedIndex = incomeOptions.firstIndex(of: currentValue)
        
        SelectOptionPicker.show(
            title: "当年的收入情况",
            options: incomeOptions,
            selectedIndex: selectedIndex,
            from: self
        ) { [weak self] index, text in
            guard let self = self else { return }
            self.saveUserInfo(field: "income", value: text)
        }
    }
    
    private func showEducationPicker() {
        let currentValue = userInfo?.education ?? ""
        let selectedIndex = educationOptions.firstIndex(of: currentValue)
        
        SelectOptionPicker.show(
            title: "您的最高学历",
            options: educationOptions,
            selectedIndex: selectedIndex,
            from: self
        ) { [weak self] index, text in
            guard let self = self else { return }
            self.saveUserInfo(field: "education", value: text)
        }
    }
    
    private func showOccupationPicker() {
        let isMale = userInfo?.genderRaw == 2
        let currentValue = userInfo?.occupation ?? ""
        
        let occupationVC = OccupationPickerViewController(isMale: isMale, initialOccupation: currentValue)
        occupationVC.onOccupationSelected = { [weak self] occupation in
            guard let self = self else { return }
            self.saveUserInfo(field: "occupation", value: occupation)
        }
        navigationController?.pushViewController(occupationVC, animated: true)
    }
    
    private func showActivityTypeSelection() {
        // 创建 ActivityTypeListViewController
        let activityTypeVC = ActivityTypeListViewController()
        
        // 正向传值：把当前已选择的类型传进去
        if !selectedActivityCategories.isEmpty {
            activityTypeVC.initialSelectedTags = selectedActivityCategories
        }
        
        // 反向传值：接收用户选择的活动类型
        activityTypeVC.onTagsSelected = { [weak self] types in
            guard let self = self else { return }
            self.selectedActivityCategories = types
            // 保存活动（用逗号分隔）
            let activity = types.joined(separator: ",")
            self.saveUserInfo(field: "activity", value: activity)
        }
        
        navigationController?.pushViewController(activityTypeVC, animated: true)
    }
    
    private func showSocialMediaInput() {
        let title = selectedSocialMedia == 1 ? "微信号" : (selectedSocialMedia == 2 ? "QQ号" : "请先选择平台")
        if selectedSocialMedia == 0 {
            showToast("请先选择微信或QQ")
            return
        }
        
        // 检查当前选择的平台是否正在审核中
        let currentStatus = selectedSocialMedia == 1 ? (userInfo?.isWx ?? -1) : (userInfo?.isQq ?? -1)
        if currentStatus == 0 {
            showToast("\(title)正在审核中")
            return
        }
        
        AppAlert.showInput(
            title: title,
            placeholder: "请输入\(title)",
            defaultValue: socialAccount,
            confirmText: "提交",
            keyboardType: .asciiCapable,
            restrictAlphanumeric: true,
            onConfirm: { [weak self] text in
                guard let self = self else { return }
                self.socialAccount = text
                let field = self.selectedSocialMedia == 1 ? "wechat" : "qq"
                self.saveUserInfo(field: field, value: text)
            }
        )
    }
}

// MARK: - EditProfileInfoItem

struct EditProfileInfoItem {
    let title: String
    let value: String
    let placeholder: String
    let showArrow: Bool
    let isEditable: Bool

    init(title: String, value: String, placeholder: String = "", showArrow: Bool = true, isEditable: Bool = true) {
        self.title = title
        self.value = value
        self.placeholder = placeholder
        self.showArrow = showArrow
        self.isEditable = isEditable
    }
}

// MARK: - EditProfileAvatarCell

final class EditProfileAvatarCell: UITableViewCell {

    static let reuseId = "EditProfileAvatarCell"

    var onAvatarTapped: (() -> Void)?

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 44
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = UIColor(hex: "#F5F5F5")
        iv.isUserInteractionEnabled = true
        return iv
    }()

    private let uploadIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "me_update_icon")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let avatarLabel: UILabel = {
        let label = UILabel()
        label.text = "更换头像"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(hex: "#100A1D")
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white

        // 创建底部的上传区域
        let bottomStackView = UIStackView(arrangedSubviews: [uploadIcon, avatarLabel])
        bottomStackView.axis = .horizontal
        bottomStackView.spacing = 8
        bottomStackView.alignment = .center
        bottomStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建主容器
        let mainStackView = UIStackView(arrangedSubviews: [avatarImageView, bottomStackView])
        mainStackView.axis = .vertical
        mainStackView.spacing = 10
        mainStackView.alignment = .center
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStackView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        avatarImageView.addGestureRecognizer(tapGesture)

        mainStackView.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(16)
            make.bottom.lessThanOrEqualToSuperview().offset(-16)
        }
        
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(88)
        }
        
        uploadIcon.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
    }

    func configure(with avatarUrl: String?) {
        if let avatarUrl = avatarUrl, !avatarUrl.isEmpty {
            let fullUrl = AppConfig.API.fullImageURL(path: avatarUrl)
            if let url = URL(string: fullUrl) {
                avatarImageView.kf.setImage(with: url)
            }
            uploadIcon.isHidden = false
            avatarLabel.isHidden = false
        } else {
            avatarImageView.image = nil
            uploadIcon.isHidden = false
            avatarLabel.isHidden = false
        }
    }
    
    func setImage(_ image: UIImage) {
        avatarImageView.image = image
        uploadIcon.isHidden = false
        avatarLabel.isHidden = false
    }

    @objc private func avatarTapped() {
        onAvatarTapped?()
    }
}

// MARK: - EditProfileInfoCell

final class EditProfileInfoCell: UITableViewCell {

    static let reuseId = "EditProfileInfoCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = AppColor.textMain
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor(hex: "#999999")
        label.textAlignment = .right
        return label
    }()

    private let arrowImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "me_edit_more")
        return iv
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#F5F5F5")
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .white

        contentView.addSubviews(titleLabel, valueLabel, arrowImageView, separatorView)

        setupConstraints()
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        arrowImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        valueLabel.snp.makeConstraints { make in
            make.right.equalTo(arrowImageView.snp.left).offset(-8)
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(16)
        }

        separatorView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    func configure(with item: EditProfileInfoItem) {
        titleLabel.text = item.title
        valueLabel.text = item.value.isEmpty ? item.placeholder : item.value
        valueLabel.font = .systemFont(ofSize: 12)
        
        if item.isEditable {
            valueLabel.textColor = item.value.isEmpty ? UIColor(hex: "#888888") : UIColor(hex: "#888888")
            arrowImageView.isHidden = !item.showArrow
            selectionStyle = item.showArrow ? .default : .none
        } else {
            valueLabel.textColor = UIColor(hex: "#100A1D")
            arrowImageView.isHidden = true
            selectionStyle = .none
        }
    }
}

// MARK: - EditProfileSignatureCell

final class EditProfileSignatureCell: UITableViewCell, UITextViewDelegate {

    static let reuseId = "EditProfileSignatureCell"

    var onSignatureChanged: ((String) -> Void)?
    var onSignatureBeginEditing: (() -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "个人签名"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColor.textMain
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "(勇敢表达您的真实想法...)"
        label.font = .systemFont(ofSize: 13)
        label.textColor = UIColor(hex: "#999999")
        return label
    }()

    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 15)
        tv.textColor = AppColor.textMain
        tv.backgroundColor = UIColor(hex: "#F8F8F8")
        tv.layer.cornerRadius = 8
        tv.layer.masksToBounds = true
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return tv
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = UIColor(hex: "#CCCCCC")
        label.textAlignment = .right
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .white
        selectionStyle = .none

        contentView.addSubviews(titleLabel, subtitleLabel, textView, countLabel)
        textView.delegate = self

        setupConstraints()
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(4)
            make.centerY.equalTo(titleLabel)
        }

        textView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(120)
        }

        countLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(textView.snp.bottom).offset(8)
        }
    }

    func configure(with signature: String?) {
        textView.text = signature
        countLabel.text = "\(signature?.count ?? 0)/500"
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        onSignatureBeginEditing?()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text ?? ""
        countLabel.text = "\(text.count)/500"
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        let text = textView.text ?? ""
        onSignatureChanged?(text)
    }
}

// MARK: - EditProfileTagsCell

final class EditProfileTagsCell: UITableViewCell {

    static let reuseId = "EditProfileTagsCell"

    var onSelectionChanged: (([Int]) -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        let fullText = "您报名活动的初心/大胆表露（可多选）"
        let attributedString = NSMutableAttributedString(string: fullText)
        let range = (fullText as NSString).range(of: "（可多选）")
        attributedString.addAttribute(.foregroundColor, value: UIColor(hex: "#888888"), range: range)
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16, weight: .medium), range: NSRange(location: 0, length: fullText.count))
        label.attributedText = attributedString
        return label
    }()

    private let tagFlowView = MultiSelectTagFlowView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .white
        selectionStyle = .none

        contentView.addSubviews(titleLabel, tagFlowView)

        tagFlowView.onSelectionChanged = { [weak self] indices in
            self?.onSelectionChanged?(indices)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        tagFlowView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
            tagFlowView.makeHeightConstraint(make)
        }
    }

    func configure(titles: [String], selectedIndices: Set<Int>) {
        tagFlowView.configure(titles: titles, selectedIndices: selectedIndices)
    }
}

// MARK: - EditProfileActivityCell

final class EditProfileActivityCell: UITableViewCell {

    static let reuseId = "EditProfileActivityCell"

    var onTapped: (() -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        let fullText = "选择您感兴趣的活动（可多选）"
        let attributedString = NSMutableAttributedString(string: fullText)
        let range = (fullText as NSString).range(of: "（可多选）")
        attributedString.addAttribute(.foregroundColor, value: UIColor(hex: "#888888"), range: range)
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16, weight: .medium), range: NSRange(location: 0, length: fullText.count))
        label.attributedText = attributedString
        return label
    }()

    private let tagContainerView = ActivityTagContainerView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .white
        selectionStyle = .none

        contentView.addSubviews(titleLabel, tagContainerView)

        tagContainerView.onTapped = { [weak self] in
            self?.onTapped?()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        tagContainerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(48.fit)
        }
    }

    func configure(selectedCategories: [String]) {
        tagContainerView.selectedCategories = selectedCategories
    }
}

// MARK: - EditProfileSocialMediaCell

final class EditProfileSocialMediaCell: UITableViewCell {
    
    static let reuseId = "EditProfileSocialMediaCell"
    
    var onWechatSelected: (() -> Void)?
    var onQQSelected: (() -> Void)?
    var onSocialMediaInputTapped: (() -> Void)?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "社媒账号（选填）"
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = AppColor.textMain
        return label
    }()
    
    private let wechatButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.cornerRadius = 20
        btn.clipsToBounds = true
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor(hex: "#F0F0F0").cgColor
        btn.tag = 1
        return btn
    }()
    
    private let wechatIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "login_wx_no"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let qqButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.cornerRadius = 20
        btn.clipsToBounds = true
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor(hex: "#F0F0F0").cgColor
        btn.tag = 2
        return btn
    }()
    
    private let qqIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "login_qq_no"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let socialMediaTextField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 14)
        tf.textColor = AppColor.textMain
        tf.attributedPlaceholder = NSAttributedString(
            string: "方便您的活动搭子与您取得联系~",
            attributes: [.foregroundColor: UIColor(hex: "#C0C0C0") ?? .gray, .font: UIFont.systemFont(ofSize: 14)]
        )
        tf.layer.cornerRadius = 20
        tf.layer.masksToBounds = true
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor(hex: "#F0F0F0").cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftViewMode = .always
        return tf
    }()
    
    private let socialMediaArrow: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        iv.image = UIImage(systemName: "chevron.right", withConfiguration: config)
        iv.tintColor = UIColor(hex: "#C0C0C0")
        return iv
    }()
    
    private var selectedSocialMedia: Int = 0 {
        didSet {
            updateSocialMediaUI()
        }
    }
    
    private var socialAccount: String = "" {
        didSet {
            socialMediaTextField.text = socialAccount
        }
    }
    
    // 审核状态：-1 未填写，0 待审核，1 审核通过，2 审核失败
    private var wechatStatus: Int = -1
    private var qqStatus: Int = -1
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        selectionStyle = .none
        
        contentView.addSubviews(titleLabel, wechatButton, qqButton, socialMediaTextField)
        wechatButton.addSubview(wechatIcon)
        qqButton.addSubview(qqIcon)
        socialMediaTextField.addSubview(socialMediaArrow)
        
        wechatButton.addTarget(self, action: #selector(wechatTapped), for: .touchUpInside)
        qqButton.addTarget(self, action: #selector(qqTapped), for: .touchUpInside)
        
        let socialMediaTap = UITapGestureRecognizer(target: self, action: #selector(socialMediaInputTapped))
        socialMediaTextField.addGestureRecognizer(socialMediaTap)
        socialMediaTextField.isUserInteractionEnabled = true
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(5)
        }
        
        wechatButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.width.height.equalTo(40)
        }
        
        wechatIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        qqButton.snp.makeConstraints { make in
            make.left.equalTo(wechatButton.snp.right).offset(12)
            make.centerY.equalTo(wechatButton)
            make.width.height.equalTo(40)
        }
        
        qqIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        socialMediaTextField.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(wechatButton.snp.bottom).offset(12)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        socialMediaArrow.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
        }
    }
    
    func configure(selectedSocialMedia: Int, socialAccount: String, wechatStatus: Int, qqStatus: Int) {
        self.selectedSocialMedia = selectedSocialMedia
        self.socialAccount = socialAccount
        self.wechatStatus = wechatStatus
        self.qqStatus = qqStatus
        
        updatePlaceholderText()
    }
    
    @objc private func wechatTapped() {
        selectedSocialMedia = selectedSocialMedia == 1 ? 0 : 1
        onWechatSelected?()
    }
    
    @objc private func qqTapped() {
        selectedSocialMedia = selectedSocialMedia == 2 ? 0 : 2
        onQQSelected?()
    }
    
    @objc private func socialMediaInputTapped() {
        onSocialMediaInputTapped?()
    }
    
    private func updatePlaceholderText() {
        let isWechat = selectedSocialMedia == 1
        let isQQ = selectedSocialMedia == 2
        
        let isUnderReview = (isWechat && wechatStatus == 0) || (isQQ && qqStatus == 0)
        
        if isUnderReview {
            // 正在审核中
            socialMediaTextField.text = "正在审核中"
            socialMediaTextField.textColor = UIColor(hex: "#999999")
            socialMediaTextField.isUserInteractionEnabled = false
            socialMediaArrow.isHidden = true
        } else {
            // 正常状态
            if socialAccount.isEmpty {
                socialMediaTextField.attributedPlaceholder = NSAttributedString(
                    string: "方便您的活动搭子与您取得联系~",
                    attributes: [.foregroundColor: UIColor(hex: "#C0C0C0") ?? .gray, .font: UIFont.systemFont(ofSize: 14)]
                )
                socialMediaTextField.text = ""
            } else {
                socialMediaTextField.text = socialAccount
            }
            socialMediaTextField.textColor = AppColor.textMain
            socialMediaTextField.isUserInteractionEnabled = true
            socialMediaArrow.isHidden = false
        }
    }
    
    private func updateSocialMediaUI() {
        let isWechat = selectedSocialMedia == 1
        let isQQ = selectedSocialMedia == 2
        
        wechatIcon.image = UIImage(named: isWechat ? "login_wx_yes" : "login_wx_no")
        qqIcon.image = UIImage(named: isQQ ? "login_qq_yes" : "login_qq_no")
        
        wechatButton.backgroundColor = isWechat ? AppColor.buttonDark : .white
        qqButton.backgroundColor = isQQ ? AppColor.buttonDark : .white
        
        updatePlaceholderText()
    }
}

