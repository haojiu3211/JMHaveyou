//
//  PhotoPicker.swift
//  haveseeyou
//
//  通用照片选择器 - 封装 YPImagePicker
//  提供底部弹框（从相册选择 / 拍照 / 取消）+ 图片裁剪 + 压缩
//  使用方式：PhotoPicker.show(from: self) { image in ... }
//

import UIKit
import Photos
import YPImagePicker
import SnapKit

// MARK: - 选择来源

enum PhotoSource {
    /// 相册
    case library
    /// 拍照
    case camera
}

// MARK: - 配置模型

struct PhotoPickerConfig {

    /// 是否显示裁剪功能（默认 true）
    var showsCrop: Bool = true

    /// 裁剪类型，默认 1:1 正方形（头像场景）
    /// 可选 .rectangle(ratio: Double) 或 .circle
    var cropType: YPCropType = .rectangle(ratio: 1.0)

    /// 是否只选一张（默认 true，头像场景）
    var singlePhoto: Bool = true

    /// 压缩后最大宽度（默认 800px）
    var maxWidth: CGFloat = 800

    /// 压缩质量（默认 0.8）
    var compressionQuality: CGFloat = 0.8

    /// 弹框"从相册选择"文案
    var libraryText: String = "从相册选择"

    /// 弹框"拍照"文案
    var cameraText: String = "拍照"

    /// 弹框“取消”文案
    var cancelText: String = "取消"

    /// 是否隐藏相册页顶部预览区，直接展示图片网格。默认 true
    var hidesPreview: Bool = true
}

// MARK: - 全局调用入口

enum PhotoPicker {

    /// 弹出底部选择弹框，选中后回调 UIImage（已压缩）
    static func show(
        from viewController: UIViewController,
        config: PhotoPickerConfig = PhotoPickerConfig(),
        onSelected: @escaping (UIImage) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        let actionSheet = PhotoActionSheetController(
            config: config,
            onLibrary: {
                presentYPImagePicker(
                    from: viewController,
                    source: .library,
                    config: config,
                    onSelected: onSelected,
                    onCancel: onCancel
                )
            },
            onCamera: {
                presentYPImagePicker(
                    from: viewController,
                    source: .camera,
                    config: config,
                    onSelected: onSelected,
                    onCancel: onCancel
                )
            },
            onCancel: onCancel
        )
        actionSheet.modalPresentationStyle = .overFullScreen
        actionSheet.modalTransitionStyle = .crossDissolve
        viewController.present(actionSheet, animated: true)
    }
    
    /// 弹出底部选择弹框，支持多选，选中后回调 [UIImage]（已压缩）
    static func showMultiple(
        from viewController: UIViewController,
        config: PhotoPickerConfig = PhotoPickerConfig(),
        maxCount: Int = 9,
        onSelected: @escaping ([UIImage]) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        var multiConfig = config
        multiConfig.singlePhoto = false
        
        let actionSheet = PhotoActionSheetController(
            config: multiConfig,
            onLibrary: {
                presentYPImagePickerMultiple(
                    from: viewController,
                    source: .library,
                    config: multiConfig,
                    maxCount: maxCount,
                    onSelected: onSelected,
                    onCancel: onCancel
                )
            },
            onCamera: {
                presentYPImagePicker(
                    from: viewController,
                    source: .camera,
                    config: multiConfig,
                    onSelected: { image in
                        onSelected([image])
                    },
                    onCancel: onCancel
                )
            },
            onCancel: onCancel
        )
        actionSheet.modalPresentationStyle = .overFullScreen
        actionSheet.modalTransitionStyle = .crossDissolve
        viewController.present(actionSheet, animated: true)
    }

    /// 直接打开相册（不弹底部弹框）
    static func openLibrary(
        from viewController: UIViewController,
        config: PhotoPickerConfig = PhotoPickerConfig(),
        onSelected: @escaping (UIImage) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        presentYPImagePicker(
            from: viewController,
            source: .library,
            config: config,
            onSelected: onSelected,
            onCancel: onCancel
        )
    }
    
    /// 直接打开相册（不弹底部弹框），支持多选
    static func openLibraryMultiple(
        from viewController: UIViewController,
        config: PhotoPickerConfig = PhotoPickerConfig(),
        maxCount: Int = 9,
        onSelected: @escaping ([UIImage]) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        var multiConfig = config
        multiConfig.singlePhoto = false
        
        presentYPImagePickerMultiple(
            from: viewController,
            source: .library,
            config: multiConfig,
            maxCount: maxCount,
            onSelected: onSelected,
            onCancel: onCancel
        )
    }

    /// 直接打开相机（不弹底部弹框）
    static func openCamera(
        from viewController: UIViewController,
        config: PhotoPickerConfig = PhotoPickerConfig(),
        onSelected: @escaping (UIImage) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        presentYPImagePicker(
            from: viewController,
            source: .camera,
            config: config,
            onSelected: onSelected,
            onCancel: onCancel
        )
    }

    // MARK: - Private: 构建 YPConfig

    private static func buildYPConfig(source: PhotoSource, config: PhotoPickerConfig, maxCount: Int = 10) -> YPImagePickerConfiguration {
        var ypConfig = YPImagePickerConfiguration()

        // 选择来源
        switch source {
        case .library:
            ypConfig.screens = [.library]
            ypConfig.library.mediaType = .photo
            ypConfig.startOnScreen = .library
        case .camera:
            ypConfig.screens = [.photo]
            ypConfig.startOnScreen = .photo
            ypConfig.onlySquareImagesFromCamera = false
        }

        // 单选 / 多选模式配置
        if config.singlePhoto {
            ypConfig.library.maxNumberOfItems = 1
            ypConfig.library.defaultMultipleSelection = false
            if config.showsCrop {
                ypConfig.showsCrop = config.cropType
            } else {
                ypConfig.showsCrop = .none
            }
        } else {
            ypConfig.library.maxNumberOfItems = maxCount
            ypConfig.library.defaultMultipleSelection = true
            ypConfig.library.preSelectItemOnMultipleSelection = false
            ypConfig.showsCrop = .none
            ypConfig.library.isSquareByDefault = false
            ypConfig.library.minNumberOfItems = 0
        }

        // 过滤视频：mediaType + 自定义 PHFetchOptions 双重保险，确保相册只展示图片
        ypConfig.library.mediaType = .photo
        let photoOnlyOptions = PHFetchOptions()
        photoOnlyOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        photoOnlyOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        ypConfig.library.options = photoOnlyOptions

        // 关闭滤镜页面（避免 filters 为空时 collectionView selectItem 崩溃）
        ypConfig.showsPhotoFilters = false

        // 不保存裁剪后的图片到系统相册
        ypConfig.shouldSaveNewPicturesToAlbum = false

        // 不显示筛选（只选照片）
        ypConfig.filters = []

        // 隐藏相册页顶部预览区，直接展示图片网格
        ypConfig.library.hidesPreview = config.hidesPreview
        
        // 配置中文按钮文字
        ypConfig.wordings.libraryTitle = "相册"
        ypConfig.wordings.cancel = "取消"
        ypConfig.wordings.next = "下一步"
        ypConfig.wordings.trim = "裁剪"
        ypConfig.wordings.filter = "滤镜"
        ypConfig.wordings.albumsTitle = "相册"
        ypConfig.wordings.done = "完成"
        ypConfig.wordings.cameraTitle = "拍照"
        ypConfig.wordings.videoTitle = "视频"
        ypConfig.wordings.crop = "裁剪"
        ypConfig.wordings.save = "保存"
        ypConfig.wordings.warningMaxItemsLimit = "最多只能选9张图片"

        return ypConfig
    }

    // MARK: - Private: 呈现 YPImagePicker（单选）

    private static func presentYPImagePicker(
        from viewController: UIViewController,
        
        source: PhotoSource,
        config: PhotoPickerConfig,
        onSelected: @escaping (UIImage) -> Void,
        onCancel: (() -> Void)?
    ) {
        let ypConfig = buildYPConfig(source: source, config: config)
        let picker = YPImagePicker(configuration: ypConfig)

        picker.didFinishPicking { [weak picker] items, cancelled in
            guard let picker = picker else { return }

            if cancelled {
                onCancel?()
                picker.dismiss(animated: true)
                return
            }

            if let photo = items.singlePhoto {
                let image = compressImage(photo.image, config: config)
                onSelected(image)
            } else {
                onCancel?()
            }
            picker.dismiss(animated: true)
        }

        viewController.present(picker, animated: true)
    }
    
    // MARK: - Private: 呈现 YPImagePicker（多选）
    
    private static func presentYPImagePickerMultiple(
        from viewController: UIViewController,
        source: PhotoSource,
        config: PhotoPickerConfig,
        maxCount: Int,
        onSelected: @escaping ([UIImage]) -> Void,
        onCancel: (() -> Void)?
    ) {
        let ypConfig = buildYPConfig(source: source, config: config, maxCount: maxCount)
        let picker = YPImagePicker(configuration: ypConfig)

        picker.didFinishPicking { [weak picker] items, cancelled in
            guard let picker = picker else { return }

            if cancelled {
                onCancel?()
                picker.dismiss(animated: true)
                return
            }

            // 处理多张图片
            var images: [UIImage] = []
            for item in items {
                switch item {
                case .photo(let photo):
                    let compressed = compressImage(photo.image, config: config)
                    images.append(compressed)
                case .video:
                    break // 只处理图片
                }
            }
            
            if images.isEmpty {
                onCancel?()
            } else {
                onSelected(images)
            }
            
            picker.dismiss(animated: true)
        }

        viewController.present(picker, animated: true)
    }

    // MARK: - Private: 图片压缩

    private static func compressImage(_ image: UIImage, config: PhotoPickerConfig) -> UIImage {
        // 先按 maxWidth 缩放
        let scale = image.size.width > config.maxWidth
            ? config.maxWidth / image.size.width
            : 1.0

        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let resized = resizedImage else { return image }

        // 再按 compressionQuality 压缩 JPEG
        guard let data = resized.jpegData(compressionQuality: config.compressionQuality),
              let compressed = UIImage(data: data) else {
            return resized
        }

        return compressed
    }
}

// MARK: - 底部弹框控制器

final class PhotoActionSheetController: UIViewController {

    private let config: PhotoPickerConfig
    private let onLibrary: (() -> Void)?
    private let onCamera: (() -> Void)?
    private let onCancel: (() -> Void)?

    // MARK: - UI

    /// 半透明蒙层
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        return view
    }()

    /// 底部容器卡片
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16.fit
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()

    /// "从相册选择" 按钮
    private let libraryButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("从相册选择", for: .normal)
        btn.setTitleColor(AppColor.textMain, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.backgroundColor = .white
        return btn
    }()

    /// "拍照" 按钮
    private let cameraButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("拍照", for: .normal)
        btn.setTitleColor(AppColor.textMain, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.backgroundColor = .white
        return btn
    }()


    /// "取消" 按钮
    private let cancelButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("取消", for: .normal)
        btn.setTitleColor(AppColor.textSecondary, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
//        btn.backgroundColor = UIColor(hex: "#F5F5F5")
        return btn
    }()

    // MARK: - Init

    init(
        config: PhotoPickerConfig,
        onLibrary: (() -> Void)?,
        onCamera: (() -> Void)?,
        onCancel: (() -> Void)?
    ) {
        self.config = config
        self.onLibrary = onLibrary
        self.onCamera = onCamera
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        configureContent()
        addSubviews()
        setupConstraints()
        bindActions()
    }

    // MARK: - Configure

    private func configureContent() {
        libraryButton.setTitle(config.libraryText, for: .normal)
        cameraButton.setTitle(config.cameraText, for: .normal)
        cancelButton.setTitle(config.cancelText, for: .normal)
    }

    private func addSubviews() {
        view.addSubviews(overlayView, cardView)
        cardView.addSubviews(libraryButton, cameraButton, cancelButton)
    }

    // MARK: - Constraints

    private func setupConstraints() {
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        cardView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }

        libraryButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
        }

        cameraButton.snp.makeConstraints { make in
            make.top.equalTo(libraryButton.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
        }

       

        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(cameraButton.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    // MARK: - Actions

    private func bindActions() {
        libraryButton.addTarget(self, action: #selector(libraryTapped), for: .touchUpInside)
        cameraButton.addTarget(self, action: #selector(cameraTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let overlayTap = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
        overlayView.addGestureRecognizer(overlayTap)
    }

    @objc private func libraryTapped() {
        dismiss(animated: true) {
            self.onLibrary?()
        }
    }

    @objc private func cameraTapped() {
        dismiss(animated: true) {
            self.onCamera?()
        }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true) {
            self.onCancel?()
        }
    }
}
