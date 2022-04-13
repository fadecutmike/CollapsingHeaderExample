//
//  WHHelpers.swift
//  MDCollapsingHeader
//
//  Created by mad on 2/20/22.
//

import Foundation
import UIKit

public let stdSize: CGFloat = 12.0

// Ensure case names match suffix (case insensitive)
protocol WHFontable: Hashable, CustomStringConvertible, CaseAccessible {
    var styleSuffix: String { get }
    var caseName: String { get }
    var fontName: String { get }
    var fontSize: CGFloat { get }
    var font: UIFont { get }
}

extension WHFontable {
    var fontSize: CGFloat { (associatedValue() as CGFloat?) ?? stdSize }
    var font: UIFont { UIFont(name: fontName, size: fontSize)! }
    var styleSuffix: String { caseName.capitalized }

    /// The name of an enum case as a String
    var caseName: String { Mirror(reflecting: self).children.first?.label ?? "WHFontable enum case err..." }

    /// CustomStringConvertible description string
    public var description: String { "\(fontName) \(fontSize)px" }

    /// Checks equatability based on the font style
    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.caseName == rhs.caseName }
}

public struct WHFont {
    // Proxima
    public enum Proxima: WHFontable {
        case light(CGFloat = stdSize), regular(CGFloat = stdSize), medium(CGFloat = stdSize), semiBold(CGFloat = stdSize), bold(CGFloat = stdSize), extraBld(CGFloat = stdSize)
        var fontName: String { "ProximaNovaCond-\(styleSuffix)" }
    }

    // DINAlternate-Bold
    public enum DINAlternate: WHFontable {
        case bold(CGFloat = stdSize)
        var fontName: String { "DINAlternate-\(styleSuffix)" }
    }
    
    public static func getAttr(_ proxima: WHFont.Proxima, _ color: UIColor) -> [NSAttributedString.Key: Any] {
        [.font: proxima.font, .foregroundColor: color]
    }
    
    public static func getAttrDin(_ din: WHFont.DINAlternate, _ color: UIColor) -> [NSAttributedString.Key: Any] {
        [.font: din.font, .foregroundColor: color]
    }
}

extension UILabel {
    func proximaLight(size: CGFloat)     { font = .proxima(.light(size)) }
    func proximaMedium(size: CGFloat)    { font = .proxima(.medium(size)) }
    func proximaRegular(size: CGFloat)   { font = .proxima(.regular(size)) }
    func proximaBold(size: CGFloat)      { font = .proxima(.bold(size)) }
    func proximaExtraBold(size: CGFloat) { font = .proxima(.extraBld(size)) }
    func proximaSemiBold(size: CGFloat)  { font = .proxima(.semiBold(size)) }
    func dniBold(size: CGFloat)          { font = .dinaAlt(.bold(size)) }
}

extension UIFont {
    open class func proxima(_ style: WHFont.Proxima)      -> UIFont { style.font }
    open class func dinaAlt(_ style: WHFont.DINAlternate) -> UIFont { style.font }
}

struct WHAttr {
    static func str(_ text: String? = nil) -> NSAttributedString {
        NSAttributedString(string: text ?? "")
    }

    static func getAttrString(text: String, isBold: Bool = false, _ aFont: UIFont = WHFont.Proxima.medium(16.0).font) -> NSAttributedString {
        getCustomStr(text: text, isBold ? .black : .black, aFont)
    }
    
    static func getCustomStr(text: String, _ color: UIColor = .black, _ aFont: UIFont = WHFont.Proxima.medium(16.0).font) -> NSAttributedString {

        let attributedText = NSMutableAttributedString(string: text, attributes: [
            .font: aFont,
            .foregroundColor: color
        ])

        return attributedText
    }

    static func getVal(_ topValue: String, _ bottomValue: String? = nil, _ isTopBold: Bool = false) -> NSAttributedString {

        let finalAttributedString = NSMutableAttributedString(attributedString: getAttrString(text: topValue, isBold: isTopBold))

        if let bVal = bottomValue, bVal.count > 0 {
            finalAttributedString.append(getAttrString(text: "\n\(bVal)", isBold: false))
        }

        return finalAttributedString
    }

    static func getTitle(_ text: String) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: text, attributes: [
            .font: WHFont.Proxima.medium(13.0).font,
            .foregroundColor: UIColor.black
        ])

        return attributedText
    }

    static func makeAttributed(title: String, value: String) -> NSAttributedString {
        let titleAttributedText = NSMutableAttributedString(string: title, attributes: [
            .font: WHFont.Proxima.bold(16.0).font,
            .foregroundColor: UIColor.black
        ])

        let valueAttributedText = NSMutableAttributedString(string: " \(value)", attributes: [
            .font: WHFont.Proxima.semiBold(16.0).font,
            .foregroundColor: UIColor.black
        ])

        titleAttributedText.append(valueAttributedText)
        return titleAttributedText
    }
}

// MARK: - Utility methods allowing font specification
extension WHAttr {
    static let defaultFont = WHFont.Proxima.medium(16.0).font

    static func getPackAttrString(text: String, font: UIFont?, color: UIColor) -> NSAttributedString {
        guard let font = font else { fatalError("font failed to load!") }

        let attributedText = NSMutableAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: color
        ])

        return attributedText
    }

    static func getPackVal(_ lines: [String], _ fontsAndColors: [FontColor] = [(defaultFont, .black)]) -> NSAttributedString {

        guard let topValue = lines.first, let topFont = fontsAndColors.first else { fatalError("getPackVal Error!") }
        
        let finalAttributedString = NSMutableAttributedString(attributedString: getPackAttrString(text: topValue, font: topFont.font, color: topFont.color))

        if lines.count > 1, let bottomValue = lines.last, bottomValue.count > 0, let fcTwo = fontsAndColors.last {
            finalAttributedString.append(getPackAttrString(text: "\n\(bottomValue)", font: fcTwo.font, color: fcTwo.color))
        }

        return finalAttributedString
    }
    
    static func getPackOutputAttrString(_ lines: [String], _ fontsAndColors: [FontColor] = [(defaultFont, .black)]) -> NSAttributedString {

        guard let topValue = lines.first, let topFont = fontsAndColors.first else { fatalError("getPackVal Error!") }
        
        let finalAttributedString = NSMutableAttributedString(attributedString: getPackAttrString(text: topValue, font: topFont.font, color: topFont.color))

        if lines.count > 1, let bottomValue = lines.last, bottomValue.count > 0, let fcTwo = fontsAndColors.last {
            finalAttributedString.append(getPackAttrString(text: "\n\(bottomValue)", font: fcTwo.font, color: fcTwo.color))
        }

        return finalAttributedString
    }
}

extension WHAttr {
    static func getCashout(_ amount: String) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: "Cashed Out ", attributes: [
            .font: WHFont.Proxima.regular(18.0).font,
            .foregroundColor: UIColor.black
        ])

        attributedText.append(NSAttributedString(string: amount, attributes: [
            .font: WHFont.Proxima.regular(18.0).font,
            .foregroundColor: UIColor.black
        ]))

        return attributedText
    }
    
    /// Attributed string generator for Open Bets ParleyLeg PreGame label
    /// - Parameters:
    ///   - eventStartDate: The event start date as a Date object
    ///   - rhsText: The Team1 vs. Team2 text for the event
    /// - Returns: Attributed and formated string
    static func getAttrPregameLeg(_ eventStartDate: Date, _ rhsText: String) -> NSAttributedString {
        let evDateFmt = DateFormatter()
        evDateFmt.dateFormat = "h:mma, dd MMM | "
        let attributedText = NSMutableAttributedString(string: evDateFmt.string(from: eventStartDate), attributes: [
            .font: WHFont.Proxima.regular(16.0).font,
            .foregroundColor: UIColor.black
        ])

        attributedText.append(NSAttributedString(string: rhsText, attributes: [
            .font: WHFont.Proxima.regular(16.0).font,
            .foregroundColor: UIColor.black
        ]))

        return attributedText
    }
}

// MARK: - My Bonus Activity

extension WHAttr {
    static func getBonusAttrType(_ title: String, _ type: String) -> NSAttributedString {
        
        let attributedText = NSMutableAttributedString(string: title, attributes: [
            .font: WHFont.Proxima.bold(14.0).font,
            .foregroundColor: UIColor.black
        ])

        attributedText.append(NSAttributedString(string: "\n\(type)", attributes: [
            .font: WHFont.Proxima.regular(14.0).font,
            .foregroundColor: UIColor.black
        ]))

        return attributedText
    }
    
    static func getBonusTimestamp(_ title: String, _ time: String) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: title, attributes: [
            .font: WHFont.Proxima.bold(14).font,
            .foregroundColor: UIColor.black
        ])
        
        attributedText.append(NSAttributedString(string: " \(time)", attributes: [
            .font: WHFont.Proxima.regular(14.0).font,
            .foregroundColor: UIColor.black
        ]))
        
        return attributedText
    }
}

// Mark: - Caesar rewards attributed strings for credits
extension WHAttr {
    static func getCredits(creditNumber: String, tier: String) -> NSAttributedString {
        
        let attributedText = NSMutableAttributedString(string: creditNumber, attributes: [
            .font: WHFont.Proxima.bold(14.0).font,
            .foregroundColor: UIColor.black
        ])

        attributedText.append(NSAttributedString(string: tier, attributes: [
            .font: WHFont.Proxima.bold(14.0).font,
            .foregroundColor: UIColor.black
        ]))

        return attributedText
    }
}

// MARK: - Image attachments for attributed strings

extension WHAttr {
    static func getImgAttachStr(_ img: UIImage) -> NSMutableAttributedString {
        let imgAttach = NSTextAttachment(image: img)
        imgAttach.bounds = CGRect(x: 0.0, y: -4.0, width: img.size.width, height: img.size.height)
        let completeText = NSMutableAttributedString(string: "")
        completeText.append(NSAttributedString(attachment: imgAttach))
        return completeText
    }
}

// MARK: - Attributed strings for EVD

extension WHAttr {
    
    static func getEVDNavTitle(_ text: String, _ color: UIColor = .black, _ isBold: Bool = true) -> NSMutableAttributedString {
        getEVDNavTitleCustomFont(text, color, isBold ? .bold(14.0) : .medium(12.0))
    }
    
    static func getEVDNavTitleCustomFont(_ text: String, _ color: UIColor = .black, _ fontStyle: WHFont.Proxima = .bold(14.0)) -> NSMutableAttributedString {
        let attributedText = NSMutableAttributedString(string: text, attributes: [
            .font: fontStyle.font,
            .foregroundColor: color
        ])

        return attributedText
    }
    
    static func getEVDImgAttachStr(_ img: UIImage) -> NSMutableAttributedString {

        let imgAttach = NSTextAttachment(image: img)
        imgAttach.bounds = CGRect(x: 0.0, y: -1.5, width: img.size.width, height: img.size.height)
        let attributedText = NSMutableAttributedString(string: "")
        attributedText.append(NSAttributedString(attachment: imgAttach))
        return attributedText
    }
}

// MARK: - Team name abbreviation attr string

extension WHAttr {
    static func getTeamNameOneLine(_ abbreviation: String, _ shortName: String) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: getCustomStr(text: abbreviation, .black, .proxima(.regular(16.0))))
        result.append(NSMutableAttributedString(attributedString: getCustomStr(text: " \(shortName)", .black, .proxima(.semiBold(16.0)))))
        
        return result
    }
    
    static func getTeamNameTwoLines(_ abbreviation: String, _ shortName: String) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: getCustomStr(text: abbreviation, .black, .proxima(.medium(12.0))))
        result.append(NSMutableAttributedString(attributedString: getCustomStr(text: "\n\(shortName)", .black, .proxima(.semiBold(14.0)))))
        
        return result
    }
}


extension WHAttr {
    static func getStep4Header(p1: String, p2: String, p3: String) -> NSAttributedString {
        
        let attributedText = NSMutableAttributedString(string: p1, attributes: [
            .font: WHFont.Proxima.regular(16.0).font,
            .foregroundColor: UIColor.black
        ])

        attributedText.append(NSAttributedString(string: p2, attributes: [
            .font: WHFont.Proxima.bold(16.0).font,
            .foregroundColor: UIColor.black
        ]))
        
        attributedText.append(NSAttributedString(string: p3, attributes: [
            .font: WHFont.Proxima.regular(16.0).font,
            .foregroundColor: UIColor.black
        ]))

        return attributedText
    }
}

private let globalColors: [CZK.ThemeColor : UIColor] = [.globalWhite: .white, .globalBlk: .black, .globalClear: .clear]

extension CZK {
    enum ThemeColor: String, CaseIterable {
        case
        
        page,               brand,              errState,           // Page,                    Brand,              Error State,
        foreground,         secondary,          primary,            // Foreground,              Secondary,          Primary,
        info,               primaryStroke,      selected,           // Info,                    Primary Stroke,     Selected,

        disabled,           live,               promotions,         // Disabled,                Live,               Promotions,
        bg,                 popOver,            notification,       // Background,              Pop Over,           Notification,
        favorite,           tabBar,             alert,              // Favorite,                Tab Bar,            Alert,

        neutral,            successState,       divider,            // Neutral,                 Success State,      Divider,
        pageDivider,        systemBlue,                             // Page Divider,            System Blue,

        // MARK: - Reward + Global Colors
        rewardsCTA,        rewardsError,    rTierGold,              // Rewards CTA,             Rewards Error,      Rewards Gold,
        rTierPlatinum,     rTierDiamond,    rTierDiamondPlus,       // Rewards Platinum,        Rewards Diamond,    Rewards Diamond Plus,
        rTierDiamondElite, rTierSevenStars,                         // Rewards Diamond Elite,   Rewards 7 Stars,

        globalWhite,       globalBlk,       globalClear             // Global White,            Global Black,       Gloabal Clear

        var idxVal: Int { Self.allCases.firstIndex(of: self) ?? -1 }
        
        var color: UIColor {
            if let gColor = globalColorCheck() { return gColor }
            
            var name = "\(WHLookup.appTheme.description)_\(rawValue)"
            if idxVal >= Self.rewardsCTA.idxVal {
                name = rawValue.contains("rTier") ? rawValue.replacingOccurrences(of: "rTier", with: "").uppercased() : rawValue
            }
            guard let result = UIColor(named: name) else { fatalError("CZK.ThemeColor Failed!!!") }
            return result
        }
        
        /// Used to fix strange issue with Tabman bar button text color
        var forcedColor: UIColor {
            if let gColor = globalColorCheck() { return gColor }
            
            var name = "\(WHLookup.appTheme.description)_\(rawValue)"
            if idxVal >= Self.rewardsCTA.idxVal {
                name = rawValue.contains("rTier") ? rawValue.replacingOccurrences(of: "rTier", with: "").uppercased() : rawValue
            }
            guard let result = UIColor(named: name)?.resolvedColor(with: .init(userInterfaceStyle: WHLookup.internalAppDisplayMode.overrideStyleVal)) else { fatalError("CZK.ThemeColor Failed!!!") }
            return result
        }
        
        private func globalColorCheck() -> UIColor? { globalColors[self] }
        
        var colorSet: [UIColor] {
            var result: [String] = []
            switch WHLookup.appTheme {
            case .czr: result = WHLookup.appDisplayMode == .dark ? czrDark : czrLight
            case .wh:  result = WHLookup.appDisplayMode == .dark ? whDark  : whLight
            }
            
            return result.map{ UIColor.hex("#\($0)") }
        }
        
        var hexColor: UIColor {
            if let gColor = globalColorCheck() { return gColor }
            return colorSet[idxVal]
        }
    }
}

private let constColors: [String] = [
    "A9975B",
    "838787", "BCBCB7", "3E4243",
    "752533", "892031",
    "FFFFFF", "000000"]

// MARK: - Caesers Themes

private let czrLight: [String] = [
    "F2F2F2", "786847", "EA1319",
    "343840", "F4FCF2", "128152",
    "5A5E61", "7CA18D", "255E46",

    "E5E5E5", "3600D0", "FA6400",
    "FFFFFF", "FFFFFF", "9D2D2A",
    "FFE500", "F5F5F5", "FCB514",

    "C4C4C6", "128152", "EEEEEE",
    "EEEEEE", "007AFF",

    "AD1F23", "D60000"] + constColors

private let czrDark: [String] = [
    "161616", "CBAA65", "FF375F",
    "FFFFFF", "303030", "03E385",
    "AAAAAA", "444444", "13AA6A",

    "888888", "8F68FF", "FFFFFF",
    "202020", "303030", "FF375F",
    "FFE500", "202020", "FCB514",

    "5A595E", "03E385", "2C2C2C",
    "161616", "0A84FF",

    "E4686B", "FF375F"] + constColors

// MARK: - William Hill Themes

private let whLight: [String] = [
    "F2F2F2", "3E5F9B", "EA1319",
    "000000", "F4F7FC", "3F609B",
    "5A5E61", "6580AF", "965198",

    "E5E5E5", "EA1319", "FA6400",
    "FFFFFF", "FFFFFF", "1BC47D",
    "FFE500", "F5F5F5", "FCB514",

    "C9C9CC", "14AF6E", "EDEDED",
    "EDEDED", "0079FF",
    
    "AD1F23", "D60000"] + constColors

private let whDark: [String] = [
    "161616", "FBB618", "FF453A",
    "FFFFFF", "1E1E1E", "FCB619",
    "AAAAAA", "615515", "FFFFFF",

    "35373C", "FF453A", "FA6400",
    "121212", "2F2F2F", "19C95D",
    "FFE500", "1E1E1F", "80EDFC",

    "585858", "19C95D", "2C2C2C",
    "151515", "0984FF",
    
    "E4686B", "FF375F"] + constColors

protocol CaseAccessible {
    func associatedValue<AssociatedValue>() -> AssociatedValue?
}

extension CaseAccessible {
    func associatedValue<AssociatedValue>() -> AssociatedValue? { Mirror(reflecting: self).children.compactMap({ $0.value }).first as? AssociatedValue }
}
