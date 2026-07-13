//
//  MemberBottom.swift
//  haveseeyou
//
//  Created by admin开发测试 on 2026/6/12.
//

import UIKit
import SnapKit

class MemberBottom: UIView {

    // 正常模式数据
    private let normalDataSource: [PrivilegeItem] = [
        PrivilegeItem(icon: "vip_jiawx", title: "社媒账号解锁", subtitle: "每日女10次/男10次"),
        PrivilegeItem(icon: "vip_quite", title: "活动优先沟通", subtitle: "每日女20次/男10次"),
        PrivilegeItem(icon: "vip_activiti_fiflter", title: "活动类型筛选", subtitle: "无限"),
        PrivilegeItem(icon: "vip_friend_fiflter", title: "搭子类型筛选", subtitle: "无限"),
        PrivilegeItem(icon: "vip_eye_no", title: "解锁隐身模式", subtitle: "私密访问主页不让TA知道"),
        PrivilegeItem(icon: "vip_good", title: "优先推荐", subtitle: "发布活动优先推荐"),
        PrivilegeItem(icon: "vip_sf", title: "专属身份标识", subtitle: "vip专属身份标识"),
        PrivilegeItem(icon: "vip_kefu", title: "专属客服", subtitle: "7*24小时为您服务"),
        PrivilegeItem(icon: "vip_fensi", title: "解锁粉丝、关注", subtitle: "好友、访客") // 最后一个单独一行
    ]
    
    // 审核模式数据
    private let auditDataSource: [PrivilegeItem] = [
        PrivilegeItem(icon: "vip_jiawx", title: "社媒账号解锁", subtitle: "每日女10次/男10次"),
        PrivilegeItem(icon: "vip_activiti_fiflter", title: "活动类型筛选", subtitle: "无限"),
        PrivilegeItem(icon: "vip_friend_fiflter", title: "搭子类型筛选", subtitle: "无限"),
        PrivilegeItem(icon: "vip_eye_no", title: "解锁隐身模式", subtitle: "私密访问主页不让TA知道"),
        PrivilegeItem(icon: "vip_good", title: "优先推荐", subtitle: "发布活动优先推荐"),
        PrivilegeItem(icon: "vip_sf", title: "专属身份标识", subtitle: "vip专属身份标识"),
        PrivilegeItem(icon: "vip_kefu", title: "专属客服", subtitle: "7*24小时为您服务"),
        PrivilegeItem(icon: "vip_fensi", title: "解锁粉丝、关注", subtitle: "好友、访客") // 最后一个单独一行
    ]
    
    // 当前使用的数据来源
    private var dataSource: [PrivilegeItem] {
        if AuditConfigManager.shared.isAudit {
            return auditDataSource
        } else {
            return normalDataSource
        }
    }

    
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "member_bottom_bg")
        return iv
    }()
    
    private let titleImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "member_bottom_list_title")
        return iv
    }()

    lazy var collectionView: UICollectionView = {
        // 根据屏幕宽度计算缩放比例
        let screenWidth = UIScreen.main.bounds.width
        let baseWidth: CGFloat = 375.0 // iPhone 12/13/14 作为基准
        let scale = min(screenWidth / baseWidth, 1.2) // 最大放大到 1.2 倍
        
        // 计算自适应高度（以96为基准）
        let cellHeight = 96.0 * scale
        
        // 1. 定义 Item：宽度由 group 平均分配，使用绝对高度
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(cellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        // 2. 定义 Group（一行 2 个），用 count: 2，避免小屏 .fractionalWidth(0.5) 在窄屏被压成 1 列
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(cellHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                      subitem: item,
                                                      count: 2)
        group.interItemSpacing = .fixed(12 * scale) // 列间距自适应

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12 * scale      // 行间距自适应
        section.contentInsets = NSDirectionalEdgeInsets(top: 10 * scale, leading: 16 * scale, bottom: 10 * scale, trailing: 16 * scale)

        let layout = UICollectionViewCompositionalLayout(section: section)

        // ... 后续初始化代码保持不变 ...
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.isScrollEnabled = false
        cv.register(MemberBottomCell.self, forCellWithReuseIdentifier: "MemberBottomCell")
        cv.delegate = self
        cv.dataSource = self

        return cv
    }()
    
    
    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
       
    }
    
    /// 刷新特权列表（审核状态变化时调用）
    func refresh() {
        collectionView.reloadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup UI

    private func setupUI() {
        self.backgroundColor = UIColor.clear//UIColor(hex: "#18181A")
        addSubviews(backgroundImageView,
                    titleImageView,
                    collectionView)
        
        backgroundImageView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        
        titleImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleImageView.snp.bottom).offset(8)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
}

extension MemberBottom: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MemberBottomCell", for: indexPath) as? MemberBottomCell else {
            return UICollectionViewCell()
        }
        let item = dataSource[indexPath.item]
        cell.configure(with: item)
        return cell
    }
}
