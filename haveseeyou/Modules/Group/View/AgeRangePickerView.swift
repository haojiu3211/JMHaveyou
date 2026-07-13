//
//  AgeRangePickerView.swift
//  haveseeyou
//
//  年龄区间选择弹框 - 从底部弹出的面板
//  双列 UIPickerView（最小年龄 / 最大年龄）
//  年龄范围 6~100，默认最小18、最大25
//

import UIKit
import SnapKit

final class AgeRangePickerView: UIView {

    // MARK: - Callback

    /// 确认回调，返回 (最小年龄, 最大年龄)
    var onConfirm: ((Int, Int) -> Void)?

    /// 取消回调
    var onCancel: (() -> Void)?

    // MARK: - Config

    private let minAge = 6
    private let maxAge = 100

    // MARK: - Private

    private var selectedMinAge: Int
    private var selectedMaxAge: Int

    /// 年龄数据源 [6, 7, 8, ..., 100]
    private lazy var ageList: [Int] = Array(minAge...maxAge)

    /// 面板高度
    private let sheetHeight: CGFloat = 300

    // MARK: - UI Components

    /// 半透明蒙层
    private let overlayView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        return v
    }()

    /// 底部面板
    private let sheetView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.clipsToBounds = true
        return v
    }()

    /// 顶部工具栏 - 包含取消、标题、确定
    private let toolbarView = UIView()

    /// 取消按钮 - 左侧
    private let cancelButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("取消", for: .normal)
        btn.setTitleColor(AppColor.textSecondary, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15)
//        btn.backgroundColor = .purple
        return btn
    }()

    /// 确定按钮 - 右侧
    private let confirmButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("确定", for: .normal)
        btn.setTitleColor(AppColor.textMain, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        return btn
    }()

    /// 最小年龄标题 - 中间偏左
    private let minAgeTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "最小年龄"
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textColor = AppColor.textMain
        l.textAlignment = .center
        return l
    }()

    /// 最大年龄标题 - 中间偏右
    private let maxAgeTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "最大年龄"
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textColor = AppColor.textMain
        l.textAlignment = .center
        return l
    }()

    /// 双列选择器
    private let pickerView: UIPickerView = {
        let pv = UIPickerView()
        pv.backgroundColor = .white
        return pv
    }()

    // MARK: - Init

    init(defaultMin: Int = 18, defaultMax: Int = 25) {
        self.selectedMinAge = defaultMin
        self.selectedMaxAge = defaultMax
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Show / Hide

    /// 在 Window 上弹出
    func show(defaultMin: Int = 18, defaultMax: Int = 25) {
        self.selectedMinAge = defaultMin
        self.selectedMaxAge = defaultMax

        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first(where: { $0.isKeyWindow }) else { return }

        window.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        setupSubviews()
        setupActions()

        // 设置默认选中行
        if let minIndex = ageList.firstIndex(of: defaultMin) {
            pickerView.selectRow(minIndex, inComponent: 0, animated: false)
        }
        if let maxIndex = ageList.firstIndex(of: defaultMax) {
            pickerView.selectRow(maxIndex, inComponent: 1, animated: false)
        }

        // 入场动画：从底部滑入
        layoutIfNeeded()
        sheetView.transform = CGAffineTransform(translationX: 0, y: sheetHeight)
        overlayView.alpha = 0
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.overlayView.alpha = 1
            self.sheetView.transform = .identity
        }
    }

    /// 隐藏弹框
    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
            self.overlayView.alpha = 0
            self.sheetView.transform = CGAffineTransform(translationX: 0, y: self.sheetHeight)
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }

    // MARK: - Setup

    private func setupSubviews() {
        addSubview(overlayView)
        addSubview(sheetView)

        pickerView.dataSource = self
        pickerView.delegate = self

        sheetView.addSubview(toolbarView)
        sheetView.addSubview(pickerView)

        toolbarView.addSubviews(
            cancelButton,
            minAgeTitleLabel,
            maxAgeTitleLabel,
            confirmButton
        )

        // 蒙层
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 底部面板
        sheetView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(sheetHeight)
        }

        // 顶部工具栏
        toolbarView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(50)
        }

        // 取消 - 左侧
        cancelButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.left.equalToSuperview().offset(6)
            make.size.equalTo(CGSizeMake(80, 34))
        }

        // 确定 - 右侧
        confirmButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-6)
            make.top.equalTo(cancelButton)
            make.size.equalTo(CGSizeMake(80, 34))
        }

        // 最小年龄标题 - 左中
        minAgeTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(cancelButton)
            make.left.equalTo(cancelButton.snp.right).offset(4)
//            make.right.equalTo(sheetView.snp.centerX)
        }

        // 最大年龄标题 - 右中
        maxAgeTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(minAgeTitleLabel)
//            make.left.equalTo(sheetView.snp.centerX)
            make.right.equalTo(confirmButton.snp.left).offset(-8)
        }

        // Picker
        pickerView.snp.makeConstraints { make in
            make.top.equalTo(toolbarView.snp.bottom)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview()
        }
       
    }

    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        let overlayTap = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
        overlayView.addGestureRecognizer(overlayTap)
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss { [weak self] in
            self?.onCancel?()
        }
    }

    @objc private func confirmTapped() {
        let min = selectedMinAge
        let max = selectedMaxAge

        if min > max {
            AppToast.show("年龄设置有误请重新设置")
            return
        }

        dismiss { [weak self] in
            self?.onConfirm?(min, max)
        }
    }
}

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate

extension AgeRangePickerView: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return ageList.count
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.text = "\(ageList[row])"
        label.textAlignment = .center

        let selectedRow = pickerView.selectedRow(inComponent: component)
        if row == selectedRow {
            label.font = .systemFont(ofSize: 30, weight: .semibold)
            label.textColor = AppColor.textMain
        } else {
            label.font = .systemFont(ofSize: 20)
            label.textColor = AppColor.textSecondary
        }
        return label
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            selectedMinAge = ageList[row]
        default:
            selectedMaxAge = ageList[row]
        }
        pickerView.reloadComponent(component)
    }
}
