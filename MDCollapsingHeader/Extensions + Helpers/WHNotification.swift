//
//  WHNotification.swift
//  WH_CZR_SBK
//
//  Created by Michael Dimore on 3/1/21.
//  Copyright © 2021 Caesar's Entertainment. All rights reserved.
//

import UIKit

// swiftlint:disable line_length

public typealias CZNO = WHNotification

/// Enum representing Notification cases for use with `NotificationCenter`
public enum WHNotification: String {
    case
    // Account + Settings
    kInbox, kLoginStatusChange, kLoggedInAccountChanged, kOddsFormatChanged, kCloseForRegisterAndDeposit,
    kCloseAllFromDeposit, kShowUserAccountPage, kCloseForgotPasswordPage, kUserSessionExpired, kActiveStateChange,
    kUserDataChanged,

    // GeoComply
    kGeoComplyVerificationStatusChanged,

    // Betslip
    kBetslipContentsChanged, kChangeBetSlipsTotalCount, kBetPlacedResponse, kBetReferralMessage, kHighlightedSelectionIdsChanged,

    // Diffusion Updates (all share the same NSNotification.Name)
    // The `rawValue` of each diffusion update case is used for the userInfo dictionary key
    diffusionUpdate,

    // Other
    kInApp, kFromTabbarEventsPagePresented,
    
    // Used to observe both displayMode and CZKTheme changes
    kCZKDidChange

    /// The NSNotification.Name object for each WHNotification case
    /// Diffusion updates are a special case, only one notification name is used for each update type
    var name: NSNotification.Name { NSNotification.Name(rawValue: rawValue) }

    /// Generates a Notification object for posting notifications
    /// - Parameters:
    ///   - object: Notification object input
    ///   - userInfo: Notification userInfo dictionary input
    /// - Returns: A complete Notification object
    func object(_ object: Any? = nil, _ userInfo: [String: Any]? = nil) -> Notification {
        Notification(name: name, object: object, userInfo: infoDict(object, userInfo))
    }

    /// Generates a dictionary payload for use in a Notification object
    /// - Parameters:
    ///   - obj: The value assigned to the userInfo dictionary for the selected `key`
    ///   - userInfo: Existing userInfo dictionary, gets returned if it exists and contains values
    /// - Returns: A dictionary representing the `userInfo` object for a Notification post
    private func infoDict(_ obj: Any?, _ userInfo: [String: Any]?) -> [String: Any]? {
        var result = [String: Any]()
        if let userInfo = userInfo { result = userInfo }
        if self == .diffusionUpdate { result["kDiffusionUpdate"] = self }
        return result
    }
}
