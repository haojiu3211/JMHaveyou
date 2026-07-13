//
//  CallRespondViewController.swift
//  haveseeyou
//
//  一呼百应页面 - 配置活动发起参数（地点、年龄、性别、活动、邀请人数）
//

import UIKit
import SnapKit
import Combine

final class CallRespondViewController: BaseViewController {

    /// 使用标准返回按钮
    override var useStandardBackButton: Bool { true }

    // MARK: - Properties

    /// 关联的活动模型
    private var activity: PublishModel

    /// 当前配置
    private var config: CallRespondConfig

    /// 邀请人数选项
    private let inviteOptions = [50, 100, 200, 300, 400, 500]

    /// 当前选中的邀请人数索引
    private var selectedInviteIndex: Int = 1 // 默认100人

    // MARK: - Init

    init(activity: PublishModel) {
        self.activity = activity
        let cityId = CityDataManager.cityId(for: activity.city).map { "\($0)" } ?? ""
        self.config = CallRespondConfig(
            activity: activity,
            location: activity.city,
            cityId: cityId,
            genderFilter: .unlimited,
            inviteCount: 100
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        return sv
    }()

    private let contentView = UIView()

    /// 顶部 Banner
    private let bannerImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
//        iv.clipsToBounds = true
        iv.image = UIImage(named: "sy_baiying_bg")
        return iv
    }()

    /// 配置卡片容器
    private let configCardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.layer.masksToBounds = true
        return v
    }()

    /// 活动地点行
    private lazy var locationRow: CallRespondRowView = {
        let row = CallRespondRowView(
            icon: UIImage(named: "sy_detai_local"),
            title: "推广城市",
            value: activity.city.isEmpty ? "未设置" : activity.city,
            showArrow: true
        )
        return row
    }()
    
   

    /// 年龄区间行
    private lazy var ageRow: CallRespondRowView = {
        let row = CallRespondRowView(
            icon: UIImage(named: "publish_ic_gender"),
            title: "年龄区间",
            value: "18-25",
            showArrow: true
        )
        return row
    }()

    /// 性别选择行
    private let genderTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = AppColor.textMain
        l.text = "性别选择"
        return l
    }()

    private let genderIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "publish_ic_gender"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    /// 性别按钮 - 男
    private let maleButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("男", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.setTitleColor(UIColor(hex: "#FF888888"), for: .normal)
        btn.backgroundColor = .clear
        btn.layer.cornerRadius = 14
        btn.tag = 0
        return btn
    }()

    /// 性别按钮 - 女
    private let femaleButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("女", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.setTitleColor(UIColor(hex: "#FF888888"), for: .normal)
        btn.backgroundColor = .clear
        btn.layer.cornerRadius = 14
        btn.tag = 1
        return btn
    }()

    /// 性别按钮 - 不限
    private let unlimitedButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("不限", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = AppColor.textMain
        btn.layer.cornerRadius = 14
        btn.tag = 2
        return btn
    }()

    /// 选择活动行
    private lazy var activityRow: CallRespondRowView = {
        let row = CallRespondRowView(
            icon: UIImage(named: "publish_ic_catgr"),
            title: "选择活动",
            value: "\(activity.title)",
            showArrow: true,
            showLine: false
        )
        return row
    }()
    

   
    /// 邀请人数容器
    private let invateCardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.layer.masksToBounds = true
        return v
    }()
    /// 邀请人数标题
    private let inviteTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = AppColor.textMain
        l.text = "邀请人数"
        return l
    }()

    private let inviteIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "publish_ic_num"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    /// 邀请人数网格容器
    private let inviteGridContainer = UIView()

    /// 底部"马上发起"按钮容器
    private let bottomContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    /// 马上发起按钮
    private let launchButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("马上发起", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        let gradientColor = UIColor.gradientTextColor(size: CGSize(width: 100, height: 48), colors: sy_gradientArr)
        btn.setTitleColor(gradientColor, for: .normal)
        btn.backgroundColor = AppColor.buttonDark
        btn.layer.cornerRadius = 24
        btn.clipsToBounds = true
        
        return btn
    }()
    
    // 活动币相关UI
    private let coinSectionView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.masksToBounds = true
        v.layer.cornerRadius = 12
        return v
    }()
    
    private let coinIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "member_bg_coin_icon")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let coinSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "所需活动币："
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColor.textMain
        return label
    }()
    
    
    private let requiredCoinValueLabel: UILabel = {
        let label = UILabel()
        label.text = "---枚"
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = AppColor.textMain
        return label
    }()
    
    private let remainingCoinLabel: UILabel = {
        let label = UILabel()
        label.text = "剩余活动币："
        label.font = .systemFont(ofSize: 14)
        label.textColor = AppColor.textSecondary
        return label
    }()
    
    private let remainingCoinValueLabel: UILabel = {
        let label = UILabel()
        label.text = "---枚"
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = AppColor.textSecondary
        return label
    }()

    // MARK: - Lifecycle

    override func setupUI() {
        view.backgroundColor = .white
        title = "一呼百应"
        contentView.backgroundColor = AppColor.background
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        view.addSubview(launchButton)
//        bottomContainer.addSubview(launchButton)

        launchButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(30)
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
            make.height.equalTo(48)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
//            make.bottom.equalTo(bottomContainer.snp.top)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

//        bottomContainer.snp.makeConstraints { make in
//            make.left.right.bottom.equalToSuperview()
//            make.height.equalTo(88)
//        }

        

        setupContentView()
        
        setupInviteGrid()

        launchButton.addTarget(self, action: #selector(launchTapped), for: .touchUpInside)

        // 活动地点点击手势 - 跳转城市选择
        let tapLocation = UITapGestureRecognizer(target: self, action: #selector(locationTapped))
        locationRow.addGestureRecognizer(tapLocation)
        locationRow.isUserInteractionEnabled = true

        // 年龄区间点击手势
        let tapAge = UITapGestureRecognizer(target: self, action: #selector(ageTapped))
        ageRow.addGestureRecognizer(tapAge)
        ageRow.isUserInteractionEnabled = true

        // 选择活动点击手势
        let tapActivity = UITapGestureRecognizer(target: self, action: #selector(activityRowTapped))
        activityRow.addGestureRecognizer(tapActivity)
        activityRow.isUserInteractionEnabled = true

        // 右上角"发起记录"按钮
        let recordBtn = UIButton(type: .custom)
        recordBtn.setTitle("发起记录", for: .normal)
        recordBtn.titleLabel?.font = .systemFont(ofSize: 13)
        let gard = UIColor.gradientTextColor(size: CGSizeMake(80, 20), colors: sy_gradientArr)
        recordBtn.setTitleColor(gard, for: .normal)
        recordBtn.backgroundColor = AppColor.buttonDark
        recordBtn.layer.cornerRadius = 14
        recordBtn.contentEdgeInsets = UIEdgeInsets(
            top: 5,
            left: 10,
            bottom: 5,
            right: 10
        )
        recordBtn.sizeToFit()
        recordBtn.frame.size.height = 28
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: recordBtn)
        recordBtn.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCoinData()
    }
    
    private func loadCoinData() {
        let cachedCoin = UserDefaults.standard.integer(forKey: "mine_coin")
        remainingCoinValueLabel.text = "\(cachedCoin)枚"
        print("💰 [CallRespond] 刷新活动币显示: \(cachedCoin)")
    }

    // MARK: - Setup Content
    //选择新的活动后更新新的UI
    func updateUIWithData(){
        
    }
    
    private func setupContentView() {
        contentView.addSubviews(
            bannerImageView,
            configCardView,
            invateCardView,
            coinSectionView
        )

        configCardView.addSubviews(
            locationRow,
            ageRow,
            genderIcon,
            genderTitleLabel,
            activityRow
        )
        invateCardView.addSubviews(
            inviteTitleLabel,
            inviteIcon,
            inviteGridContainer)

        // Banner
        bannerImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
//            make.top.left.right.equalToSuperview()
//            make.height.equalTo(180.fit)
        }

        // 配置卡片
        configCardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(260)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        // 活动地点
        locationRow.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }

        // 年龄区间
        ageRow.snp.makeConstraints { make in
            make.top.equalTo(locationRow.snp.bottom)
            make.left.right.height.equalTo(locationRow)
        }

        // 性别标题
        genderIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalTo(ageRow.snp.bottom).offset(14)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        genderTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(genderIcon.snp.right).offset(8)
            make.centerY.equalTo(genderIcon)
        }

        setupGenderButtons()

        // 选择活动
        activityRow.snp.makeConstraints { make in
            make.top.equalTo(genderIcon.snp.bottom).offset(14)
            make.left.right.height.equalTo(locationRow)
            make.bottom.equalToSuperview().offset(-16)
        }

        // 邀请view
        invateCardView.snp.makeConstraints { make in
            make.top.equalTo(configCardView.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(150)
        }
        
        setupCoinSectionUI()

        // 邀请人数标题
        inviteIcon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(CGSize(width: 18, height: 18))
        }

        inviteTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(inviteIcon.snp.right).offset(8)
            make.centerY.equalTo(inviteIcon)
        }

        // 邀请人数网格
        inviteGridContainer.snp.makeConstraints { make in
            make.top.equalTo(inviteIcon.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(100)
            
        }
    }
    
    // MARK: - Setup Coin Section UI
    private func setupCoinSectionUI() {
        coinSectionView.addSubviews(coinIconImageView, coinSectionLabel, requiredCoinValueLabel, remainingCoinLabel, remainingCoinValueLabel)
        
        coinSectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(invateCardView.snp.bottom).offset(16)
            make.height.equalTo(85)
            make.bottom.equalToSuperview().inset(100)
        }
        
        coinIconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.top.equalToSuperview().offset(16)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        coinSectionLabel.snp.makeConstraints { make in
            make.left.equalTo(coinIconImageView.snp.right).offset(5)
            make.centerY.equalTo(coinIconImageView)
        }
        
        requiredCoinValueLabel.snp.makeConstraints { make in
            make.left.equalTo(coinSectionLabel.snp.right)
            make.centerY.equalTo(coinSectionLabel)
        }
        
        remainingCoinLabel.snp.makeConstraints { make in
            make.left.equalTo(coinSectionLabel)
            make.top.equalTo(coinSectionLabel.snp.bottom).offset(12)
        }
        
        remainingCoinValueLabel.snp.makeConstraints { make in
            make.left.equalTo(remainingCoinLabel.snp.right)
            make.centerY.equalTo(remainingCoinLabel)
        }
        
        updateRequiredCoin()
    }
   
    
    // MARK: - 性别按钮（与 PublishViewController 一致的 StackView 样式）
    private func setupGenderButtons() {
        let genderStackView = UIStackView(arrangedSubviews: [maleButton, femaleButton, unlimitedButton])
        genderStackView.axis = .horizontal
        genderStackView.spacing = 1
        genderStackView.backgroundColor = AppColor.background
        genderStackView.layer.masksToBounds = true
        genderStackView.layer.cornerRadius = 14
        genderStackView.distribution = .fillEqually
        configCardView.addSubview(genderStackView)

        genderStackView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(genderTitleLabel)
            make.width.equalTo(180)
            make.height.equalTo(28)
        }

        maleButton.addTarget(self, action: #selector(genderTapped(_:)), for: .touchUpInside)
        femaleButton.addTarget(self, action: #selector(genderTapped(_:)), for: .touchUpInside)
        unlimitedButton.addTarget(self, action: #selector(genderTapped(_:)), for: .touchUpInside)
    }

    @objc private func genderTapped(_ sender: UIButton) {
        [maleButton, femaleButton, unlimitedButton].forEach {
            $0.backgroundColor = .clear
            $0.setTitleColor(UIColor(hex: "#FF888888"), for: .normal)
        }
        sender.backgroundColor = AppColor.textMain
        sender.setTitleColor(.white, for: .normal)

        switch sender.tag {
        case 0: config.genderFilter = .male
        case 1: config.genderFilter = .female
        default: config.genderFilter = .unlimited
        }
    }

    // MARK: - 邀请人数网格

    private func setupInviteGrid() {
        inviteGridContainer.subviews.forEach { $0.removeFromSuperview() }

        let columns = 3
        let spacing: CGFloat = 10
        let itemHeight: CGFloat = 40

        for (i, count) in inviteOptions.enumerated() {
            let row = i / columns
            let col = i % columns

            let btn = UIButton(type: .custom)
            btn.setTitle("\(count)人", for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 14)
            btn.layer.cornerRadius = 8
//            btn.layer.borderWidth = 1
//            btn.layer.borderColor = UIColor(hex: "#FFD9D9D9").cgColor
            btn.backgroundColor = .white
            btn.setTitleColor(AppColor.textMain, for: .normal)
            btn.tag = i
            btn.addTarget(self, action: #selector(inviteCountTapped(_:)), for: .touchUpInside)

            inviteGridContainer.addSubview(btn)

            let itemWidth = 100.0
            btn.snp.makeConstraints { make in
                make.width.equalTo(itemWidth)
                make.height.equalTo(itemHeight)
                make.top.equalToSuperview().offset(CGFloat(row) * (itemHeight + spacing))
                make.left.equalToSuperview().offset(CGFloat(col) * (itemWidth + spacing))
            }
        }

        // 默认选中100人
        updateInviteSelection(index: selectedInviteIndex)
    }

    @objc private func inviteCountTapped(_ sender: UIButton) {
        selectedInviteIndex = sender.tag
        config.inviteCount = inviteOptions[sender.tag]
        updateInviteSelection(index: sender.tag)
        updateRequiredCoin()
        
        if (sender.tag == 0){
            self.activity.participantCount = 50
            self.config.activity = self.activity
        }else {
            self.activity.participantCount = sender.tag * 100
            self.config.activity = self.activity
            
        }
    }
    
    private func updateRequiredCoin() {
        let inviteCount = inviteOptions[selectedInviteIndex]
        let requiredCoin = inviteCount * 10
        requiredCoinValueLabel.text = "\(requiredCoin)枚"
    }

    private func updateInviteSelection(index: Int) {
        for (i, subview) in inviteGridContainer.subviews.enumerated() {
            guard let btn = subview as? UIButton else { continue }
            if i == index {
                btn.setBackgroundImage(UIImage(named: "sy_invatbtn_select"), for: .normal)
                btn.setTitleColor(UIColor(hex: "#FF539D00"), for: .normal)
               

            } else {
                btn.setBackgroundImage(UIImage(named: "sy_invatbtn_unselect"), for: .normal)
                btn.setTitleColor(UIColor(hex: "#FF888888"), for: .normal)

            }
        }
    }

    // MARK: - Actions

    @objc private func launchTapped() {
        
        print("🎯 [CallRespond] 点击发起按钮，开始检查活动币余额")
        
        let inviteCount = inviteOptions[selectedInviteIndex]
        let requiredCoin = inviteCount * 10
        let cachedCoin = UserDefaults.standard.integer(forKey: "mine_coin")
        
        print("💰 [CallRespond] 所需活动币: \(requiredCoin), 剩余活动币: \(cachedCoin)")
        
        guard cachedCoin >= requiredCoin else {
            print("❌ [CallRespond] 活动币余额不足，弹出充值提示")
            AppAlert.showSingle(
                title: "提示",
                message: "您的活动币余额不足，请选择以下权益进行开通。",
                confirmText: "充值活动币",
                messageAlignment: .center
            ) { [weak self] in
                // 点击开通会员，跳转到会员中心
                self?.pushWallet()
            }
        
            return
        }
        
        print("✅ [CallRespond] 活动币余额充足，继续发起")
        
        let genderStr: String
        switch config.genderFilter {
        case .unlimited: genderStr = "0"
        case .female: genderStr = "1"
        case .male: genderStr = "2"
        }

        NetworkManager.shared
            .request(PublishAPI.informPublish(
                meetActivityId: activity.id ?? "",
                cityId: config.cityId,
                ageMin: "\(config.ageMin)",
                ageMax: "\(config.ageMax)",
                gender: genderStr,
                inviteCount: "\(config.inviteCount)"
            ), as: APIResponse<EmptyResponse>.self)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    AppToast.show("发起失败: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                if response.code == 0 {
                    print("✅ [CallRespond] 发起成功")
                    AppToast.show("发起成功")
                    let vc = CallRespondRecordViewController()
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    AppToast.show(response.message ?? "发起失败")
                }
            })
            .store(in: &cancellables)
    }
    
    // MARK: - 导航跳转
    private func pushWallet() {
        print("🚀 [CallRespond] 跳转到钱包页面")
        let vc = MyWalletViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func pushMemberCenter() {
        print("🚀 [CallRespond] 跳转到会员中心页面")
        let vc = MemberCenterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func recordTapped() {
        
//        let web = WebViewController(urlString: webUrlPublishRecord)
//        navigationController?.pushViewController(web, animated: true)
        let vc = CallRespondRecordViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - 行点击事件

    @objc private func locationTapped() {
        let cityPicker = CityPickerViewController()
        cityPicker.onCitySelected = { [weak self] cityName in
            guard let self = self else { return }
            let cityId = CityDataManager.cityId(for: cityName).map { "\($0)" } ?? ""
            self.config.location = cityName
            self.config.cityId = cityId
            self.locationRow.updateValue(cityName)
            self.activity.city = cityName
        }
        navigationController?.pushViewController(cityPicker, animated: true)
    }

    @objc private func ageTapped() {
        let picker = AgeRangePickerView()
        picker.show(defaultMin: config.ageMin, defaultMax: config.ageMax)
        picker.onConfirm = { [weak self] minAge, maxAge in
            guard let self = self else { return }
            self.config.ageMin = minAge
            self.config.ageMax = maxAge
            self.ageRow.updateValue("\(minAge)-\(maxAge)")
        }
    }

    @objc private func activityRowTapped() {
        //这里应该是用户审核过的活动那个页面选择
        let selectVC = SelectActivityViewController()
        selectVC.onActivitySelected = { [weak self] selectedActivity in
                guard let self = self else { return }
                
                // 使用选中的活动数据
                print("✅ 选中的活动: \(selectedActivity.title)")
                
                // 更新界面显示
            self.activity = selectedActivity
            self.config.activity = self.activity
            
            self.locationRow.updateValue(self.activity.city)
            self.activityRow.updateValue(self.activity.title)
            
         }
        navigationController?.pushViewController(selectVC, animated: true)
    }
}

// MARK: - 配置行视图

final class CallRespondRowView: UIView {

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = AppColor.textMain
        return l
    }()

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = AppColor.textSecondary
        l.textAlignment = .right
        return l
    }()

    private let arrowView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "app_right_gray")
        return iv
    }()

    private let bottomLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#FFE5E5E5")
        return v
    }()

    init(icon: UIImage?, title: String, value: String, showArrow: Bool = true,showLine: Bool = true) {
        super.init(frame: .zero)
        iconView.image = icon
        titleLabel.text = title
        valueLabel.text = value
        arrowView.isHidden = !showArrow
        bottomLine.isHidden = !showLine

        addSubviews(iconView, titleLabel, valueLabel, arrowView, bottomLine)

        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(8)
            make.centerY.equalToSuperview()
        }

        valueLabel.snp.makeConstraints { make in
            if showArrow {
                make.left.equalTo(titleLabel.snp.right).offset(8)
                make.right.equalTo(arrowView.snp.left).offset(-4)
            } else {
                make.left.equalTo(titleLabel.snp.right).offset(8)
                make.right.equalToSuperview().offset(-4)
            }
            make.centerY.equalToSuperview()
        }

        arrowView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 15, height: 15))
        }

        bottomLine.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func updateValue(_ value: String) {
        valueLabel.text = value
    }
}
