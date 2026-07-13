//
//  profileHeaderView.swift
//  haveseeyou
//
//  Created by admin on 2026/6/9.
//

import UIKit
import SnapKit

class ProfileHeaderView: UIView {

    let titles = ["粉丝", "关注", "足迹", "访客"]
    private var numLabels: [UILabel] = []
    
    var onItemTapped: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        let mainStackView = UIStackView()
        mainStackView.axis = .horizontal
        mainStackView.distribution = .fillEqually
        mainStackView.alignment = .center
        mainStackView.spacing = 0

        self.addSubview(mainStackView)

        for i in 0..<titles.count {
            let itemStack = createItemStack(tag: i, title: titles[i])
            mainStackView.addArrangedSubview(itemStack)
        }

        mainStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func createItemStack(tag: Int, title: String) -> UIStackView {
        let numLabel = UILabel()
        numLabel.text = "0"
        numLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        numLabel.textColor = .black
        numLabel.textAlignment = .center
        numLabels.append(numLabel)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textColor = .gray
        titleLabel.textAlignment = .center

        let vStack = UIStackView(arrangedSubviews: [numLabel, titleLabel])
        vStack.axis = .vertical
        vStack.alignment = .center
        vStack.spacing = 4
        vStack.distribution = .equalCentering
        
        vStack.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleItemTap(_:)))
        vStack.addGestureRecognizer(tapGesture)
        vStack.tag = tag
        
        return vStack
    }
    
    func updateNumbers(_ numbers: [Int]) {
        for (index, number) in numbers.enumerated() {
            if index < numLabels.count {
                numLabels[index].text = "\(number)"
            }
        }
    }
    
    @objc private func handleItemTap(_ gesture: UITapGestureRecognizer) {
        if let tappedView = gesture.view {
            onItemTapped?(tappedView.tag)
        }
    }
}