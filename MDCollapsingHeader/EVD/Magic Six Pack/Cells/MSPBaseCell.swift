//
//  MSPBaseCell.swift
//  MDCollapsingHeader
//
//  Created by mad on 2/20/22.
//

import UIKit
import WHSportsbook

enum SixPackMarketType: String, Equatable, CaseIterable {
    case spread = "two-way-handicap", moneyLine = "standard-market-template", totalsOverUnder = "over-under"
    
    static func mktTypeScan(_ mkt: WHSportsbook.Market) -> SixPackMarketType? {
        let selections = mkt.selections.filter({ $0.price != nil })
        guard selections.compactMap({$0.price}).count > 0 else { return nil }
        
        if let result = SixPackMarketType.init(rawValue: mkt.type ?? "") { return result }
                    
        // Fall thru checks if market.type doesn't match
        if mkt.line == nil { return .moneyLine }
        let mktSelTypes = selections.map({$0.type.lowercased()})

        if mkt.line != nil, mktSelTypes.contains(where: { $0 == "home" || $0 == "away" }) { return .spread }
        if mktSelTypes.contains(where: { $0 == "over" || $0 == "under" }) { return .totalsOverUnder }
        
        return nil
    }
            
    var czLines: [CZLine] {
        switch self {
            case .moneyLine:       return .centerOnly([.init(.selectionPrice)])
            case .spread:          return .centerOnly([.init(.marketLine, .foreground), .init(.selectionPrice)])
            case .totalsOverUnder: return .centerOnly([.init(.marketOverUnder, .foreground), .init(.selectionPrice)])
        }
    }
}

protocol MSPBaseCell: AnyObject {
    var event: WHSportsbook.Event? { get set }
    
    var mainTitleLabel: UILabel! { get set }
    var topSpaceConstraint: NSLayoutConstraint! { get set }
    var sgpIcon: UIImageView! { get set }
    var teamNameLbls: [UILabel]! { get set }
    var teamScoresLbls: [UILabel]! { get set }
    var teamLogoImgs: [UIImageView]! { get set }
    
    var marketLabels: [UILabel]! { get set }
    var upperPackBtns: [UISixPackButton]! { get set }
    var lowerPackBtns: [UISixPackButton]! { get set }
    
    var allLabels: [UILabel] { get }
    var allSixPackBtns: [UISixPackButton] { get }
    var upperScoreLbl: UILabel { get }
    var lowerScoreLbl: UILabel { get }
    var upperLogo: UIImageView { get }
    var lowerLogo: UIImageView { get }
    var upperTeamLbl: UILabel { get }
    var lowerTeamLbl: UILabel { get }
    
    func removeEVDTapGesture()
    func configureMagicSixPackCell(_ event: WHSportsbook.Event, _ customMarkets: WHSportsbook.Markets?)
    func processSixPackMarkets(_ sixPackViewMarkets: WHSportsbook.Markets, _ mspType: MagicSixPackType)
    func loadLeftSideElements(_ event: WHSportsbook.Event)
    
    func configureStackviews(_ type: MagicSixPackType)
    func appendLiveScoresIfAccessible(_ text: String?) -> String
    func prepareForReuseBaseMethod()
    func hideColumnsCheck()
    func trimMarketTitlesCategory()
}

enum MSPPackButtonTag: Int {
    case upperLeft = 1, upperMid, upperRight, lowerLeft, lowerMid, lowerRight
    var isUpperPack: Bool { rawValue <= 3 }
    var columnNum: Int { [3, 1, 2][rawValue%3] }
    var selectionIdx: Int { isUpperPack ? 0 : 1 }
}

extension MSPBaseCell {
    
        
    func prepareForReuseBaseMethod() {
        
        allLabels.forEach({$0.attributedText = WHAttr.getTitle("")})
        teamLogoImgs.forEach({$0.image = nil})
        sgpIcon.isHidden = true
        allSixPackBtns.prepareButtonsForReuse()
    }
    
    // MARK: Mock configuration
    func configureMagicSixPackCell(_ event: WHSportsbook.Event, _ customMarkets: WHSportsbook.Markets? = nil) {
        self.event = event
        if vcTypeName == "MSPTableViewCell" {
            typealias czkType = CZK.ReusableAppWide.MagicSixPack.MSPTableViewCell
            getElem(czkType.dividerLine)?.isHidden = true
            getElem(czkType.titleImg)?.isHidden = true
        }
        
        if let byo = event.byoEligible { sgpIcon.isHidden = !byo }
        let mspType = MagicSixPackType(event.sportId, event.competitionName)
        
        configureStackviews(mspType)
        loadLeftSideElements(event)
    
        if let mkts = customMarkets {
            processSixPackMarkets(mkts, mspType)
        } else {
            let sixPackViewMarkets = event.markets.filter({ (($0.displayName ?? "").lowercased().replacePipes().contains("live") == (event.started ? true : false)) && (($0.sixPackView ?? false) || (SixPackMarketType.allCases.map({$0.rawValue}).contains(($0.type ?? "")) && $0.selections.count <= 3))})
            processSixPackMarkets(sixPackViewMarkets, mspType)
        }
    }
    
    func trimMarketTitlesCategory() {
        for (idx, label) in marketLabels.enumerated() {
            if let attrString = label.attributedText?.string, attrString.count > 6, let mkt = upperPackBtns[idx].market ?? lowerPackBtns[idx].market,
               var mktCatTitle = mkt.metadata?.marketCategoryName ?? mkt.metadata?.marketCategory?.replacingOccurrences(of: "_", with: " ").capExcludingNumbers {
                mktCatTitle.magicSixPackTrimSectionHeaderTitle()
                
                if attrString.contains(mktCatTitle) {
                    label.attributedText = WHAttr.getTitle(attrString.replacingOccurrences(of: "\(mktCatTitle) ", with: ""))
                }
            }
        }
    }
    
    internal func processSixPackMarkets(_ sixPackViewMarkets: WHSportsbook.Markets, _ mspType: MagicSixPackType) {
        let markets = sixPackViewMarkets.prefix(upperPackBtns.filter({!$0.isHidden}).count).map({$0})
        let buttons = (0..<upperPackBtns.count).map({[upperPackBtns[$0], lowerPackBtns[$0]]}).flatCmpt.filter({!$0.isHidden})
        
        buttons.forEach({ $0.setAttributedTitle(WHAttr.getAttrString(text: ""), for: .normal)})
        marketLabels.forEach({$0.attributedText = WHAttr.getTitle("")})
        
        let teams = event?.teamSelections
        let moneyLine = markets.first(where: {$0.type == "standard-market-template" && ($0.sixPackView ?? false)})
        
        let numRows = mspType.rhsRowCount()
        for (idx, mkt) in markets.enumerated() {
            if let mktType = SixPackMarketType.mktTypeScan(mkt) {
                let sels = mkt.selections.filter({$0.price != nil})
                let result = sels.map({ (CZPackButtonData(mktType.czLines), $0) })
                for (packIdx, pack) in result.enumerated() {
                    let btnIdx = (idx * numRows) + (numRows == 2 ? packIdx : 0)
                    guard btnIdx < buttons.count else { fatalError() }
                    let btn = buttons[btnIdx]
                    btn.configBtn(pack.0, mkt, pack.1, .init(.init(rawValue: btn.tag), .init(teams?.home.name, teams?.away.name), moneyLine))
                }
            } else {
                for packIdx in 0..<numRows {
                    let btnIdx = (idx * numRows) + (numRows == 2 ? packIdx : 0)
                    guard btnIdx < buttons.count else { fatalError() }
                    let btn = buttons[btnIdx]
                    btn.market = mkt
                    btn.setAttributedTitle(WHAttr.getAttrString(text: "-"), for: .normal)
                }
            }
            
            if mspType == .threePack, let lhsTitle = mkt.selections.first?.name.abbrv(), let rhsTitle = mkt.selections.last?.name.abbrv() {
                let titles = [lhsTitle, "DRAW", (rhsTitle == "UNDE" ? "UNDER" : rhsTitle)]
                titles.enumerated().forEach({ (idx, title) in marketLabels[idx].attributedText = WHAttr.getTitle(title) })
            } else {
                var title = (mkt.name ?? mkt.displayName ?? "???").replacePipes()
                if (event?.started ?? false), !title.lowercased().contains("live") { title += " LIVE" }
                marketLabels[idx].attributedText = WHAttr.getTitle(title)
            }
        }
    }
    
    internal func loadLeftSideElements(_ event: WHSportsbook.Event) {
        guard let teams = event.teamSelections else { return }
        let isUsMajorSport = ["NHL", "NFL", "NBA", "MLB"].contains(event.competitionName)
        
        if isUsMajorSport {
            if let data = event.teamData, let homeTeamAbbreviation = data.home.teamShortName?.split(separator: " ").first,
               let homeTeamNickName = data.home.teamNickName,
               let awayTeamAbbreviation = data.away.teamShortName?.split(separator: " ").first,
               let awayTeamNickName = data.away.teamNickName {
                
                upperTeamLbl.attributedText = WHAttr.getTeamNameTwoLines(String(awayTeamAbbreviation), awayTeamNickName)
                lowerTeamLbl.attributedText = WHAttr.getTeamNameTwoLines(String(homeTeamAbbreviation), homeTeamNickName)
            } else {
                upperTeamLbl.text = teams.away.name.replacePipes().abbrvTeam()
                lowerTeamLbl.text = teams.home.name.replacePipes().abbrvTeam()
            }
        } else {
            upperTeamLbl.text = teams.away.teamData?.teamName ?? teams.away.name.replacePipes()
            lowerTeamLbl.text = teams.home.teamData?.teamName ?? teams.home.name.replacePipes()
        }
        
//        gameMoreBetsLabel.text = ("\(teams.home.name.replacePipes()) AT \(teams.away.name.replacePipes())").uppercased()
        
        let shouldDisplayTeamLogo = ["NHL", "NFL", "NBA"].contains(event.competitionName)
        if shouldDisplayTeamLogo, (lowerTeamLbl.text?.count ?? 0) + (upperTeamLbl.text?.count ?? 0) > 1 {
            upperLogo.image = UIImage(named: teams.away.name.replacePipes().lowercased().replacingOccurrences(of: " ", with: "_"))
            lowerLogo.image = UIImage(named: teams.home.name.replacePipes().lowercased().replacingOccurrences(of: " ", with: "_"))
        } else {
            upperLogo.image = nil
            lowerLogo.image = nil
        }

        lowerLogo.isHidden = lowerLogo.image == nil
        upperLogo.isHidden = upperLogo.image == nil
        
        let fmtStr = event.startTime.timeIsOnTheHour ? "E ha" : "E h:mma"
        mainTitleLabel.text = fmtStr.dateFmtStr(event.startTime).uppercased()
        
        // Live game scores
        let scores = event.liveEventData?.scores.compactMap({ (team: $0.team, points: $0.points) }) ?? []
        if WHLookup.liveEnabledComps.contains(event.competitionName), let upperTeamScore = scores.first(where: { teams.away.name.replacePipes() == $0.team })?.points, let lowerTeamScore = scores.first(where: { teams.home.name.replacePipes() == $0.team })?.points {
            upperScoreLbl.text = upperTeamScore.strValue
            lowerScoreLbl.text = lowerTeamScore.strValue
        } else {
            upperScoreLbl.text = ""
            lowerScoreLbl.text = ""
        }

//        configureAccessibility(with: (teams.away.name.replacePipes(), teams.home.name.replacePipes()))
    }
    
    func hideColumnsCheck() {
        for (idx, btn) in upperPackBtns.enumerated() where btn.market == nil {
            let lowerBtn = lowerPackBtns[idx]
            if lowerBtn.market == nil {
                btn.isHidden = true
                lowerBtn.isHidden = true
                marketLabels[idx].isHidden = true
            }
        }
    }

    func configureStackviews(_ type: MagicSixPackType) {
        guard let mktTitles = marketLabels.first?.superview as? UIStackView,
                let upperBtns = upperPackBtns.first?.superview as? UIStackView,
                let lowerBtns = lowerPackBtns.first?.superview as? UIStackView else { return }
        
        mktTitles.isHidden = false
        upperBtns.isHidden = false

        switch type {
        case .twoPack:
            lowerBtns.isHidden = false
            mktTitles.arrangedSubviews[1...2].forEach({$0.isHidden = true})
            upperBtns.arrangedSubviews[1...2].forEach({$0.isHidden = true})
            lowerBtns.arrangedSubviews[1...2].forEach({$0.isHidden = true})
            lowerBtns.arrangedSubviews[0].isHidden = false
        case .threePack:
            lowerBtns.isHidden = true
            mktTitles.arrangedSubviews.forEach({$0.isHidden = false})
            upperBtns.arrangedSubviews.forEach({$0.isHidden = false})
            lowerBtns.arrangedSubviews.forEach({$0.isHidden = true})
        default:
            lowerBtns.isHidden = false
            mktTitles.arrangedSubviews.forEach({$0.isHidden = false})
            upperBtns.arrangedSubviews.forEach({$0.isHidden = false})
            lowerBtns.arrangedSubviews.forEach({$0.isHidden = false})
        }
    }
    
    func removeEVDTapGesture() {
        if (mainTitleLabel.superview?.gestureRecognizers?.count ?? 0) > 0 {
            upperTeamLbl.superview?.superview?.gestureRecognizers?.removeAll()
            mainTitleLabel.superview?.gestureRecognizers?.removeAll()
        }
    }
    
    func appendLiveScoresIfAccessible(_ text: String?) -> String {
        let text = text ?? ""
        guard !upperScoreLbl.isHidden && !lowerScoreLbl.isHidden,
            let topScore = upperScoreLbl.text,
            let bottomScore = lowerScoreLbl.text,
            !topScore.isEmpty && !bottomScore.isEmpty
        else {
            return text
        }
        let formattedText = !text.isEmpty ? "\(text). " : ""
        return "\(formattedText)Current score is \(bottomScore) to \(topScore)."
    }
}

extension WHSportsbook.Event {
    public var teamsDataMarket: WHSportsbook.Market? {
        let teamDataOnly = markets.first(where: { $0.selections.compactMap({$0.teamData?.teamName}).count > 0 })
        let typeOrTeamData = markets.first(where: { $0.selections.compactMap({["home", "away"].contains($0.type.lowercased())}).count > 0 })
        
        return teamDataOnly ?? typeOrTeamData
    }
    
    public var teamSelections: (home: WHSportsbook.Selection, away: WHSportsbook.Selection)? {
        guard let mkt = teamsDataMarket else { return nil }
        
        if let homeSel = mkt.selections.first(where: {$0.type == "home"}), let awaySel = mkt.selections.first(where: {$0.type == "away"}) {
            return (homeSel, awaySel)
        } else if let homeSel = homeTeam, let awaySel = awayTeam {
            return (homeSel, awaySel)
        } else if let homeSel = mkt.selections.last, let awaySel = mkt.selections.first, homeSel.id != awaySel.id {
            return (homeSel, awaySel)
        }
        return nil
    }
    
    public var teamData: (home: WHSportsbook.TeamData, away: WHSportsbook.TeamData)? {
        guard let teams = teamSelections else { return nil }
        if let homeData = teams.home.teamData, let awayData = teams.away.teamData {
            return (homeData, awayData)
        } else if let homeData = markets.compactMap({$0.selections}).flatCmpt.first(where: {($0.teamData?.teamName ?? "tdErr") == teams.home.name.replacePipes()})?.teamData,
                  let awayData = markets.compactMap({$0.selections}).flatCmpt.first(where: {($0.teamData?.teamName ?? "tdErr") == teams.away.name.replacePipes()})?.teamData {
            return (homeData, awayData)
        }
        
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
        var color: UIColor {[.successState, .errState, .brand].map{.black}[rawValue]}
    }
}

