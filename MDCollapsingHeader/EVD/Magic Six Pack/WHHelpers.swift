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
    
    public static func getAttr(_ proxima: WHFont.Proxima, _ color: UIColor) -> [NSAttributedString.Key: Any] {
        [.font: proxima.font, .foregroundColor: color]
    }

    // DINAlternate-Bold
    public enum DINAlternate: WHFontable {
        case bold(CGFloat = stdSize)
        var fontName: String { "DINAlternate-\(styleSuffix)" }
    }
    
    public static func getAttrDin(_ din: WHFont.DINAlternate, _ color: UIColor) -> [NSAttributedString.Key: Any] {
        [.font: din.font, .foregroundColor: color]
    }
    
    // Refrigerator Deluxe
    public enum Refrigerator: WHFontable {
        case light(CGFloat = stdSize), regular(CGFloat = stdSize), bold(CGFloat = stdSize), extraBold(CGFloat = stdSize), heavy(CGFloat = stdSize)
        var fontName: String { self == .regular() ? "RefrigeratorDeluxe" : "RefrigeratorDeluxe-\(styleSuffix)" }
    }
    
    public static func getAttrRefrigerator(_ refrigerator: WHFont.Refrigerator, _ color: UIColor) -> [NSAttributedString.Key: Any] {
        [.font: refrigerator.font, .foregroundColor: color]
    }
}

extension UILabel {
    func setFontProxima(_ style: WHFont.Proxima)           { font = style.font }
    func setFontRefrigerator(_ style: WHFont.Refrigerator) { font = style.font }
    func setFontDinaAlt(_ style: WHFont.Proxima)           { font = style.font }
}

extension UIButton {
    func setFontProxima(_ style: WHFont.Proxima)           { titleLabel?.setFontProxima(style) }
    func setFontRefrigerator(_ style: WHFont.Refrigerator) { titleLabel?.setFontRefrigerator(style) }
    func setFontDinaAlt(_ style: WHFont.Proxima)           { titleLabel?.setFontDinaAlt(style) }
}

extension UIFont {
    open class func proxima(_ style: WHFont.Proxima)           -> UIFont { style.font }
    open class func dinaAlt(_ style: WHFont.DINAlternate)      -> UIFont { style.font }
    open class func refrigerator(_ style: WHFont.Refrigerator) -> UIFont { style.font }
}

protocol CaseAccessible {
    func associatedValue<AssociatedValue>() -> AssociatedValue?
}

extension CaseAccessible {
    func associatedValue<AssociatedValue>() -> AssociatedValue? { Mirror(reflecting: self).children.compactMap({ $0.value }).first as? AssociatedValue }
}
