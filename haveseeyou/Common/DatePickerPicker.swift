//
//  DatePickerPicker.swift
//  haveseeyou
//
//  通用日期选择弹框 - 基于 UIDatePicker + UIToolbar
//  使用方式：调用 show() 弹出，通过 onConfirm / onCancel 回调获取结果
//

import UIKit
import SnapKit

final class DatePickerPicker {

    // MARK: - Callback

    /// 确认选择回调，返回选中的日期字符串（按指定 format 格式化）
    var onConfirm: ((String, Date) -> Void)?

    /// 取消回调
    var onCancel: (() -> Void)?

    // MARK: - Config

    /// 日期格式，默认 "yyyy年MM月dd日"
    var dateFormat: String = "yyyy年MM月dd日"

    /// 最大可选日期（用户最小18岁，即出生日期不能晚于18年前）
    var maximumDate: Date? = Calendar.current.date(byAdding: .year, value: -19, to: Date())

    /// 最小可选日期（用户最大100岁，即出生日期不能早于100年前）
    var minimumDate: Date? = Calendar.current.date(byAdding: .year, value: -100, to: Date())

    /// 默认选中日期（未设置时取 maximumDate 或当前日期）
    var defaultDate: Date?

    /// 选择器模式，默认 .date
    var datePickerMode: UIDatePicker.Mode = .date

    // MARK: - Private

    private let datePicker = UIDatePicker()
    private let hiddenTextField = UITextField()
    private weak var hostView: UIView?

    // MARK: - Show / Hide

    /// 在指定 view 上弹出日期选择器
    func show(on view: UIView) {
        hostView = view
        view.endEditing(true)

        // 配置 DatePicker
        datePicker.datePickerMode = datePickerMode
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = Locale(identifier: "zh_CN")
        datePicker.maximumDate = maximumDate
        datePicker.minimumDate = minimumDate
        datePicker.date = defaultDate ?? maximumDate ?? Date()

        // 隐藏输入框作为键盘触发器
        hiddenTextField.isHidden = true
        hiddenTextField.inputView = datePicker
        hiddenTextField.inputAccessoryView = makeToolbar()

        // 添加到 hostView 并弹出键盘
        if hiddenTextField.superview == nil {
            view.addSubview(hiddenTextField)
            hiddenTextField.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(-1)
                make.top.equalToSuperview().offset(-10)
                make.width.height.equalTo(1)
            }
        }
        hiddenTextField.becomeFirstResponder()
    }

    /// 隐藏日期选择器
    func hide() {
        hiddenTextField.resignFirstResponder()
    }

    // MARK: - Toolbar

    private lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.barTintColor = AppColor.buttonDark
        toolbar.isTranslucent = false

        let done = UIBarButtonItem(title: "确定", style: .done, target: self, action: #selector(confirmAction))
        done.setTitleTextAttributes(
            [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 17, weight: .medium)],
            for: .normal
        )
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancel = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(cancelAction))
        cancel.setTitleTextAttributes(
            [.foregroundColor: UIColor.red, .font: UIFont.systemFont(ofSize: 17, weight: .medium)],
            for: .normal
        )
        toolbar.items = [cancel, space, done]
        return toolbar
    }()

    private func makeToolbar() -> UIToolbar {
        return toolbar
    }

    // MARK: - Actions

    @objc private func confirmAction() {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        let dateString = formatter.string(from: datePicker.date)
        
        // 调用原来的 hide 方法
        hide()
        
        // 稍微延迟一下再回调，确保隐藏完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.onConfirm?(dateString, self?.datePicker.date ?? Date())
        }
    }

    @objc private func cancelAction() {
        // 调用原来的 hide 方法
        hide()
        
        // 稍微延迟一下再回调，确保隐藏完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.onCancel?()
        }
    }
}
