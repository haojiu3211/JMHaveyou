//
//  HelpFeedbackViewController.swift
//  haveseeyou
//
//  问题反馈页面
//

import UIKit
import SnapKit
import Combine

final class HelpFeedbackViewController: BaseViewController {
    
    // MARK: - Properties
    
    private var userId: String?
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.backgroundColor = .white
        return sv
    }()
    
    private let contentView = UIView()
    
    // 图片证据标题
    private let photoTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColor.textMain
        
        let attributedText = NSMutableAttributedString(string: "*图片证据（最多4张）")
        attributedText.addAttribute(.foregroundColor, value: UIColor.red, range: NSRange(location: 0, length: 1))
        label.attributedText = attributedText
        
        return label
    }()
    
    // 图片容器
    private let photoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    // 图片 CollectionView
    private lazy var photoCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: 100, height: 100)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(HelpFeedbackPhotoCell.self, forCellWithReuseIdentifier: HelpFeedbackPhotoCell.identifier)
        return cv
    }()
    
    // 文字描述标题
    private let descriptionTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColor.textMain
        
        let attributedText = NSMutableAttributedString(string: "*文字描述（讲述对方的违规行为）")
        attributedText.addAttribute(.foregroundColor, value: UIColor.red, range: NSRange(location: 0, length: 1))
        label.attributedText = attributedText
        
        return label
    }()
    
    // 文字描述输入框
    private let descriptionTextView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = UIColor(hex: "#F5F5F5")
        tv.textColor = AppColor.textMain
        tv.font = .systemFont(ofSize: 14)
        tv.layer.cornerRadius = 8
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return tv
    }()
    
    // 描述占位文字
    private let descriptionPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "请输入..."
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor(hex: "#B2B6C1")
        label.numberOfLines = 0
        return label
    }()
    
    // 字数统计
    private let wordCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0/500"
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor(hex: "#999999")
        label.textAlignment = .right
        return label
    }()
    
    // 提交按钮
    private let submitButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("提交", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btn.backgroundColor = UIColor(hex: "#B3B3B3")
        btn.layer.cornerRadius = 24
        btn.clipsToBounds = true
        btn.isEnabled = false
        return btn
    }()
    
    // MARK: - Properties
    
    private var selectedImages: [UIImage] = []
    private let maxPhotoCount = 4
    private let maxWordCount = 500
    
    // MARK: - Init
    
    init(userId: String? = nil) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = userId != nil ? "举报用户" : "问题反馈"
    }
    
    override func setupUI() {
        super.setupUI()
        view.backgroundColor = .white
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-80)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        
        setupContentViews()
        setupSubmitButton()
        
        descriptionTextView.delegate = self
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
    }
    
    private func setupContentViews() {
        contentView.addSubviews(
            photoTitleLabel,
            photoContainerView,
            descriptionTitleLabel,
            descriptionTextView,
            wordCountLabel
        )
        
        photoContainerView.addSubview(photoCollectionView)
        
        // 图片证据标题
        photoTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        // 图片容器
        photoContainerView.snp.makeConstraints { make in
            make.top.equalTo(photoTitleLabel.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(100)
        }
        
        photoCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 描述标题
        descriptionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(photoContainerView.snp.bottom).offset(32)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        // 描述输入框
        descriptionTextView.snp.makeConstraints { make in
            make.top.equalTo(descriptionTitleLabel.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(220)
        }
        
        descriptionTextView.addSubview(descriptionPlaceholderLabel)
        descriptionPlaceholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-16)
        }
        
        // 字数统计
        wordCountLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionTextView.snp.bottom).offset(8)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-30)
        }
    }
    
    private func setupSubmitButton() {
        view.addSubview(submitButton)
        
        submitButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().offset(-32)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.height.equalTo(48)
        }
    }
    
    // MARK: - Actions
    
    @objc private func addPhotoTapped() {
        let remainingCount = maxPhotoCount - selectedImages.count
        
        var config = PhotoPickerConfig()
        config.showsCrop = false
        config.hidesPreview = true
        
        PhotoPicker.showMultiple(
            from: self,
            config: config,
            maxCount: remainingCount,
            onSelected: { [weak self] images in
                guard let self = self else { return }
                self.selectedImages.append(contentsOf: images)
                self.photoCollectionView.reloadData()
                self.updateSubmitButtonState()
            },
            onCancel: {
                print("取消选择图片")
            }
        )
    }
    
    @objc private func deletePhotoTapped(_ sender: UIButton) {
        let index = sender.tag
        selectedImages.remove(at: index)
        photoCollectionView.reloadData()
        updateSubmitButtonState()
    }
    
    @objc private func submitTapped() {
        guard !selectedImages.isEmpty else {
            showToast("请选择图片证据")
            return
        }
        
        guard let description = descriptionTextView.text, !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showToast("请输入文字描述")
            return
        }
        
        showLoading("提交中...")
        
        // 1. 把内存中的 UIImage 写到临时目录
        let tempDir = NSTemporaryDirectory()
        var absPaths: [String] = []
        let ts = Int(Date().timeIntervalSince1970 * 1000)
        for (idx, image) in selectedImages.enumerated() {
            guard let data = image.jpegData(compressionQuality: 0.8) else { continue }
            let fileName = "report_\(ts)_\(idx).jpg"
            let absPath = (tempDir as NSString).appendingPathComponent(fileName)
            do {
                try data.write(to: URL(fileURLWithPath: absPath), options: .atomic)
                absPaths.append(absPath)
            } catch {
                #if DEBUG
                print("❌ [Report] 写临时文件失败 \(fileName): \(error.localizedDescription)")
                #endif
            }
        }
        
        guard !absPaths.isEmpty else {
            hideLoading()
            showToast("图片处理失败")
            return
        }
        
        // 2. 申请 STS
        OssUploadUtil.getSTS(type: "report") { [weak self] sts in
            guard let self = self else { return }
            guard let sts = sts else {
                self.hideLoading()
                self.showToast("获取上传凭证失败")
                return
            }
            
            // 3. 上传到 OSS
            OssUploadUtil.uploadToOSS(sts: sts, filePaths: absPaths) { [weak self] keys in
                guard let self = self else { return }
                guard let keys = keys, keys.count == absPaths.count else {
                    self.hideLoading()
                    self.showToast("图片上传失败")
                    return
                }
                
                #if DEBUG
                print("✅ [Report] OSS 上传完成: \(keys)")
                #endif
                
                // 4. 调用举报接口
                self.submitReport(images: keys.joined(separator: ","), content: description)
            }
        }
    }
    
    private func submitReport(images: String, content: String) {
        let reportUserId = userId ?? ""
        let type = userId != nil ? "1" : "2"
        
        NetworkManager.shared.request(
            LoginAPI.reportUser(reportUid: reportUserId, content: content, images: images, type: type),
            as: APIResponse<EmptyData>.self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.hideLoading()
                
                if case let .failure(error) = completion {
                    self.showToast(error.localizedDescription)
                }
            },
            receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.hideLoading()
                
                if response.isSuccess {
                    self.showToast("提交成功")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.navigationController?.popViewController(animated: true)
                    }
                } else {
                    self.showToast(response.message ?? "提交失败")
                }
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Private
    
    private func updateSubmitButtonState() {
        let hasPhoto = !selectedImages.isEmpty
        let hasDescription = !descriptionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        let canSubmit = hasPhoto && hasDescription
        submitButton.isEnabled = canSubmit
        
        if(canSubmit){
            submitButton.backgroundColor = AppColor.buttonDark
            submitButton.setTitleColor(AppColor.theme, for: .normal)
        }else {
            submitButton.backgroundColor = UIColor(hex: "#B3B3B3")
            submitButton.setTitleColor(.white, for: .normal)
        }
   
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension HelpFeedbackViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedImages.count + (selectedImages.count < maxPhotoCount ? 1 : 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HelpFeedbackPhotoCell.identifier, for: indexPath) as! HelpFeedbackPhotoCell
        
        if indexPath.item < selectedImages.count {
            cell.configure(image: selectedImages[indexPath.item], index: indexPath.item)
            cell.deleteButton.addTarget(self, action: #selector(deletePhotoTapped(_:)), for: .touchUpInside)
        } else {
            cell.configureAsAddButton()
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == selectedImages.count {
            addPhotoTapped()
        }
    }
}

// MARK: - UITextViewDelegate

extension HelpFeedbackViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        // 更新占位文字
        descriptionPlaceholderLabel.isHidden = !textView.text.isEmpty
        
        // 限制字数
        if textView.text.count > maxWordCount {
            textView.text = String(textView.text.prefix(maxWordCount))
        }
        
        // 更新字数统计
        wordCountLabel.text = "\(textView.text.count)/\(maxWordCount)"
        
        // 更新提交按钮状态
        updateSubmitButtonState()
    }
}

// MARK: - Photo Cell

final class HelpFeedbackPhotoCell: UICollectionViewCell {
    
    static let identifier = "HelpFeedbackPhotoCell"
    
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = UIColor(hex: "#F5F5F5")
        return iv
    }()
    
    let deleteButton: UIButton = {
        let btn = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        btn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        btn.layer.cornerRadius = 12
        btn.clipsToBounds = true
        return btn
    }()
    
    let addImageView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#F5F5F5")
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(hex: "#E5E5E5").cgColor
        
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "plus")
        imageView.tintColor = UIColor(hex: "#CCCCCC")
        imageView.contentMode = .scaleAspectFit
        
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(deleteButton)
        contentView.addSubview(addImageView)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        deleteButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-4)
            make.right.equalToSuperview().offset(4)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        addImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addImageView.isHidden = true
    }
    
    func configure(image: UIImage, index: Int) {
        imageView.image = image
        imageView.isHidden = false
        deleteButton.isHidden = false
        addImageView.isHidden = true
        deleteButton.tag = index
    }
    
    func configureAsAddButton() {
        imageView.isHidden = true
        deleteButton.isHidden = true
        addImageView.isHidden = false
    }
}
