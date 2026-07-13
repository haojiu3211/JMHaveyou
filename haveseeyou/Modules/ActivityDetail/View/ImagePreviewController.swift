//
//  ImagePreviewController.swift
//  haveseeyou
//
//  全屏图片浏览器（支持多张左右滑动 + 缩放）
//

import UIKit
import SnapKit
import Kingfisher

final class ImagePreviewController: BaseViewController {

    /// 隐藏系统导航栏
    override var prefersNavigationBarHidden: Bool { true }

    // MARK: - 数据

    private let imageUrls: [String]
    private let initialIndex: Int

    // MARK: - UI

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .black
        cv.register(ImagePreviewCell.self, forCellWithReuseIdentifier: ImagePreviewCell.reuseID)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    /// 关闭按钮
    private let closeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(systemName: "xmark")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        btn.layer.cornerRadius = 18
        btn.clipsToBounds = true
        return btn
    }()

    /// 页码指示器
    private let pageLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    // MARK: - Init

    init(imageUrls: [String], initialIndex: Int = 0) {
        self.imageUrls = imageUrls
        self.initialIndex = initialIndex
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func setupUI() {
        view.backgroundColor = .black

        view.addSubviews(collectionView, closeButton, pageLabel)

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(72)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(CGSize(width: 36, height: 36))
        }

        pageLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(closeButton)
        }

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        updatePageLabel(index: initialIndex)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 初始滚动到指定位置
        if initialIndex > 0 && initialIndex < imageUrls.count {
            let offsetX = CGFloat(initialIndex) * collectionView.bounds.width
            collectionView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
        }
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func updatePageLabel(index: Int) {
        pageLabel.text = "\(index + 1) / \(imageUrls.count)"
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension ImagePreviewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imageUrls.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImagePreviewCell.reuseID, for: indexPath) as! ImagePreviewCell
        cell.configure(imageUrl: imageUrls[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let w = max(scrollView.bounds.width, 1)
        let index = Int(round(scrollView.contentOffset.x / w))
        updatePageLabel(index: index)
    }
}

// MARK: - ImagePreviewCell

private final class ImagePreviewCell: UICollectionViewCell {

    static let reuseID = "ImagePreviewCell"

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 3.0
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        return sv
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.delegate = self

        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        imageView.snp.makeConstraints { make in
            make.width.height.equalToSuperview()
        }

        // 双击放大
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTap)
    }

    func configure(imageUrl: String) {
        // 拼接完整图片 URL
        let fullURLString: String
        if imageUrl.hasPrefix("http") {
            fullURLString = imageUrl
        } else if UIImage(named: imageUrl) != nil {
            // 如果是本地图片名称
            imageView.image = UIImage(named: imageUrl)
            scrollView.zoomScale = 1.0
            return
        } else {
            fullURLString = AppConfig.API.fullImageURL(path: imageUrl)
        }
        if let url = URL(string: fullURLString) {
            imageView.kf.setImage(with: url)
        }
        scrollView.zoomScale = 1.0
    }

    @objc private func doubleTapped(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1.0 {
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            let point = gesture.location(in: imageView)
            let zoomRect = CGRect(x: point.x - 50, y: point.y - 50, width: 100, height: 100)
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
}

extension ImagePreviewCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // 居中显示
        let offsetX = max((scrollView.bounds.width - imageView.frame.width) / 2, 0)
        let offsetY = max((scrollView.bounds.height - imageView.frame.height) / 2, 0)
        imageView.center = CGPoint(x: offsetX + imageView.frame.width / 2,
                                   y: offsetY + imageView.frame.height / 2)
    }
}
