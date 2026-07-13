//
//  SelfSizingTableView.swift
//  haveseeyou
//
//  自适应高度的 UITableView：把 contentSize.height 暴露为 intrinsicContentSize，
//  嵌在外层 UIScrollView 内时可直接用 Auto Layout 撑起，无需手动算 rowHeight * count。
//  使用前提：自身 isScrollEnabled 应设为 false，由外层 scrollView 处理滚动。
//

import UIKit

final class SelfSizingTableView: UITableView {

    override var contentSize: CGSize {
        didSet {
            guard oldValue != contentSize else { return }
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
