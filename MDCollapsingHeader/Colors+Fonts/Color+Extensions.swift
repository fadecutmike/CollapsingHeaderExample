//
//  UIColor+WilliamHill.swift
//  WHSandbox
//
//  Created by Josh Kimmelman on 2/5/20.
//  Copyright © 2020 Josh Kimmelman. All rights reserved.
//

import UIKit

// MARK: - UIColor helper methods

extension UIColor {
    
    /// Quickly get an RGBA UIColor
    /// - Parameters:
    ///   - r: red Int
    ///   - g: green Int
    ///   - b: blue Int
    ///   - a: alpha CGFloat
    /// - Returns: UIColor object
    class func rgba(_ r: Int, _ g: Int, _ b: Int, _ a: CGFloat = 1.0) -> UIColor {
        assert(r >= 0 && r <= 255, "Invalid red component")
        assert(g >= 0 && g <= 255, "Invalid green component")
        assert(b >= 0 && b <= 255, "Invalid blue component")
        return UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: CGFloat(a))
    }
    
    class func randomColor(_ a: CGFloat = 1.0) -> UIColor {
        let r: Int = .random(in: 0...255)
        var g: Int = .random(in: 0...255)
        var b: Int = .random(in: 0...255)
        
        if abs(r-g) < 50 { g = r>=205 ? r-50 : r+50 }
        if r+g+b > 650 {
            g /= 2
            b = 15
        } else if r+b+g < 200 {
            g *= 2
            b = 250
        }
        return UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: CGFloat(a))
    }
        
    /// UIColor from CZK ThemeColor enum
    /// - Parameter theme: The specified CZK ThemeColor case
    /// - Returns: UIColor object from CZK ThemeColors respecting system displayMode setting or user overridden UserInterfaceStyle (From `WHLookup.internalAppDisplayMode`)
    class func czkColor(_ theme: CZK.ThemeColor)    -> UIColor { theme.color }
    class func czkColorHex(_ theme: CZK.ThemeColor) -> UIColor { theme.hexColor }
}

// MARK: - Hex Color methods

extension UIColor {
    
    /// UIColor from hex string
    /// - Parameter hex: hex string of desired color
    /// - Returns: UIColor object from inputted hex string
    class func hex(_ hex: String) -> UIColor {

        var rgb       : (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) = (0, 0, 0, 0)
        let hexString : String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().replacingOccurrences(of: "#", with: "")
        var hexNumber : UInt64 = 0
        let scanner = Scanner(string: hexString)
        
        guard [6, 8].contains(hexString.count) else { fatalError("Invalid hex string length for UIColor.hex init...") }
        
        if scanner.scanHexInt64(&hexNumber) {
            switch hexString.count {
            case 8: rgb = ( r: CGFloat((hexNumber & 0xff000000) >> 24) / 255,
                            g: CGFloat((hexNumber & 0x00ff0000) >> 16) / 255,
                            b: CGFloat((hexNumber & 0x0000ff00) >> 8)  / 255,
                            a: CGFloat( hexNumber & 0x000000ff)        / 255)
                
            case 6: rgb = ( r: CGFloat((hexNumber & 0xff0000) >> 16) / 255,
                            g: CGFloat((hexNumber & 0x00ff00) >> 8)  / 255,
                            b: CGFloat((hexNumber & 0x0000ff))       / 255,
                            a: 1.0)
            default: fatalError("Invalid hex string for UIColor.hex init...")
            }
        }
        return UIColor.init(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: rgb.a)
    }
}

// MARK: - CGColor methods (for borders/shadows etc.)

extension CGColor {
    /// CGColor from CZK ThemeColor enum
    /// - Parameter theme: The specified CZK ThemeColor case
    /// - Returns: CGColor object from CZK ThemeColors respecting system displayMode setting or user overridden UserInterfaceStyle (From `WHLookup.internalAppDisplayMode`)
    class func czkCGColor(_ theme: CZK.ThemeColor)    -> CGColor { theme.color.cgColor }
    class func czkCGColorHex(_ theme: CZK.ThemeColor) -> CGColor { theme.hexColor.cgColor }
}
