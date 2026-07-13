//
//  DetailBannerView.swift
//  haveseeyou
//
//  活动详情页 Banner 轮播视图（支持自动轮播 + 点击查看大图）
//

import UIKit
import SnapKit
import Kingfisher

final class DetailBannerView: UIView {

    // MARK: - 回调

    /// 点击图片回调（传图片索引）
    var onImageTapped: ((Int) -> Void)?

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.bounces = false
        sv.isScrollEnabled = true
        return sv
    }()

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .white
        pc.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.5)
        pc.hidesForSinglePage = true
        return pc
    }()

    /// 自动轮播定时器
    private var timer: Timer?
    /// 当前轮播间隔（秒）
    private let autoScrollInterval: TimeInterval = 3.0

    private var imageUrls: [String] = []

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        stopAutoScroll()
        // 清理回调
        onImageTapped = nil
        // 清理 scrollView delegate
        scrollView.delegate = nil
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        stopAutoScroll()
        onImageTapped = nil
        scrollView.delegate = nil
    }

    private func setupUI() {
        addSubviews(scrollView, pageControl)
        scrollView.delegate = self

        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(22)
            make.height.equalTo(14)
        }
    }

    // MARK: - 配置数据

    func configure(_ imageUrls: [String]) {
        self.imageUrls = imageUrls
        stopAutoScroll()

        // 清理旧视图
        scrollView.subviews.forEach { $0.removeFromSuperview() }

        pageControl.numberOfPages = imageUrls.count
        pageControl.currentPage = 0

        // 单张图片时禁用滚动
        scrollView.isScrollEnabled = imageUrls.count > 1

        layoutIfNeeded()
        let w = bounds.width
        let h = bounds.height

        for (i, url) in imageUrls.enumerated() {
            let container = UIView()
            container.frame = CGRect(x: CGFloat(i) * w, y: 0, width: w, height: h)
            scrollView.addSubview(container)

            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.backgroundColor = UIColor(hex: "#E5E5E5")
            container.addSubview(imageView)
            imageView.snp.makeConstraints { $0.edges.equalToSuperview() }

            // 加载图片（支持本地资源名和网络 URL）
            let fullURLString: String
            if url.hasPrefix("http") {
                fullURLString = url
            } else if UIImage(named: url) != nil {
                // 如果是本地图片名称
                imageView.image = UIImage(named: url)
                continue
            } else {
                fullURLString = AppConfig.API.fullImageURL(path: url)
            }
            imageView.kf.setImage(with: URL(string: fullURLString))
           
            
          
            // 点击手势
            let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
            tap.view?.tag = i
            container.tag = i
            container.isUserInteractionEnabled = true
            container.addGestureRecognizer(tap)
        }

        scrollView.contentSize = CGSize(width: w * CGFloat(imageUrls.count), height: h)

        // 多张图片时开启自动轮播
        if imageUrls.count > 1 {
            startAutoScroll()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width
        // 只在有图片时才布局
        guard !imageUrls.isEmpty else { return }
        
        // 只处理实际添加的图片容器，使用 imageUrls.count 来限制
        for i in 0..<min(scrollView.subviews.count, imageUrls.count) {
            let v = scrollView.subviews[i]
            v.frame = CGRect(x: CGFloat(i) * w, y: 0, width: w, height: bounds.height)
        }
        // 使用实际的图片数量设置 contentSize
        scrollView.contentSize = CGSize(width: w * CGFloat(imageUrls.count), height: bounds.height)
    }

    // MARK: - 点击事件

    @objc private func imageTapped(_ gesture: UITapGestureRecognizer) {
        let index = gesture.view?.tag ?? 0
        onImageTapped?(index)
    }

    // MARK: - 自动轮播

    private func startAutoScroll() {
        stopAutoScroll()
        timer = Timer.scheduledTimer(withTimeInterval: autoScrollInterval, repeats: true) { [weak self] _ in
            self?.autoScrollToNext()
        }
    }

    private func stopAutoScroll() {
        timer?.invalidate()
        timer = nil
    }

    private func autoScrollToNext() {
        guard imageUrls.count > 1 else { return }
        let w = scrollView.bounds.width
        let currentPage = Int(round(scrollView.contentOffset.x / max(w, 1)))
        let nextPage = (currentPage + 1) % imageUrls.count
        scrollView.setContentOffset(CGPoint(x: CGFloat(nextPage) * w, y: 0), animated: true)
    }
}

// MARK: - UIScrollViewDelegate

extension DetailBannerView: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updatePageControl()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updatePageControl()
    }

    private func updatePageControl() {
        let w = max(scrollView.bounds.width, 1)
        let page = Int(round(scrollView.contentOffset.x / w))
        pageControl.currentPage = page
    }
}
