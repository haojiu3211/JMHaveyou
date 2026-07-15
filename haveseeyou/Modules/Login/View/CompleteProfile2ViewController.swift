//
//  CompleteProfile2ViewController.swift
//  haveseeyou
//
//  资料补充简化页面
//

import UIKit
import SnapKit
import Combine

// MARK: - CompleteProfile2ViewController

final class CompleteProfile2ViewController: BaseViewController {

    /// 完善资料页不使用系统导航栏
    override var prefersNavigationBarHidden: Bool { true }
    /// 不使用标准返回按钮（自定义UI无系统导航栏）
    override var useStandardBackButton: Bool { false }
    
    // MARK: - UI Components

    private let backButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "app_back"), for: .normal)
        return btn
    }()

    private let skipButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("跳过", for: .normal)
        btn.setTitleColor(UIColor(hex: "#999999"), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15)
        return btn
    }()

    private let tableView = UITableView(frame: .zero, style: .plain)

    private let submitButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("提交", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.layer.cornerRadius = 24
        btn.clipsToBounds = true
        btn.backgroundColor = AppColor.buttonDark

        let gradientColor = UIColor.gradientTextColor(
            size: CGSize(width: 120, height: 30),
            colors: [
                UIColor(hex: "#A2EF4D"),
                UIColor(hex: "#F7FFFF"),
                UIColor(hex: "#F7FFFF")
            ]
        )
        btn.setTitleColor(gradientColor, for: .normal)
        return btn
    }()

    // MARK: - Data

    private let tagOptions = ["认识新朋友", "找同好搭子", "寻找恋爱/脱单", "体验新鲜事物", "满足兴趣爱好", "学习新技能", "向上社交资源", "朋友一起娱乐", "打发枯燥生活"]
    private var selectedTagIndices: Set<Int> = []
    private var selectedActivityCategories: [String] = []
    private var signature: String = ""
//    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        registerKeyboardNotifications()
        updateSubmitButtonState()
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

        let signatureIndexPath = IndexPath(row: 0, section: 3)
        tableView.scrollToRow(at: signatureIndexPath, at: .bottom, animated: true)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        tableView.contentInset = .zero
        tableView.scrollIndicatorInsets = .zero
    }

    override func setupUI() {
        view.backgroundColor = .white

        navigationController?.interactivePopGestureRecognizer?.delegate = self

        view.addSubviews(backButton, skipButton, tableView, submitButton)

        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(Profile2TagsCell.self, forCellReuseIdentifier: Profile2TagsCell.reuseId)
        tableView.register(Profile2ActivityCell.self, forCellReuseIdentifier: Profile2ActivityCell.reuseId)
        tableView.register(Profile2SignatureCell.self, forCellReuseIdentifier: Profile2SignatureCell.reuseId)
        tableView.register(Profile2TitleCell.self, forCellReuseIdentifier: Profile2TitleCell.reuseId)

        setupConstraints()
        bindActions()
    }

    private func setupConstraints() {
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(44)
        }

        skipButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(44)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(60)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(submitButton.snp.top).offset(-20)
        }

        submitButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().offset(-32)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.height.equalTo(48)
        }
    }

    private func bindActions() {
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func skipTapped() {
        showLoading("处理中...")
        NetworkManager.shared
            .request(LoginAPI.skipRegister, as: EmptyData.self)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.hideLoading()
                if case .failure = completion {
                    self?.showToast("跳过失败，请重试")
                }
            } receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.hideLoading()
                NotificationCenter.default.post(name: .userDidLogin, object: nil)
            }
            .store(in: &cancellables)
    }

    @objc private func submitTapped() {
        // 构建参数
        let initialHeart = selectedTagIndices.sorted().map { tagOptions[$0] }.joined(separator: ",")
        let activity = selectedActivityCategories.joined(separator: ",")
        let sign = signature.trimmingCharacters(in: .whitespacesAndNewlines)

        showLoading("提交中...")

        NetworkManager.shared
            .request(
                LoginAPI.appendUserDataPartial(
                    initialHeart: initialHeart,
                    activity: activity,
                    sign: sign
                ),
                as: EmptyData.self
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.hideLoading()
                if case .failure = completion {
                    self?.showToast("提交失败，请重试")
                }
            } receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.hideLoading()
                // 更新本地用户信息
                UserManager.shared.updateUserInfo(initialHeart: initialHeart, shouldNotify: false)
                UserManager.shared.updateUserInfo(activity: activity, shouldNotify: false)
                UserManager.shared.updateUserInfo(sign: sign, shouldNotify: false)
                self.showToast("提交成功")
                NotificationCenter.default.post(name: .userDidLogin, object: nil)
            }
            .store(in: &cancellables)
    }

    /// 更新提交按钮状态：三个字段都填了才能点击
    private func updateSubmitButtonState() {
        let hasInitialHeart = !selectedTagIndices.isEmpty
        let hasActivity = !selectedActivityCategories.isEmpty
        let hasSign = !signature.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let canSubmit = hasInitialHeart && hasActivity && hasSign

        submitButton.isEnabled = canSubmit
        submitButton.alpha = canSubmit ? 1.0 : 0.4
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
            self.updateSubmitButtonState()
            self.tableView.reloadSections([2], with: .none)
        }
        
        navigationController?.pushViewController(activityTypeVC, animated: true)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension CompleteProfile2ViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return tableView.dequeueReusableCell(withIdentifier: Profile2TitleCell.reuseId, for: indexPath) as! Profile2TitleCell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: Profile2TagsCell.reuseId, for: indexPath) as! Profile2TagsCell
            cell.configure(titles: tagOptions, selectedIndices: selectedTagIndices)
            cell.onSelectionChanged = { [weak self] indices in
                guard let self = self else { return }
                self.selectedTagIndices = Set(indices)
                self.updateSubmitButtonState()
            }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: Profile2ActivityCell.reuseId, for: indexPath) as! Profile2ActivityCell
            cell.configure(selectedCategories: selectedActivityCategories)
            cell.onTapped = { [weak self] in
                self?.showActivityTypeSelection()
            }
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: Profile2SignatureCell.reuseId, for: indexPath) as! Profile2SignatureCell
            cell.configure(with: signature)
            cell.onSignatureChanged = { [weak self] text in
                guard let self = self else { return }
                self.signature = text
                self.updateSubmitButtonState()
            }
            cell.onSignatureBeginEditing = { [weak self] in
                let signatureIndexPath = IndexPath(row: 0, section: 3)
                tableView.scrollToRow(at: signatureIndexPath, at: .bottom, animated: true)
            }
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == 1){
            return 270
        }else {
            return UITableView.automaticDimension
        }
//        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        if (indexPath.section == 1){
//            return 270
//        }else {
//            return 200
//        }
        return 200
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
}

// MARK: - UIGestureRecognizerDelegate

extension CompleteProfile2ViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return navigationController?.viewControllers.count ?? 0 > 1
    }
}

// MARK: - Profile2TagFlowView
/// 支持多选的标签流式布局视图
final class Profile2TagFlowView: UIView {

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

// MARK: - Profile2ActivityTagView

/// 活动类型标签容器视图
final class Profile2ActivityTagView: UIView {

    private let maxVisible = 4

    var onTapped: (() -> Void)?

    var selectedCategories: [String] = [] {
        didSet { renderTags() }
    }

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

    private func renderTags() {
        tagPills.forEach { $0.removeFromSuperview() }
        tagPills.removeAll()

        placeholderLabel.isHidden = false
        if selectedCategories.count > 0 {
            placeholderLabel.isHidden = true
        }

        let maxWidth: CGFloat = kScreenWidth - 20.fit - 20 - 30
        let horizontalSpacing: CGFloat = 10.fit
        let horizontalPadding: CGFloat = 20.fit

        let font = UIFont.systemFont(
            ofSize: 13,
            weight: .medium
        )

        var displayCategories: [String] = []
        var totalWidth: CGFloat = 0
        var hasMore = false

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
        for category in displayCategories {
            let pill = makeTagPill(category)
            tagContainer.addSubview(pill)
            pill.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                if let lastView = lastView {
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

    private func makeTagPill(_ text: String) -> UIView {
        let container = UIView()
        container.layer.cornerRadius = 14.fit
        container.layer.masksToBounds = true

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

// MARK: - Profile2SelectedTagsView

final class Profile2SelectedTagsView: UIView {

    var onTapped: (() -> Void)?

    var selectedTitles: [String] = [] {
        didSet { renderTags() }
    }

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "请选择报名活动的初心"
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

    private func renderTags() {
        tagPills.forEach { $0.removeFromSuperview() }
        tagPills.removeAll()

        placeholderLabel.isHidden = false
        if selectedTitles.count > 0 {
            placeholderLabel.isHidden = true
        }

        let maxWidth: CGFloat = kScreenWidth - 20.fit - 20 - 30
        let horizontalSpacing: CGFloat = 10.fit
        let horizontalPadding: CGFloat = 20.fit

        let font = UIFont.systemFont(
            ofSize: 13,
            weight: .medium
        )

        var displayTitles: [String] = []
        var totalWidth: CGFloat = 0
        var hasMore = false

        for title in selectedTitles {
            let textWidth = title.size(
                withAttributes: [
                    .font: font
                ]
            ).width
            let tagWidth = textWidth + horizontalPadding
            let spacing = displayTitles.isEmpty ? 0 : horizontalSpacing

            if totalWidth + spacing + tagWidth > maxWidth {
                hasMore = true
                break
            }

            totalWidth += spacing + tagWidth
            displayTitles.append(title)
        }

        var lastView: UIView?
        for title in displayTitles {
            let pill = makeTagPill(title)
            tagContainer.addSubview(pill)
            pill.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                if let lastView = lastView {
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

    private func makeTagPill(_ text: String) -> UIView {
        let container = UIView()
        container.layer.cornerRadius = 14.fit
        container.layer.masksToBounds = true

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

// MARK: - Profile2TitleCell

final class Profile2TitleCell: UITableViewCell {

    static let reuseId = "Profile2TitleCell"

    private let welcomeLabel1: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = AppColor.textMain
        label.text = "人潮人海中~"
        return label
    }()

    private let welcomeLabel2: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = AppColor.textMain
        label.text = "做自己不一样的烟火"
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
        contentView.addSubviews(welcomeLabel1, welcomeLabel2)

        welcomeLabel1.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(38.fit)
        }

        welcomeLabel2.snp.makeConstraints { make in
            make.top.equalTo(welcomeLabel1.snp.bottom).offset(8)
            make.left.equalTo(welcomeLabel1)
            make.bottom.equalToSuperview().offset(-16)
        }
    }
}

// MARK: - Profile2SignatureCell

final class Profile2SignatureCell: UITableViewCell, UITextViewDelegate {

    static let reuseId = "Profile2SignatureCell"

    var onSignatureChanged: ((String) -> Void)?
    var onSignatureBeginEditing: (() -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "个性签名"
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
        tv.returnKeyType = .done
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
            make.bottom.equalToSuperview().offset(-16)
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
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}

// MARK: - Profile2TagsCell

final class Profile2TagsCell: UITableViewCell {

    static let reuseId = "Profile2TagsCell"

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

// MARK: - Profile2ActivityCell

final class Profile2ActivityCell: UITableViewCell {

    static let reuseId = "Profile2ActivityCell"

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

    private let tagContainerView = Profile2ActivityTagView()

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

