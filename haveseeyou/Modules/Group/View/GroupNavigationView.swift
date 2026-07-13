//
//  GroupNavigationView.swift
//  haveseeyou
//
//  搭子首页顶部导航栏：标题 + 活动规则按钮
//

import UIKit
import SnapKit

final class GroupNavigationView: UIView {

    // MARK: - 回调

    var onFilterButtonTapped: (() -> Void)?
    var onTabSelected: ((String) -> Void)?

    // MARK: - UI

    private lazy var titleButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("一呼百应", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        btn.setTitleColor(UIColor(hex: "#100A1D"), for: .normal)
        btn.addTarget(self, action: #selector(titleButtonTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var activityPartnerButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("活动搭子", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        btn.setTitleColor(UIColor(hex: "#888888"), for: .normal)
        btn.addTarget(self, action: #selector(activityPartnerButtonTapped), for: .touchUpInside)
        return btn
    }()

    private let filterButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "dazi_flutter_icon"), for: .normal)
        btn.setTitle("筛选", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(AppColor.textMain, for: .normal)
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupUI()
        setupActions()
        filterButton.isHidden = true
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        addSubviews(titleButton, activityPartnerButton, filterButton)

        titleButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(26)
            make.centerY.equalToSuperview()
        }

        activityPartnerButton.snp.makeConstraints { make in
            make.left.equalTo(titleButton.snp.right).offset(16)
            make.centerY.equalToSuperview()
        }

        filterButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    private func setupActions() {
        filterButton.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
    }

    @objc private func filterButtonTapped() {
        onFilterButtonTapped?()
    }

    @objc private func titleButtonTapped() {
        updateSelection(selected: .title)
        onTabSelected?("一呼百应")
    }

    @objc private func activityPartnerButtonTapped() {
        updateSelection(selected: .activityPartner)
        onTabSelected?("活动搭子")
    }

    private func updateSelection(selected: TabType) {
        switch selected {
        case .title:
            titleButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
            titleButton.setTitleColor(UIColor(hex: "#100A1D"), for: .normal)
            activityPartnerButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
            activityPartnerButton.setTitleColor(UIColor(hex: "#888888"), for: .normal)
            filterButton.isHidden = true
        case .activityPartner:
            activityPartnerButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
            activityPartnerButton.setTitleColor(UIColor(hex: "#100A1D"), for: .normal)
            titleButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
            titleButton.setTitleColor(UIColor(hex: "#888888"), for: .normal)
            filterButton.isHidden = false
        }
    }
}

private enum TabType {
    case title
    case activityPartner
}
