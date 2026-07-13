//
//  HomeNavigationView.swift
//  haveseeyou
//
//  首页顶部自定义导航：LOGO + 城市 + 类型筛选 + 搜索
//

import UIKit
import SnapKit


final class ActivityNavigationView: UIView {

    // MARK: - 回调

    /// 点击城市区域回调
    var onCityTapped: (() -> Void)?

    /// 点击筛选区域（活动类型/搜索）回调
    var onFilterTapped: (() -> Void)?

    // LOGO
    private let activeImg: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "sy_active_icon"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    // 搜索容器
    private let searchBg: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.black.cgColor
        return v
    }()

    // 城市
    private let cityLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = AppColor.textMain
        l.text = ""
        return l
    }()

    private let cityArrow: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "sy_active_triangle"))
        iv.tintColor = AppColor.textMain
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let verticalDivider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#D9D9D9")
        return v
    }()

    // 活动类型
    private let categoryLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = AppColor.textSecondary
        l.text = "活动类型： #运动健康-篮球"
        return l
    }()

    // 搜索 icon
    private let searchIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "sy_active_search"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupUI()
        setupGestures()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        addSubviews(activeImg, searchBg)
        searchBg.addSubviews(cityLabel, cityArrow, verticalDivider, categoryLabel, searchIcon)

        activeImg.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(18)
            make.centerY.equalToSuperview()
            make.width.equalTo(52.fit)
            make.height.equalTo(21.fit)
        }

        searchBg.snp.makeConstraints { make in
            make.left.equalTo(activeImg.snp.right).offset(8)
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(40)
        }

        cityLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
        }
        cityArrow.snp.makeConstraints { make in
            make.left.equalTo(cityLabel.snp.right).offset(2)
            make.bottom.equalToSuperview().offset(-12)
            make.size.equalTo(CGSize(width: 5, height: 5))
        }
        verticalDivider.snp.makeConstraints { make in
            make.left.equalTo(cityArrow.snp.right).offset(8)
            make.centerY.equalToSuperview()
            make.width.equalTo(1)
            make.height.equalTo(14)
        }
        categoryLabel.snp.makeConstraints { make in
            make.left.equalTo(verticalDivider.snp.right).offset(8)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(searchIcon.snp.left).offset(-8)
        }
        searchIcon.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
    }

    // MARK: - 手势

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(searchBgTapped(_:)))
        searchBg.isUserInteractionEnabled = true
        searchBg.addGestureRecognizer(tap)
    }

    @objc private func searchBgTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: searchBg)
        // 点击位置在竖线左侧 → 视为城市选择
        if point.x < verticalDivider.frame.minX {
            onCityTapped?()
        } else {
            // 点击位置在竖线右侧 → 视为筛选/搜索
            onFilterTapped?()
        }
    }

    // MARK: - 公开配置
    func update(city: String, category: String?) {
        let effectiveCity: String
        if !city.isEmpty {
            effectiveCity = city
        } else {
            effectiveCity = "全国"
        }
        cityLabel.text = effectiveCity
        
        if let c = category, !c.isEmpty {
            // 支持多类别：逗号分隔时显示首个类别 + 数量提示
            let parts = c.split(separator: ",").map(String.init)
            if parts.count > 1 {
                categoryLabel.text = "活动类型： \(parts.first ?? "")等\(parts.count)项"
            } else {
                categoryLabel.text = "活动类型： \(c)"
            }
        } else {
            categoryLabel.text = "活动类型：全部"
        }
    }
}
