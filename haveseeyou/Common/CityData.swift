//
//  CityData.swift
//  haveseeyou
//
//  城市数据模型与数据源
//  内置全国地级市以上城市，按拼音首字母分组
//

import Foundation

// MARK: - 城市模型

struct CityItem {
    /// 城市名
    let name: String
    /// 拼音首字母（大写）
    let initial: String
    /// 完整拼音（小写）
    let pinyin: String

}

// MARK: - 城市数据管理器

enum CityDataManager {

    /// 热门城市
    static let hotCities = [
        "北京", "上海", "广州", "深圳", "杭州",
        "南京", "成都", "武汉", "天津", "沈阳",
        "西安", "苏州"
    ]
    /// 热门城市
    static let hotCities2 = [
        "全国", "北京", "上海", "广州", "深圳", "杭州",
        "南京", "成都",  "天津", "沈阳",
        "西安", "苏州"
    ]

    /// 所有城市（按首字母分组，组内按拼音排序）
    static let groupedCities: [(letter: String, cities: [CityItem])] = {
        let allCities = rawCityNames.map { name -> CityItem in
            let pinyin = PinyinHelper.fullPinyin(name)
            let initial = PinyinHelper.firstLetter(name)
            return CityItem(name: name, initial: initial, pinyin: pinyin)
        }

        // 按首字母分组
        var dict = [String: [CityItem]]()
        for city in allCities {
            let key = city.initial
            dict[key, default: []].append(city)
        }

        // 排序：组内按拼音排，组间按字母排
        let letters = dict.keys.sorted()
        return letters.map { letter in
            (letter: letter, cities: dict[letter]!.sorted { $0.pinyin < $1.pinyin })
        }
    }()

    /// 所有字母索引
    static let sectionIndexTitles: [String] = {
        groupedCities.map { $0.letter }
    }()

    /// 搜索城市（支持汉字、拼音、首字母）
    static func search(_ keyword: String) -> [CityItem] {
        guard !keyword.isEmpty else { return [] }
        let lower = keyword.lowercased()

        return allCityItems.filter { city in
            city.name.contains(keyword) ||
            city.pinyin.hasPrefix(lower) ||
            city.pinyin.split(separator: " ").contains { $0.hasPrefix(lower) } ||
            city.initial.lowercased() == lower
        }
    }

    /// 所有城市平铺列表
    static let allCityItems: [CityItem] = {
        groupedCities.flatMap { $0.cities }
    }()

    // MARK: - 内置城市数据（从 citys.json 加载）

    private static let rawCityNames: [String] = {
        return Array(cityIdMap.keys)
    }()

    /// 城市名称 -> ID 映射（从 citys.json 加载）
    private static let cityIdMap: [String: Int] = {
        guard let url = Bundle.main.url(forResource: "citys", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let cityList = json["data"] as? [[String: Any]] else {
            return [String: Int]()
        }

        var map = [String: Int]()
        for province in cityList {
            // 先处理子城市（普通地级市）
            if let children = province["child"] as? [[String: Any]] {
                for child in children {
                    if let name = child["name"] as? String,
                       let id = child["id"] as? Int {
                        let cityName = name.hasSuffix("市") ? String(name.dropLast()) : name
                        map[cityName] = id
                    }
                }
            }

            // 再处理顶级行政区（只保留直辖市：北京、上海、天津、重庆）
            if let provinceName = province["name"] as? String,
               let provinceId = province["id"] as? Int {
                // 只添加直辖市，不添加省份
                let municipalities = ["北京", "上海", "天津", "重庆"]
                if municipalities.contains(provinceName) {
                    map[provinceName] = provinceId
                }
            }
        }
        return map
    }()

    /// 根据城市名称获取城市ID
    /// - Parameter cityName: 城市名称（如 "北京"、"石家庄"）
    /// - Returns: 城市ID（如 110000、130100），未找到返回 nil
    static func cityId(for cityName: String) -> Int? {
        return cityIdMap[cityName]
    }

    /// 根据城市ID获取城市名称
    /// - Parameter cityId: 城市ID（如 110000、130100）
    /// - Returns: 城市名称（如 "北京"、"石家庄"），未找到返回 nil
    static func cityName(for cityId: Int) -> String? {
        return cityIdMap.first { $0.value == cityId }?.key
    }
}
