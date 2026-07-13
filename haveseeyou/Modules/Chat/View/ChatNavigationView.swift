import UIKit
import SnapKit

final class ChatNavigationView: UIView {

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "消息"
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = AppColor.textMain
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        addSubviews(titleLabel)

        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
    }
}