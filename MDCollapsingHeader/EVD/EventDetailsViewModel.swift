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

typealias TeamNamesData = (teamOne: WHSportsbook.TeamData, teamTwo: WHSportsbook.TeamData)

class EventDetailsViewModel: NSObject {
    // MARK: - EVD ViewModel Base Parameters
    
    weak var delegate  : EventDetailsDelegate?
    var eventDetails   : WHSportsbook.Event?
    var eventId        : String = ""
    var navBarLiveIcon : UIImage = .init(named: "evdNavBarLiveIcon")!
    var allRelatedEventIds: [String] = []
    
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

    var teamDataGroup       : TeamNamesData?
    var adjustedSectionData : [String : EVDSectionData] = [:]
    var evdTabsData         : [EVDTabData] = []
    
    private(set) var selectedMktColIndex: Int = 0
    
    func setSelectedMktCollectionIndex(_ idx: Int) {
        adjustedSectionData.removeAll()
        clearCollapsedSections()
        clearSectionsShowingAllRows()
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
        super.init()
        if eventId.count > 10, delegate != nil {
            print("\n\n\t\t evd eventId: \(eventId)\n\n")
        }
    }
        
    func shouldHideSpinner(_ delay: Double = 0.0) {
        //
    }
}

extension EventDetailsViewModel {
        
    func updateLiftingHeader(_ newState: LiftingHeaderState) {
        minOperatingHeight = newState.minHeight
        maxOperatingHeight = newState.maxHeight
        
        if let vc = delegate as? EventDetailsViewController { vc.updateLiftingHeaderNoAnimation() }
    }
    
    var evdNavAttrTitle: NSAttributedString {
        guard let ev = eventDetails else { return .init(string: "EVD event not loaded...") }

        if ev.started, let liveEventData = ev.liveEventData, liveEventData.scores.count > 0 {
            guard let homeTeam = ev.homeTeam, let awayTeam = ev.awayTeam else { return .init(string: "home/away teams failed") }
            
            let result = navBarLiveTitleTopLine(ev)                              // Begin with the event time info on the top line
            result.append(navBarLiveTeamTitle(homeTeam, liveEventData, true))    // Append home team attributed string
            result.append(WHAttr.getEVDImgAttachStr(navBarLiveIcon))             // Append EVD live icon image between home/away team text
            result.append(navBarLiveTeamTitle(awayTeam, liveEventData, false))   // Append away team attributed string
            
            return result
        } else {
            return WHAttr.getCustomStr(text: ev.eventName.rp.uppercased(), .czkColor(.foreground), WHFont.Refrigerator.extraBold(18.0).font)
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
        
        return WHAttr.getEVDNavTitle("\(topLineTxt)\n", .czkColor(.live), false)
    }
    
    /// Generates attributed string for team names and scores for either left or right team for navBar attributed title
    /// - Parameters:
    ///   - team: The team selection object for title being generated
    ///   - liveScoreData: Event livescore data
    ///   - isLeftTeam: Whether to create string for left or right side of navBar title
    /// - Returns: NSAttributedString
    private func navBarLiveTeamTitle(_ team: WHSportsbook.Selection, _ liveScoreData: WHSportsbook.LiveEventData?, _ isLeftTeam: Bool) -> NSAttributedString {
        let teamName = team.teamData?.teamShortName ?? team.name.rp
        
//        var scoreStr = " 0 "
//        if let liveScoreData = liveScoreData, liveScoreData.scores.count > 1 {
//            if ConfigurationManager.instance.getFeatureFlag(.livescores) == false {
//                scoreStr = ""
//            }
//            else {
//                let idx = isLeftTeam.flipped.intValue
//                scoreStr = " \(liveScoreData.scores[idx].points) "              // Attempt to load live score data if it exists.
//            }
//        }
        
        let namePart = WHAttr.getEVDNavTitle(teamName)                      // Create team short name
        let scorePart = WHAttr.getEVDNavTitle(" 0 ", .czkColor(.live))   // Create colorized team livescore
        
        let result = isLeftTeam ? namePart : scorePart                      // Begin with name for left side team, otherwise begin with livescore
        result.append(isLeftTeam ? scorePart : namePart)
        
        return result
    }
}

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
    func loadEventDetails(_ handler: (() -> ())? = nil) {
        WHDataManager().decodeJsonDataFrom(url: WHAPI.eventDetails(eventId).url, objectType: WHSportsbook.Event.self) { [weak self] (jsonObject, error) in
            guard let model = jsonObject, model.markets.count > 0 else {
                if let err = error { print("eventDetailData request failed... error: \(err)\n") }
                return
            }

            self?.eventFinishedLoad(model, handler)
        }
    }
    
    /// DEBUG ONLY!
    func loadLocalJSONEvent() {
        DispatchQueue.main.asyncAfter(deadline: .now()+1.0) { loadDebugEventFromLocalJSON = false }
        guard let filepath = Bundle.main.path(forResource: debugJSONFile.rawValue, ofType: "json") else { return }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filepath), options: .mappedIfSafe)
            let decoder = JSONDecoder()
            let model = try decoder.decode(WHSportsbook.Event.self, from: data)
                        
            eventFinishedLoad(model)
        } catch {
            print(error)
        }
    }
    
    private func constructEVDSectionData(_ metadataMkts: WHSportsbook.Markets, _ tabTitle: String) -> [EVDSectionData] {
        
        let categoryNameOrder = metadataMkts.compactMap({$0.metadata?.marketCategory})
        var orderedMktCategoryNames: [String] = []
        for mktCat in categoryNameOrder {
            if !orderedMktCategoryNames.contains(mktCat) { orderedMktCategoryNames.append(mktCat) }
        }
        
        var result: [EVDSectionData] = []
        for mktCategory in orderedMktCategoryNames {
            let markets = metadataMkts.filter({ $0.metadata?.marketCategory == mktCategory })
            guard let marketOne = markets.first, let metaData = marketOne.metadata else { fatalError() }
            
            let colName = (metaData.marketCategoryName ?? marketOne.name ?? marketOne.displayName ?? "mktNameErr").rp
            var resultMkts : [EVDRowData] = marketOne.selections.map({ .init($0.name.rp, metaData, marketOne, [$0]) })
            if markets.count > 1 { resultMkts = markets.compactMap({ .init(($0.metadata?.player ?? $0.name ?? colName).rp, $0.metadata, $0, $0.selections) }) }
            
            // Logic to populate parameters that are used to enable filtering for tabs grouped cells
            if (metaData.marketDisplayType ?? "err") == "tabs" {
                if resultMkts.count > 0 { for (idx, mkt) in resultMkts.enumerated() { resultMkts[idx].tabFilterText = mkt.metadata?.teamName ?? mkt.titleText } }
            }
            
            let mktCatTitle = metaData.marketCategoryName ?? metaData.marketCategory?.replacingOccurrences(of: "_", with: " ").capExcludingNumbers
            var sectionTitle = (mktCatTitle ?? marketOne.name ?? marketOne.displayName ?? marketOne.selections.first?.name ?? "err").rp
            sectionTitle.magicSixPackTrimSectionHeaderTitle()
            
            result.append(.init(sectionTitle, resultMkts, tabTitle))
        }
        
        return result
    }
    
    private func eventFinishedLoad(_ ev: WHSportsbook.Event, _ handler: (() -> ())? = nil) {
        
        eventDetails = ev
        allRelatedEventIds = [ev.id]

        let marketTabs = ev.marketTabs ?? []
        var result: [EVDTabData] = []
        
        for mktTab in marketTabs {
            let markets = mktTab.marketIds.unique().compactMap({ tabMktId in ev.markets.first(where: {$0.id == tabMktId}) })
            var groupEVDSections: [EVDSectionData] = []
            var mktsAdded: [String] = []
            
            let popularSixPack = markets.filter({ $0.sixPackView ?? false })
            if popularSixPack.count > 0 {
                groupEVDSections.append(.popularSixPack(popularSixPack, mktTab.name))
                mktsAdded.append(contentsOf: popularSixPack.compactMap({$0.id}))
            }
            
            let metadataMarkets = markets.filter({ !mktsAdded.contains($0.id) && ($0.metadata?.useMetadataGroups ?? false) })
            if metadataMarkets.count > 0 {
                groupEVDSections.append(contentsOf: constructEVDSectionData(metadataMarkets, mktTab.name))
                mktsAdded.append(contentsOf: metadataMarkets.compactMap({$0.id}))
            }
            
            let nonMetadataMkts = markets.filter({ !mktsAdded.contains($0.id) })
            if nonMetadataMkts.count > 0 {
                groupEVDSections.append(contentsOf: EVDSectionData.nonGroupedMarkets(nonMetadataMkts, mktTab.name))
            }
            
            result.append(.init(filterTabTitle: mktTab.name, evdSections: groupEVDSections))
        }
        
        evdTabsData = result
        let tabTitles = result.compactMap({ $0.filterTabTitle }).map({ SingleSelectFilter($0) })
        if selectedMktColIndex >= tabTitles.count { setSelectedMktCollectionIndex(tabTitles.count-1) }
        
        DispatchQueue.main.async { [weak self] in
            
            self?.headerVC?.filterView?.clearFilterOptions()
            self?.headerVC?.filterView?.addData(tabTitles)
            self?.headerVC?.filterView?.setSelectedIndex(self?.selectedMktColIndex ?? 0)
            self?.headerVC?.setupEVDHeader(ev)
            
            if !ev.started {
                self?.updateLiftingHeader(.preGame)
            }
            
//            WHDiffusionManager.shared.subscribeTopics(topics)
            self?.delegate?.eventDetailLoaded()
            handler?()
        }
        
        let teamDataArray = ev.markets.map({$0.selections.compactMap({$0.teamData}) }).flatCmpt.unique().map({$0})
        if teamDataArray.count > 1 { teamDataGroup = (teamDataArray[0], teamDataArray[1]) }
    }
}

// MARK: - Data helpers and diffusion code

extension EventDetailsViewModel {
    
    func numberSections() -> Int {
        if eventDetails?.display == false { return 0 }
        return getEVDTabData()?.evdSections.count ?? 0
    }
    
    func numberRows(_ section: Int) -> Int {
        if eventDetails?.display == false { return 0 }
        guard let evdSectionData = getEVDSectionData(section) else { return 0 }
        if collapsedSections.contains(section) { return 1 } // Section is collapsed, only return header cell
        
        let dataRowsCount = numberOfEvdDataRows(evdSectionData)
        let nonDataHeaderOrTopRowCount = numberOfNonDataHeaderRows(evdSectionData, section)
        var result = dataRowsCount + nonDataHeaderOrTopRowCount
        
        if dataRowsCount > 4 {
            let allRowsIncludingHeadersAndFooters = dataRowsCount + nonDataHeaderOrTopRowCount + 1       // Add 1 for the 'show more' footer cell
            let limitedRowsShowMoreState = nonDataHeaderOrTopRowCount + 4 + 1 // Add 1 for the 'show less' footer cell
            result = sectionsShowingAllRows.contains(section) ? allRowsIncludingHeadersAndFooters : limitedRowsShowMoreState
        }
        
        return result
    }
    
    func numberOfNonDataHeaderRows(_ evdSectionData: EVDSectionData, _ section: Int = 1) -> Int {
        var result = 1 // Default EVD collapsible section header cell
        if evdSectionData.groupType == .tabs { result += 1 } // Tab buttons cell
        if section == 0 && evdSectionData.parentTabTitle == "Popular" && evdSectionData.groupType == .sixPack { result -= 1 } // Removes a row for Popular tab sixPacks
        
        return result
    }
    
    func numberOfEvdDataRows(_ sectData: EVDSectionData) -> Int { [.slider, .sixPack].contains(sectData.groupType) ? 1 : sectData.evdRows.count }
    
    private func adjustedSectionKey(_ section: Int) -> String { "\(selectedMktColIndex),\(section)" }
    
    func getEVDSectionData(_ section: Int) -> EVDSectionData? {
        guard let tabsData = getEVDTabData(), section < tabsData.evdSections.count else { return nil }
        return adjustedSectionData[adjustedSectionKey(section)] ?? tabsData.evdSections[section]
    }
    
    func getEVDTabData() -> EVDTabData? {
        guard evdTabsData.count > 0 && selectedMktColIndex < evdTabsData.count else { return nil }
        return evdTabsData[selectedMktColIndex]
    }
}

/// Debug parameter that will load local json data if true one time on the first open of an EVD page
var loadDebugEventFromLocalJSON = false
let debugJSONFile: EVDDebugJSONFile = .tabsA
