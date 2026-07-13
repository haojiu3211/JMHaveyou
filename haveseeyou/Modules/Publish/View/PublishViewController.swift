//
//  PublishViewController.swift
//  haveseeyou
//

import UIKit
import SnapKit
import Combine


final class PublishViewController: BaseViewController {
    
    // MARK: - ViewModel
    private let viewModel = PublishViewModel()
    
    override var baseViewModel: BaseViewModel? { viewModel }
    
    // 图片数组
    private var selectedImages: [UIImage] = []
    private let maxImageCount = 9
    
    /// Tab根页面隐藏系统导航栏
    override var prefersNavigationBarHidden: Bool { true }
    /// 不使用标准返回按钮
    override var useStandardBackButton: Bool { false }
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.backgroundColor = .clear
        sv.contentInsetAdjustmentBehavior = .never
        sv.alwaysBounceVertical = true
        return sv
    }()
    
    private let contentView = UIView()
   
    // 页面标题
    private let pageTitle: UILabel = {
        let l = UILabel()
        l.text = "发布"
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = AppColor.textMain
        return l
    }()
    let topBgBiew: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.layer.masksToBounds = true
        return v
    }()
    
    // 图片区域
    private let imageContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        return v
    }()
    
    private lazy var imageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(PublishImageCell.self, forCellWithReuseIdentifier: PublishImageCell.identifier)
        return cv
    }()
    
    //图标
    private let icPeopelNumImg:UIImageView = {
        let iv = UIImageView(image: UIImage(named: "publish_ic_num"))
        return iv
    }()
    private let icGenderImg:UIImageView = {
        let iv = UIImageView(image: UIImage(named: "publish_ic_gender"))
        return iv
    }()
    private let icTimeImg:UIImageView = {
        let iv = UIImageView(image: UIImage(named: "publish_ic_time"))
        return iv
    }()
    private let icLocalImg:UIImageView = {
        let iv = UIImageView(image: UIImage(named: "sy_detai_local"))
        return iv
    }()
    private let icCatgrImg:UIImageView = {
        let iv = UIImageView(image: UIImage(named: "publish_ic_catgr"))
        return iv
    }()
    
    // 活动费用图标
    private let icExpenseImg: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "publish_ic_expense"))
        return iv
    }()
    
    private let addImageButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("+ 添加优质图片\n更吸引人", for: .normal)
        btn.titleLabel?.numberOfLines = 2
        btn.titleLabel?.textAlignment = .center
        btn.setTitleColor(AppColor.textSecondary, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        return btn
    }()
    
    // 标题输入
    private let titleInputField: UITextField = {
        let tf = UITextField()
        
        tf.attributedPlaceholder =
                NSAttributedString(
                    string: "输入活动标题",
                    attributes: [
                        .foregroundColor: UIColor.lightGray
                    ]
                )
        tf.textColor = AppColor.textMain
        tf.borderStyle = .roundedRect
        tf.backgroundColor = .white
        tf.font = .systemFont(ofSize: 14)
        return tf
    }()
    
    // 描述输入
    private let descriptionInputView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .white
        tv.textColor = AppColor.textSecondary
        tv.font = .systemFont(ofSize: 14)
        tv.layer.cornerRadius = 8
        tv.backgroundColor = .white
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return tv
    }()
    
    // 描述输入占位文字
    private let descriptionPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "注意事项：添加正文"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.numberOfLines = 0
        return label
    }()
    
    // 顶部背景视图
    private let topBgView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()
    
    //中间卡片
    let midCardView:UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.masksToBounds = true
        v.layer.cornerRadius = 12
        return v
    }()
    
    // 参与人数
    private let participantCountContainer: UIView = {
        let v = UIView()
//        v.backgroundColor = UIColor(hex: "#F5F5F5")
//        v.layer.cornerRadius = 12
        return v
    }()
    
    private let participantCountLabel: UILabel = {
        let l = UILabel()
        l.text = "活动人数"
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = AppColor.textMain
        return l
    }()
    
    private let decreaseButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("−", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        btn.setTitleColor(AppColor.textMain, for: .normal)
        return btn
    }()
    
    private let countLabel: UILabel = {
        let l = UILabel()
        l.text = "1"
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = AppColor.textMain
        l.textAlignment = .center
        return l
    }()
    
    private let increaseButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("+", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        btn.setTitleColor(AppColor.textMain, for: .normal)
        return btn
    }()
    
    // 性别要求
    private let genderContainer: UIView = {
        let v = UIView()
//        v.backgroundColor = .purple
//        v.layer.cornerRadius = 12
        return v
    }()
    
    private let genderLabel: UILabel = {
        let l = UILabel()
        l.text = "性别要求"
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = AppColor.textMain
        return l
    }()
    
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
    
    // 活动时间
    private let timeContainer: UIView = {
        let v = UIView()
        return v
    }()
    
    private let timeLabel: UILabel = {
        let l = UILabel()
        l.text = "活动时间"
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = AppColor.textMain
        return l
    }()
    
    // 周末假期按钮
    private let weekendButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("周末假期", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        btn.setTitleColor(AppColor.textSecondary, for: .normal)
        btn.setTitleColor(.white, for: .selected)
        btn.backgroundColor = AppColor.background
        btn.layer.cornerRadius = 14
        btn.tag = 0
        return btn
    }()
    
    // 长期有效按钮
    private let longTermButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("长期有效", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitleColor(.white, for: .selected)
        btn.backgroundColor = AppColor.textMain
        btn.layer.cornerRadius = 14
        btn.isSelected = true // 默认选中
        btn.tag = 1
        return btn
    }()
    
    // 设置时间按钮
    private let setTimeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("设置时间", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.setTitleColor(AppColor.textSecondary, for: .normal)
        btn.backgroundColor = .clear
        btn.tag = 2
        return btn
    }()
    
    // 时间显示标签（选择具体时间后显示）
    private let timeDisplayLabel: UILabel = {
        let l = UILabel()
        l.text = ""
        l.font = .systemFont(ofSize: 14)
        l.textColor = AppColor.textSecondary
        l.textAlignment = .right
        l.isHidden = true // 默认隐藏
        return l
    }()
    
    // 右箭头图标
    private let timeArrowIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "app_right_gray"))
        return iv
    }()
    
    // 活动地点
    private let locationContainer: UIView = {
        let v = UIView()
//        v.backgroundColor = UIColor(hex: "#F5F5F5")
//        v.layer.cornerRadius = 12
        return v
    }()
    
    private let locationLabel: UILabel = {
        let l = UILabel()
        l.text = "活动地点"
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = AppColor.textMain
        return l
    }()
    
    private let locationDisplayLabel: UILabel = {
        let l = UILabel()
        l.text = "未设置"
        l.font = .systemFont(ofSize: 14)
        l.textColor = AppColor.textSecondary
        l.textAlignment = .right
        return l
    }()
    
    // 活动类型
    private let categoryContainer: UIView = {
        let v = UIView()
//        v.backgroundColor = UIColor(hex: "#F5F5F5")
//        v.layer.cornerRadius = 12
        return v
    }()
    
    private let categoryLabel: UILabel = {
        let l = UILabel()
        l.text = "活动类型"
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = AppColor.textMain
        return l
    }()
    
    private let categoryDisplayLabel: UILabel = {
        let l = UILabel()
        l.text = ""
        l.font = .systemFont(ofSize: 14)
        l.textColor = AppColor.textSecondary
        l.textAlignment = .right
        l.lineBreakMode = .byTruncatingTail
        return l
    }()
    
    // 同意条款
    private let agreeCheckbox: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "publish_unselect"), for: .normal)
        btn.setImage(UIImage(named: "publish_select"), for: .selected)
        btn.backgroundColor = .clear
//        btn.tintColor = AppColor.textMain
        return btn
    }()
    
    private let agreeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColor.textSecondary
        l.isUserInteractionEnabled = true // 启用用户交互
        
        // 使用富文本，给《活动内容发布准则》添加下划线
        let fullText = "我已阅读并同意《活动内容发布准则》"
        let attributedString = NSMutableAttributedString(string: fullText)
        
        // 设置整体颜色
        attributedString.addAttribute(.foregroundColor, 
                                     value: AppColor.textSecondary, 
                                     range: NSRange(location: 0, length: fullText.count))
        
        // 找到《活动内容发布准则》的范围
        if let range = fullText.range(of: "《活动内容发布准则》") {
            let nsRange = NSRange(range, in: fullText)
            // 添加下划线
            attributedString.addAttribute(.underlineStyle, 
                                         value: NSUnderlineStyle.single.rawValue, 
                                         range: nsRange)
            // 可以设置不同的颜色（可选）
            attributedString.addAttribute(.foregroundColor, 
                                         value: AppColor.textMain, 
                                         range: nsRange)
        }
        
        l.attributedText = attributedString
        return l
    }()
    
    // 活动费用卡片
    private let expenseCardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.masksToBounds = true
        v.layer.cornerRadius = 12
        return v
    }()
    
    private let expenseLabel: UILabel = {
        let l = UILabel()
        l.text = "活动费用"
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = AppColor.textMain
        return l
    }()
    
    // 费用按钮 - 免费
    private let freeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "publish_free_select"), for: .selected)
        btn.setImage(UIImage(named: "publish_free_unselect"), for: .normal)
        btn.backgroundColor = .clear
        btn.isSelected = true // 默认选中
        btn.tag = 0
        btn.imageView?.contentMode = .scaleAspectFit
        btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        return btn
    }()
    
    // 费用按钮 - 平摊费用
    private let averageButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "publish_average_select"), for: .selected)
        btn.setImage(UIImage(named: "publish_average_unselect"), for: .normal)
        btn.tag = 1
        btn.backgroundColor = .clear
        btn.imageView?.contentMode = .scaleAspectFit
        btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        return btn
    }()
    
    // 费用按钮 - 由你买单
    private let yourBuyButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "publish_yourbuy_select"), for: .selected)
        btn.setImage(UIImage(named: "publish_yourbuy_unselect"), for: .normal)
        btn.imageView?.contentMode = .scaleAspectFit
        btn.tag = 2
        btn.backgroundColor = .clear
        btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        return btn
    }()
    
    // 费用按钮 - 我买单
    private let myBuyButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "publish_mybuy_select"), for: .selected)
        btn.setImage(UIImage(named: "publish_mybuy_unselect"), for: .normal)
        btn.imageView?.contentMode = .scaleAspectFit
        btn.tag = 3
        btn.backgroundColor = .clear
        btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        return btn
    }()
    
    // 发布按钮
    private let publishButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("发布活动", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        let grad = UIColor.gradientTextColor(size: CGSizeMake(100, 30), colors: sy_gradientArr)
        btn.setTitleColor(grad, for: .normal)
        btn.backgroundColor = AppColor.buttonDark
        btn.layer.cornerRadius = 24
        return btn
    }()
    
    // MARK: - Lifecycle
    override func setupUI() {
        view.backgroundColor = .white
        
        view.addSubviews(pageTitle, scrollView)
        contentView.backgroundColor = AppColor.background
        scrollView.addSubview(contentView)
        
        pageTitle.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.centerX.equalToSuperview()
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(pageTitle.snp.bottom).offset(16)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom) // 使用 safeAreaLayoutGuide 避免被 TabBar 遮挡
        }
        
        contentView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        
        setupTopUI()
        setupMidUI()
        setupExpenseUI()
        setupPublishButton()
        setupAgreementSection()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 调试：打印 scrollView 的 contentSize
        print("📏 ScrollView frame: \(scrollView.frame)")
        print("📏 ContentView frame: \(contentView.frame)")
        print("📏 ScrollView contentSize: \(scrollView.contentSize)")
        print("📏 ScrollView isScrollEnabled: \(scrollView.isScrollEnabled)")
    }

    private func setupTopUI() {
        contentView.addSubview(topBgView)
        topBgView.addSubviews(imageContainer,titleInputField,descriptionInputView)
        imageContainer.addSubview(imageCollectionView)
        
        topBgView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(16)
            make.height.equalTo(280)
        }
        
        imageContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.right.equalToSuperview()
            make.height.equalTo(112)
        }
        
        imageCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
      
        titleInputField.snp.makeConstraints { make in
            make.top.equalTo(imageContainer.snp.bottom).offset(0)
            make.left.right.equalToSuperview().inset(12)
            make.height.equalTo(30)
        }
        
        descriptionInputView.delegate = self
      
        descriptionInputView.snp.makeConstraints { make in
            make.top.equalTo(titleInputField.snp.bottom).offset(5)
            make.right.equalToSuperview().inset(12)
            make.left.equalToSuperview().inset(5)
            make.height.equalTo(100)

        }
        
        // 添加占位文字标签
        descriptionInputView.addSubview(descriptionPlaceholderLabel)
        descriptionPlaceholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-16)
        }
        
        titleInputField.addTarget(self, action: #selector(titleChanged), for: .editingChanged)
    }
    
    // MARK: - Setup Participant Count Section
    private func setupMidUI() {
        contentView.addSubview(midCardView)
        midCardView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().inset(16)
            make.top.equalTo(topBgView.snp.bottom).offset(16)
            make.height.equalTo(260)
        }
        //活动人数
        midCardView.addSubview(participantCountContainer)
        let v1 = SyLineView()
        let countBgView = UIView()
        countBgView.backgroundColor = AppColor.background
        countBgView.layer.masksToBounds = true
        countBgView.layer.cornerRadius = 16
        countBgView.addSubviews(decreaseButton, countLabel, increaseButton)
        participantCountContainer.addSubviews(icPeopelNumImg,participantCountLabel, countBgView,v1)
        
       
        
        participantCountContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            
            make.right.left.equalToSuperview().inset(12)
            make.height.equalTo(50)
        }
        icPeopelNumImg.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 15, height: 15))
        }
        participantCountLabel.snp.makeConstraints { make in
            
            make.left.equalTo(icPeopelNumImg.snp.right).offset(5)
            make.centerY.equalToSuperview()
        }
        countBgView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(5)
            make.width.equalTo(102)
            make.height.equalTo(32)
        }
        increaseButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-5)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }
        
        countLabel.snp.makeConstraints { make in
            make.right.equalTo(increaseButton.snp.left)
            make.centerY.equalToSuperview()
            make.width.equalTo(30)
        }
        
        decreaseButton.snp.makeConstraints { make in
            make.right.equalTo(countLabel.snp.left)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }
        v1.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(12)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        
        decreaseButton.addTarget(self, action: #selector(decreaseCount), for: .touchUpInside)
        increaseButton.addTarget(self, action: #selector(increaseCount), for: .touchUpInside)
        //性别要求
        midCardView.addSubview(genderContainer)
        let v2 = SyLineView()
        genderContainer.addSubviews(icGenderImg,genderLabel,v2)
        
        genderContainer.snp.makeConstraints { make in
            make.top.equalTo(participantCountContainer.snp.bottom)
            make.left.right.equalToSuperview().inset(12)
            make.height.equalTo(50)
        }
        icGenderImg.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 15, height: 15))
        }
        genderLabel.snp.makeConstraints { make in
            make.left.equalTo(icGenderImg.snp.right).offset(5)
            make.centerY.equalToSuperview()
        }
        
        v2.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(12)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        let genderStackView = UIStackView(arrangedSubviews: [maleButton, femaleButton, unlimitedButton])
        genderStackView.axis = .horizontal
        genderStackView.spacing = 1
        genderStackView.backgroundColor = AppColor.background
        genderStackView.layer.masksToBounds = true
        genderStackView.layer.cornerRadius = 14
        genderStackView.distribution = .fillEqually
        genderContainer.addSubview(genderStackView)
        genderStackView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-5)
            make.centerY.equalToSuperview()
            make.width.equalTo(180)
        }
        
        maleButton.addTarget(self, action: #selector(genderTapped(_:)), for: .touchUpInside)
        femaleButton.addTarget(self, action: #selector(genderTapped(_:)), for: .touchUpInside)
        unlimitedButton.addTarget(self, action: #selector(genderTapped(_:)), for: .touchUpInside)
        
        //活动时间
        midCardView.addSubview(timeContainer)
        let v3 = SyLineView()
        
        // 创建按钮容器
        let timeButtonsContainer = UIView()
        timeButtonsContainer.backgroundColor = .clear
        
        timeContainer.addSubviews(icTimeImg, timeLabel, timeButtonsContainer, v3)
        
        // 添加3个按钮和时间显示标签到容器
        timeButtonsContainer.addSubviews(weekendButton, longTermButton, setTimeButton, timeDisplayLabel, timeArrowIcon)
        
        timeContainer.snp.makeConstraints { make in
            make.top.equalTo(genderContainer.snp.bottom)
            make.left.right.equalToSuperview().inset(12)
            make.height.equalTo(50)
        }
        
        icTimeImg.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 15, height: 15))
        }
        
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(icTimeImg.snp.right).offset(5)
            make.centerY.equalToSuperview()
        }
        
        timeButtonsContainer.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-5)
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
        }
        
        // 右箭头
        timeArrowIcon.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 14, height: 14))
        }
        
        // 时间显示标签（选择具体时间后显示）
        timeDisplayLabel.snp.makeConstraints { make in
            make.right.equalTo(timeArrowIcon.snp.left).offset(-5)
            make.centerY.equalToSuperview()
        }
        
        // 设置时间按钮
        setTimeButton.snp.makeConstraints { make in
            make.right.equalTo(timeArrowIcon.snp.left).offset(-1)
            make.centerY.equalToSuperview()
            make.height.equalTo(28)
            make.width.equalTo(66)
        }
        
        // 长期有效按钮
        longTermButton.snp.makeConstraints { make in
            make.right.equalTo(setTimeButton.snp.left).offset(-4)
            make.centerY.equalToSuperview()
            make.height.equalTo(28)
            make.width.equalTo(66)
        }
        
        // 周末假期按钮
        weekendButton.snp.makeConstraints { make in
            make.right.equalTo(longTermButton.snp.left).offset(-4)
            make.centerY.equalToSuperview()
            make.height.equalTo(28)
            make.width.equalTo(66)
            make.left.equalToSuperview() // 确保容器宽度
        }
        
        v3.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(12)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        
        // 添加按钮点击事件
        weekendButton.addTarget(self, action: #selector(timeOptionTapped(_:)), for: .touchUpInside)
        longTermButton.addTarget(self, action: #selector(timeOptionTapped(_:)), for: .touchUpInside)
        setTimeButton.addTarget(self, action: #selector(setTimeTapped), for: .touchUpInside)
        
        // 添加时间容器点击手势（用于重新选择具体时间）
        let tapTimeContainer = UITapGestureRecognizer(target: self, action: #selector(timeContainerTapped))
        timeContainer.addGestureRecognizer(tapTimeContainer)
        
        //活动地点
        midCardView.addSubview(locationContainer)
        let v4 = SyLineView()
        let ivRight4 = UIImageView(image: UIImage(named: "app_right_gray"))
        
        locationContainer.addSubviews(icLocalImg,locationLabel, locationDisplayLabel,v4,ivRight4)
        
        locationContainer.snp.makeConstraints { make in
            make.top.equalTo(timeContainer.snp.bottom)
            make.left.right.equalToSuperview().inset(12)
            make.height.equalTo(50)
        }
        icLocalImg.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 15, height: 15))
        }
        locationLabel.snp.makeConstraints { make in
            make.left.equalTo(icLocalImg.snp.right).offset(5)
            make.centerY.equalToSuperview()
        }
        ivRight4.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-5)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 14, height: 14))
        }
        locationDisplayLabel.snp.makeConstraints { make in
            make.right.equalTo(ivRight4.snp.left).offset(-5)
            make.centerY.equalToSuperview()
        }
        v4.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(12)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        //活动类型
        let tapLocation = UITapGestureRecognizer(target: self, action: #selector(locationTapped))
        locationContainer.addGestureRecognizer(tapLocation)
        
        midCardView.addSubview(categoryContainer)
        let ivRight5 = UIImageView(image: UIImage(named: "app_right_gray"))
        
        categoryContainer.addSubviews(icCatgrImg,categoryLabel, categoryDisplayLabel,ivRight5)
        
        categoryContainer.snp.makeConstraints { make in
            make.top.equalTo(locationContainer.snp.bottom)
            make.left.right.equalToSuperview().inset(12)
            make.height.equalTo(50)
        }
        icCatgrImg.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 15, height: 15))
        }
        categoryLabel.snp.makeConstraints { make in
            make.left.equalTo(icCatgrImg.snp.right).offset(5)
            make.centerY.equalToSuperview()
        }
        ivRight5.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-5)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 14, height: 14))
        }
        categoryDisplayLabel.snp.makeConstraints { make in
            make.right.equalTo(ivRight5.snp.left).offset(-5)
            make.left.equalTo(categoryLabel.snp.right).offset(5)
            make.centerY.equalToSuperview()
        }
        
        let tapCategory = UITapGestureRecognizer(target: self, action: #selector(categoryTapped))
        categoryContainer.addGestureRecognizer(tapCategory)
    }

    
    // MARK: - Setup Expense UI
    private func setupExpenseUI() {
        contentView.addSubview(expenseCardView)
        expenseCardView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(midCardView.snp.bottom).offset(16)
            make.height.equalTo(100)
        }
        
        expenseCardView.addSubviews(icExpenseImg, expenseLabel)
        
        icExpenseImg.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.top.equalToSuperview().offset(16)
            make.size.equalTo(CGSize(width: 15, height: 15))
        }
        
        expenseLabel.snp.makeConstraints { make in
            make.left.equalTo(icExpenseImg.snp.right).offset(5)
            make.centerY.equalTo(icExpenseImg)
        }
        
        // 创建按钮容器
        let buttonStackView = UIStackView(arrangedSubviews: [freeButton, averageButton, yourBuyButton, myBuyButton])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 6.fit
        buttonStackView.distribution = .fillEqually
        
        expenseCardView.addSubview(buttonStackView)
        buttonStackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(24.fit)
            make.top.equalTo(expenseLabel.snp.bottom).offset(16.fit)
            make.height.equalTo(40.fit)
        }
        
        // 添加按钮点击事件
        freeButton.addTarget(self, action: #selector(expenseTapped(_:)), for: .touchUpInside)
        averageButton.addTarget(self, action: #selector(expenseTapped(_:)), for: .touchUpInside)
        yourBuyButton.addTarget(self, action: #selector(expenseTapped(_:)), for: .touchUpInside)
        myBuyButton.addTarget(self, action: #selector(expenseTapped(_:)), for: .touchUpInside)
    }
    
    // MARK: - Setup Publish Button
    private func setupPublishButton() {
        contentView.addSubview(publishButton)
        publishButton.snp.makeConstraints { make in
            make.top.equalTo(expenseCardView.snp.bottom).offset(32)
            make.left.right.equalToSuperview().inset(32)
            make.height.equalTo(48)
        }
        
        publishButton.addTarget(self, action: #selector(publishTapped), for: .touchUpInside)
    }
    
    // MARK: - Setup Agreement Section
    private func setupAgreementSection() {
        let container = UIView()
        contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalTo(publishButton.snp.bottom).offset(16)
//            make.left.right.equalToSuperview().inset(16)
            make.centerX.equalToSuperview()
            make.height.equalTo(22)
            make.bottom.equalToSuperview().inset(50).priority(.required) // 增加底部间距，避免被遮挡
        }
        
        container.addSubviews(agreeCheckbox, agreeLabel)
        
        agreeCheckbox.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        agreeLabel.snp.makeConstraints { make in
            make.left.equalTo(agreeCheckbox.snp.right).offset(3)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        agreeCheckbox.addTarget(self, action: #selector(agreementTapped), for: .touchUpInside)
        
        // 添加点击手势到 agreeLabel
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(agreeLabelTapped(_:)))
        agreeLabel.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Binding
    override func bindViewModel() {
        // 绑定参与人数
        viewModel.$participantCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.countLabel.text = "\(count)"
            }
            .store(in: &cancellables)
        
        // 绑定地点显示
        viewModel.$locationDisplayText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.locationDisplayLabel.text = text
            }
            .store(in: &cancellables)
        
        // 绑定活动类型显示（category 为逗号分隔的字符串，转换为 #xxx 格式展示）
        viewModel.$category
            .receive(on: DispatchQueue.main)
            .sink { [weak self] category in
                guard let self = self else { return }
                if category.isEmpty {
                    self.categoryDisplayLabel.text = "未设置"
                } else {
                    let displayText = category
                        .split(separator: ",")
                        .map { "#\($0)" }
                        .joined(separator: " ")
                    self.categoryDisplayLabel.text = displayText
                }
            }
            .store(in: &cancellables)
        
        // 绑定表单验证状态和发布状态 - 控制发布按鈕的可用性和样式
        Publishers.CombineLatest(viewModel.$isFormValid, viewModel.$isPublishing)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isValid, isPublishing in
                // 只有表单验证通过且不在发布中时，按钮才可用
                let isEnabled = isValid && !isPublishing
                self?.publishButton.isEnabled = isEnabled
                
                // 设置透明度：发布中0.6，表单无效0.5，正常1.0
                if isPublishing {
                    self?.publishButton.alpha = 0.6
                } else if !isValid {
                    self?.publishButton.alpha = 0.5
                } else {
                    self?.publishButton.alpha = 1.0
                }
            }
            .store(in: &cancellables)
        
        // 绑定发布成功
        viewModel.$publishSuccess
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { [weak self] _ in
                self?.showPublishSuccess()
            }
            .store(in: &cancellables)
        
        // 绑定发布错误
        viewModel.$publishError
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    @objc private func addImageTapped() {
        // 计算剩余可选数量
        let remainingCount = maxImageCount - selectedImages.count
        
        // 配置
        var config = PhotoPickerConfig()
        config.showsCrop = false // 不需要裁剪
        config.hidesPreview = true // 显示预览
        
        // 使用封装的多选方法
        PhotoPicker.showMultiple(
            from: self,
            config: config,
            maxCount: remainingCount,
            onSelected: { [weak self] images in
                guard let self = self else { return }
                for image in images {
                    // 保存图片到本地，生成唯一文件名
                    let fileName = "publish_\(Int(Date().timeIntervalSince1970 * 1000))_\(self.selectedImages.count).png"
                    if let localPath = image.saveToLocal(fileName: fileName) {
                        self.viewModel.addCoverImage(localPath)
                    }
                    self.selectedImages.append(image)
                }
                self.imageCollectionView.reloadData()
            },
            onCancel: {
                print("取消选择图片")
            }
        )
    }
    
    private func deleteImage(at index: Int) {
        guard index < selectedImages.count else { return }
        // 同步移除 ViewModel 中的封面图片路径
        let imageIndex = selectedImages.count < maxImageCount ? index - 1 : index
        if imageIndex >= 0 && imageIndex < viewModel.coverImages.count {
            let path = viewModel.coverImages[imageIndex]
            viewModel.removeCoverImage(path)
        }
        selectedImages.remove(at: index)
        imageCollectionView.reloadData()
    }
    
    @objc private func titleChanged() {
        viewModel.title = titleInputField.text ?? ""
    }
    
    @objc private func decreaseCount() {
        viewModel.decreaseParticipantCount()
    }
    
    @objc private func increaseCount() {
        viewModel.increaseParticipantCount()
    }
    
    @objc private func genderTapped(_ sender: UIButton) {
        [maleButton, femaleButton, unlimitedButton].forEach {
            $0.backgroundColor = .clear
            $0.setTitleColor(UIColor(hex: "#FF888888"), for: .normal)
        }
        sender.backgroundColor = AppColor.textMain
        sender.setTitleColor(.white, for: .normal)
        
        
        let requirement: GenderRequirement = sender == maleButton ? .male : (sender == femaleButton ? .female : .unlimited)
        viewModel.updateGenderRequirement(requirement)
    }
    
    @objc private func timeOptionTapped(_ sender: UIButton) {
        // 显示所有按钮，隐藏时间文本
        weekendButton.isHidden = false
        longTermButton.isHidden = false
        setTimeButton.isHidden = false
        timeDisplayLabel.isHidden = true
        
        // 重置所有按钮状态
        weekendButton.isSelected = false
        weekendButton.backgroundColor = AppColor.background
        weekendButton.setTitleColor(AppColor.textSecondary, for: .normal)
        
        longTermButton.isSelected = false
        longTermButton.backgroundColor = AppColor.background
        longTermButton.setTitleColor(AppColor.textSecondary, for: .normal)
        
        // 设置选中按钮的状态
        sender.isSelected = true
        sender.backgroundColor = AppColor.textMain
        sender.setTitleColor(.white, for: .normal)
        
        // 更新 ViewModel
        if sender == weekendButton {
            viewModel.updateTimeType(.weekend)
            viewModel.updateSpecificTime(nil) // 清除具体时间
            print("✅ 选择：周末假期")
        } else if sender == longTermButton {
            viewModel.updateTimeType(.longTerm)
            viewModel.updateSpecificTime(nil) // 清除具体时间
            print("✅ 选择：长期有效")
        }
    }
    
    @objc private func setTimeTapped() {
        print("点击设置时间 - 弹出时间选择器")
        
        // 显示时间选择器
        TimePickerViewController.show(from: self) { [weak self] selectedDate in
            guard let self = self else { return }
            
            // 格式化选择的时间
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日 HH:mm"
            let timeString = formatter.string(from: selectedDate)
            
            print("✅ 选择的时间: \(timeString)")
            
            // 更新 ViewModel
            self.viewModel.updateTimeType(.specific)
            self.viewModel.updateSpecificTime(selectedDate)
            
            // 隐藏所有按钮，显示时间文本
            self.weekendButton.isHidden = true
            self.longTermButton.isHidden = true
            self.setTimeButton.isHidden = true
            
            // 显示时间文本
            self.timeDisplayLabel.text = timeString
            self.timeDisplayLabel.isHidden = false
            
            // 重置按钮状态
            self.weekendButton.isSelected = false
            self.weekendButton.backgroundColor = AppColor.background
            self.weekendButton.setTitleColor(AppColor.textSecondary, for: .normal)
            
            self.longTermButton.isSelected = false
            self.longTermButton.backgroundColor = AppColor.background
            self.longTermButton.setTitleColor(AppColor.textSecondary, for: .normal)
        }
    }
    
    @objc private func timeContainerTapped() {
        // 如果当前显示的是具体时间，点击可以重新选择
        if !timeDisplayLabel.isHidden {
            setTimeTapped()
        }
    }
    
    @objc private func locationTapped() {
        print("选择活动地点")
        
        // 创建城市选择器
        let cityPicker = CityPickerViewController()
        cityPicker.useHotCities2 = false
        // 设置选中城市的回调
        cityPicker.onCitySelected = { [weak self] cityName in
            guard let self = self else { return }
            
            // 更新显示的城市名称
//            self.locationDisplayLabel.text = "\(cityName)"
            
            // 更新 ViewModel 中的数据
            self.viewModel.updateLocation(cityName)
            
            print("✅ 已选择城市: \(cityName)")
        }
        
        // 跳转到城市选择页面
        navigationController?.pushViewController(cityPicker, animated: true)
    }
    
    @objc private func categoryTapped() {
        // 创建 ActivityTypeListViewController
        let activityTypeVC = ActivityTypeListViewController()
        
        // 正向传值：把当前已选择的类型传进去
        if !viewModel.category.isEmpty {
            activityTypeVC.initialSelectedTags = viewModel.category.split(separator: ",").map { String($0) }
        }
        
        // 反向传值：接收用户选择的活动类型
        activityTypeVC.onTagsSelected = { [weak self] selectedTypes in
            guard let self = self else { return }
            // 展示格式： "#喝茶 #羽毛球 #野餐"
            let displayText = selectedTypes.map { "#\($0)" }.joined(separator: " ")
            self.categoryDisplayLabel.text = displayText.isEmpty ? "#喝茶" : displayText
            // 存入 ViewModel，逗号分隔存储
            self.viewModel.updateCategory(selectedTypes.joined(separator: ","))
        }

        navigationController?.pushViewController(activityTypeVC, animated: true)
    }
    
    @objc private func expenseTapped(_ sender: UIButton) {
        // 重置所有按钮为未选中状态
        [freeButton, averageButton, yourBuyButton, myBuyButton].forEach {
            $0.isSelected = false
        }
        
        // 设置当前按钮为选中状态
        sender.isSelected = true
        
        // 更新 ViewModel
        let expenseType: ActivityExpenseType
        switch sender.tag {
        case 0:
            expenseType = .free
            print("✅ 选择：免费")
        case 1:
            expenseType = .average
            print("✅ 选择：平摊费用（默认）")
        case 2:
            expenseType = .yourBuy
            print("✅ 选择：由你买单")
        case 3:
            expenseType = .myBuy
            print("✅ 选择：我买单")
        default:
            expenseType = .free
        }
        
        viewModel.updateExpenseType(expenseType)
    }
    
    @objc private func agreementTapped() {
        agreeCheckbox.isSelected.toggle()
        viewModel.updateAgreedToTerms(agreeCheckbox.isSelected)
    }
    
    @objc private func agreeLabelTapped(_ gesture: UITapGestureRecognizer) {
        guard let attributedText = agreeLabel.attributedText else { return }
        let text = attributedText.string
        let nsText = text as NSString
        let termsRange = nsText.range(of: "《活动内容发布准则》")
        
        let location = gesture.location(in: agreeLabel)
        
        // 判断点击位置是否在《活动内容发布准则》范围内
        if let termsRect = rectFor(range: termsRange, in: agreeLabel), termsRect.contains(location) {
            // 跳转到活动内容发布准则H5页面
            openPublishGuidelinesPage()
        } else {
            // 点击非链接区域，切换勾选状态
            agreementTapped()
        }
    }
    
    /// 计算文本范围的矩形区域
    private func rectFor(range: NSRange, in label: UILabel) -> CGRect? {
        guard let attributedText = label.attributedText else { return nil }
        
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: label.bounds.size)
        let textStorage = NSTextStorage(attributedString: attributedText)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = label.numberOfLines
        textContainer.lineBreakMode = label.lineBreakMode
        
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        return rect
    }
    
    /// 打开活动内容发布准则H5页面
    private func openPublishGuidelinesPage() {
        
        // 使用 WebViewController 打开 H5 页面
        let webVC = WebViewController(
            urlString: webUrlReleaseGuidelines,
        )
//        webVC.configuration.isFullScreen = true
        navigationController?.pushViewController(webVC, animated: true)
    }
    
    @objc private func publishTapped() {
        viewModel.title = titleInputField.text ?? ""
        viewModel.description = descriptionInputView.text

        // 没有图直接发布
        if selectedImages.isEmpty {
            viewModel.publishActivity()
            return
        }

        // 1) 把内存里的 UIImage 写到临时目录，拿到绝对路径（OSS 需要绝对路径）
        let tempDir = NSTemporaryDirectory()
        var absPaths: [String] = []
        let ts = Int(Date().timeIntervalSince1970 * 1000)
        for (idx, image) in selectedImages.enumerated() {
            guard let data = image.jpegData(compressionQuality: 0.8) else { continue }
            let fileName = "publish_\(ts)_\(idx).jpg"
            let absPath = (tempDir as NSString).appendingPathComponent(fileName)
            do {
                try data.write(to: URL(fileURLWithPath: absPath), options: .atomic)
                absPaths.append(absPath)
            } catch {
                #if DEBUG
                print("❌ [Publish] 写临时文件失败 \(fileName): \(error.localizedDescription)")
                #endif
            }
        }
        guard !absPaths.isEmpty else {
            showError("图片处理失败")
            return
        }

        showLoading("上传中...")

        // 2) 申请 STS
        OssUploadUtil.getSTS(type: "album") { [weak self] sts in
            guard let self = self else { return }
            guard let sts = sts else {
                self.hideLoading()
                self.showError("获取上传凭证失败")
                return
            }
            // 3) 上传到 OSS（绝对路径）
            OssUploadUtil.uploadToOSS(sts: sts, filePaths: absPaths) { [weak self] keys in
                guard let self = self else { return }
                self.hideLoading()
                guard let keys = keys, keys.count == absPaths.count else {
                    self.showError("图片上传失败")
                    return
                }
                #if DEBUG
                print("✅ [Publish] OSS 上传完成: \(keys)")
                #endif
                // 4) 用 OSS 返回的 key 整体替换 viewModel.coverImages，再调发布接口
                self.viewModel.replaceCoverImages(keys)
                self.viewModel.publishActivity()
            }
        }
    }
    
    // MARK: - UI Feedback
    private func showPublishSuccess() {
        let alert = UIAlertController(title: "发布成功", message: "您的活动已成功发布", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.viewModel.resetForm()
            self?.resetUI()
            self?.navigateToTab4()
        })
        present(alert, animated: true)
        
        // 1秒后自动跳转到第4个tab
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.navigateToTab4()
        }
    }
    
    private func navigateToTab4() {
           guard let tabBarController = self.tabBarController else { return }
           tabBarController.selectedIndex = 4
    }
    
    /// 重置所有 UI 到初始状态
    private func resetUI() {
        // 标题输入框
        titleInputField.text = ""
        
        // 描述输入框和占位文字
        descriptionInputView.text = ""
        descriptionPlaceholderLabel.isHidden = false
        
        // 图片重置
        selectedImages.removeAll()
        imageCollectionView.reloadData()
        
        // 活动人数重置为1
        countLabel.text = "1"
        
        // 性别要求重置为"不限"
        [maleButton, femaleButton].forEach {
            $0.backgroundColor = .clear
            $0.setTitleColor(UIColor(hex: "#FF888888"), for: .normal)
        }
        unlimitedButton.backgroundColor = AppColor.textMain
        unlimitedButton.setTitleColor(.white, for: .normal)
        
        // 活动时间重置为"长期有效"
        weekendButton.isHidden = false
        longTermButton.isHidden = false
        setTimeButton.isHidden = false
        timeDisplayLabel.isHidden = true
        timeDisplayLabel.text = ""
        weekendButton.isSelected = false
        weekendButton.backgroundColor = AppColor.background
        weekendButton.setTitleColor(AppColor.textSecondary, for: .normal)
        longTermButton.isSelected = true
        longTermButton.backgroundColor = AppColor.textMain
        longTermButton.setTitleColor(.white, for: .normal)
        
        // 活动地点重置
        locationDisplayLabel.text = "未设置"
        
        // 活动类型重置
        categoryDisplayLabel.text = "未设置"
        
        // 费用类型重置为"免费"
        [freeButton, averageButton, yourBuyButton, myBuyButton].forEach {
            $0.isSelected = false
        }
        freeButton.isSelected = true
        
        // 同意条款重置
        agreeCheckbox.isSelected = false
        
        // 滚动回顶部
        scrollView.setContentOffset(.zero, animated: true)
    }
    
    private func showError(_ message: String) {
        showToast(message)
//        let alert = UIAlertController(title: "发布失败", message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "确定", style: .default))
//        present(alert, animated: true)
    }
}

// MARK: - UITextViewDelegate
extension PublishViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // 根据文本是否为空来显示或隐藏占位文字
        descriptionPlaceholderLabel.isHidden = !textView.text.isEmpty
        viewModel.description = textView.text
    }
}


// MARK: - UICollectionViewDataSource & UICollectionViewDelegate
extension PublishViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // 如果图片数量小于最大值，第一个显示添加按钮 + 已选图片
        return selectedImages.count < maxImageCount ? selectedImages.count + 1 : selectedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PublishImageCell.identifier, for: indexPath) as! PublishImageCell
        
        // 如果是第一个cell且图片数量未满，显示添加按钮
        if indexPath.item == 0 && selectedImages.count < maxImageCount {
            cell.configureAsAddButton()
        } else {
            // 显示图片（需要根据是否有添加按钮来调整索引）
            let imageIndex = selectedImages.count < maxImageCount ? indexPath.item - 1 : indexPath.item
            let image = selectedImages[imageIndex]
            cell.configure(with: image)
            cell.onDelete = { [weak self] in
                self?.deleteImage(at: imageIndex)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 如果点击的是第一个cell且图片数量未满，说明点击的是添加按钮
        if indexPath.item == 0 && selectedImages.count < maxImageCount {
            addImageTapped()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 92x92 的正方形
        return CGSize(width: 92, height: 92)
    }
}


