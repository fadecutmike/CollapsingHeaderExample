//
//  CZK+Colors.swift
//  WH_CZR_SBK
//
//  Created by Michael Dimore on 8/23/21.
//  Copyright © 2021 Caesar's Entertainment. All rights reserved.
//

import UIKit

private let globalColors: [CZK.ThemeColor : UIColor] = [.globalWhite: .white, .globalBlk: .black, .globalClear: .clear]

enum CZK {
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
            
            var name = "czr_\(rawValue)"
            if idxVal >= Self.rewardsCTA.idxVal {
                name = rawValue.contains("rTier") ? rawValue.replacingOccurrences(of: "rTier", with: "").uppercased() : rawValue
            }
            guard let result = UIColor(named: name) else { fatalError("CZK.ThemeColor Failed!!!") }
            return result
        }
        
        /// Used to fix strange issue with Tabman bar button text color
        var forcedColor: UIColor {
            if let gColor = globalColorCheck() { return gColor }
            
            var name = "czr_\(rawValue)"
            if idxVal >= Self.rewardsCTA.idxVal {
                name = rawValue.contains("rTier") ? rawValue.replacingOccurrences(of: "rTier", with: "").uppercased() : rawValue
            }
            guard let result = UIColor(named: name)?.resolvedColor(with: .init(userInterfaceStyle: .dark)) else { fatalError("CZK.ThemeColor Failed!!!") }
            return result
        }
        
        private func globalColorCheck() -> UIColor? { globalColors[self] }
        
        var colorSet: [UIColor] {
            var result: [String] = []
//            switch WHLookup.appTheme {
//            case .czr: result = WHLookup.appDisplayMode == .dark ? czrDark : czrLight
//            case .wh:  result = WHLookup.appDisplayMode == .dark ? whDark  : whLight
//            }
            
            return czrDark.map{ UIColor.hex("#\($0)") }
        }
        
        var hexColor: UIColor {
            if let gColor = globalColorCheck() { return gColor }
            return colorSet[idxVal]
        }

        var dark: UIColor {
            if let gColor = globalColorCheck() { return gColor }
            var result: [String] = []
//            switch WHLookup.appTheme {
//            case .czr: result = czrDark
//            case .wh:  result = whDark
//            }
            return czrDark.map{ UIColor.hex("#\($0)") }[idxVal]
        }

        var light: UIColor {
            if let gColor = globalColorCheck() { return gColor }
            var result: [String] = []
//            switch WHLookup.appTheme {
//            case .czr: result = czrLight
//            case .wh:  result = whLight
//            }
            return czrDark.map{ UIColor.hex("#\($0)") }[idxVal]
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
