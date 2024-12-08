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

    /// The "btn_color" asset catalog color resource.
    static let btn = ColorResource(name: "btn_color", bundle: resourceBundle)

    /// The "btn_color_disable" asset catalog color resource.
    static let btnColorDisable = ColorResource(name: "btn_color_disable", bundle: resourceBundle)

    /// The "row_color_select" asset catalog color resource.
    static let rowColorSelect = ColorResource(name: "row_color_select", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
extension ImageResource {

    /// The "angle-left-18pt" asset catalog image resource.
    static let angleLeft18Pt = ImageResource(name: "angle-left-18pt", bundle: resourceBundle)

    /// The "angle-left-20pt" asset catalog image resource.
    static let angleLeft20Pt = ImageResource(name: "angle-left-20pt", bundle: resourceBundle)

    /// The "angle-left-24pt" asset catalog image resource.
    static let angleLeft24Pt = ImageResource(name: "angle-left-24pt", bundle: resourceBundle)

    /// The "angle-left-36pt" asset catalog image resource.
    static let angleLeft36Pt = ImageResource(name: "angle-left-36pt", bundle: resourceBundle)

    /// The "angle-left-48pt" asset catalog image resource.
    static let angleLeft48Pt = ImageResource(name: "angle-left-48pt", bundle: resourceBundle)

    /// The "angle-right-18pt" asset catalog image resource.
    static let angleRight18Pt = ImageResource(name: "angle-right-18pt", bundle: resourceBundle)

    /// The "angle-right-20pt" asset catalog image resource.
    static let angleRight20Pt = ImageResource(name: "angle-right-20pt", bundle: resourceBundle)

    /// The "angle-right-24pt" asset catalog image resource.
    static let angleRight24Pt = ImageResource(name: "angle-right-24pt", bundle: resourceBundle)

    /// The "angle-right-36pt" asset catalog image resource.
    static let angleRight36Pt = ImageResource(name: "angle-right-36pt", bundle: resourceBundle)

    /// The "angle-right-48pt" asset catalog image resource.
    static let angleRight48Pt = ImageResource(name: "angle-right-48pt", bundle: resourceBundle)

    /// The "bg_equalizer" asset catalog image resource.
    static let bgEqualizer = ImageResource(name: "bg_equalizer", bundle: resourceBundle)

    /// The "bg_hearing_test" asset catalog image resource.
    static let bgHearingTest = ImageResource(name: "bg_hearing_test", bundle: resourceBundle)

    /// The "bg_splash" asset catalog image resource.
    static let bgSplash = ImageResource(name: "bg_splash", bundle: resourceBundle)

    /// The "ces_mark" asset catalog image resource.
    static let cesMark = ImageResource(name: "ces_mark", bundle: resourceBundle)

    /// The "circle-user-18pt" asset catalog image resource.
    static let circleUser18Pt = ImageResource(name: "circle-user-18pt", bundle: resourceBundle)

    /// The "circle-user-20pt" asset catalog image resource.
    static let circleUser20Pt = ImageResource(name: "circle-user-20pt", bundle: resourceBundle)

    /// The "circle-user-24pt" asset catalog image resource.
    static let circleUser24Pt = ImageResource(name: "circle-user-24pt", bundle: resourceBundle)

    /// The "circle-user-36pt" asset catalog image resource.
    static let circleUser36Pt = ImageResource(name: "circle-user-36pt", bundle: resourceBundle)

    /// The "circle-user-48pt" asset catalog image resource.
    static let circleUser48Pt = ImageResource(name: "circle-user-48pt", bundle: resourceBundle)

    /// The "contact" asset catalog image resource.
    static let contact = ImageResource(name: "contact", bundle: resourceBundle)

    /// The "en_onboarding1" asset catalog image resource.
    static let enOnboarding1 = ImageResource(name: "en_onboarding1", bundle: resourceBundle)

    /// The "en_onboarding2" asset catalog image resource.
    static let enOnboarding2 = ImageResource(name: "en_onboarding2", bundle: resourceBundle)

    /// The "en_onboarding3" asset catalog image resource.
    static let enOnboarding3 = ImageResource(name: "en_onboarding3", bundle: resourceBundle)

    /// The "en_onboarding4" asset catalog image resource.
    static let enOnboarding4 = ImageResource(name: "en_onboarding4", bundle: resourceBundle)

    /// The "equalizer" asset catalog image resource.
    static let equalizer = ImageResource(name: "equalizer", bundle: resourceBundle)

    /// The "folder-18pt" asset catalog image resource.
    static let folder18Pt = ImageResource(name: "folder-18pt", bundle: resourceBundle)

    /// The "folder-20pt" asset catalog image resource.
    static let folder20Pt = ImageResource(name: "folder-20pt", bundle: resourceBundle)

    /// The "folder-24pt" asset catalog image resource.
    static let folder24Pt = ImageResource(name: "folder-24pt", bundle: resourceBundle)

    /// The "folder-36pt" asset catalog image resource.
    static let folder36Pt = ImageResource(name: "folder-36pt", bundle: resourceBundle)

    /// The "folder-48pt" asset catalog image resource.
    static let folder48Pt = ImageResource(name: "folder-48pt", bundle: resourceBundle)

    /// The "globe-18pt" asset catalog image resource.
    static let globe18Pt = ImageResource(name: "globe-18pt", bundle: resourceBundle)

    /// The "globe-20pt" asset catalog image resource.
    static let globe20Pt = ImageResource(name: "globe-20pt", bundle: resourceBundle)

    /// The "globe-24pt" asset catalog image resource.
    static let globe24Pt = ImageResource(name: "globe-24pt", bundle: resourceBundle)

    /// The "globe-36pt" asset catalog image resource.
    static let globe36Pt = ImageResource(name: "globe-36pt", bundle: resourceBundle)

    /// The "globe-48pt" asset catalog image resource.
    static let globe48Pt = ImageResource(name: "globe-48pt", bundle: resourceBundle)

    /// The "ic_acc" asset catalog image resource.
    static let icAcc = ImageResource(name: "ic_acc", bundle: resourceBundle)

    /// The "ic_arrow_down" asset catalog image resource.
    static let icArrowDown = ImageResource(name: "ic_arrow_down", bundle: resourceBundle)

    /// The "ic_arrow_down_black" asset catalog image resource.
    static let icArrowDownBlack = ImageResource(name: "ic_arrow_down_black", bundle: resourceBundle)

    /// The "ic_back" asset catalog image resource.
    static let icBack = ImageResource(name: "ic_back", bundle: resourceBundle)

    /// The "ic_calendar" asset catalog image resource.
    static let icCalendar = ImageResource(name: "ic_calendar", bundle: resourceBundle)

    /// The "ic_check_none" asset catalog image resource.
    static let icCheckNone = ImageResource(name: "ic_check_none", bundle: resourceBundle)

    /// The "ic_check_select" asset catalog image resource.
    static let icCheckSelect = ImageResource(name: "ic_check_select", bundle: resourceBundle)

    /// The "ic_close" asset catalog image resource.
    static let icClose = ImageResource(name: "ic_close", bundle: resourceBundle)

    /// The "ic_direction" asset catalog image resource.
    static let icDirection = ImageResource(name: "ic_direction", bundle: resourceBundle)

    /// The "ic_edit" asset catalog image resource.
    static let icEdit = ImageResource(name: "ic_edit", bundle: resourceBundle)

    /// The "ic_edit_white" asset catalog image resource.
    static let icEditWhite = ImageResource(name: "ic_edit_white", bundle: resourceBundle)

    /// The "ic_equalizer" asset catalog image resource.
    static let icEqualizer = ImageResource(name: "ic_equalizer", bundle: resourceBundle)

    /// The "ic_file" asset catalog image resource.
    static let icFile = ImageResource(name: "ic_file", bundle: resourceBundle)

    /// The "ic_global" asset catalog image resource.
    static let icGlobal = ImageResource(name: "ic_global", bundle: resourceBundle)

    /// The "ic_headphone" asset catalog image resource.
    static let icHeadphone = ImageResource(name: "ic_headphone", bundle: resourceBundle)

    /// The "ic_hearing_round" asset catalog image resource.
    static let icHearingRound = ImageResource(name: "ic_hearing_round", bundle: resourceBundle)

    /// The "ic_info" asset catalog image resource.
    static let icInfo = ImageResource(name: "ic_info", bundle: resourceBundle)

    /// The "ic_language" asset catalog image resource.
    static let icLanguage = ImageResource(name: "ic_language", bundle: resourceBundle)

    /// The "ic_line_ear" asset catalog image resource.
    static let icLineEar = ImageResource(name: "ic_line_ear", bundle: resourceBundle)

    /// The "ic_line_ear_2" asset catalog image resource.
    static let icLineEar2 = ImageResource(name: "ic_line_ear_2", bundle: resourceBundle)

    /// The "ic_line_ear_3" asset catalog image resource.
    static let icLineEar3 = ImageResource(name: "ic_line_ear_3", bundle: resourceBundle)

    /// The "ic_line_ear_4" asset catalog image resource.
    static let icLineEar4 = ImageResource(name: "ic_line_ear_4", bundle: resourceBundle)

    /// The "ic_line_ear_full" asset catalog image resource.
    static let icLineEarFull = ImageResource(name: "ic_line_ear_full", bundle: resourceBundle)

    /// The "ic_line_earphone" asset catalog image resource.
    static let icLineEarphone = ImageResource(name: "ic_line_earphone", bundle: resourceBundle)

    /// The "ic_line_hear" asset catalog image resource.
    static let icLineHear = ImageResource(name: "ic_line_hear", bundle: resourceBundle)

    /// The "ic_link" asset catalog image resource.
    static let icLink = ImageResource(name: "ic_link", bundle: resourceBundle)

    /// The "ic_mic" asset catalog image resource.
    static let icMic = ImageResource(name: "ic_mic", bundle: resourceBundle)

    /// The "ic_mic_select" asset catalog image resource.
    static let icMicSelect = ImageResource(name: "ic_mic_select", bundle: resourceBundle)

    /// The "ic_option" asset catalog image resource.
    static let icOption = ImageResource(name: "ic_option", bundle: resourceBundle)

    /// The "ic_option_off" asset catalog image resource.
    static let icOptionOff = ImageResource(name: "ic_option_off", bundle: resourceBundle)

    /// The "ic_option_on" asset catalog image resource.
    static let icOptionOn = ImageResource(name: "ic_option_on", bundle: resourceBundle)

    /// The "ic_play" asset catalog image resource.
    static let icPlay = ImageResource(name: "ic_play", bundle: resourceBundle)

    /// The "ic_plus_circle" asset catalog image resource.
    static let icPlusCircle = ImageResource(name: "ic_plus_circle", bundle: resourceBundle)

    /// The "ic_plus_white" asset catalog image resource.
    static let icPlusWhite = ImageResource(name: "ic_plus_white", bundle: resourceBundle)

    /// The "ic_question" asset catalog image resource.
    static let icQuestion = ImageResource(name: "ic_question", bundle: resourceBundle)

    /// The "ic_rec" asset catalog image resource.
    static let icRec = ImageResource(name: "ic_rec", bundle: resourceBundle)

    /// The "ic_rec_stop" asset catalog image resource.
    static let icRecStop = ImageResource(name: "ic_rec_stop", bundle: resourceBundle)

    /// The "ic_refresh" asset catalog image resource.
    static let icRefresh = ImageResource(name: "ic_refresh", bundle: resourceBundle)

    /// The "ic_setting" asset catalog image resource.
    static let icSetting = ImageResource(name: "ic_setting", bundle: resourceBundle)

    /// The "ic_share" asset catalog image resource.
    static let icShare = ImageResource(name: "ic_share", bundle: resourceBundle)

    /// The "ic_simple_mic" asset catalog image resource.
    static let icSimpleMic = ImageResource(name: "ic_simple_mic", bundle: resourceBundle)

    /// The "ic_simple_setting" asset catalog image resource.
    static let icSimpleSetting = ImageResource(name: "ic_simple_setting", bundle: resourceBundle)

    /// The "ic_speaker" asset catalog image resource.
    static let icSpeaker = ImageResource(name: "ic_speaker", bundle: resourceBundle)

    /// The "ic_trash" asset catalog image resource.
    static let icTrash = ImageResource(name: "ic_trash", bundle: resourceBundle)

    /// The "ic_trash_white" asset catalog image resource.
    static let icTrashWhite = ImageResource(name: "ic_trash_white", bundle: resourceBundle)

    /// The "ic_volume" asset catalog image resource.
    static let icVolume = ImageResource(name: "ic_volume", bundle: resourceBundle)

    /// The "img_graph" asset catalog image resource.
    static let imgGraph = ImageResource(name: "img_graph", bundle: resourceBundle)

    /// The "img_graph_2" asset catalog image resource.
    static let imgGraph2 = ImageResource(name: "img_graph_2", bundle: resourceBundle)

    /// The "ko_onboarding1" asset catalog image resource.
    static let koOnboarding1 = ImageResource(name: "ko_onboarding1", bundle: resourceBundle)

    /// The "ko_onboarding2" asset catalog image resource.
    static let koOnboarding2 = ImageResource(name: "ko_onboarding2", bundle: resourceBundle)

    /// The "ko_onboarding3" asset catalog image resource.
    static let koOnboarding3 = ImageResource(name: "ko_onboarding3", bundle: resourceBundle)

    /// The "ko_onboarding4" asset catalog image resource.
    static let koOnboarding4 = ImageResource(name: "ko_onboarding4", bundle: resourceBundle)

    /// The "logo" asset catalog image resource.
    static let logo = ImageResource(name: "logo", bundle: resourceBundle)

    /// The "logo_en" asset catalog image resource.
    static let logoEn = ImageResource(name: "logo_en", bundle: resourceBundle)

    /// The "logo_kr" asset catalog image resource.
    static let logoKr = ImageResource(name: "logo_kr", bundle: resourceBundle)

    /// The "logo_w" asset catalog image resource.
    static let logoW = ImageResource(name: "logo_w", bundle: resourceBundle)

    /// The "manual" asset catalog image resource.
    static let manual = ImageResource(name: "manual", bundle: resourceBundle)

    /// The "minute_selected" asset catalog image resource.
    static let minuteSelected = ImageResource(name: "minute_selected", bundle: resourceBundle)

    /// The "minute_unselected" asset catalog image resource.
    static let minuteUnselected = ImageResource(name: "minute_unselected", bundle: resourceBundle)

    /// The "play-circle-18pt" asset catalog image resource.
    static let playCircle18Pt = ImageResource(name: "play-circle-18pt", bundle: resourceBundle)

    /// The "play-circle-20pt" asset catalog image resource.
    static let playCircle20Pt = ImageResource(name: "play-circle-20pt", bundle: resourceBundle)

    /// The "play-circle-24pt" asset catalog image resource.
    static let playCircle24Pt = ImageResource(name: "play-circle-24pt", bundle: resourceBundle)

    /// The "play-circle-36pt" asset catalog image resource.
    static let playCircle36Pt = ImageResource(name: "play-circle-36pt", bundle: resourceBundle)

    /// The "play-circle-48pt" asset catalog image resource.
    static let playCircle48Pt = ImageResource(name: "play-circle-48pt", bundle: resourceBundle)

    /// The "process_on" asset catalog image resource.
    static let processOn = ImageResource(name: "process_on", bundle: resourceBundle)

    /// The "rec_off" asset catalog image resource.
    static let recOff = ImageResource(name: "rec_off", bundle: resourceBundle)

    /// The "rec_on" asset catalog image resource.
    static let recOn = ImageResource(name: "rec_on", bundle: resourceBundle)

    /// The "settings-18pt" asset catalog image resource.
    static let settings18Pt = ImageResource(name: "settings-18pt", bundle: resourceBundle)

    /// The "settings-20pt" asset catalog image resource.
    static let settings20Pt = ImageResource(name: "settings-20pt", bundle: resourceBundle)

    /// The "settings-24pt" asset catalog image resource.
    static let settings24Pt = ImageResource(name: "settings-24pt", bundle: resourceBundle)

    /// The "settings-36pt" asset catalog image resource.
    static let settings36Pt = ImageResource(name: "settings-36pt", bundle: resourceBundle)

    /// The "settings-48pt" asset catalog image resource.
    static let settings48Pt = ImageResource(name: "settings-48pt", bundle: resourceBundle)

    /// The "share-18pt" asset catalog image resource.
    static let share18Pt = ImageResource(name: "share-18pt", bundle: resourceBundle)

    /// The "share-20pt" asset catalog image resource.
    static let share20Pt = ImageResource(name: "share-20pt", bundle: resourceBundle)

    /// The "share-24pt" asset catalog image resource.
    static let share24Pt = ImageResource(name: "share-24pt", bundle: resourceBundle)

    /// The "share-36pt" asset catalog image resource.
    static let share36Pt = ImageResource(name: "share-36pt", bundle: resourceBundle)

    /// The "share-48pt" asset catalog image resource.
    static let share48Pt = ImageResource(name: "share-48pt", bundle: resourceBundle)

    /// The "slider-18pt" asset catalog image resource.
    static let slider18Pt = ImageResource(name: "slider-18pt", bundle: resourceBundle)

    /// The "slider-20pt" asset catalog image resource.
    static let slider20Pt = ImageResource(name: "slider-20pt", bundle: resourceBundle)

    /// The "slider-24pt" asset catalog image resource.
    static let slider24Pt = ImageResource(name: "slider-24pt", bundle: resourceBundle)

    /// The "slider-36pt" asset catalog image resource.
    static let slider36Pt = ImageResource(name: "slider-36pt", bundle: resourceBundle)

    /// The "slider-48pt" asset catalog image resource.
    static let slider48Pt = ImageResource(name: "slider-48pt", bundle: resourceBundle)

    /// The "trash-18pt" asset catalog image resource.
    static let trash18Pt = ImageResource(name: "trash-18pt", bundle: resourceBundle)

    /// The "trash-20pt" asset catalog image resource.
    static let trash20Pt = ImageResource(name: "trash-20pt", bundle: resourceBundle)

    /// The "trash-24pt" asset catalog image resource.
    static let trash24Pt = ImageResource(name: "trash-24pt", bundle: resourceBundle)

    /// The "trash-36pt" asset catalog image resource.
    static let trash36Pt = ImageResource(name: "trash-36pt", bundle: resourceBundle)

    /// The "trash-48pt" asset catalog image resource.
    static let trash48Pt = ImageResource(name: "trash-48pt", bundle: resourceBundle)

    /// The "voice-circle" asset catalog image resource.
    static let voiceCircle = ImageResource(name: "voice-circle", bundle: resourceBundle)

}

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