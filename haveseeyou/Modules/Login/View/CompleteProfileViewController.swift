//
//  CompleteProfileViewController.swift
//  haveseeyou
//
//  完善资料页 - 注册后完善个人信息，无返回按钮，提交即注册成功
//

import UIKit
import SnapKit
import Combine
import YPImagePicker

final class CompleteProfileViewController: BaseViewController {

    /// 完善资料页不使用系统导航栏
    override var prefersNavigationBarHidden: Bool { true }
    /// 不使用标准返回按钮（自定义UI无系统导航栏）
    override var useStandardBackButton: Bool { false }

    // MARK: - ViewModel

    private let viewModel: CompleteProfileViewModel
    
    override var baseViewModel: BaseViewModel? { viewModel }

    // MARK: - UI Components

    /// 标题 "Hi~完善一下资料吧"
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = AppColor.textMain
        label.text = "Hi~完善一下资料吧"
        return label
    }()

    /// 副标题 "让大家更好的认识你"
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = AppColor.textSecondary
        label.text = "让大家更好的认识你"
        return label
    }()

    /// 头像容器
    private let avatarContainer: UIView = {
        let view = UIView()
        return view
    }()

    /// 头像圆形
    private let avatarButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.cornerRadius = 52
        btn.clipsToBounds = true
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor(hex: "#E0E0E0").cgColor
//        btn.backgroundColor = UIColor(hex: "#F5F5F5")
        return btn
    }()

    /// 相机图标
    private let cameraIcon: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        iv.image = UIImage(named: "sy_camera")
        iv.tintColor = UIColor(hex: "#B0B0B0")
        return iv
    }()

    /// "上传头像" 文字
    private let avatarLabel: UILabel = {
        let label = UILabel()
        label.text = "上传头像"
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor(hex: "#B0B0B0")
        label.textAlignment = .center
        return label
    }()

    /// 滚动容器
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.keyboardDismissMode = .onDrag
        return sv
    }()

    private let contentStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 0
        return sv
    }()

    // MARK: - 昵称行

    private let nicknameRow: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.text = "昵称"
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = AppColor.textMain
        return label
    }()

    private let nicknameField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 16)
        tf.textColor = AppColor.textMain
        tf.attributedPlaceholder = NSAttributedString(
            string: "请输入您的昵称",
            attributes: [.foregroundColor: AppColor.textSecondary, .font: UIFont.systemFont(ofSize: 16)]
        )
        tf.textAlignment = .right
        tf.returnKeyType = .done
        return tf
    }()

    private let nicknameSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#F0F0F0")
        return view
    }()

    // MARK: - 性别行

    private let genderRow: UIView = {
        let view = UIView()
        return view
    }()


    /// 男按钮
    private let maleButton: UIButton = {
        let btn = UIButton(type: .custom)
        var config = UIButton.Configuration.plain()
        config.title = "男"
        config.image = UIImage(named: "sy_login_male")

        // 图片和文字间距
        config.imagePadding = 8
        config.baseForegroundColor = AppColor.textMain
        btn.configuration = config
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.layer.cornerRadius = 27
        btn.clipsToBounds = true
        btn.layer.borderColor = UIColor(hex: "#FF100A1D").cgColor
        btn.layer.borderWidth = 1
        btn.tag = 2
        return btn
    }()

    /// 女按钮
    private let femaleButton: UIButton = {
        let btn = UIButton(type: .custom)
        var config = UIButton.Configuration.plain()
        config.title = "女"
        config.image = UIImage(named: "sy_login_female_sel")

        // 图片和文字间距
        config.imagePadding = 8
        config.baseForegroundColor = AppColor.theme
        btn.configuration = config
        
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        
        btn.backgroundColor = AppColor.buttonDark
        btn.layer.cornerRadius = 27
        btn.clipsToBounds = true
        btn.layer.borderColor = UIColor(hex: "#FF100A1D").cgColor
        btn.layer.borderWidth = 1
        btn.tag = 1
        return btn
    }()

    /// 性别提示
    private let genderHintLabel: UILabel = {
        let label = UILabel()
        label.text = "注册之后性别不可更改"
        label.font = .systemFont(ofSize: 12)
        label.textColor = AppColor.textSecondary
        return label
    }()

    // MARK: - 生日行

    private let birthdayRow: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let birthdayLabel: UILabel = {
        let label = UILabel()
        label.text = "生日"
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = AppColor.textMain
        return label
    }()

    private let birthdayValueLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 16)
        label.textColor = AppColor.textSecondary
        label.textAlignment = .right
        return label
    }()

    private let birthdayArrow: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        iv.image = UIImage(systemName: "chevron.right", withConfiguration: config)
        iv.tintColor = UIColor(hex: "#C0C0C0")
        return iv
    }()

    private let birthdaySeparator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#F0F0F0")
        return view
    }()

    /// 通用日期选择器
    private lazy var datePickerPicker: DatePickerPicker = {
        let picker = DatePickerPicker()
        picker.dateFormat = "yyyy年MM月dd日"
        // 不再覆盖 maximumDate，使用 DatePickerPicker 的默认值（18年前）
        picker.defaultDate = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月dd日"
            return formatter.date(from: "2000年01月01日") ?? Date()
        }()
        picker.onConfirm = { [weak self] dateString, _ in
            self?.viewModel.birthday = dateString
            self?.birthdayValueLabel.text = dateString
            self?.birthdayValueLabel.textColor = AppColor.textMain
        }
        return picker
    }()

    // MARK: - 城市行

    private let cityRow: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let cityLabel: UILabel = {
        let label = UILabel()
        label.text = "生活城市"
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = AppColor.textMain
        return label
    }()

    private let cityValueLabel: UILabel = {
        let label = UILabel()
        label.text = "为你优先推荐同城活动及搭子"
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor(hex: "#C0C0C0")
        label.textAlignment = .right
        return label
    }()

    private let cityArrow: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        iv.image = UIImage(systemName: "chevron.right", withConfiguration: config)
        iv.tintColor = UIColor(hex: "#C0C0C0")
        return iv
    }()

    // MARK: - 社媒账号行

    private let socialMediaRow: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let socialMediaLabel: UILabel = {
        let label = UILabel()
        label.text = "社媒账号（选填）"
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = AppColor.textMain
        return label
    }()

    /// 微信按钮
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
        let iv = UIImageView(image: UIImage(named: "login_wx_yes"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    /// QQ按钮
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

    /// 社媒账号输入框
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

    /// 输入框右侧箭头
    private let socialMediaArrow: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        iv.image = UIImage(systemName: "chevron.right", withConfiguration: config)
        iv.tintColor = UIColor(hex: "#C0C0C0")
        return iv
    }()

    // MARK: - 提交按钮

    private let submitButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("提交", for: .normal)
        let gradientColor = UIColor.gradientTextColor(
            size: CGSize(width: 60, height: 24),
            colors: sy_gradientArr
        )
        btn.setTitleColor(gradientColor, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.backgroundColor = AppColor.buttonDark
        btn.layer.cornerRadius = 24.fit
        btn.clipsToBounds = true
        btn.isEnabled = false
        btn.alpha = 0.5
        return btn
    }()

    // MARK: - DatePicker（已封装为 DatePickerPicker，见 Common/DatePickerPicker.swift）

    // MARK: - Init

    init(phoneNumber: String) {
        viewModel = CompleteProfileViewModel(phoneNumber: phoneNumber)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func setupUI() {
        view.backgroundColor = .white
        // 无返回按钮，禁止侧滑返回
        navigationItem.hidesBackButton = true

        view.addSubviews(
            titleLabel,
            subtitleLabel,
            avatarContainer,
            scrollView,
            submitButton
        )

        avatarContainer.addSubviews(avatarButton, cameraIcon, avatarLabel)

        scrollView.addSubview(contentStackView)
        contentStackView.addArrangedSubviews(
            nicknameRow,
            genderRow,
            birthdayRow,
            cityRow,
            socialMediaRow
        )

        // 昵称行
        nicknameRow.addSubviews(nicknameLabel, nicknameField, nicknameSeparator)
        nicknameField.inputAccessoryView = nil

        // 性别行
        genderRow.addSubviews(maleButton, femaleButton, genderHintLabel)

        // 生日行
        birthdayRow.addSubviews(birthdayLabel, birthdayValueLabel, birthdayArrow, birthdaySeparator)

        // 城市行
        cityRow.addSubviews(cityLabel, cityValueLabel, cityArrow)

        // 社媒账号行
        socialMediaRow.addSubviews(socialMediaLabel, wechatButton, qqButton, socialMediaTextField)
        wechatButton.addSubview(wechatIcon)
        qqButton.addSubview(qqIcon)
        socialMediaTextField.addSubview(socialMediaArrow)

        setupConstraints()
        bindActions()
        updateGenderUI()
        updateSocialMediaUI()
    }

    // MARK: - Constraints

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(30)
            make.left.equalToSuperview().offset(38.fit)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.equalTo(titleLabel)
        }

        // 头像
        avatarContainer.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.width.equalTo(106)
            make.height.equalTo(106)
        }

        avatarButton.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(104)
        }

        cameraIcon.snp.makeConstraints { make in
            make.centerX.equalTo(avatarButton)
            make.top.equalTo(avatarButton).offset(28)
        }

        avatarLabel.snp.makeConstraints { make in
            make.top.equalTo(cameraIcon.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }

        // ScrollView
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(avatarContainer.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(submitButton.snp.top).offset(-20)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        // 昵称行
        nicknameRow.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
        nicknameLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(38.fit)
            make.centerY.equalToSuperview()
        }
        nicknameField.snp.makeConstraints { make in
            make.left.equalTo(nicknameLabel.snp.right).offset(16)
            make.right.equalToSuperview().offset(-38.fit)
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
        }
        nicknameSeparator.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(38.fit)
            make.right.equalToSuperview().offset(-38.fit)
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }

        // 性别行
        genderRow.snp.makeConstraints { make in
            make.height.equalTo(100)
        }
//        genderLabel.snp.makeConstraints { make in
//            make.left.equalToSuperview().offset(38.fit)
//            make.top.equalToSuperview().offset(16)
//        }
        maleButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(32.fit)
            make.top.equalToSuperview().offset(12)
            make.width.equalTo(150.fit)
            make.height.equalTo(54)
        }
        femaleButton.snp.makeConstraints { make in
            make.left.equalTo(maleButton.snp.right).offset(12)
            make.centerY.equalTo(maleButton)
            make.width.equalTo(150.fit)
            make.height.equalTo(54)
        }
        genderHintLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(38.fit)
            make.top.equalTo(maleButton.snp.bottom).offset(10)
        }

        // 生日行
        birthdayRow.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
        birthdayLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(38.fit)
            make.centerY.equalToSuperview()
        }
        birthdayArrow.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-38.fit)
            make.centerY.equalToSuperview()
        }
        birthdayValueLabel.snp.makeConstraints { make in
            make.right.equalTo(birthdayArrow.snp.left).offset(-8)
            make.centerY.equalToSuperview()
        }
        birthdaySeparator.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(38.fit)
            make.right.equalToSuperview().offset(-38.fit)
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }

        // 城市行
        cityRow.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
        cityLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(38.fit)
            make.centerY.equalToSuperview()
        }
        cityArrow.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-38.fit)
            make.centerY.equalToSuperview()
        }
        cityValueLabel.snp.makeConstraints { make in
            make.right.equalTo(cityArrow.snp.left).offset(-8)
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualTo(cityLabel.snp.right).offset(12)
        }

        // 社媒账号行
        socialMediaRow.snp.makeConstraints { make in
            make.height.equalTo(140)
        }
        socialMediaLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(38.fit)
            make.top.equalToSuperview().offset(5)
        }
        wechatButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(38.fit)
            make.top.equalTo(socialMediaLabel.snp.bottom).offset(12)
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
            make.left.equalToSuperview().offset(28.fit)
            make.right.equalToSuperview().offset(-28.fit)
            make.top.equalTo(wechatButton.snp.bottom).offset(12)
            make.height.equalTo(40)
        }
        socialMediaArrow.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
        }

        // 提交按钮
        submitButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-30)
            make.centerX.equalToSuperview()
            make.width.equalTo(300.fit)
            make.height.equalTo(48.fit)
        }
    }

    // MARK: - Actions

    private func bindActions() {
        avatarButton.addTarget(self, action: #selector(avatarTapped), for: .touchUpInside)
        maleButton.addTarget(self, action: #selector(genderSelected(_:)), for: .touchUpInside)
        femaleButton.addTarget(self, action: #selector(genderSelected(_:)), for: .touchUpInside)
        wechatButton.addTarget(self, action: #selector(socialMediaSelected(_:)), for: .touchUpInside)
        qqButton.addTarget(self, action: #selector(socialMediaSelected(_:)), for: .touchUpInside)
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        nicknameField.delegate = self
        nicknameField.addTarget(self, action: #selector(nicknameChanged), for: .editingChanged)

        let socialMediaTap = UITapGestureRecognizer(target: self, action: #selector(socialMediaInputTapped))
        socialMediaTextField.addGestureRecognizer(socialMediaTap)
        socialMediaTextField.isUserInteractionEnabled = true

        let birthdayTap = UITapGestureRecognizer(target: self, action: #selector(birthdayTapped))
        birthdayRow.addGestureRecognizer(birthdayTap)

        let cityTap = UITapGestureRecognizer(target: self, action: #selector(cityTapped))
        cityRow.addGestureRecognizer(cityTap)
    }

    // MARK: - Bind ViewModel

    override func bindViewModel() {
        // 提交按钮状态
        viewModel.isSubmittable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canSubmit in
                self?.submitButton.isEnabled = canSubmit
                UIView.animate(withDuration: 0.25) {
                    self?.submitButton.alpha = canSubmit ? 1.0 : 0.5
                }
            }
            .store(in: &cancellables)

        // 注册成功 -> 跳转首页
        viewModel.registerSuccess
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                let complet2 = CompleteProfile2ViewController()
                self?.navigationController?.pushViewController(complet2, animated: true)
            }
            .store(in: &cancellables)

        // 错误
        viewModel.errorSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showToast(message)
            }
            .store(in: &cancellables)
    }

    // MARK: - Event Handlers

    @objc private func avatarTapped() {
        var pickerConfig = PhotoPickerConfig()
        pickerConfig.showsCrop = true
        pickerConfig.cropType = .rectangle(ratio: 1.0)
        pickerConfig.singlePhoto = true

        PhotoPicker.show(from: self, config: pickerConfig) { [weak self] image in
            guard let self = self else { return }
            self.viewModel.avatarImage = image
            self.avatarButton.setImage(image, for: .normal)
            self.cameraIcon.isHidden = true
            self.avatarLabel.isHidden = true
            // 保存图片到本地，存路径供"我的"页读取
            if let localPath = image.saveToLocal() {
                UserManager.shared.avatarLocalPath = localPath
                self.viewModel.avatarURL = localPath
            }

            // 上传图片到OSS
            self.uploadAvatarToOSS(image: image)
        }
    }

    /// 上传头像到OSS
    private func uploadAvatarToOSS(image: UIImage) {
        // 先将图片保存到临时目录获取文件路径
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
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
                return
            }

            // 2. 上传到OSS
            OssUploadUtil.uploadToOSS(sts: sts, filePaths: [filePath]) { [weak self] keys in
                guard let self = self else { return }
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

                // 3. 将OSS返回的key赋值给viewModel
                self.viewModel.avatarURL = firstKey
            }
        }
    }

    @objc private func genderSelected(_ sender: UIButton) {
        viewModel.gender = sender.tag
//        maleButton.isSelected = sender.tag == 1
//        femaleButton.isSelected = sender.tag == 2
        updateGenderUI()
    }

    private func updateGenderUI() {
        let isMale = viewModel.gender == 2

        // 更新男按钮文字颜色（Configuration API 需通过 baseForegroundColor 设置）
        var maleConfig = maleButton.configuration
        maleConfig?.baseForegroundColor = isMale ? AppColor.theme : AppColor.textMain
        maleConfig?.image =  UIImage(named: isMale ?"sy_login_male_sel":"sy_login_male")
        maleButton.configuration = maleConfig
        

        // 更新女按钮文字颜色
        var femaleConfig = femaleButton.configuration
        femaleConfig?.baseForegroundColor = isMale ? AppColor.textMain : AppColor.theme
        femaleConfig?.image =  UIImage(named: isMale ?"sy_login_female":"sy_login_female_sel")
        femaleButton.configuration = femaleConfig

        UIView.animate(withDuration: 0.2) {
            self.maleButton.backgroundColor = isMale ? AppColor.buttonDark : .white
            self.femaleButton.backgroundColor = isMale ? UIColor(hex: "#F5F5F5") : AppColor.buttonDark
        }
    }

    @objc private func socialMediaSelected(_ sender: UIButton) {
        viewModel.socialMedia = sender.tag
        updateSocialMediaUI()
    }

    private func updateSocialMediaUI() {
        let selectedType = viewModel.socialMedia
        let isWechat = selectedType == 1
        let isQQ = selectedType == 2

        wechatIcon.image = UIImage(named: isWechat ? "login_wx_yes" : "login_wx_no")
        qqIcon.image = UIImage(named: isQQ ? "login_qq_yes" : "login_qq_no")

        wechatButton.backgroundColor = isWechat ? AppColor.buttonDark : .white
        qqButton.backgroundColor = isQQ ? AppColor.buttonDark : .white
    }

    @objc private func nicknameChanged() {
        viewModel.nickname = nicknameField.text ?? ""
    }

    @objc private func socialMediaInputTapped() {
        let title = viewModel.socialMedia == 1 ? "微信号" : "QQ号"
        AppAlert.showInput(
            title: title,
            placeholder: "请输入\(title)",
            defaultValue: viewModel.socialAccount,
            keyboardType: .asciiCapable,
            restrictAlphanumeric: true,
            onConfirm: { [weak self] text in
                self?.viewModel.socialAccount = text
                self?.socialMediaTextField.text = text
            }
        )
    }

    @objc private func birthdayTapped() {
        // 如果已有生日，设置默认选中日期
        if !viewModel.birthday.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月dd日"
            if let date = formatter.date(from: viewModel.birthday) {
                datePickerPicker.defaultDate = date
            }
        }
        datePickerPicker.show(on: view)
    }

    @objc private func cityTapped() {
        let cityVC = CityPickerViewController()
        cityVC.useHotCities2 = false
        cityVC.onCitySelected = { [weak self] cityName in
            self?.viewModel.city = cityName
            self?.cityValueLabel.text = cityName
            self?.cityValueLabel.textColor = AppColor.textMain
        }
        navigationController?.pushViewController(cityVC, animated: true)
    }

    @objc private func submitTapped() {
        view.endEditing(true)
        let genderText = viewModel.gender == 2 ? "男" : "女"
        AppAlert.showDouble(message: "性别一旦提交无法修改，您当前选择的性别为\(genderText)", onConfirm:  {
            [weak  self] in
            self?.viewModel.submit()
        })//        viewModel.submit()
    }

}

// MARK: - UITextFieldDelegate

extension CompleteProfileViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    /// 限制昵称最多输入12个中文字符
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // 只对昵称输入框生效
        guard textField == nicknameField else {
            return true
        }
        
        // 最大字符数（中文字符）
        let maxLength = 12
        
        // 获取当前文本
        let currentText = textField.text ?? ""
        
        // 计算新文本长度
        let newText = currentText.replacingCharacters(in: Range(range, in: currentText)!, with: string)
        
        // 返回是否允许输入（长度不超过限制）
        return newText.count <= maxLength
    }
}

// MARK: - UIStackView 扩展

private extension UIStackView {

    func addArrangedSubviews(_ views: UIView...) {
        views.forEach { addArrangedSubview($0) }
    }
}
