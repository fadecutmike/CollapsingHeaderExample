//
//  EventDetailsViewModel.swift
//  WH_CZR_SBK
//
//  Created by Michael Dimore on 10/7/20.
//  Copyright © 2020 Caesar's Entertainment. All rights reserved.
//

import UIKit
import WHSportsbook
import WHNetwork

protocol EventDetailsDelegate: AnyObject {
    func eventDetailLoaded()
    var tableViewRef: UITableView? { get }
}

private let preGameInfoHeight : CGFloat = 60.0 + 8.0 // Plus spacing
let sboardBtnHeight           : CGFloat = 42.0
private let filterViewHeight  : CGFloat = 60.0

enum LiftingHeaderState: Equatable {
    case preGame,                // non-live event
         liveNoScoreboard,       // live event without scoreboard
         scoreboardUp,           // live event w/scoreboard in the raised position (fully collapsed)
         scoreboardDown(CGFloat) // live event w/scoreboard in the lowered position (fully expanded). Takes a height value representing the scoreboard height for calculating maxHeight.
    
    var caseName: String {
        let result = String(describing: self)
        return !result.contains("(") ? result : Mirror(reflecting: self).children.first?.label ?? "failed"
    }

    static func == (lhs: LiftingHeaderState, rhs: LiftingHeaderState) -> Bool { lhs.caseName.prefix(12) == rhs.caseName.prefix(12) }
    
    /// The minimum or 'fully collapsed' header height
    var minHeight: CGFloat {
        switch self {
        case .preGame, .liveNoScoreboard:    return filterViewHeight
        case .scoreboardUp, .scoreboardDown: return sboardBtnHeight + filterViewHeight
        }
    }
    
    /// The maximum or 'fully expanded' header height
    var maxHeight: CGFloat {
        switch self {
        case .preGame:          return preGameInfoHeight + 8.0 + filterViewHeight
        case .liveNoScoreboard: return filterViewHeight
        case .scoreboardUp:     return sboardBtnHeight + filterViewHeight
        case .scoreboardDown(let sbHeight): return sbHeight + sboardBtnHeight + filterViewHeight
        }
    }
}

class EventDetailsViewModel {
    
    // MARK: - EVD ViewModel Base Parameters
    
    weak var delegate  : EventDetailsDelegate?
    var eventDetails   : WHSportsbook.Event?
    var eventId        : String = ""
    var navBarLiveIcon : UIImage = .init(named: "evdNavBarLiveIcon")!
    
    // MARK: - EVD LiftingHeader
    
    var headerVC: EVDLiftingHeaderVC? {
        didSet { startEVDLoad() }
    }
    
    // MARK: - EVD LiftingHeader Scroll/Lifting Parameters
    
    /// Scoreboard height as returned from network request response
    var sbHeight: CGFloat { headerVC?.viewModel.scoreboardHeight ?? 0.0 }
    
    /// The largest size the Header can expand to
    var maxOperatingHeight: CGFloat = 60.0

    /// The smallest height the Header will collapse to
    var minOperatingHeight: CGFloat = 0.0
    
    /// Tracks the contentOffset.y value of the tableView and applies an adjustment to account for LiftingHeader so only positive values starting at zero are returned
    var lastScrollOffsetClean: CGFloat = 0.0
    
    /// A parameter for keeping track of the point when the tableView begins scrolling upward to collapse the LiftingHeader
    var lastScrollReverseOffset: CGFloat?
    
    // MARK: - EVD TableView and Data Parameters

    var evdTabsData   : [EVDTabData] = []
    var teamDataGroup : (team1: WHSportsbook.TeamData, team2: WHSportsbook.TeamData)?
    
    private(set) var selectedMktColIndex: Int = 0
    
    func setSelectedMktCollectionIndex(_ idx: Int) {
        selectedMktColIndex = idx < evdTabsData.count ? idx : max(0, evdTabsData.count-1)
    }
    
    private(set) var collapsedSections: Set<Int> = .init()
    func clearCollapsedSections() { collapsedSections.removeAll() }
    
    func updateCollapsedSection(_ section: Int) {
        sectionsShowingAllRows.remove(section)
        if collapsedSections.contains(section) {
            collapsedSections.remove(section)
        } else {
            collapsedSections.insert(section)
        }
    }
    
    private(set) var sectionsShowingAllRows: Set<Int> = .init()
    
    func clearSectionsShowingAllRows() { sectionsShowingAllRows.removeAll() }
    func updateShowingAllRowsSection(_ section: Int) {
        if sectionsShowingAllRows.contains(section) {
            sectionsShowingAllRows.remove(section)
        } else {
            sectionsShowingAllRows.insert(section)
        }
    }
    
    init(_ eventId: String, _ delegate: EventDetailsDelegate?) {
        self.eventId  = eventId
        self.delegate = delegate
        if eventId.count > 10, delegate != nil {
            print("\n\n\t\t evd eventId: \(eventId)\n\n")
        }
    }
}

extension WHSportsbook.Market {
    var isAlternativeMarket: Bool { movingLines != nil }
}

extension EventDetailsViewModel {
        
    func updateLiftingHeader(_ newState: LiftingHeaderState) {
        minOperatingHeight = newState.minHeight
        maxOperatingHeight = newState.maxHeight
        
        if let vc = delegate as? EventDetailsViewController {
            vc.updateLiftingHeaderNoAnimation()
        }
    }
    
    var navBarAttributedTitle: NSAttributedString {
        guard let ev = eventDetails else { return .init(string: "EVD event not loaded...") }
            
        if ev.started, let liveEventData = ev.liveEventData, liveEventData.scores.count > 0 {
            guard let homeTeam = ev.homeTeam, let awayTeam = ev.awayTeam else { return .init(string: "home/away teams failed") }
            
            let result = navBarLiveTitleTopLine(ev)                              // Begin with the event time info on the top line
            result.append(navBarLiveTeamTitle(homeTeam, liveEventData, true))    // Append home team attributed string
            result.append(WHAttr.getEVDImgAttachStr(navBarLiveIcon))             // Append EVD live icon image between home/away team text
            result.append(navBarLiveTeamTitle(awayTeam, liveEventData, false))   // Append away team attributed string
            
            return result
        } else {
            return WHAttr.getEVDNavTitleCustomFont(ev.eventName.replacePipes(), .white, .bold(16.0))
        }
    }
    
    /// Generates attributed string for the Event time info for navBar attributed title
    /// - Parameter ev: Event object
    /// - Returns: NSMutableAttributedString
    private func navBarLiveTitleTopLine(_ ev: WHSportsbook.Event) -> NSMutableAttributedString {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ev.startTime.timeIsOnTheHour ? "ha MM.dd.yy" : "h:mma MM.dd.yy"
        var topLineTxt = dateFormatter.string(from: ev.startTime)
        
        if let liveEventData = ev.liveEventData {
            var gTimeString = "\(liveEventData.gameTime.minutes):\(liveEventData.gameTime.seconds)"
            if ev.sportId != "baseball" {
                gTimeString.append(" - \(ev.sportId.contains("hockey") ? "P":"Q")\(liveEventData.period)")
            }
            
            topLineTxt = gTimeString
        }
        
        return WHAttr.getEVDNavTitle("\(topLineTxt)\n", .red, false)
    }
    
    /// Generates attributed string for team names and scores for either left or right team for navBar attributed title
    /// - Parameters:
    ///   - team: The team selection object for title being generated
    ///   - liveScoreData: Event livescore data
    ///   - isLeftTeam: Whether to create string for left or right side of navBar title
    /// - Returns: NSAttributedString
    private func navBarLiveTeamTitle(_ team: WHSportsbook.Selection, _ liveScoreData: WHSportsbook.LiveEventData, _ isLeftTeam: Bool) -> NSAttributedString {
        let teamName = team.teamData?.teamShortName ?? team.name.replacePipes()
        
        var scoreStr = " 0 "
        if liveScoreData.scores.count > 1 {
            let idx = isLeftTeam.flipped.intValue
            scoreStr = " \(liveScoreData.scores[idx].points) "              // Attempt to load live score data if it exists.
        }
        
        let namePart = WHAttr.getEVDNavTitle(teamName)                      // Create team short name
        let scorePart = WHAttr.getEVDNavTitle(scoreStr, .red)   // Create colorized team livescore
        
        let result = isLeftTeam ? namePart : scorePart                      // Begin with name for left side team, otherwise begin with livescore
        result.append(isLeftTeam ? scorePart : namePart)
        
        return result
    }
}

/// Debug parameter that will load local json data if true one time on the first open of an EVD page
var loadDebugEventFromLocalJSON = false

// MARK: - Networking functions

extension EventDetailsViewModel: WHJsonRequestable {
    
    func startEVDLoad() {
        #if DEBUG
        _ = loadDebugEventFromLocalJSON ? loadLocalJSONEvent() : loadEventDetails()
        #else
        loadEventDetails()
        #endif
    }
    
    /// Required, EventDetails must make an API call to get the full event data.
    func loadEventDetails() {
        WHDataManager().decodeJsonDataFrom(url: WHAPI.eventDetails(eventId).url, objectType: WHSportsbook.Event.self) { [weak self] (jsonObject, error) in
            guard let model = jsonObject, model.markets.count > 0 else {
                if let err = error { print("eventDetailData request failed... error: \(err)\n") }
                return
            }
            
            self?.eventFinishedLoad(model)
        }
    }
    
    /// DEBUG ONLY!
    func loadLocalJSONEvent() {
        DispatchQueue.main.asyncAfter(deadline: .now()+1.0) { loadDebugEventFromLocalJSON = false }
        guard let filepath = Bundle.main.path(forResource: "sliderMarketsEvent2", ofType: "json") else { return }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filepath), options: .mappedIfSafe)
            let decoder = JSONDecoder()
            let model = try decoder.decode(WHSportsbook.Event.self, from: data)
                        
            eventFinishedLoad(model)
        } catch {
            print(error)
        }
    }
    
    private func constructEVDSectionData(_ allMetadataGroupedMarkets: WHSportsbook.Markets, _ marketDisplayType: String) -> [EVDSectionData] {
        let allCategorySpecificGroupedMarkets = allMetadataGroupedMarkets.filter({$0.metadata?.marketDisplayType == marketDisplayType })
        let uniqueGroupCategories = allCategorySpecificGroupedMarkets.compactMap({$0.metadata?.marketCategory}).unique().map({String($0)})
        
        var result: [EVDSectionData] = []
        for groupCategory in uniqueGroupCategories {
            let markets = allMetadataGroupedMarkets.filter({ $0.metadata?.marketCategory == groupCategory })
            guard let marketOne = markets.first, let metaData = marketOne.metadata else { fatalError() }
            
            let colName = (metaData.marketCategoryName ?? marketOne.name ?? "mktNameErr").replacePipes()
            let singleMkt : [EVDRowData] = marketOne.selections.map({ .init(titleText: $0.name.replacePipes(), metadata: metaData, market: marketOne, selections: [$0]) })
            let multiMkt  : [EVDRowData] = markets.compactMap({ .init(titleText: ($0.metadata?.player ?? $0.name ?? colName).replacePipes(), metadata: $0.metadata, market: $0, selections: $0.selections) })
            
            let mktCatTitle = metaData.marketCategoryName ?? metaData.marketCategory?.replacingOccurrences(of: "_", with: " ").capExcludingNumbers
            var sectionTitle = (mktCatTitle ?? marketOne.name ?? marketOne.selections.first?.name ?? "err").replacePipes()
            sectionTitle.magicSixPackTrimSectionHeaderTitle()
            
            let newSection: EVDSectionData = .init(sectionHeaderTitle: sectionTitle, evdRows: markets.count == 1 ? singleMkt : multiMkt)
            result.append(newSection)
        }
        
        return result
    }
    
    private func eventFinishedLoad(_ ev: WHSportsbook.Event) {
        
        DispatchQueue.main.async { [self] in
            eventDetails = ev
            let rootMarketCollections = (ev.marketCollectionsFromV3MarketTabs() ?? []).filter({$0.markets.compactMap({$0.selections}).count > 0})
    
            var result: [EVDTabData] = []
            for mktCol in rootMarketCollections {
                var groupEVDSections: [EVDSectionData] = []
                let allMetadataGroupedMarkets = mktCol.markets.filter({$0.metadata?.useMetadataGroups ?? false})
                let groupedSectionData = EVDMarketGroupType.caseStrs.map({constructEVDSectionData(allMetadataGroupedMarkets, $0)}).flatCmpt
                groupEVDSections.append(contentsOf: groupedSectionData)
                
                let allNonMetadataGroupedMarkets = mktCol.markets.filter({!($0.metadata?.useMetadataGroups ?? false)})
                groupEVDSections.append(contentsOf: EVDSectionData.nonGroupedMarkets(allNonMetadataGroupedMarkets))
                
                result.append(.init(filterTabTitle: mktCol.name, evdSections: groupEVDSections))
            }
            
            evdTabsData = result
            
            headerVC?.filterView?.addData(evdTabsData.compactMap({ $0.filterTabTitle }).map({ SingleSelectFilter($0) }) )
            headerVC?.filterView?.setSelectedIndex(selectedMktColIndex)
            headerVC?.setupEVDHeader(ev)
            
            
            updateLiftingHeader(.preGame)
            delegate?.eventDetailLoaded()
            
            let teamDataArray = ev.markets.map({$0.selections.compactMap({$0.teamData}) }).flatCmpt.unique().map({$0})
            if teamDataArray.count > 1 { teamDataGroup = (teamDataArray[0], teamDataArray[1]) }
        }
    }
}

enum EVDMarketGroupType: String, CaseIterable, Equatable {
    case sixPack = "alternativeSixPack", slider, tabs
    
    static var caseStrs: [String] { allCases.map({$0.rawValue}) }
}

struct EVDTabData {
    let filterTabTitle : String
    let evdSections    : [EVDSectionData]
    var numSections    : Int { evdSections.count }
}

struct EVDSectionData {
    let sectionHeaderTitle : String
    let evdRows            : [EVDRowData]
    var markets            : WHSportsbook.Markets { evdRows.map({ $0.market })}
    var rootMetadata       : WHSportsbook.Metadata? { evdRows.first?.metadata }
    var groupType          : EVDMarketGroupType? { evdRows.first?.groupType }
        
    static func nonGroupedMarkets(_ mkts: WHSportsbook.Markets) -> [EVDSectionData] {
        var result: [EVDSectionData] = []
        for mkt in mkts {
            let singleMkt : [EVDRowData] = mkt.selections.map({ .init(titleText: $0.name.replacePipes(), metadata: nil, market: mkt, selections: [$0]) })
            let newSection: EVDSectionData = .init(sectionHeaderTitle: (mkt.name ?? mkt.selections.first?.name ?? "").replacePipes(), evdRows: singleMkt)
            result.append(newSection)
        }
        return result
    }
}

struct EVDRowData {
    let titleText  : String
    let metadata   : WHSportsbook.Metadata?
    let market     : WHSportsbook.Market
    let selections : WHSportsbook.Selections
    var groupType  : EVDMarketGroupType? { .init(rawValue: metadata?.marketDisplayType ?? "err") }
}

// MARK: - Data helpers and diffusion code

extension EventDetailsViewModel {
    
    func numberRows(_ section: Int) -> Int {
        if collapsedSections.contains(section) { return 0 }
        guard selectedMktColIndex < evdTabsData.count, section < evdTabsData[selectedMktColIndex].evdSections.count else { fatalError("EVDVM, invalid numRows for \(section)") }
        
        if evdTabsData[selectedMktColIndex].filterTabTitle == "Popular" { return 0 }
        
        let evdSectionData = evdTabsData[selectedMktColIndex].evdSections[section]
        let rowCount = evdSectionData.evdRows.count
        
        var result = 0
        
        if let groupType = evdSectionData.groupType, groupType == .sixPack { return 1 }
                
        if rowCount == 4 { result = rowCount } // Do not add 'View more/less' row to count
        if rowCount < 4  { return 1 }        // For 3 or less selections, only return one prefab row containing the selections
        
        if rowCount == 4, let groupType = evdSectionData.groupType, groupType == .tabs { return 4 + 1 }
        
        result = sectionsShowingAllRows.contains(section) ? rowCount : 4 + 1
        if let groupType = evdSectionData.groupType, groupType == .tabs { return result+1 }
        
        return result
    }
    
    func numberSections() -> Int {
        guard selectedMktColIndex < evdTabsData.count else { return 0 }
        
        if evdTabsData[selectedMktColIndex].filterTabTitle == "Popular" { return 1 }
        
        return evdTabsData[selectedMktColIndex].evdSections.count
    }
    
    func getEVDSectionData(_ section: Int) -> EVDSectionData? {
        guard selectedMktColIndex < evdTabsData.count, section < evdTabsData[selectedMktColIndex].evdSections.count else { return nil }
        return evdTabsData[selectedMktColIndex].evdSections[section]
    }
    
    func getEVDTabData() -> EVDTabData? {
        guard selectedMktColIndex < evdTabsData.count else { return nil }
        return evdTabsData[selectedMktColIndex]
    }
}

class WHSlider: UISlider {
    override func awakeFromNib() {
        super.awakeFromNib()
        setThumbImage(UIImage(named: "sliderThumb"), for: .normal)
    }
}
