//
//  ActivityBannerView.swift
//  haveseeyou
//
//  首页头部 Banner（横向滚动 + 分页指示器 + 无限自动轮播）
//
//  无限轮播原理：
//  原始数据 [A, B, C] → 实际渲染 [C(ghost), A, B, C, A(ghost)]
//  滚到两端的 ghost 帧时，无动画瞬移回真实帧，用户感知不到跳变。
//

import UIKit
import SnapKit
import Kingfisher

final class ActivityBannerView: UIView {

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.bounces = false
        return sv
    }()

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = AppColor.buttonDark
        pc.pageIndicatorTintColor = AppColor.textSecondary
        pc.hidesForSinglePage = true
        return pc
    }()

    // MARK: - State

    /// 原始数据
    private var items: [BannerModel] = []

    /// 含首尾 ghost 帧的渲染数组：[last, item0, item1, ..., itemN, first]
    private var loopItems: [BannerModel] = []

    /// 当前显示的 loop 索引（包含 ghost 帧）
    private var currentLoopIndex: Int = 1

    private var autoScrollTimer: Timer?

    /// Banner 点击回调，返回被点击的 BannerModel（原始索引对应的真实数据）
    var onBannerTapped: ((BannerModel) -> Void)?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    deinit {
        stopAutoScroll()
    }

    // MARK: - Setup

    private func setupUI() {
        addSubviews(scrollView, pageControl)
        scrollView.delegate = self
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(8)
            make.height.equalTo(12)
        }
    }

    // MARK: - Configure

    func configure(_ banners: [BannerModel]) {
        stopAutoScroll()
        items = banners
        scrollView.subviews.forEach { $0.removeFromSuperview() }

        guard !banners.isEmpty else { return }

        // 构建 loopItems：[last] + items + [first]
        loopItems = [banners.last!] + banners + [banners.first!]

        pageControl.numberOfPages = banners.count
        pageControl.currentPage = 0
        currentLoopIndex = 1

        layoutIfNeeded()
        buildPages()

        // 定位到真正第一帧（index=1）
        let w = bounds.width
        scrollView.setContentOffset(CGPoint(x: w * CGFloat(currentLoopIndex), y: 0), animated: false)

        startAutoScroll()
    }

    /// 根据 loopItems 创建所有子视图
    private func buildPages() {
        scrollView.subviews.forEach { $0.removeFromSuperview() }

        let w = bounds.width
        let h = bounds.height

        for (i, item) in loopItems.enumerated() {
            let card = UIImageView(image: UIImage(named: item.imageURL))
            card.backgroundColor = .clear
            card.contentMode = .scaleAspectFill
            card.clipsToBounds = true
            card.layer.cornerRadius = 20
            card.layer.masksToBounds = true
            card.isUserInteractionEnabled = true
            // 内缩 padding 与之前一致
            card.frame = CGRect(
                x: CGFloat(i) * w + 16,
                y: 4,
                width: w - 32,
                height: h - 34
            )

            // tag 存原始数据索引（ghost 帧也映射到真实 item）
            card.tag = realIndex(from: i)

            scrollView.addSubview(card)

            let tap = UITapGestureRecognizer(target: self, action: #selector(bannerTapped(_:)))
            card.addGestureRecognizer(tap)
        }

        scrollView.contentSize = CGSize(width: w * CGFloat(loopItems.count), height: h)
    }

    // MARK: - layoutSubviews

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !loopItems.isEmpty else { return }

        let w = bounds.width
        let h = bounds.height

        for (i, v) in scrollView.subviews.enumerated() {
            v.frame = CGRect(
                x: CGFloat(i) * w + 16,
                y: 4,
                width: w - 32,
                height: h - 34
            )
        }
        scrollView.contentSize = CGSize(width: w * CGFloat(loopItems.count), height: h)
        // 保持当前帧位置不偏移
        scrollView.setContentOffset(CGPoint(x: w * CGFloat(currentLoopIndex), y: 0), animated: false)
    }

    // MARK: - 自动轮播

    private func startAutoScroll() {
        guard items.count > 1 else { return }
        stopAutoScroll()
        autoScrollTimer = Timer.scheduledTimer(
            timeInterval: 3.0,
            target: self,
            selector: #selector(scrollToNext),
            userInfo: nil,
            repeats: true
        )
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    @objc private func scrollToNext() {
        let nextIndex = currentLoopIndex + 1
        let w = bounds.width
        scrollView.setContentOffset(CGPoint(x: w * CGFloat(nextIndex), y: 0), animated: true)
    }

    // MARK: - 工具

    /// 将 loopIndex 映射为原始数据索引
    private func realIndex(from loopIndex: Int) -> Int {
        // loopItems = [last(0), item0(1), item1(2), ..., itemN(n), first(n+1)]
        let count = items.count
        if loopIndex == 0 { return count - 1 }
        if loopIndex == count + 1 { return 0 }
        return loopIndex - 1
    }
}

// MARK: - UIScrollViewDelegate

extension ActivityBannerView: UIScrollViewDelegate {

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        handleScrollEnd()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        handleScrollEnd()
    }

    /// 用户开始拖动时暂停自动轮播
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopAutoScroll()
    }

    /// 用户拖动结束后恢复自动轮播
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            handleScrollEnd()
        }
        startAutoScroll()
    }

    private func handleScrollEnd() {
        let w = max(bounds.width, 1)
        let page = Int(round(scrollView.contentOffset.x / w))
        currentLoopIndex = page

        // 到达右侧 ghost 帧（index = count+1）→ 跳到真实第一帧（index=1）
        if page == loopItems.count - 1 {
            currentLoopIndex = 1
            scrollView.setContentOffset(CGPoint(x: w * CGFloat(currentLoopIndex), y: 0), animated: false)
        }
        // 到达左侧 ghost 帧（index = 0）→ 跳到真实最后一帧（index=count）
        else if page == 0 {
            currentLoopIndex = items.count
            scrollView.setContentOffset(CGPoint(x: w * CGFloat(currentLoopIndex), y: 0), animated: false)
        }

        pageControl.currentPage = realIndex(from: currentLoopIndex)
    }
}

// MARK: - 点击事件

extension ActivityBannerView {
    @objc private func bannerTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        let index = view.tag   // tag 已映射为原始索引
        guard index < items.count else { return }
        onBannerTapped?(items[index])
    }
}
