//
//  AutoGreetAlertView.swift
//  haveseeyou
//
//  自动打招呼弹窗
//

import UIKit
import SnapKit

final class AutoGreetAlertView: UIView {
    
    // MARK: - UI
    
    /// 半透明蒙层
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        return view
    }()
    
    /// 弹窗内容容器（带背景图）
    private let contentContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        return view
    }()
    
    /// 背景图容器
    private let backgroundContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    /// 背景图片
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "auto_greet_bg")
        return imageView
    }()
    
    /// 关闭按钮
    private let closeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "alert_close"), for: .normal)
        return btn
    }()
    
    /// 标题图片
    private let titleImageView: UIImageView = {
        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "auto_greet_title")
        return imageView
    }()
    
    /// 收集视图布局
    private let collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        return layout
    }()
    
    /// 收集视图
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(AutoGreetCollectionViewCell.self, forCellWithReuseIdentifier: AutoGreetCollectionViewCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()
    
    /// 换一换按钮
    private let refreshButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "auto_greet_refer"), for: .normal)
        btn.setTitle("换一批", for: .normal)
        btn.setTitleColor(UIColor(hex: "#100A1D"), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        return btn
    }()
    
    /// 一键发送按钮
    private let sendButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("一键发送", for: .normal)
        
        // 渐变文字
        let gradientColor = UIColor.gradientTextColor(
            size: CGSize(width: 180, height: 48),
            colors: [
                UIColor(hex: "#A2EF4D"),
                UIColor(hex: "#F7FFFF"),
                UIColor(hex: "#F7FFFF")
            ]
        )
        
        btn.setTitleColor(gradientColor, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.backgroundColor = .black
        btn.layer.cornerRadius = 24
        return btn
    }()
    
    // MARK: - Data
    private var mockData: [(image: UIImage?, name: String, location: String, isSelected: Bool)] = [
        (UIImage(named: "sy_head_1"), "小梨涡很甜", "深圳市", true),
        (UIImage(named: "sy_head_1"), "夜幕星河", "上海市", true),
        (UIImage(named: "sy_head_1"), "与星星私奔", "北京市", true),
        (UIImage(named: "sy_head_1"), "月亮邮递员", "广州市", false),
        (UIImage(named: "sy_head_1"), "偷喝一口奶茶", "杭州市", false),
        (UIImage(named: "sy_head_1"), "贩卖日落", "成都市", false)
    ]
    
    // MARK: - 回调
    var onClose: (() -> Void)?
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: UIScreen.main.bounds)
        setupUI()
        bindActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        
        addSubviews(overlayView, contentContainerView)
        contentContainerView.addSubview(backgroundContainerView)
        backgroundContainerView.addSubview(backgroundImageView)
        contentContainerView.addSubviews(closeButton, titleImageView, collectionView, refreshButton, sendButton)
        
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentContainerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().offset(0)
            make.height.equalTo(contentContainerView.snp.width).multipliedBy(1.48)
        }
        
        backgroundContainerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(0) // 左右完全贴合父视图边缘

        }
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(75)
            make.right.equalToSuperview().offset(-39)
            make.size.equalTo(CGSize(width: 48, height: 48))
        }
        
        titleImageView.snp.makeConstraints { make in
            make.centerY.equalTo(closeButton)
            make.trailing.equalTo(closeButton.snp.leading).offset(-30)
            make.width.equalTo(174.fit)
            make.height.equalTo(21.fit)

        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleImageView.snp.bottom).offset(27)
            make.left.equalToSuperview().offset(14)//24
            make.right.equalToSuperview().offset(-44)//0
        }
        
        refreshButton.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(16)
            
            make.centerX.equalToSuperview().offset(-10)
    
        }
        
        sendButton.snp.makeConstraints { make in
            make.top.equalTo(refreshButton.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-58)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-24)
        }
    }
    
    private func bindActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        
        let overlayTap = UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
        overlayView.addGestureRecognizer(overlayTap)
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss()
        onClose?()
    }
    
    @objc private func overlayTapped() {
        dismiss()
        onClose?()
    }
    
    @objc private func refreshTapped() {
        // 换一换逻辑
        collectionView.reloadData()
    }
    
    @objc private func sendTapped() {
        // 一键发送逻辑
        dismiss()
        onClose?()
    }
    
    // MARK: - Public Methods
    func show() {
        guard let window = UIApplication.shared.keyWindow else { return }
        window.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 动画效果
        contentContainerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        contentContainerView.alpha = 0
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.contentContainerView.transform = .identity
            self.contentContainerView.alpha = 1
        }
    }
    
    func dismiss() {
        UIView.animate(withDuration: 0.25, animations: {
            self.contentContainerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.contentContainerView.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension AutoGreetAlertView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mockData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AutoGreetCollectionViewCell.identifier, for: indexPath) as! AutoGreetCollectionViewCell
        let data = mockData[indexPath.item]
        cell.configure(with: data.image, name: data.name, location: data.location, isSelected: data.isSelected)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        mockData[indexPath.item].isSelected.toggle()
        collectionView.reloadItems(at: [indexPath])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 24) / 3
        return CGSize(width: width, height: width + 30)
    }
}
