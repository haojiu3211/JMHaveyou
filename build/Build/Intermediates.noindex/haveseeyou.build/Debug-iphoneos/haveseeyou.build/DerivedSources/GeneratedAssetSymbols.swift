import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
extension ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
extension ImageResource {

    /// The "ac_fm_1" asset catalog image resource.
    static let acFm1 = ImageResource(name: "ac_fm_1", bundle: resourceBundle)

    /// The "ac_fm_10_1" asset catalog image resource.
    static let acFm101 = ImageResource(name: "ac_fm_10_1", bundle: resourceBundle)

    /// The "ac_fm_10_2" asset catalog image resource.
    static let acFm102 = ImageResource(name: "ac_fm_10_2", bundle: resourceBundle)

    /// The "ac_fm_1_1" asset catalog image resource.
    static let acFm11 = ImageResource(name: "ac_fm_1_1", bundle: resourceBundle)

    /// The "ac_fm_1_2" asset catalog image resource.
    static let acFm12 = ImageResource(name: "ac_fm_1_2", bundle: resourceBundle)

    /// The "ac_fm_1_2 1" asset catalog image resource.
    static let acFm121 = ImageResource(name: "ac_fm_1_2 1", bundle: resourceBundle)

    /// The "ac_fm_2_1" asset catalog image resource.
    static let acFm21 = ImageResource(name: "ac_fm_2_1", bundle: resourceBundle)

    /// The "ac_fm_3_1" asset catalog image resource.
    static let acFm31 = ImageResource(name: "ac_fm_3_1", bundle: resourceBundle)

    /// The "ac_fm_4_1" asset catalog image resource.
    static let acFm41 = ImageResource(name: "ac_fm_4_1", bundle: resourceBundle)

    /// The "ac_fm_5_1" asset catalog image resource.
    static let acFm51 = ImageResource(name: "ac_fm_5_1", bundle: resourceBundle)

    /// The "ac_fm_6_1" asset catalog image resource.
    static let acFm61 = ImageResource(name: "ac_fm_6_1", bundle: resourceBundle)

    /// The "ac_fm_7_1" asset catalog image resource.
    static let acFm71 = ImageResource(name: "ac_fm_7_1", bundle: resourceBundle)

    /// The "ac_fm_8_1" asset catalog image resource.
    static let acFm81 = ImageResource(name: "ac_fm_8_1", bundle: resourceBundle)

    /// The "ac_fm_9_1" asset catalog image resource.
    static let acFm91 = ImageResource(name: "ac_fm_9_1", bundle: resourceBundle)

    /// The "app_back" asset catalog image resource.
    static let appBack = ImageResource(name: "app_back", bundle: resourceBundle)

    /// The "app_right" asset catalog image resource.
    static let appRight = ImageResource(name: "app_right", bundle: resourceBundle)

    /// The "app_splash" asset catalog image resource.
    static let appSplash = ImageResource(name: "app_splash", bundle: resourceBundle)

    /// The "group_bg" asset catalog image resource.
    static let groupBg = ImageResource(name: "group_bg", bundle: resourceBundle)

    /// The "group_rule" asset catalog image resource.
    static let groupRule = ImageResource(name: "group_rule", bundle: resourceBundle)

    /// The "login_next" asset catalog image resource.
    static let loginNext = ImageResource(name: "login_next", bundle: resourceBundle)

    /// The "sy_active_icon" asset catalog image resource.
    static let syActiveIcon = ImageResource(name: "sy_active_icon", bundle: resourceBundle)

    /// The "sy_active_ing" asset catalog image resource.
    static let syActiveIng = ImageResource(name: "sy_active_ing", bundle: resourceBundle)

    /// The "sy_active_local" asset catalog image resource.
    static let syActiveLocal = ImageResource(name: "sy_active_local", bundle: resourceBundle)

    /// The "sy_active_search" asset catalog image resource.
    static let syActiveSearch = ImageResource(name: "sy_active_search", bundle: resourceBundle)

    /// The "sy_active_triangle" asset catalog image resource.
    static let syActiveTriangle = ImageResource(name: "sy_active_triangle", bundle: resourceBundle)

    /// The "sy_active_wait" asset catalog image resource.
    static let syActiveWait = ImageResource(name: "sy_active_wait", bundle: resourceBundle)

    /// The "sy_banner_1" asset catalog image resource.
    static let syBanner1 = ImageResource(name: "sy_banner_1", bundle: resourceBundle)

    /// The "sy_banner_2" asset catalog image resource.
    static let syBanner2 = ImageResource(name: "sy_banner_2", bundle: resourceBundle)

    /// The "sy_banner_3" asset catalog image resource.
    static let syBanner3 = ImageResource(name: "sy_banner_3", bundle: resourceBundle)

    /// The "sy_camera" asset catalog image resource.
    static let syCamera = ImageResource(name: "sy_camera", bundle: resourceBundle)

    /// The "sy_city_search" asset catalog image resource.
    static let syCitySearch = ImageResource(name: "sy_city_search", bundle: resourceBundle)

    /// The "sy_detai_ing" asset catalog image resource.
    static let syDetaiIng = ImageResource(name: "sy_detai_ing", bundle: resourceBundle)

    /// The "sy_detai_local" asset catalog image resource.
    static let syDetaiLocal = ImageResource(name: "sy_detai_local", bundle: resourceBundle)

    /// The "sy_detai_money" asset catalog image resource.
    static let syDetaiMoney = ImageResource(name: "sy_detai_money", bundle: resourceBundle)

    /// The "sy_detai_time" asset catalog image resource.
    static let syDetaiTime = ImageResource(name: "sy_detai_time", bundle: resourceBundle)

    /// The "sy_detail_female" asset catalog image resource.
    static let syDetailFemale = ImageResource(name: "sy_detail_female", bundle: resourceBundle)

    /// The "sy_detail_male" asset catalog image resource.
    static let syDetailMale = ImageResource(name: "sy_detail_male", bundle: resourceBundle)

    /// The "sy_detail_more" asset catalog image resource.
    static let syDetailMore = ImageResource(name: "sy_detail_more", bundle: resourceBundle)

    /// The "sy_head_1" asset catalog image resource.
    static let syHead1 = ImageResource(name: "sy_head_1", bundle: resourceBundle)

    /// The "sy_head_10@2x" asset catalog image resource.
    static let syHead102X = ImageResource(name: "sy_head_10@2x", bundle: resourceBundle)

    /// The "sy_head_2" asset catalog image resource.
    static let syHead2 = ImageResource(name: "sy_head_2", bundle: resourceBundle)

    /// The "sy_head_3" asset catalog image resource.
    static let syHead3 = ImageResource(name: "sy_head_3", bundle: resourceBundle)

    /// The "sy_head_4" asset catalog image resource.
    static let syHead4 = ImageResource(name: "sy_head_4", bundle: resourceBundle)

    /// The "sy_head_5" asset catalog image resource.
    static let syHead5 = ImageResource(name: "sy_head_5", bundle: resourceBundle)

    /// The "sy_head_6" asset catalog image resource.
    static let syHead6 = ImageResource(name: "sy_head_6", bundle: resourceBundle)

    /// The "sy_head_7" asset catalog image resource.
    static let syHead7 = ImageResource(name: "sy_head_7", bundle: resourceBundle)

    /// The "sy_head_8" asset catalog image resource.
    static let syHead8 = ImageResource(name: "sy_head_8", bundle: resourceBundle)

    /// The "sy_head_9" asset catalog image resource.
    static let syHead9 = ImageResource(name: "sy_head_9", bundle: resourceBundle)

    /// The "sy_login_female" asset catalog image resource.
    static let syLoginFemale = ImageResource(name: "sy_login_female", bundle: resourceBundle)

    /// The "sy_login_female_sel" asset catalog image resource.
    static let syLoginFemaleSel = ImageResource(name: "sy_login_female_sel", bundle: resourceBundle)

    /// The "sy_login_male" asset catalog image resource.
    static let syLoginMale = ImageResource(name: "sy_login_male", bundle: resourceBundle)

    /// The "sy_login_male_sel" asset catalog image resource.
    static let syLoginMaleSel = ImageResource(name: "sy_login_male_sel", bundle: resourceBundle)

    /// The "sy_login_select" asset catalog image resource.
    static let syLoginSelect = ImageResource(name: "sy_login_select", bundle: resourceBundle)

    /// The "sy_login_sologen" asset catalog image resource.
    static let syLoginSologen = ImageResource(name: "sy_login_sologen", bundle: resourceBundle)

    /// The "sy_login_unselect" asset catalog image resource.
    static let syLoginUnselect = ImageResource(name: "sy_login_unselect", bundle: resourceBundle)

    /// The "sy_splash" asset catalog image resource.
    static let sySplash = ImageResource(name: "sy_splash", bundle: resourceBundle)

    /// The "tab_activity" asset catalog image resource.
    static let tabActivity = ImageResource(name: "tab_activity", bundle: resourceBundle)

    /// The "tab_activity_sel" asset catalog image resource.
    static let tabActivitySel = ImageResource(name: "tab_activity_sel", bundle: resourceBundle)

    /// The "tab_dazi" asset catalog image resource.
    static let tabDazi = ImageResource(name: "tab_dazi", bundle: resourceBundle)

    /// The "tab_dazi_sel" asset catalog image resource.
    static let tabDaziSel = ImageResource(name: "tab_dazi_sel", bundle: resourceBundle)

    /// The "tab_me" asset catalog image resource.
    static let tabMe = ImageResource(name: "tab_me", bundle: resourceBundle)

    /// The "tab_me_sel" asset catalog image resource.
    static let tabMeSel = ImageResource(name: "tab_me_sel", bundle: resourceBundle)

    /// The "tab_publish" asset catalog image resource.
    static let tabPublish = ImageResource(name: "tab_publish", bundle: resourceBundle)

    /// The "tab_publish_sel" asset catalog image resource.
    static let tabPublishSel = ImageResource(name: "tab_publish_sel", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "ac_fm_1" asset catalog image.
    static var acFm1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .acFm1)
#else
        .init()
#endif
    }

    /// The "ac_fm_10_1" asset catalog image.
    static var acFm101: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .acFm101)
#else
        .init()
#endif
    }

    /// The "ac_fm_10_2" asset catalog image.
    static var acFm102: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .acFm102)
#else
        .init()
#endif
    }

    /// The "ac_fm_1_1" asset catalog image.
    static var acFm11: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .acFm11)
#else
        .init()
#endif
    }

    /// The "ac_fm_1_2" asset catalog image.
    static var acFm12: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .acFm12)
#else
        .init()
#endif
    }

    /// The "ac_fm_1_2 1" asset catalog image.
    static var acFm121: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .acFm121)
#else
        .init()
#endif
    }

    /// The "ac_fm_2_1" asset catalog image.
    static var acFm21: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .acFm21)
#else
        .init()
#endif
    }

    /// The "ac_fm_3_1" asset catalog image.
    static var acFm31: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .acFm31)
#else
        .init()
#endif
    }

    /// The "ac_fm_4_1" asset catalog image.
    static var acFm41: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .acFm41)
#else
        .init()
#endif
    }

    /// The "ac_fm_5_1" asset catalog image.
    static var acFm51: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .acFm51)
#else
        .init()
#endif
    }

    /// The "ac_fm_6_1" asset catalog image.
    static var acFm61: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .acFm61)
#else
        .init()
#endif
    }

    /// The "ac_fm_7_1" asset catalog image.
    static var acFm71: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .acFm71)
#else
        .init()
#endif
    }

    /// The "ac_fm_8_1" asset catalog image.
    static var acFm81: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .acFm81)
#else
        .init()
#endif
    }

    /// The "ac_fm_9_1" asset catalog image.
    static var acFm91: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .acFm91)
#else
        .init()
#endif
    }

    /// The "app_back" asset catalog image.
    static var appBack: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appBack)
#else
        .init()
#endif
    }

    /// The "app_right" asset catalog image.
    static var appRight: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appRight)
#else
        .init()
#endif
    }

    /// The "app_splash" asset catalog image.
    static var appSplash: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appSplash)
#else
        .init()
#endif
    }

    /// The "group_bg" asset catalog image.
    static var groupBg: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .groupBg)
#else
        .init()
#endif
    }

    /// The "group_rule" asset catalog image.
    static var groupRule: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .groupRule)
#else
        .init()
#endif
    }

    /// The "login_next" asset catalog image.
    static var loginNext: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .loginNext)
#else
        .init()
#endif
    }

    /// The "sy_active_icon" asset catalog image.
    static var syActiveIcon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syActiveIcon)
#else
        .init()
#endif
    }

    /// The "sy_active_ing" asset catalog image.
    static var syActiveIng: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syActiveIng)
#else
        .init()
#endif
    }

    /// The "sy_active_local" asset catalog image.
    static var syActiveLocal: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syActiveLocal)
#else
        .init()
#endif
    }

    /// The "sy_active_search" asset catalog image.
    static var syActiveSearch: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syActiveSearch)
#else
        .init()
#endif
    }

    /// The "sy_active_triangle" asset catalog image.
    static var syActiveTriangle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syActiveTriangle)
#else
        .init()
#endif
    }

    /// The "sy_active_wait" asset catalog image.
    static var syActiveWait: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syActiveWait)
#else
        .init()
#endif
    }

    /// The "sy_banner_1" asset catalog image.
    static var syBanner1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syBanner1)
#else
        .init()
#endif
    }

    /// The "sy_banner_2" asset catalog image.
    static var syBanner2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syBanner2)
#else
        .init()
#endif
    }

    /// The "sy_banner_3" asset catalog image.
    static var syBanner3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syBanner3)
#else
        .init()
#endif
    }

    /// The "sy_camera" asset catalog image.
    static var syCamera: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syCamera)
#else
        .init()
#endif
    }

    /// The "sy_city_search" asset catalog image.
    static var syCitySearch: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syCitySearch)
#else
        .init()
#endif
    }

    /// The "sy_detai_ing" asset catalog image.
    static var syDetaiIng: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syDetaiIng)
#else
        .init()
#endif
    }

    /// The "sy_detai_local" asset catalog image.
    static var syDetaiLocal: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syDetaiLocal)
#else
        .init()
#endif
    }

    /// The "sy_detai_money" asset catalog image.
    static var syDetaiMoney: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syDetaiMoney)
#else
        .init()
#endif
    }

    /// The "sy_detai_time" asset catalog image.
    static var syDetaiTime: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syDetaiTime)
#else
        .init()
#endif
    }

    /// The "sy_detail_female" asset catalog image.
    static var syDetailFemale: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syDetailFemale)
#else
        .init()
#endif
    }

    /// The "sy_detail_male" asset catalog image.
    static var syDetailMale: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syDetailMale)
#else
        .init()
#endif
    }

    /// The "sy_detail_more" asset catalog image.
    static var syDetailMore: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syDetailMore)
#else
        .init()
#endif
    }

    /// The "sy_head_1" asset catalog image.
    static var syHead1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syHead1)
#else
        .init()
#endif
    }

    /// The "sy_head_10@2x" asset catalog image.
    static var syHead102X: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syHead102X)
#else
        .init()
#endif
    }

    /// The "sy_head_2" asset catalog image.
    static var syHead2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syHead2)
#else
        .init()
#endif
    }

    /// The "sy_head_3" asset catalog image.
    static var syHead3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syHead3)
#else
        .init()
#endif
    }

    /// The "sy_head_4" asset catalog image.
    static var syHead4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syHead4)
#else
        .init()
#endif
    }

    /// The "sy_head_5" asset catalog image.
    static var syHead5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syHead5)
#else
        .init()
#endif
    }

    /// The "sy_head_6" asset catalog image.
    static var syHead6: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syHead6)
#else
        .init()
#endif
    }

    /// The "sy_head_7" asset catalog image.
    static var syHead7: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syHead7)
#else
        .init()
#endif
    }

    /// The "sy_head_8" asset catalog image.
    static var syHead8: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syHead8)
#else
        .init()
#endif
    }

    /// The "sy_head_9" asset catalog image.
    static var syHead9: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syHead9)
#else
        .init()
#endif
    }

    /// The "sy_login_female" asset catalog image.
    static var syLoginFemale: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syLoginFemale)
#else
        .init()
#endif
    }

    /// The "sy_login_female_sel" asset catalog image.
    static var syLoginFemaleSel: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syLoginFemaleSel)
#else
        .init()
#endif
    }

    /// The "sy_login_male" asset catalog image.
    static var syLoginMale: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syLoginMale)
#else
        .init()
#endif
    }

    /// The "sy_login_male_sel" asset catalog image.
    static var syLoginMaleSel: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syLoginMaleSel)
#else
        .init()
#endif
    }

    /// The "sy_login_select" asset catalog image.
    static var syLoginSelect: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syLoginSelect)
#else
        .init()
#endif
    }

    /// The "sy_login_sologen" asset catalog image.
    static var syLoginSologen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syLoginSologen)
#else
        .init()
#endif
    }

    /// The "sy_login_unselect" asset catalog image.
    static var syLoginUnselect: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .syLoginUnselect)
#else
        .init()
#endif
    }

    /// The "sy_splash" asset catalog image.
    static var sySplash: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .sySplash)
#else
        .init()
#endif
    }

    /// The "tab_activity" asset catalog image.
    static var tabActivity: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tabActivity)
#else
        .init()
#endif
    }

    /// The "tab_activity_sel" asset catalog image.
    static var tabActivitySel: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tabActivitySel)
#else
        .init()
#endif
    }

    /// The "tab_dazi" asset catalog image.
    static var tabDazi: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tabDazi)
#else
        .init()
#endif
    }

    /// The "tab_dazi_sel" asset catalog image.
    static var tabDaziSel: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tabDaziSel)
#else
        .init()
#endif
    }

    /// The "tab_me" asset catalog image.
    static var tabMe: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tabMe)
#else
        .init()
#endif
    }

    /// The "tab_me_sel" asset catalog image.
    static var tabMeSel: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tabMeSel)
#else
        .init()
#endif
    }

    /// The "tab_publish" asset catalog image.
    static var tabPublish: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tabPublish)
#else
        .init()
#endif
    }

    /// The "tab_publish_sel" asset catalog image.
    static var tabPublishSel: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tabPublishSel)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "ac_fm_1" asset catalog image.
    static var acFm1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .acFm1)
#else
        .init()
#endif
    }

    /// The "ac_fm_10_1" asset catalog image.
    static var acFm101: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .acFm101)
#else
        .init()
#endif
    }

    /// The "ac_fm_10_2" asset catalog image.
    static var acFm102: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .acFm102)
#else
        .init()
#endif
    }

    /// The "ac_fm_1_1" asset catalog image.
    static var acFm11: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .acFm11)
#else
        .init()
#endif
    }

    /// The "ac_fm_1_2" asset catalog image.
    static var acFm12: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .acFm12)
#else
        .init()
#endif
    }

    /// The "ac_fm_1_2 1" asset catalog image.
    static var acFm121: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .acFm121)
#else
        .init()
#endif
    }

    /// The "ac_fm_2_1" asset catalog image.
    static var acFm21: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .acFm21)
#else
        .init()
#endif
    }

    /// The "ac_fm_3_1" asset catalog image.
    static var acFm31: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .acFm31)
#else
        .init()
#endif
    }

    /// The "ac_fm_4_1" asset catalog image.
    static var acFm41: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .acFm41)
#else
        .init()
#endif
    }

    /// The "ac_fm_5_1" asset catalog image.
    static var acFm51: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .acFm51)
#else
        .init()
#endif
    }

    /// The "ac_fm_6_1" asset catalog image.
    static var acFm61: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .acFm61)
#else
        .init()
#endif
    }

    /// The "ac_fm_7_1" asset catalog image.
    static var acFm71: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .acFm71)
#else
        .init()
#endif
    }

    /// The "ac_fm_8_1" asset catalog image.
    static var acFm81: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .acFm81)
#else
        .init()
#endif
    }

    /// The "ac_fm_9_1" asset catalog image.
    static var acFm91: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .acFm91)
#else
        .init()
#endif
    }

    /// The "app_back" asset catalog image.
    static var appBack: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .appBack)
#else
        .init()
#endif
    }

    /// The "app_right" asset catalog image.
    static var appRight: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .appRight)
#else
        .init()
#endif
    }

    /// The "app_splash" asset catalog image.
    static var appSplash: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .appSplash)
#else
        .init()
#endif
    }

    /// The "group_bg" asset catalog image.
    static var groupBg: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .groupBg)
#else
        .init()
#endif
    }

    /// The "group_rule" asset catalog image.
    static var groupRule: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .groupRule)
#else
        .init()
#endif
    }

    /// The "login_next" asset catalog image.
    static var loginNext: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .loginNext)
#else
        .init()
#endif
    }

    /// The "sy_active_icon" asset catalog image.
    static var syActiveIcon: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syActiveIcon)
#else
        .init()
#endif
    }

    /// The "sy_active_ing" asset catalog image.
    static var syActiveIng: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syActiveIng)
#else
        .init()
#endif
    }

    /// The "sy_active_local" asset catalog image.
    static var syActiveLocal: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syActiveLocal)
#else
        .init()
#endif
    }

    /// The "sy_active_search" asset catalog image.
    static var syActiveSearch: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syActiveSearch)
#else
        .init()
#endif
    }

    /// The "sy_active_triangle" asset catalog image.
    static var syActiveTriangle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syActiveTriangle)
#else
        .init()
#endif
    }

    /// The "sy_active_wait" asset catalog image.
    static var syActiveWait: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syActiveWait)
#else
        .init()
#endif
    }

    /// The "sy_banner_1" asset catalog image.
    static var syBanner1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syBanner1)
#else
        .init()
#endif
    }

    /// The "sy_banner_2" asset catalog image.
    static var syBanner2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syBanner2)
#else
        .init()
#endif
    }

    /// The "sy_banner_3" asset catalog image.
    static var syBanner3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syBanner3)
#else
        .init()
#endif
    }

    /// The "sy_camera" asset catalog image.
    static var syCamera: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syCamera)
#else
        .init()
#endif
    }

    /// The "sy_city_search" asset catalog image.
    static var syCitySearch: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syCitySearch)
#else
        .init()
#endif
    }

    /// The "sy_detai_ing" asset catalog image.
    static var syDetaiIng: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syDetaiIng)
#else
        .init()
#endif
    }

    /// The "sy_detai_local" asset catalog image.
    static var syDetaiLocal: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syDetaiLocal)
#else
        .init()
#endif
    }

    /// The "sy_detai_money" asset catalog image.
    static var syDetaiMoney: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syDetaiMoney)
#else
        .init()
#endif
    }

    /// The "sy_detai_time" asset catalog image.
    static var syDetaiTime: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syDetaiTime)
#else
        .init()
#endif
    }

    /// The "sy_detail_female" asset catalog image.
    static var syDetailFemale: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syDetailFemale)
#else
        .init()
#endif
    }

    /// The "sy_detail_male" asset catalog image.
    static var syDetailMale: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syDetailMale)
#else
        .init()
#endif
    }

    /// The "sy_detail_more" asset catalog image.
    static var syDetailMore: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syDetailMore)
#else
        .init()
#endif
    }

    /// The "sy_head_1" asset catalog image.
    static var syHead1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syHead1)
#else
        .init()
#endif
    }

    /// The "sy_head_10@2x" asset catalog image.
    static var syHead102X: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syHead102X)
#else
        .init()
#endif
    }

    /// The "sy_head_2" asset catalog image.
    static var syHead2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syHead2)
#else
        .init()
#endif
    }

    /// The "sy_head_3" asset catalog image.
    static var syHead3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syHead3)
#else
        .init()
#endif
    }

    /// The "sy_head_4" asset catalog image.
    static var syHead4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syHead4)
#else
        .init()
#endif
    }

    /// The "sy_head_5" asset catalog image.
    static var syHead5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syHead5)
#else
        .init()
#endif
    }

    /// The "sy_head_6" asset catalog image.
    static var syHead6: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syHead6)
#else
        .init()
#endif
    }

    /// The "sy_head_7" asset catalog image.
    static var syHead7: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syHead7)
#else
        .init()
#endif
    }

    /// The "sy_head_8" asset catalog image.
    static var syHead8: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syHead8)
#else
        .init()
#endif
    }

    /// The "sy_head_9" asset catalog image.
    static var syHead9: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syHead9)
#else
        .init()
#endif
    }

    /// The "sy_login_female" asset catalog image.
    static var syLoginFemale: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syLoginFemale)
#else
        .init()
#endif
    }

    /// The "sy_login_female_sel" asset catalog image.
    static var syLoginFemaleSel: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syLoginFemaleSel)
#else
        .init()
#endif
    }

    /// The "sy_login_male" asset catalog image.
    static var syLoginMale: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syLoginMale)
#else
        .init()
#endif
    }

    /// The "sy_login_male_sel" asset catalog image.
    static var syLoginMaleSel: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syLoginMaleSel)
#else
        .init()
#endif
    }

    /// The "sy_login_select" asset catalog image.
    static var syLoginSelect: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syLoginSelect)
#else
        .init()
#endif
    }

    /// The "sy_login_sologen" asset catalog image.
    static var syLoginSologen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syLoginSologen)
#else
        .init()
#endif
    }

    /// The "sy_login_unselect" asset catalog image.
    static var syLoginUnselect: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .syLoginUnselect)
#else
        .init()
#endif
    }

    /// The "sy_splash" asset catalog image.
    static var sySplash: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .sySplash)
#else
        .init()
#endif
    }

    /// The "tab_activity" asset catalog image.
    static var tabActivity: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tabActivity)
#else
        .init()
#endif
    }

    /// The "tab_activity_sel" asset catalog image.
    static var tabActivitySel: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tabActivitySel)
#else
        .init()
#endif
    }

    /// The "tab_dazi" asset catalog image.
    static var tabDazi: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tabDazi)
#else
        .init()
#endif
    }

    /// The "tab_dazi_sel" asset catalog image.
    static var tabDaziSel: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tabDaziSel)
#else
        .init()
#endif
    }

    /// The "tab_me" asset catalog image.
    static var tabMe: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tabMe)
#else
        .init()
#endif
    }

    /// The "tab_me_sel" asset catalog image.
    static var tabMeSel: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tabMeSel)
#else
        .init()
#endif
    }

    /// The "tab_publish" asset catalog image.
    static var tabPublish: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tabPublish)
#else
        .init()
#endif
    }

    /// The "tab_publish_sel" asset catalog image.
    static var tabPublishSel: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tabPublishSel)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
@available(watchOS, unavailable)
extension ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
@available(watchOS, unavailable)
extension ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

// MARK: - Backwards Deployment Support -

/// A color resource.
struct ColorResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog color resource name.
    fileprivate let name: Swift.String

    /// An asset catalog color resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize a `ColorResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

/// An image resource.
struct ImageResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog image resource name.
    fileprivate let name: Swift.String

    /// An asset catalog image resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize an `ImageResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// Initialize a `NSColor` with a color resource.
    convenience init(resource: ColorResource) {
        self.init(named: NSColor.Name(resource.name), bundle: resource.bundle)!
    }

}

protocol _ACResourceInitProtocol {}
extension AppKit.NSImage: _ACResourceInitProtocol {}

@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension _ACResourceInitProtocol {

    /// Initialize a `NSImage` with an image resource.
    init(resource: ImageResource) {
        self = resource.bundle.image(forResource: NSImage.Name(resource.name))! as! Self
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// Initialize a `UIColor` with a color resource.
    convenience init(resource: ColorResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}

@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// Initialize a `UIImage` with an image resource.
    convenience init(resource: ImageResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    /// Initialize a `Color` with a color resource.
    init(_ resource: ColorResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Image {

    /// Initialize an `Image` with an image resource.
    init(_ resource: ImageResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}
#endif