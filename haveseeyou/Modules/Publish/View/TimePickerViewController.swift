//
//  TimePickerViewController.swift
//  haveseeyou
//
//  时间选择弹框
//  左侧：日期选择（从今天开始，最多1个月）
//  右侧：时间选择（从当前时间开始，每5分钟一个刻度）
//

import UIKit
import SnapKit

final class TimePickerViewController: UIViewController {
    
    // MARK: - 回调
    
    /// 选择时间后的回调
    var onTimeSelected: ((Date) -> Void)?
    
    // MARK: - 数据
    
    private var dateList: [DateItem] = []
    private var hourList: [Int] = []
    private var minuteList: [Int] = []
    
    private var selectedDateIndex: Int = 0
    private var selectedHourIndex: Int = 0
    private var selectedMinuteIndex: Int = 0
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.clipsToBounds = true
        return v
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "活动时间"
        l.font = .systemFont(ofSize: 18, weight: .medium)
        l.textColor = AppColor.textMain
        l.textAlignment = .center
        return l
    }()
    
    private let cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("取消", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.setTitleColor(AppColor.textSecondary, for: .normal)
        return btn
    }()
    
    private let confirmButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "publish_right"), for: .normal)
        return btn
    }()
    
    // 日期选择器
    private lazy var datePickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()
    
    // 小时选择器
    private lazy var hourPickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()
    
    // 分钟选择器
    private lazy var minutePickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()
    
    private let colonLabel1: UILabel = {
        let l = UILabel()
        l.text = ":"
        l.font = .systemFont(ofSize: 24, weight: .medium)
        l.textColor = AppColor.textMain
        l.textAlignment = .center
        return l
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupData()
        setupActions()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        view.addSubview(containerView)
        containerView.addSubviews(titleLabel, cancelButton, confirmButton, 
                                  datePickerView, hourPickerView, minutePickerView, colonLabel1)
        
        containerView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(400)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
            make.width.equalTo(60)
            make.height.equalTo(32)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(cancelButton)
        }
        
        confirmButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(cancelButton)
            make.width.height.equalTo(32)
        }
        
        // 日期选择器（左侧，占比更大）
        datePickerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.width.equalTo(180)
        }
        
        // 小时选择器
        hourPickerView.snp.makeConstraints { make in
            make.left.equalTo(datePickerView.snp.right).offset(10)
            make.top.bottom.equalTo(datePickerView)
            make.width.equalTo(60)
        }
        
        // 冒号
        colonLabel1.snp.makeConstraints { make in
            make.left.equalTo(hourPickerView.snp.right)
            make.centerY.equalTo(hourPickerView)
            make.width.equalTo(20)
        }
        
        // 分钟选择器
        minutePickerView.snp.makeConstraints { make in
            make.left.equalTo(colonLabel1.snp.right)
            make.top.bottom.equalTo(datePickerView)
            make.right.equalToSuperview().offset(-16)
            make.width.equalTo(60)
        }
    }
    
    private func setupData() {
        let now = Date()
        let calendar = Calendar.current
        
        // 1. 生成日期列表（从今天开始，最多1个月）
        dateList = []
        for dayOffset in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: now) {
                let dateItem = DateItem(date: date)
                dateList.append(dateItem)
            }
        }
        
        // 2. 生成小时列表（0-23）
        hourList = Array(0...23)
        
        // 3. 生成分钟列表（每5分钟一个刻度）
        minuteList = stride(from: 0, to: 60, by: 5).map { $0 }
        
        // 4. 设置默认选中项（当前时间向上取整到最近的5分钟）
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        // 分钟向上取整到5的倍数
        let roundedMinute = ((currentMinute / 5) + 1) * 5
        
        if roundedMinute >= 60 {
            // 如果分钟超过60，小时+1，分钟归0
            selectedHourIndex = hourList.firstIndex(of: (currentHour + 1) % 24) ?? 0
            selectedMinuteIndex = 0
        } else {
            selectedHourIndex = hourList.firstIndex(of: currentHour) ?? 0
            selectedMinuteIndex = minuteList.firstIndex(of: roundedMinute) ?? 0
        }
        
        // 5. 刷新选择器
        datePickerView.reloadAllComponents()
        hourPickerView.reloadAllComponents()
        minutePickerView.reloadAllComponents()
        
        // 6. 设置默认选中
        datePickerView.selectRow(selectedDateIndex, inComponent: 0, animated: false)
        hourPickerView.selectRow(selectedHourIndex, inComponent: 0, animated: false)
        minutePickerView.selectRow(selectedMinuteIndex, inComponent: 0, animated: false)
    }
    
    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        
        // 添加点击背景关闭
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func confirmTapped() {
        let selectedDate = dateList[selectedDateIndex].date
        let selectedHour = hourList[selectedHourIndex]
        let selectedMinute = minuteList[selectedMinuteIndex]
        
        // 组合日期和时间
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = selectedHour
        components.minute = selectedMinute
        components.second = 0
        
        guard var finalDate = calendar.date(from: components) else {
            dismiss(animated: true)
            return
        }
        
        // 检查选择的时间是否已经小于当前时间
        let now = Date()
        if finalDate < now {
            // 如果选择的时间已经过去，使用当前时间
            finalDate = now
            print("⚠️ 选择的时间已过期，使用当前时间")
        }
        
        // 回调
        onTimeSelected?(finalDate)
        
        dismiss(animated: true)
    }
    
    @objc private func backgroundTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - 显示方法
    
    static func show(from viewController: UIViewController, onTimeSelected: @escaping (Date) -> Void) {
        let picker = TimePickerViewController()
        picker.onTimeSelected = onTimeSelected
        picker.modalPresentationStyle = .overFullScreen
        picker.modalTransitionStyle = .crossDissolve
        viewController.present(picker, animated: true)
    }
}

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate

extension TimePickerViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == datePickerView {
            return dateList.count
        } else if pickerView == hourPickerView {
            return hourList.count
        } else {
            return minuteList.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == datePickerView {
            return dateList[row].displayText
        } else if pickerView == hourPickerView {
            return String(format: "%02d", hourList[row])
        } else {
            return String(format: "%02d", minuteList[row])
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == datePickerView {
            selectedDateIndex = row
        } else if pickerView == hourPickerView {
            selectedHourIndex = row
        } else {
            selectedMinuteIndex = row
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        
        if pickerView == datePickerView {
            label.text = dateList[row].displayText
            label.font = .systemFont(ofSize: 16, weight: .medium)
        } else if pickerView == hourPickerView {
            label.text = String(format: "%02d", hourList[row])
            label.font = .systemFont(ofSize: 24, weight: .medium)
        } else {
            label.text = String(format: "%02d", minuteList[row])
            label.font = .systemFont(ofSize: 24, weight: .medium)
        }
        
        label.textColor = AppColor.textMain
        label.textAlignment = .center
        
        return label
    }
}

// MARK: - UIGestureRecognizerDelegate

extension TimePickerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 只有点击背景时才关闭，点击容器内部不关闭
        return touch.view == view
    }
}

// MARK: - DateItem 数据模型

private struct DateItem {
    let date: Date
    
    var displayText: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        
        // 判断是否是今天
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "M月d日(今天)"
        } else {
            formatter.dateFormat = "M月d日(EEEE)"
        }
        
        return formatter.string(from: date)
    }
}
