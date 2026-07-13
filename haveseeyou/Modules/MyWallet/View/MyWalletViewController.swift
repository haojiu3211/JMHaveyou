//
//  MyWalletViewController.swift
//  haveseeyou
//
//  Created by admin开发测试 on 2026/6/12.
//

import UIKit
import SnapKit
import StoreKit

class MyWalletViewController: BaseViewController {
    
    private var rechargeItems: [MyWalletRechargeItem] = []
    private var diamondItems: [DiamondItem] = []
    private var isAgreed = false
    private let defaults = UserDefaults.standard
    private let diamondListCacheKey = "my_wallet_diamond_list_cache"
    
    // MARK: - IAP Properties
    private var productIds: Set<String> = []
    private var iapProducts: [String: IAPProduct] = [:]
    private var currentOrderNo: String?
    private var currentProductId: String?
    private var currentDiamondId: String?
    private var isProcessingPurchase = false
    
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private let cardBackgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "member_vip_coin_bg")
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.backgroundColor = UIColor(hex: "#333335")
        return iv
    }()
    
    private let coinIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "member_bg_coin_icon")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let balanceLabel: UILabel = {
        let label = UILabel()
        label.text = "----"
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.textColor = .white
        return label
    }()
    
    private let balanceTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "活动币余额："
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(hex: "#999999")
        return label
    }()
    
    private let titleStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .equalSpacing
        sv.alignment = .center
        return sv
    }()
    
    private let rechargeTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "充值金额"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = UIColor(hex: "#100A1D")
        return label
    }()
    
    private let underageLabel: UILabel = {
        let label = UILabel()
        label.text = "未成年人禁止充值消费"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(hex: "#888888")
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(MyWalletRechargeCell.self, forCellWithReuseIdentifier: "MyWalletRechargeCell")
        return cv
    }()
    
    private lazy var agreeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "member_select_coin_no"), for: .normal)
        btn.setImage(UIImage(named: "member_select_coin_yes"), for: .selected)
        btn.addTarget(self, action: #selector(agreeButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    private let agreeLabel: UILabel = {
        let label = UILabel()
        label.text = "充值即代表您同意"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor(hex: "#999999")
        return label
    }()
    
    private let agreementLabel: UILabel = {
        let label = UILabel()
        label.text = "《充值协议》"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor(hex: "#77E400")
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private let agreementStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()
    
    private lazy var confirmButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("确认充值", for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(hex: "#100A1D")
        
        // 渐变文字
        let gradientColor = UIColor.gradientTextColor(
            size: CGSize(width: 120, height: 30),
            colors: [
                UIColor(hex: "#A2EF4D"),
                UIColor(hex: "#F7FFFF"),
                UIColor(hex: "#F7FFFF")
            ]
        )
        btn.setTitleColor(gradientColor, for: .disabled)
        btn.setTitleColor(gradientColor, for: .normal)
       
        btn.layer.cornerRadius = 25
        btn.isEnabled = false
        btn.alpha = 0.4 // 与 MenberCenterView 一致
        btn.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        return btn
    }()
    

    
    private let bottomContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "我的钱包"
        view.backgroundColor = .white
        
        // 设置导航栏右边的消费记录按钮
        let recordButton = UIBarButtonItem(
            title: "消费记录",
            style: .plain,
            target: self,
            action: #selector(recordButtonTapped)
        )
        navigationItem.rightBarButtonItem = recordButton
        
        setupUI()
        loadCachedData()
        fetchDiamondList()
        setupStoreKitHelper()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 页面消失时，清除 StoreKitHelper 的 delegate，让 PurchaseManager 可以继续处理自动续费
        StoreKitHelper.shared.delegate = nil
    }
    
    @objc private func recordButtonTapped() {
        let recordVC = MyWalletRecordViewController()
        navigationController?.pushViewController(recordVC, animated: true)
    }
    

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateAdaptiveLayout()
    }
    
    private func updateAdaptiveLayout() {
        // 更新字体大小
        balanceLabel.font = UIFont.boldSystemFont(ofSize: 32)
        balanceTitleLabel.font = UIFont.systemFont(ofSize: 14)
        rechargeTitleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        underageLabel.font = UIFont.systemFont(ofSize: 12)
        
        // 更新约束
        cardBackgroundImageView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(144)
        }
        
        balanceTitleLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(20)
        }
        
        coinIconImageView.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(balanceTitleLabel.snp.bottom).offset(12)
            make.width.height.equalTo(48)
        }
        
        balanceLabel.snp.remakeConstraints { make in
            make.left.equalTo(coinIconImageView.snp.right).offset(12)
            make.centerY.equalTo(coinIconImageView)
        }
        
        titleStackView.snp.remakeConstraints { make in
            make.top.equalTo(cardBackgroundImageView.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(16)
        }
        
        collectionView.snp.remakeConstraints { make in
            make.top.equalTo(titleStackView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(12)
            make.height.equalTo(400)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    override func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        view.addSubview(bottomContainerView)
        
        contentView.addSubview(cardBackgroundImageView)
        cardBackgroundImageView.addSubview(balanceTitleLabel)
        cardBackgroundImageView.addSubview(coinIconImageView)
        cardBackgroundImageView.addSubview(balanceLabel)
        
        contentView.addSubview(titleStackView)
        titleStackView.addArrangedSubview(rechargeTitleLabel)
        titleStackView.addArrangedSubview(underageLabel)
        
        contentView.addSubview(collectionView)
        
        bottomContainerView.addSubview(confirmButton)
        bottomContainerView.addSubview(agreementStackView)
        agreementStackView.addArrangedSubview(agreeButton)
        agreementStackView.addArrangedSubview(agreeLabel)
        agreementStackView.addArrangedSubview(agreementLabel)
        
        // 添加协议点击手势
        let agreementTapGesture = UITapGestureRecognizer(target: self, action: #selector(agreementLabelTapped))
        agreementLabel.addGestureRecognizer(agreementTapGesture)
        
        // 添加协议点击手势识别器
        agreeButton.addTarget(self, action: #selector(agreeButtonTapped), for: .touchUpInside)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(bottomContainerView.snp.top)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        
        cardBackgroundImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(144)
        }
        
        balanceTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(20)
        }
        
        coinIconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(balanceTitleLabel.snp.bottom).offset(12)
            make.width.height.equalTo(48)
        }
        
        balanceLabel.snp.makeConstraints { make in
            make.left.equalTo(coinIconImageView.snp.right).offset(12)
            make.centerY.equalTo(coinIconImageView)
        }
        
        titleStackView.snp.makeConstraints { make in
            make.top.equalTo(cardBackgroundImageView.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(16)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleStackView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(12)
            make.height.equalTo(400)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        bottomContainerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-18)
        }
        
        confirmButton.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        agreementStackView.snp.makeConstraints { make in
            make.top.equalTo(confirmButton.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        agreeButton.snp.makeConstraints { make in
            make.width.height.equalTo(20)
        }
    }
    
    private func loadCachedData() {
        if let data = defaults.data(forKey: diamondListCacheKey),
           let cachedResponse = try? JSONDecoder().decode(DiamondListResponse.self, from: data) {
            // 更新余额显示
            if let coin = cachedResponse.coin {
                self.balanceLabel.text = "\(coin)枚"
            }
            
            if let cachedList = cachedResponse.list {
                self.diamondItems = cachedList
                self.rechargeItems = cachedList.map { item in
                    let totalCoins = (item.amount ?? 0) + (item.reward ?? 0)
                    let rewardValue = item.reward ?? 0
                    let bonusText = rewardValue > 0 ? "\(rewardValue)" : nil
                    return MyWalletRechargeItem(
                        coins: "\(totalCoins)",
                        price: item.price ?? "",
                        bonus: bonusText,
                        remark: item.remark,
                        isRecommended: item.superStatus == 1
                    )
                }
            }
            
            self.collectionView.reloadData()
            
            // 默认选中第一个
            DispatchQueue.main.async {
                let indexPath = IndexPath(item: 0, section: 0)
                self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .top)
                self.collectionView.delegate?.collectionView?(self.collectionView, didSelectItemAt: indexPath)
            }
        } else {
            // 如果没有缓存，使用 fallback 数据
            setupFallbackData()
            self.collectionView.reloadData()
            
            // 默认选中第一个
            DispatchQueue.main.async {
                let indexPath = IndexPath(item: 0, section: 0)
                self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .top)
                self.collectionView.delegate?.collectionView?(self.collectionView, didSelectItemAt: indexPath)
            }
        }
    }
    
    private func cacheData(_ response: DiamondListResponse) {
        if let data = try? JSONEncoder().encode(response) {
            defaults.set(data, forKey: diamondListCacheKey)
        }
    }
    
    private func fetchDiamondList() {
        NetworkManager.shared.request(PurchaseAPI.diamondList(type: "4"), as: DiamondListResponse.self) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                // 更新余额显示
                if let coin = response.coin {
                    self.balanceLabel.text = "\(coin)枚"
                    // 同时更新 mine_coin 缓存，供其他页面使用
                    UserDefaults.standard.set(coin, forKey: "mine_coin")
                    print("💰 [MyWallet] 更新本地活动币缓存: \(coin)")
                }
                
                if let list = response.list, !list.isEmpty {
                    self.diamondItems = list
                    self.rechargeItems = list.map { item in
                        let totalCoins = (item.amount ?? 0) + (item.reward ?? 0)
                        let rewardValue = item.reward ?? 0
                        let bonusText = rewardValue > 0 ? "\(rewardValue)" : nil
                        return MyWalletRechargeItem(
                            coins: "\(totalCoins)",
                            price: item.price ?? "",
                            bonus: bonusText,
                            remark: item.remark,
                            isRecommended: item.superStatus == 1
                        )
                    }
                    
                    // 更新产品ID列表用于内购
                    self.productIds.removeAll()
                    for product in list {
                        if let productId = product.iosProductId, !productId.isEmpty {
                            self.productIds.insert(productId)
                        }
                    }
                    
                    // 重新获取内购产品
                    if !self.productIds.isEmpty {
                        self.fetchStoreKitProducts()
                    }
                    
                    // 同步到 PurchaseManager 缓存
                    PurchaseManager.shared.updateDiamondProductCache(with: list)
                    
                    // 更新缓存（缓存完整的响应）
                    self.cacheData(response)
                }
                self.collectionView.reloadData()
                
                // 默认选中第一个
                DispatchQueue.main.async {
                    let indexPath = IndexPath(item: 0, section: 0)
                    self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .top)
                    self.collectionView.delegate?.collectionView?(self.collectionView, didSelectItemAt: indexPath)
                }
            case .failure(let error):
                print("❌ 获取金币列表失败: \(error)")
                // 失败时不做任何操作，保持缓存数据展示
            }
        }
    }
    
    private func setupFallbackData() {
        rechargeItems = [
            MyWalletRechargeItem(coins: "500", price: "48", bonus: "20"),
            MyWalletRechargeItem(coins: "1300", price: "98", bonus: "302"),
            MyWalletRechargeItem(coins: "4580", price: "298", bonus: "1600"),
            MyWalletRechargeItem(coins: "10000", price: "500", bonus: "5000", isRecommended: true)
        ]
    }
    
    @objc private func agreeButtonTapped() {
        isAgreed.toggle()
        agreeButton.isSelected = isAgreed
        confirmButton.isEnabled = isAgreed
        
        UIView.animate(withDuration: 0.2) {
            if self.isAgreed {
                self.confirmButton.alpha = 1.0
                
            } else {
                
                self.confirmButton.alpha = 0.4
                
            }
        }
    }
    
    @objc private func confirmButtonTapped() {
        guard !isLoading else { return }
        guard !isProcessingPurchase else {
            print("⚠️ [IAP] 交易正在处理中，跳过重复点击")
            return
        }
        guard let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first else { return }
        
        let diamondItem = diamondItems[selectedIndexPath.item]
        guard let productId = diamondItem.iosProductId, !productId.isEmpty else {
            showToast("产品信息不完整")
            return
        }
        guard let goodsId = diamondItem.id else {
            showToast("商品ID缺失")
            return
        }
        
        // 保存当前选择的产品信息
        currentProductId = productId
        currentDiamondId = "\(goodsId)"
        
        // 设置正在处理标志
        isProcessingPurchase = true
        
        // 先创建订单
        createCoinOrder(goodsId: "\(goodsId)", productId: productId)
    }
    
    // MARK: - 创建活动币订单
    private func createCoinOrder(goodsId: String, productId: String) {
        showLoading("获取订单中...")
        
        NetworkManager.shared.request(
            PurchaseAPI.createCoinOrder(goodsId: goodsId),
            as: CreateCoinOrderData.self
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let orderData):
                self.hideLoading()
                
                if let orderNo = orderData.orderNo {
                    print("✅ [Coin] 获取订单成功: \(orderNo)")
                    
                    // 保存订单号到内存
                    self.currentOrderNo = orderNo
                    
                    // 🔑 关键：持久化保存订单信息，防止App被杀掉后丢失
                    PendingTransactionManager.shared.savePendingTransaction(
                        orderNo: orderNo,
                        productId: productId,
                        goodsId: goodsId
                    )
                    
                    // 发起内购
                    print("🚀 [IAP] 发起购买: \(productId)")
                    StoreKitHelper.shared.purchaseProduct(productId: productId)
                } else {
                    self.showToast("获取订单失败")
                    self.isProcessingPurchase = false
                }
                
            case .failure(let error):
                self.hideLoading()
                print("❌ [Coin] 获取订单失败: \(error)")
                self.showToast("获取订单失败")
                self.isProcessingPurchase = false
            }
        }
    }
    

    
    @objc private func agreementLabelTapped() {
        openRechargeAgreement()
    }
    
    private func openRechargeAgreement() {
        // 直接加载本地 HTML 文件
        guard let filePath = Bundle.main.path(forResource: "活动币充值协议", ofType: "html"),
              let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            // 如果读取失败，尝试使用在线 URL
            let webVC = WebViewController(urlString: webUrlCoinRecharge, title: "活动币充值协议")
            navigationController?.pushViewController(webVC, animated: true)
            return
        }
        
        let webVC = WebViewController(htmlString: content, title: "活动币充值协议")
        navigationController?.pushViewController(webVC, animated: true)
    }
}

extension MyWalletViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rechargeItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyWalletRechargeCell", for: indexPath) as! MyWalletRechargeCell
        cell.configure(with: rechargeItems[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 8) / 2
        return CGSize(width: width, height: 94)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = rechargeItems[indexPath.item]
        print("选择了充值: \(item.coins)枚, 价格: ¥\(item.price)")
    }
}

// MARK: - IAP Methods
extension MyWalletViewController {
    
    private func setupStoreKitHelper() {
        StoreKitHelper.shared.delegate = self
    }
    
    private func fetchStoreKitProducts() {
        print("🚀 [IAP] 开始获取 StoreKit 产品")
        StoreKitHelper.shared.fetchProducts(productIds: productIds)
    }
    
    private func generateOrderNo() -> String {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let random = String(format: "%06d", arc4random_uniform(1000000))
        return "iOS\(timestamp)\(random)"
    }
    
    private func verifyApplePayPurchaseWithOrderNo(receipt: String, productId: String, transactionId: String, originalTransactionId: String, orderNo: String) {
        showLoading("确认订单中...")
        NetworkManager.shared.request(
            PurchaseAPI.applePayVerification(
                receipt: receipt,
                productId: productId,
                transactionId: transactionId,
                originalTransactionId: originalTransactionId,
                orderNo: orderNo,
                isRestore: false,
                scene: ""
            ),
            as: VerifyPurchaseResponse.self
        ) { [weak self] result in
            guard let self = self else { return }
            self.hideLoading()
            
            switch result {
            case .success(let response):
                print("✅ [Apple Pay] 购买验证成功, orderNo: \(response.orderNo ?? "unknown")")
                // 服务器验证成功后，完成交易
                StoreKitHelper.shared.finishTransaction(transactionId: transactionId)
                // 🔑 关键：移除持久化的交易记录
                PendingTransactionManager.shared.removeTransaction(orderNo: orderNo)
                self.showToast("购买成功！")
                self.refreshDiamondList()
                self.isProcessingPurchase = false
                
            case .failure(let error):
                print("❌ [Apple Pay] 验证购买失败: \(error)")
                self.showToast("支付处理中，请稍后查看")
                self.isProcessingPurchase = false
                // ⚠️ 注意：验证失败时不要 finishTransaction，让交易留在队列中，下次启动时会再次回调
            }
        }
    }
    
    private func verifyApplePayPurchase(receipt: String, productId: String, transactionId: String, originalTransactionId: String) {
        let orderNo = generateOrderNo()
        print("🚀 [Apple Pay] 订单号: \(orderNo)")
        
        showLoading("确认订单中...")
        NetworkManager.shared.request(
            PurchaseAPI.applePayVerification(
                receipt: receipt,
                productId: productId,
                transactionId: transactionId,
                originalTransactionId: originalTransactionId,
                orderNo: orderNo,
                isRestore: false,
                scene: ""
            ),
            as: VerifyPurchaseResponse.self
        ) { [weak self] result in
            guard let self = self else { return }
            self.hideLoading()
            
            switch result {
            case .success(let response):
                print("✅ [Apple Pay] 购买验证成功, orderNo: \(response.orderNo ?? "unknown")")
                // 服务器验证成功后，完成交易
                StoreKitHelper.shared.finishTransaction(transactionId: transactionId)
                self.showToast("购买成功！")
                self.refreshDiamondList()
                self.isProcessingPurchase = false
                
            case .failure(let error):
                print("❌ [Apple Pay] 验证购买失败: \(error)")
                self.showToast("支付处理中，请稍后查看")
                self.isProcessingPurchase = false
                // ⚠️ 注意：验证失败时不要 finishTransaction，让交易留在队列中，下次启动时会再次回调
            }
        }
    }
    
    private func refreshDiamondList() {
        fetchDiamondList()
    }
}

// MARK: - StoreKitHelperDelegate
extension MyWalletViewController: StoreKitHelperDelegate {
    
    func storeKitHelper(_ helper: StoreKitHelper, didFetchProducts products: [IAPProduct]) {
        print("✅ [IAP] 收到 \(products.count) 个产品")
        
        for product in products {
            iapProducts[product.productId] = product
        }
    }
    
    func storeKitHelper(_ helper: StoreKitHelper, didFailFetchProductsWithError error: Error) {
        print("❌ [IAP] 获取产品失败: \(error)")
        showToast("获取产品信息失败")
    }
    
    func storeKitHelper(_ helper: StoreKitHelper, didPurchaseProduct productId: String, receipt: String, transactionId: String) {
        print("✅ [IAP] 苹果支付成功，开始服务器验证")
        
        showToast("支付处理中，请稍后查看")
        
        if let orderNo = currentOrderNo {
            verifyApplePayPurchaseWithOrderNo(
                receipt: receipt,
                productId: productId,
                transactionId: transactionId,
                originalTransactionId: transactionId,
                orderNo: orderNo
            )
        } else {
            verifyApplePayPurchase(
                receipt: receipt,
                productId: productId,
                transactionId: transactionId,
                originalTransactionId: transactionId
            )
        }
        
        currentOrderNo = nil
        currentProductId = nil
        currentDiamondId = nil
        isProcessingPurchase = false
    }
    
    func storeKitHelper(_ helper: StoreKitHelper, didFailPurchaseProductWithError error: Error) {
        print("❌ [IAP] 购买失败: \(error)")
        
        if let nsError = error as NSError?, nsError.code == SKError.Code.paymentCancelled.rawValue {
            showToast("已取消购买")
        } else {
            showToast("购买失败: \(error.localizedDescription)")
        }
        
        isProcessingPurchase = false
    }
}
