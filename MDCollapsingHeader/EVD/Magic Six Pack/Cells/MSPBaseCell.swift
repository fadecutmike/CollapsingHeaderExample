//
//  MSPBaseCell.swift
//  WH_CZR_SBK
//
//  Created by mad on 2/14/22.
//  Copyright © 2022 Caesar's Entertainment. All rights reserved.
//

import UIKit
import WHSportsbook

enum SixPackMarketType: String, Equatable, CaseIterable {
    case spread = "two-way-handicap", moneyLine = "standard-market-template", totalsOverUnder = "over-under", other
    
    static func mktTypeScan(_ mkt: WHSportsbook.Market) -> SixPackMarketType {

        var mktType = (mkt.type ?? mkt.name ?? mkt.displayName)?.rpLow ?? ""
        if !Self.allCases.map({$0.rawValue}).contains(mktType) {
            if mktType.contains("spread") {
                mktType = Self.spread.rawValue
            } else if mktType.contains("line") {
                mktType = Self.moneyLine.rawValue
            } else if mktType.contains("total") || mktType.contains("point") {
                mktType = Self.totalsOverUnder.rawValue
            }
        }

        if let result = SixPackMarketType.init(rawValue: mktType) { return result }

        // Fall thru checks if market.type doesn't match
        if mkt.line == nil { return .moneyLine }
        let mktSelTypes = mkt.selections.compactMap({$0.type.rpLow})

        if mkt.line != nil, mktSelTypes.contains(where: { ["home", "away", "draw"].contains($0) }) { return .spread }
        if mktSelTypes.contains(where: { ["over", "under"].contains($0) }) { return .totalsOverUnder }

        return .other
    }
    
    var czValSource: (lineOne: CZSourceType, lineTwo: CZSourceType?) {
        switch self {
            case .moneyLine:       return (.selectionPrice, nil)
            case .spread:          return (.marketLine, .selectionPrice)
            case .totalsOverUnder: return (.marketOverUnder, .selectionPrice)
            case .other:           return (.selectionName, nil)
        }
    }
    
    var czLines: [CZLine] {
        switch self {
            case .moneyLine:       return .centerOnly([.init(.selectionPrice)])
            case .spread:          return .centerOnly([.init(.marketLine, .foreground), .init(.selectionPrice)])
            case .totalsOverUnder: return .centerOnly([.init(.marketOverUnder, .foreground), .init(.selectionPrice)])
            case .other:           return .centerOnly([.init(.selectionName)])
        }
    }
}

enum MSPMainLabelState: Int, Equatable {
    case standard, textOnly, allHidden, liveMode
    
    var sgpIconDisabled: Bool { self != .standard }
}

typealias TeamNames = (teamOne: String, teamTwo: String)

protocol MSPBaseCell: UIView {
    var event              : WHSportsbook.Event?        { get set }
    
    var topSpaceConstraint : NSLayoutConstraint! { get set }
    var mainTitleLabel     : UILabel!       { get set }
    var sgpIcon            : UIImageView!   { get set }
    var teamNameLbls       : [UILabel]!     { get set }
    var teamScoresLbls     : [UILabel]!     { get set }
    var teamLogoImgs       : [UIImageView]! { get set }
    
    var upperPackBtns      : [UISixPackButton]! { get set }
    var lowerPackBtns      : [UISixPackButton]! { get set }
    var allSixPackBtns     : [UISixPackButton]  { get }
    var marketLabels       : [UILabel]!         { get set }
    
    var allLabels          : [UILabel]   { get }
    var upperScoreLbl      : UILabel     { get }
    var lowerScoreLbl      : UILabel     { get }
    var upperTeamLbl       : UILabel     { get }
    var lowerTeamLbl       : UILabel     { get }
    var upperLogo          : UIImageView { get }
    var lowerLogo          : UIImageView { get }
    var mspLabelState      : MSPMainLabelState { get set }
    var teamNamesData      : TeamNamesData?    { get set }
    var teamNames          : TeamNames? { get set }
    
    func removeEVDTapGesture()
    func configureMagicSixPackCell(_ event: WHSportsbook.Event, _ labelState: MSPMainLabelState, _ customMarkets: WHSportsbook.Markets?)
    func processSixPackMarkets(_ mspMarkets: WHSportsbook.Markets)
    func loadLeftSideElements(_ event: WHSportsbook.Event)
    
    func prepareForReuseBaseMethod()
    func trimMarketTitlesCategory()
}

enum MSPPackButtonTag: Int {
    case upperLeft = 1, upperMid, upperRight, lowerLeft, lowerMid, lowerRight
    var isUpperPack    : Bool { rawValue <= 3 }
    var columnNum      : Int { [3, 1, 2][rawValue%3] }
    var mktLabelIdx    : Int { columnNum - 1 }
    var oppositeBtnIdx : Int { [0, 0, 1, 2, 0, 1, 2][rawValue] }
}

internal let ignoreNames = ["over", "under", "draw"]//, "yes", "no"]

extension MSPBaseCell {
    
    func prepareForReuseBaseMethod() {
        event = nil
        allLabels.forEach({$0.attributedText = nil})
        upperPackBtns.forEach({$0.prepBtnForReuse()})
        lowerPackBtns.forEach({$0.prepBtnForReuse()})
        teamLogoImgs.forEach({$0.image = nil})
        teamNames = nil
        teamNamesData = nil
        sgpIcon.isHidden = true
    }
    
    // MARK: Mock configuration
    func configureMagicSixPackCell(_ event: WHSportsbook.Event, _ labelState: MSPMainLabelState = .standard, _ customMarkets: WHSportsbook.Markets? = nil) {
        self.event = event
        self.mspLabelState = labelState
        
        if labelState.sgpIconDisabled {
            sgpIcon.isHidden = true
        } else if let byo = event.byoEligible {
            sgpIcon.isHidden = !byo
        }
        
        if let mkts = customMarkets?.unique() {
            processSixPackMarkets(mkts)
        } else {
            let mktsFiltered = event.markets.filter({ ($0.sixPackView ?? false) })
            if mktsFiltered.count == 0 {
                processSixPackMarkets(event.markets)
            } else {
                processSixPackMarkets(mktsFiltered)
            }
        }
        
        loadLeftSideElements(event)
    }
    
    internal func processSixPackMarkets(_ mspMarkets: WHSportsbook.Markets) {
        // Reset/Unhide all elements
        allSixPackBtns.forEach({ $0.setAttributedTitle(nil, for: .normal)})
        allLabels.forEach({ $0.attributedText = nil })
        teamNames = nil
        teamNamesData = nil
        unhideAllElements()
        
        let rawMarkets = mspMarkets.count > 0 ? mspMarkets : (event?.markets ?? [])
        if let firstTeamNamesMarket = rawMarkets.first(where: { $0.selections.compactMap({$0.name.rp}).filter({ !ignoreNames.contains($0.lowercased()) }).unique().count > 1 }), firstTeamNamesMarket.selections.count > 1, let teamOne = firstTeamNamesMarket.selections.first, let teamTwo = firstTeamNamesMarket.selections.last {
            
            let isUsMajorSport = ["NHL", "NFL", "NBA", "MLB"].contains(event?.competitionName ?? "err")
            if ["home", "away"].contains(teamOne.name.rpLow) || ["home", "away"].contains(teamTwo.name.rpLow), let eventTeamNames = event?.name.splitEventNameIntoTeamNames() {
                teamNames = eventTeamNames
            } else {
                teamNames = (teamOne.name.rp, teamTwo.name.rp)
            }
            
            if isUsMajorSport {
                let tdAll = rawMarkets.compactMap({$0.selections.compactMap({$0.teamData})}).flatCmpt.unique().map({$0})
                if tdAll.count > 1, let tDataOne = tdAll.first(where: {$0.teamName == teamNames?.teamOne}), let tDataTwo = tdAll.first(where: {$0.teamName == teamNames?.teamTwo}) {
                    teamNamesData = (tDataOne, tDataTwo)
                }
                
                let tdAllEvMkts = (event?.markets ?? []).compactMap({$0.selections.compactMap({$0.teamData})}).flatCmpt.unique().map({$0})
                if teamNamesData == nil, tdAllEvMkts.count > 1, let tDataOne = tdAllEvMkts.first(where: {$0.teamName == teamNames?.teamOne}), let tDataTwo = tdAllEvMkts.first(where: {$0.teamName == teamNames?.teamTwo}) {
                    teamNamesData = (tDataOne, tDataTwo)
                }
            } else {
                teamNamesData = nil
            }
        }
        
        let rawFiltered = rawMarkets.filter({[$0].mspMarketTitle.rpLow.contains("live") == (event?.started ?? false)})
        let mspMarkets  = (rawFiltered.count > 0 ? rawFiltered : rawMarkets).prefix(3).map({$0})
        let maxSel      = mspMarkets.map({$0.selections.count}).max() ?? 0
        
        guard let mktOne = mspMarkets.first(where: {$0.selections.count == maxSel}), mktOne.selections.count > 0 else { return }
        lowerTeamLbl.superview?.isHidden = mspMarkets.count == 1 && mktOne.selections.count == 1
        
        // If there is only one market, and either 3 or 1 total selections, the cell will process as a single row. Otherwise two rows will be used.
        let isSingleRow = mspMarkets.count == 1 && (event?.sportId ?? "") != "golf" && [1, 3].contains(mktOne.selections.count)
        
        if isSingleRow {
            lowerPackBtns.forEach({$0.isHidden = true})
            lowerPackBtns.first?.superview?.isHidden = true // Hide all buttons on the second or lower row

            if teamNames == nil, mktOne.selections.count == 1, let evName = event?.name.rp {
                marketLabels[0].attributedText = WHAttr.getMarketTitle(evName)
                if let tOne = mktOne.selections.first?.name.rp, let tTwo = mktOne.selections.last?.name.rp { teamNames = (tOne, tTwo) }
            } else {
                for (idx, sel) in mktOne.selections.enumerated() { marketLabels[idx].attributedText = WHAttr.getMarketTitle(sel.name.rp.abbrv()) }
            }
            
            hideColumnsCheck()
            
            let btns = upperPackBtns.filter({!$0.isHidden})
            let mktType = SixPackMarketType.mktTypeScan(mktOne)
            
            for (idx, btn) in btns.enumerated() where idx < mktOne.selections.count {
                let sel = mktOne.selections[idx]
                let btnData = CZPackButtonData(mktType.czLines)
                
                guard let btnTag = MSPPackButtonTag(rawValue: btn.tag) else { fatalError() }
                btn.configBtn(btnData, mktOne, sel, .init(btnTag, event?.getMoneyLineMkt(mspMarkets)))
//                btn.highlightIndicatorBar.alpha = WHLookup.highlightedSelectionIds.contains(sel.id) ? 1.0 : 0.0
            }
        } else {
            // Process and load in Market titles, then hide elements without a related market title
            let mktTitles = mspMarkets.compactMap({WHAttr.getMarketTitle([$0].mspMarketTitle)})
            mktTitles.enumerated().forEach({ marketLabels[$0.offset].attributedText = $0.element })
            
            hideColumnsCheck()
            
            let columnBtnGroups: [[UISixPackButton]] = [[upperPackBtns[0], lowerPackBtns[0]], [upperPackBtns[1], lowerPackBtns[1]], [upperPackBtns[2], lowerPackBtns[2]]].filter({$0.map({$0.isHidden}).allSatisfy({!$0}) })
            guard columnBtnGroups.count == mspMarkets.count else { fatalError() }
            
            for (idx, btnGroup) in columnBtnGroups.enumerated() where idx < mspMarkets.count {
                let mkt = mspMarkets[idx]
                let mktType = SixPackMarketType.mktTypeScan(mkt)
                
                for (bIdx, btn) in btnGroup.enumerated() where bIdx < mkt.selections.count {
                    let sel = mkt.selections[bIdx]
                    let btnData = CZPackButtonData(mktType.czLines)
                    
                    guard let btnTag = MSPPackButtonTag(rawValue: btn.tag) else { fatalError() }
                    btn.configBtn(btnData, mkt, sel, .init(btnTag, event?.getMoneyLineMkt(mspMarkets)))
//                    btn.highlightIndicatorBar.alpha = WHLookup.highlightedSelectionIds.contains(sel.id) ? 1.0 : 0.0
                }
            }
        }
    }
    
    private func loadNameLabels() {
        
        guard upperTeamLbl.labelNeedsContent || lowerTeamLbl.labelNeedsContent else { return }
                
        let isUsMajorSport = ["NHL", "NFL", "NBA", "MLB"].contains(event?.competitionName ?? "err")
        guard let upperTeamName = teamNames?.teamOne, let lowerTeamName = teamNames?.teamTwo else { failsafeLoadNameLabels(); return }
        
        if isUsMajorSport {
            let sels = mspSels
            
            if upperTeamLbl.labelNeedsContent, let upperAbbrv = teamNamesData?.teamOne ?? sels.upper.first(where: {$0.teamData != nil})?.teamData,
               let nameA = upperAbbrv.teamShortName?.split(separator: " ").first, let nameB = upperAbbrv.teamNickName {
                upperTeamLbl.attributedText = WHAttr.getTeamNameTwoLines(String(nameA), nameB)
            }
            
            if lowerTeamLbl.labelNeedsContent, let lowerAbbrv = sels.lower.first(where: {$0.teamData != nil})?.teamData,
               let nameA = lowerAbbrv.teamShortName?.split(separator: " ").first, let nameB = lowerAbbrv.teamNickName {
                lowerTeamLbl.attributedText = WHAttr.getTeamNameTwoLines(String(nameA), nameB)
            }
            
            if upperTeamLbl.labelNeedsContent { upperTeamLbl.attributedText = WHAttr.getTitle(upperTeamName.abbrvTeam()) }
            if lowerTeamLbl.labelNeedsContent { lowerTeamLbl.attributedText = WHAttr.getTitle(lowerTeamName.abbrvTeam()) }
        } else {
            if upperTeamLbl.labelNeedsContent { upperTeamLbl.attributedText = WHAttr.getTitle(upperTeamName) }
            if lowerTeamLbl.labelNeedsContent { lowerTeamLbl.attributedText = WHAttr.getTitle(lowerTeamName) }
        }
        
        failsafeLoadNameLabels()
    }
    
    private var mspSels: (upper: WHSportsbook.Selections, lower: WHSportsbook.Selections) {
        let isSingleRow = lowerPackBtns.map({$0.isHidden}).allSatisfy({$0})
        
        let visibleUpperBtns = upperPackBtns.filter({!$0.isHidden})
        let visibleLowerBtns = lowerPackBtns.filter({!$0.isHidden})
        let upperSels = (isSingleRow ? [visibleUpperBtns.first?.selection] : visibleUpperBtns.compactMap({$0.selection})).compactMap({$0})
        let lowerSels = (isSingleRow ? [visibleUpperBtns.last?.selection] : visibleLowerBtns.compactMap({$0.selection})).compactMap({$0})
        
        return (upperSels, lowerSels)
    }
        
    private func failsafeLoadNameLabels() {
        guard upperTeamLbl.labelNeedsContent || lowerTeamLbl.labelNeedsContent else { return }
        
        let sels = mspSels
        let isUsMajorSport = ["NHL", "NFL", "NBA", "MLB"].contains(event?.competitionName ?? "err")
        let eventTeamNames = event?.name.splitEventNameIntoTeamNames()
        let upperTeamName = sels.upper.first(where: { !ignoreNames.contains($0.name.rpLow) && $0.name.count > 2 })?.name.rp ?? eventTeamNames?.teamOne ?? "upperTeam Failed"
        let lowerTeamName = sels.lower.first(where: { !ignoreNames.contains($0.name.rpLow) && $0.name.count > 2 })?.name.rp ?? eventTeamNames?.teamTwo ?? "lowerTeam Failed"
        
        if isUsMajorSport {
            if upperTeamLbl.labelNeedsContent, let upperAbbrv = sels.upper.first(where: {$0.teamData != nil})?.teamData,
                let nameA = upperAbbrv.teamShortName?.split(separator: " ").first, let nameB = upperAbbrv.teamNickName {
                upperTeamLbl.attributedText = WHAttr.getTeamNameTwoLines(String(nameA), nameB)
            }
            
            if lowerTeamLbl.labelNeedsContent, let lowerAbbrv = sels.lower.first(where: {$0.teamData != nil})?.teamData,
                let nameA = lowerAbbrv.teamShortName?.split(separator: " ").first, let nameB = lowerAbbrv.teamNickName {
                lowerTeamLbl.attributedText = WHAttr.getTeamNameTwoLines(String(nameA), nameB)
            }
                        
            if upperTeamLbl.labelNeedsContent { upperTeamLbl.attributedText = WHAttr.getTitle(upperTeamName.abbrvTeam()) }
            if lowerTeamLbl.labelNeedsContent { lowerTeamLbl.attributedText = WHAttr.getTitle(lowerTeamName.abbrvTeam()) }
        } else {
            if upperTeamLbl.labelNeedsContent { upperTeamLbl.attributedText = WHAttr.getTitle(upperTeamName) }
            if lowerTeamLbl.labelNeedsContent { lowerTeamLbl.attributedText = WHAttr.getTitle(lowerTeamName) }
        }
    }
    
    private func loadLogoImages() {
        let sels = mspSels
        let shouldDisplayTeamLogo = ["NHL", "NFL", "NBA", "MLB"].contains(event?.competitionName ?? "err")
        if shouldDisplayTeamLogo, (lowerTeamLbl.stringCount + upperTeamLbl.stringCount) > 1 {
            upperLogo.image = UIImage(named: sels.upper.first(where: { $0.name.count > 1 })?.name.rpLow.replacingOccurrences(of: " ", with: "_") ?? "upperLbl Failed")
            lowerLogo.image = UIImage(named: sels.lower.first(where: { $0.name.count > 1 })?.name.rpLow.replacingOccurrences(of: " ", with: "_") ?? "lowerLbl Failed")
        } else {
            upperLogo.image = nil
            lowerLogo.image = nil
        }

        lowerLogo.isHidden = lowerLogo.image == nil
        upperLogo.isHidden = upperLogo.image == nil
    }
    
    private func unhideAllElements() {
        guard let mktTitles = marketLabels.first?.superview as? UIStackView,
              let upperBtns = upperPackBtns.first?.superview as? UIStackView,
              let lowerBtns = lowerPackBtns.first?.superview as? UIStackView else { return }
        
        mktTitles.isHidden = false
        upperBtns.isHidden = false
        lowerBtns.isHidden = false
        mktTitles.arrangedSubviews.forEach({$0.isHidden = false})
        upperBtns.arrangedSubviews.forEach({$0.isHidden = false})
        lowerBtns.arrangedSubviews.forEach({$0.isHidden = false})
    }
    
    internal func loadLeftSideElements(_ event: WHSportsbook.Event) {
        loadNameLabels()
        loadLogoImages()
        
        if mspLabelState == .allHidden {
            mainTitleLabel.text = ""
        } else {
            let fmtStr = event.startTime.timeIsOnTheHour ? "E ha" : "E h:mma"
            mainTitleLabel.text = fmtStr.dateFmtStr(event.startTime).uppercased()
        }
        let sels = mspSels
        
        // Live game scores
        let scores = event.liveEventData?.scores.compactMap({ (team: $0.team, points: $0.points) }) ?? []
        let upperTeam = sels.upper.first(where: { $0.name.count > 1 })?.name.rp ?? "upperLbl Failed"
        let lowerTeam = sels.lower.first(where: { $0.name.count > 1 })?.name.rp ?? "lowerLbl Failed"
        
        upperScoreLbl.text = ""
        lowerScoreLbl.text = ""
    }
    
    private func hideColumnsCheck() {
        for mktLbl in marketLabels where mktLbl.textIsEmpty {
            let lblColumnIdx = mktLbl.tag/100 - 1
            guard (0...2).contains(lblColumnIdx) else { fatalError() }
            
            let btns = [upperPackBtns[lblColumnIdx]] + [lowerPackBtns[lblColumnIdx]]
            btns.forEach({$0.isHidden = true})
            mktLbl.isHidden = true
        }
    }
    
    func trimMarketTitlesCategory() {
        for (idx, label) in marketLabels.enumerated() {
            if let attrString = label.attributedText?.string, attrString.count > 6, let mkt = upperPackBtns[idx].market ?? lowerPackBtns[idx].market,
               var mktCatTitle = mkt.metadata?.marketCategoryName ?? mkt.metadata?.marketCategory?.replacingOccurrences(of: "_", with: " ").capExcludingNumbers {
                mktCatTitle.magicSixPackTrimSectionHeaderTitle()
                
                if attrString.contains(mktCatTitle) {
                    label.attributedText = WHAttr.getMarketTitle(attrString.replacingOccurrences(of: "\(mktCatTitle) ", with: ""))
                }
            }
        }
    }
    
    func removeEVDTapGesture() {
        if (mainTitleLabel.superview?.gestureRecognizers?.count ?? 0) > 0 {
            upperTeamLbl.superview?.superview?.gestureRecognizers?.removeAll()
            mainTitleLabel.superview?.gestureRecognizers?.removeAll()
        }
    }
}

extension WHSportsbook.Markets {
    public var mspMarketTitle: String {
        var result: String = "-"
        if let mktCatName = compactMap({ $0.metadata?.marketCategoryName }).first(where: {$0.count > 2}) {
            result = mktCatName
        } else if let mktTitle = compactMap({ $0.name ?? $0.displayName ?? $0.selections.first?.name }).first(where: {$0.count > 2}) {
            result = mktTitle
        }
        
        return result.rp
    }
}

extension WHSportsbook.Event {
    
    func getMoneyLineMkt(_ mkts: WHSportsbook.Markets) -> WHSportsbook.Market? {
        
        let moneylineType = SixPackMarketType.moneyLine.rawValue
        let mktsA = mkts.filter({$0.type == moneylineType && ($0.sixPackView ?? false)})
        if mktsA.count > 0, let result = mktsA.first(where: { [$0].mspMarketTitle.rpLow.contains("live") == started }) { return result }
        
        let mktsB = markets.filter({$0.type == moneylineType && ($0.sixPackView ?? false)})
        if mktsB.count > 0, let result = mktsB.first(where: { [$0].mspMarketTitle.rpLow.contains("live") == started }) { return result }
                               
        let mktsC = mkts.filter({ ([$0].mspMarketTitle.rpLow.contains("money line") || [$0].mspMarketTitle.rpLow.contains("money") || [$0].mspMarketTitle.rpLow.contains("line")) && ($0.sixPackView ?? false)})
        if mktsC.count > 0, let result = mktsC.first(where: { [$0].mspMarketTitle.rpLow.contains("live") == started }) { return result }
        
        let mktsD = markets.filter({ ([$0].mspMarketTitle.rpLow.contains("money line") || [$0].mspMarketTitle.rpLow.contains("money") || [$0].mspMarketTitle.rpLow.contains("line")) && ($0.sixPackView ?? false)})
        if mktsD.count > 0, let result = mktsD.first(where: { [$0].mspMarketTitle.rpLow.contains("live") == started }) { return result }
        
        let mktsE = mkts.filter({$0.type == moneylineType && ($0.sixPackView ?? false)})
        if mktsE.count > 0, let result = mktsE.first(where: { $0.display && $0.selections.count > 0 }) { return result }
        
        let mktsF = markets.filter({$0.type == moneylineType && ($0.sixPackView ?? false)})
        if mktsF.count > 0, let result = mktsF.first(where: { $0.display && $0.selections.count > 0 }) { return result }
        
        return nil
    }
}

// MARK: - Helpers to easily access particular elements

extension MSPBaseCell {
    
    var allLabels: [UILabel] { [mainTitleLabel] + teamNameLbls + teamScoresLbls + marketLabels }
    var allSixPackBtns: [UISixPackButton] { upperPackBtns + lowerPackBtns }
    
    var upperScoreLbl: UILabel {
        guard let result = teamScoresLbls.first else { fatalError() }
        return result
    }
    
    var lowerScoreLbl: UILabel {
        guard let result = teamScoresLbls.last else { fatalError() }
        return result
    }
    
    var upperLogo: UIImageView {
        guard let result = teamLogoImgs.first else { fatalError() }
        return result
    }
    
    var lowerLogo: UIImageView {
        guard let result = teamLogoImgs.last else { fatalError() }
        return result
    }
    
    var upperTeamLbl: UILabel {
        guard let result = teamNameLbls.first else { fatalError() }
        return result
    }
    
    var lowerTeamLbl: UILabel {
        guard let result = teamNameLbls.last else { fatalError() }
        return result
    }
}

/// Protocol that tableView or collectionView Cells using UISixPackButtons can conform to for seamless diffusion subscriptions as markets/selections appear on screen
/// Also enables easy Diffusion updates for cells on screen with updates available
protocol UpdatablePackElement {
    var spBtns: [UISixPackButton] { get }
    func applyUpdateAnimations(_ allUpdates: inout Set<CZPackVisualUpdate>)
}

extension UpdatablePackElement where Self: MSPBaseCell {
    var spBtns: [UISixPackButton] { allSixPackBtns }
}
 
extension UpdatablePackElement {
    func applyUpdateAnimations(_ allUpdates: inout Set<CZPackVisualUpdate>) {
        let btns = spBtns.filter({!$0.isHidden})
        
        var updatesToSubtract = Set<CZPackVisualUpdate>()
        for btn in btns {
            if let selUpdate = allUpdates.first(where: {$0.id == btn.selection?.id}) {
                btn.updateButtonBg(selUpdate.updateType.color)
                updatesToSubtract.insert(selUpdate)
                if let mktUpdate = allUpdates.first(where: {$0.id == btn.market?.id}) { updatesToSubtract.insert(mktUpdate) }
            } else if let mktUpdate = allUpdates.first(where: {$0.id == btn.market?.id}) {
                btn.updateButtonBg(mktUpdate.updateType.color)
                updatesToSubtract.insert(mktUpdate)
            }
        }
        allUpdates.subtract(updatesToSubtract)
    }
}

/// MagicSixPack, UISixPackBtn, Futures Selections, EVD Selections, etc. Anywhere a button that can be tapped to place a bet
struct CZPackVisualUpdate: Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: CZPackVisualUpdate, rhs: CZPackVisualUpdate) -> Bool { lhs.id == rhs.id }
    
    let id: String
    let updateType: ChangeType
    let updateDataType: WHDSubscribeType
    
    init(_ updateId: String, _ oldVal: Double, _ newVal: Double, _ dataType: WHDSubscribeType) {
        self.id = updateId
        self.updateType = newVal==oldVal ? .same : newVal>oldVal ? .increased : .decreased
        self.updateDataType = dataType
    }
    
    init(_ mktUpdate: DiffusionMarketUpdate, _ oldVal: Double)    { self.init(mktUpdate.id, oldVal, mktUpdate.line ?? 0, .marketOnly) }
    init(_ selUpdate: DiffusionSelectionUpdate, _ oldVal: Double) { self.init(selUpdate.id, oldVal, selUpdate.price.d, .selectionOnly) }
    
    enum ChangeType: Int {
        case increased, decreased, same
        var color: UIColor {[.successState, .errState, .brand].map{.czkColor($0)}[rawValue]}
    }
}
