//
//  OccupationPickerViewController.swift
//  haveseeyou
//
//  职业选择控制器
//

import UIKit
import SnapKit

final class OccupationPickerViewController: BaseViewController {
    
    // MARK: - Callbacks
    
    var onOccupationSelected: ((String) -> Void)?
    
    // MARK: - Properties
    
    private let isMale: Bool
    private let initialOccupation: String?
    
    // 女性职业选项
    private let femaleOccupations = ["主播", "网红", "白领", "模特", "美容师", "个体", "学生", "游戏主播", "舞蹈", "其他"]
    
    // 男性职业选项
    private let maleOccupations = ["程序员", "摄影师", "健身教练", "设计师", "销售经理", "白领", "管理者", "自由职业", "技术宅", "CEO", "专业玩家", "壕", "金融投资", "个体", "其他"]
    
    private var selectedIndexPath: IndexPath?
    
    // MARK: - UI Components
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.showsVerticalScrollIndicator = false
        cv.register(OccupationCell.self, forCellWithReuseIdentifier: OccupationCell.identifier)
        return cv
    }()
    
    private let saveButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = .black
        btn.setTitle("保存", for: .normal)
        // 渐变文字
        let gradientColor = UIColor.gradientTextColor(
            size: CGSize(width: 120, height: 30),
            colors: [
                UIColor(hex: "#A2EF4D"),
                UIColor(hex: "#F7FFFF"),
                UIColor(hex: "#F7FFFF")
            ]
        )
        btn.setTitleColor(gradientColor, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.layer.cornerRadius = 24
        btn.clipsToBounds = true
        return btn
    }()
    
    // MARK: - Init
    
    init(isMale: Bool, initialOccupation: String? = nil) {
        self.isMale = isMale
        self.initialOccupation = initialOccupation
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func setupUI() {
        view.backgroundColor = .white
        title = "我的职业"
        
        view.addSubviews(collectionView, saveButton)
        
        collectionView.snp.makeConstraints { make in
            make.top.left.right.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.bottom.equalTo(saveButton.snp.top).offset(-32)
        }
        
        saveButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(48)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
        }
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        
        setupInitialSelection()
    }
    
    private func setupInitialSelection() {
        guard let occupation = initialOccupation, !occupation.isEmpty else { return }
        let occupations = isMale ? maleOccupations : femaleOccupations
        if let index = occupations.firstIndex(of: occupation) {
            selectedIndexPath = IndexPath(item: index, section: 0)
            collectionView.reloadData()
        }
    }
    
    // MARK: - Actions
    
    @objc private func saveTapped() {
        guard let indexPath = selectedIndexPath else {
            showToast("请选择职业")
            return
        }
        let occupations = isMale ? maleOccupations : femaleOccupations
        let occupation = occupations[indexPath.item]
        onOccupationSelected?(occupation)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UICollectionViewDelegate & DataSource

extension OccupationPickerViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isMale ? maleOccupations.count : femaleOccupations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OccupationCell.identifier, for: indexPath) as! OccupationCell
        let occupations = isMale ? maleOccupations : femaleOccupations
        let isSelected = selectedIndexPath == indexPath
        cell.configure(title: occupations[indexPath.item], isSelected: isSelected)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 24) / 3
        return CGSize(width: width, height: 44)
    }
}

// MARK: - OccupationCell

final class OccupationCell: UICollectionViewCell {
    
    static let identifier = "OccupationCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 1
        
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        if isSelected {
            contentView.backgroundColor = UIColor(hex: "#FFA2EF4D")
            contentView.layer.borderColor = UIColor.clear.cgColor
            titleLabel.textColor = AppColor.textMain
        } else {
            contentView.backgroundColor = .white
            contentView.layer.borderColor = UIColor(hex: "#E0E0E0").cgColor
            titleLabel.textColor = UIColor(hex: "#888888")
        }
    }
}
