//
//  SyLineView.swift
//  haveseeyou
//
//  Created by admin on 2026/5/26.
//

import UIKit

final class SyLineView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupUI() {

        backgroundColor = UIColor(hex: "#FFEAEAEA")
    }
}
final class SyRightImageView: UIImageView {
    
    init() {
        super.init(image: UIImage(named: "app_right"))
        
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
}
