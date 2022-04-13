//
//  EVDDataModels.swift
//  WH_CZR_SBK
//
//  Created by mad on 3/14/22.
//  Copyright © 2022 Caesar's Entertainment. All rights reserved.
//

import UIKit
import WHSportsbook

enum EVDMarketGroupType: String, CaseIterable, Equatable {
    case unGrouped, compact, sixPack = "alternativeSixPack", slider, tabs
    
    static var caseStrs: [String] { allCases.map({$0.rawValue}).dropFirst().map({$0}) }
}

struct EVDTabData: Equatable {
    let filterTabTitle : String
    let evdSections    : [EVDSectionData]
    var numSections    : Int { evdSections.count }
}

struct EVDSectionData: Equatable {
    let sectionHeaderTitle : String
    let evdRows            : [EVDRowData]
    var markets            : WHSportsbook.Markets { evdRows.map({ $0.market })}
    var rootMetadata       : WHSportsbook.Metadata? { evdRows.first?.metadata }
    var groupType          : EVDMarketGroupType? { (popularSixPackMarkets?.count ?? 0) > 0 ? .sixPack : evdRows.first?.groupType }
    let parentTabTitle     : String
    var popularSixPackMarkets : WHSportsbook.Markets? = nil
        
    static func nonGroupedMarkets(_ mkts: WHSportsbook.Markets, _ tabTitle: String) -> [EVDSectionData] {
        var result: [EVDSectionData] = []
        for mkt in mkts where mkt.selections.count > 0 {
            
            let cellType  : WHCell = mkt.selections.count < 4 ? .evdCompactCell : .evdSelectionCell
            var singleMkt : [EVDRowData] = mkt.selections.map({ .init($0.name.rp, nil, mkt, [$0]) })
            if cellType == .evdCompactCell {
                // If selections.count is less than EVD limit, only create one EVDRowData object (Compact EVD Cell)
                singleMkt = [.init("cmpt evd cell", nil, mkt, mkt.selections, nil, cellType)]
            }
            
            result.append(.init((mkt.name ?? mkt.displayName ?? mkt.selections.first?.name ?? "").rp, singleMkt, tabTitle))
        }
        return result
    }
    
    static func popularSixPack(_ mkts: WHSportsbook.Markets, _ tabTitle: String) -> EVDSectionData {
        .init("", [], tabTitle, mkts)
    }
    
    init(_ sectHeaderTitle: String, _ evdRows: [EVDRowData], _ parentTabText: String, _ popularSixPackMkts: WHSportsbook.Markets? = nil) {
        self.sectionHeaderTitle    = sectHeaderTitle
        self.evdRows               = evdRows
        self.parentTabTitle        = parentTabText
        self.popularSixPackMarkets = popularSixPackMkts
    }
}

struct EVDRowData: Equatable {
    let titleText     : String
    let metadata      : WHSportsbook.Metadata?
    let market        : WHSportsbook.Market
    let selections    : WHSportsbook.Selections
    var groupType     : EVDMarketGroupType? { .init(rawValue: metadata?.marketDisplayType ?? "err") }
    var tabFilterText : String?
    var cellType      : WHCell
    
    init(_ title: String, _ metadata: WHSportsbook.Metadata?, _ mkt: WHSportsbook.Market, _ sels: WHSportsbook.Selections, _ tabFilterTxt: String? = nil, _ cellType: WHCell? = nil) {
        self.titleText     = title
        self.metadata      = metadata
        self.market        = mkt
        self.selections    = sels
        self.tabFilterText = tabFilterTxt
        self.cellType = cellType ?? .evdSelectionCell
    }
}

protocol EVDDataAdjustDelegate: AnyObject {
    func evdDataWasAdjusted(_ dataKey: String, _ section: Int, _ adjustedData: EVDSectionData?)
}

protocol EVDDataAdjustable: AnyObject {
    var filterTabIndex  : Int { get set }
    var sectionIndex    : Int { get set }
    var originalData    : EVDSectionData? { get set }
    var delegate        : EVDDataAdjustDelegate? { get set }
    var adjustedDataKey : String { get }
    
    func configDataAdjustController(_ filterTab: Int, _ section: Int, _ originalData:EVDSectionData, _ adjustedData: EVDSectionData?, _ delegate: EVDDataAdjustDelegate)
}

extension EVDDataAdjustable {
    var adjustedDataKey : String { "\(filterTabIndex),\(sectionIndex)" }
}

enum EVDDebugJSONFile: String { case tabsA = "tabs-example", tabsB = "tabs-example2", sliderA = "sliderMarketsEvent", sliderB = "sliderMarketsEvent2" }

public struct EventDetailsLiveScoreboard: Codable {
    let eventId     : String
    let launch_link : String
    let height      : Int
    let sport       : String
}
