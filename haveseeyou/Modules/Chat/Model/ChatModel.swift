//
//  ChatModel.swift
//  haveseeyou
//
//  Created by admin on 2026/6/10.
//

import UIKit


    /// Banner 模型
struct ChatBannerModel: Codable, Hashable {
    let title: String
    let image: String
    let linkType: Int
    let linkUrl: String?

    enum CodingKeys: String, CodingKey {
        case title
        case image
        case linkType = "link_type"
        case linkUrl = "link_url"
    }
}


//测试数据
extension ChatBannerModel {
    static let mock: [ChatBannerModel] = [
        ChatBannerModel(title: "", image: "sy_banner_2", linkType: 0, linkUrl: webUrlBanner2),
        ChatBannerModel(title: "", image: "sy_banner_3", linkType: 0, linkUrl: webUrlBanner3)
    ]
}
