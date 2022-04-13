//
//  EventDetailsViewController.swift
//  WH_CZR_SBK
//
//  Created by Johnson Liu on 5/12/20.
//  Copyright © 2020 Caesar's Entertainment. All rights reserved.
//

import UIKit
import WHSportsbook

protocol EVDHeaderDelegate: TableViewOwner {
    func scoreboardFinishedLoading(_ sbHeight: CGFloat)
}

class EventDetailsViewController: UIViewController, EVDShowAllDelegate {

    @IBOutlet weak var tableView     : UITableView?
    @IBOutlet weak var liftingHeader : UIView?
    
    private var filterView: FilterView? { viewModel.headerVC?.filterView }
    var viewModel: EventDetailsViewModel
    
    /// A helper parameter which calculates the effictive current height of the LiftingHeader
    var currentHeaderHeight: CGFloat { (liftingHeaderOriginY + viewModel.maxOperatingHeight) - (tableView?.frame.origin.y ?? 0.0) }
    
    /// Value which directly sets the origin.y parameter on the LiftingHeader
    lazy var liftingHeaderOriginY: CGFloat = (tableView?.frame.origin.y ?? 0.0) {
        didSet { liftingHeader?.frame.origin.y = liftingHeaderOriginY }
    }
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
//        navBarTitle = ""
//        navBarAttributedTitle = nil
        configureTableView()
        filterView?.filterDelegate = self
        
        DispatchQueue.main.async { [self] in
            viewModel.updateLiftingHeader(.liveNoScoreboard) // By default, only allow filterView in lifting header
        }
    }
        
    class func newEVDVC(_ eventId: String) -> EventDetailsViewController {
        let evd: WHVC = .eventDetails
        guard eventId.count > 10, let vc = evd.board.instantiateViewController(withIdentifier: evd.vcId) as? EventDetailsViewController else { fatalError("Make new EVD VC failed! evId: \(eventId)") }
        vc.viewModel = EventDetailsViewModel(eventId, vc)
        return vc
    }
    
    required init?(coder: NSCoder) {
        viewModel = .init("", nil)
        super.init(coder: coder)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let vc = segue.destination as? EVDLiftingHeaderVC {
            vc.delegate = self
            viewModel.headerVC = vc
        }
    }

    private func configureTableView() {
        tableView?.registerWHCells([.evdSelectionCell, .evdMarketTemplateCell, .evdShowAllCell, .evdSectionCell, .evdAltSpreadCell, .evdTabsGroupingCell, .sixPackTableCell])
        tableView?.rowHeight = UITableView.automaticDimension
        tableView?.estimatedRowHeight = UITableView.automaticDimension
        tableView?.delegate = self
        tableView?.dataSource = self
        
        tableView?.setupRefreshControl { self.viewModel.loadEventDetails() } // Temporarily disable refresh control
    }

    // MARK: - EventDetailMarketCellBuilderDelegate methods
    
    @objc func didTapHeader(_ sender: UITapGestureRecognizer) {
        guard let section = sender.view?.tag, section >= 0 else { fatalError("invalid header section tapped EVD...") }
        let savedContentOff = tableView?.contentOffset
        viewModel.updateCollapsedSection(section)
        tableView?.reloadSections([section], with: .automatic)
        if let off = savedContentOff { tableView?.setContentOffset(off, animated: false) }
        updateBottomInsetSpacing()
    }

    func didTapFooter(_ section: Int) {
        guard section >= 0 else { fatalError("invalid footer section tapped EVD...") }
        let savedContentOff = tableView?.contentOffset
        viewModel.updateShowingAllRowsSection(section)
        tableView?.reloadSections([section], with: .automatic)
        if let off = savedContentOff { tableView?.setContentOffset(off, animated: false) }
        updateBottomInsetSpacing()
    }
}

// MARK: - ViewModel Delegate Conformance

extension EventDetailsViewController: EventDetailsDelegate {
    
    func eventDetailLoaded() {
        if tableView?.refreshControl?.isRefreshing ?? false {
            UIView.animate(withDuration: 0.35) { self.tableView?.refreshControl?.endRefreshing() }
        }
        updateNavBarAttributedTitle(viewModel.navBarAttributedTitle)
    }
    
    // Todo: Implement
    func applyLiveScoreUpdate() {
        updateNavBarAttributedTitle(viewModel.navBarAttributedTitle)
    }

    var tableViewRef: UITableView? { tableView }
}

extension EventDetailsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView)                             -> Int { viewModel.numberSections() }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { viewModel.numberRows(section) + 1 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)  -> UITableViewCell {
        let section : Int = indexPath.section
        var row     : Int = indexPath.row
        
        guard let tabData = viewModel.getEVDTabData(), let evdSection = viewModel.getEVDSectionData(section) else { fatalError() }
        let isExpanded = !viewModel.collapsedSections.contains(section)
        
        if tabData.filterTabTitle == "Popular", section == 0, row == 0, let ev = viewModel.eventDetails,
           let cell = tableView.dequeueReusableCell(withIdentifier: "MSPTableViewCell", for: indexPath) as? MSPTableViewCell {
            cell.configureMagicSixPackCell(ev)
            cell.mainTitleLabel.text = "Popular Bets"
            if cell.topSpaceConstraint.constant != 28.0 { cell.topSpaceConstraint.constant = 28.0 }
            cell.removeEVDTapGesture()
            cell.delegate = self
            return cell
        } else if row == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "MSPTableViewCell", for: indexPath) as? EVDSectionCell {
            cell.titleLabel.text = evdSection.sectionHeaderTitle
            cell.contentView.tag = section
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapHeader(_:)))
            cell.contentView.addGestureRecognizer(tapGesture)
            cell.arrowIcon.transform = CGAffineTransform.init(rotationAngle: isExpanded ? -.pi/2.0 : .pi/2.0)
            
            if evdSection.groupType == .sixPack {
                cell.updateBottomSpacingForSixPack(isExpanded)
            } else {
                cell.updateBottomSpacing(isExpanded)
            }
            
            if let mktTab = (viewModel.eventDetails?.marketTabs ?? []).first(where: {$0.name == "Same Game Parlay"}), let mkId = evdSection.markets.first?.id {
                if mktTab.marketIds.contains(mkId) { cell.sgpIcon.isHidden = false }
            }
            return cell
        }
        
        if evdSection.groupType == .slider {
            if let ev = viewModel.eventDetails, let homeTeam = ev.homeTeam, let awayTeam = ev.awayTeam, let market = evdSection.markets.first,
                let cell = tableView.dequeueReusableCell(withIdentifier: "EVDAltSpreadCell", for: indexPath) as? EVDAltSpreadCell {
                cell.configSliderCell(market, homeTeam, awayTeam)
                cell.lhsBtn?.addTarget(self, action: #selector(tappedBetslipButton(_:)), for: .touchUpInside)
                cell.rhsBtn?.addTarget(self, action: #selector(tappedBetslipButton(_:)), for: .touchUpInside)
                return cell
            }
        } else if evdSection.groupType == .sixPack {
            if let ev = viewModel.eventDetails, let cell = tableView.dequeueReusableCell(withIdentifier: "MSPTableViewCell", for: indexPath) as? MSPTableViewCell {
                cell.configureMagicSixPackCell(ev, evdSection.markets)
                cell.hideColumnsCheck()
                cell.mainTitleLabel.text = ""
                cell.removeEVDTapGesture()
                cell.trimMarketTitlesCategory()
                cell.delegate = self
                if cell.topSpaceConstraint.constant != 0.0 { cell.topSpaceConstraint.constant = 0.0 }
                return cell
            }
        } else if evdSection.groupType == .tabs, row == 1 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "EVDTabsGroupingCell", for: indexPath) as? EVDTabsGroupingCell, let tabs = evdSection.rootMetadata?.tabs {
                cell.tabButtons?[1].setTitle(tabs.first ?? "err", for: .normal)
                cell.tabButtons?[2].setTitle(tabs.last ?? "err", for: .normal)
                return cell
            }
        } else {
            if evdSection.groupType == .tabs { row -= 1 }
            let market = evdSection.markets[max(min(evdSection.markets.count-1, row-1), 0)]
            let numRows = viewModel.numberRows(section)
            let secIsShowAllRows: Bool = viewModel.sectionsShowingAllRows.contains(section)
            
            if numRows > WHLookup.evdShowAllRowsLimit || secIsShowAllRows {
                
                let isShowLessCell: Bool = (row == numRows - (evdSection.groupType == .tabs ? 1 : 0)) && secIsShowAllRows
                let isShowMoreCell: Bool = (row == WHLookup.evdShowAllRowsLimit + 1) && !secIsShowAllRows
                
                if (isShowLessCell || isShowMoreCell),
                   let cell = tableView.dequeueReusableCell(withIdentifier: "EventDetailsShowAllCell", for: indexPath) as? EventDetailsShowAllCell {
                    
                    cell.section = section
                    cell.delegate = self
                    cell.showAllBtn.setTitle("Show \(isShowLessCell ? "less" : "more")", for: .normal)
                    return cell
                }
                
                if let cell = tableView.dequeueReusableCell(withIdentifier: "EventDetailMarketSelectionCell") as? EventDetailMarketSelectionCell {
                    cell.populate(event: viewModel.eventDetails, market: market, row: row - 1)
                    cell.delegate = self
                    return cell
                }
            }
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: "EventDetailMarketSelectionCell") as? EventDetailMarketSelectionCell {
                cell.populate(event: viewModel.eventDetails, market: market, row: row - 1, row == numRows-1)
                cell.delegate = self
                return cell
            }
        }
                
        return UITableViewCell()
    }
    
    @objc func tappedBetslipButton(_ sender: UISixPackButton) {
    
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        tableView.diffusionSubscribeCheck()
    }
}

// MARK: - Lifting Header Logic

extension EventDetailsViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating) {
            let headerHeight: CGFloat = currentHeaderHeight
            let minHeight: CGFloat = viewModel.minOperatingHeight
            let maxHeight: CGFloat = viewModel.maxOperatingHeight
            
            // Adjusts scroll indicator so it doesn't go behind/underneath lifting header
            defer { scrollView.verticalScrollIndicatorInsets.top = currentHeaderHeight }
            
            // Normalized scroll offset.y value accounting for headerHeight and returning only positive offset values
            let cleanOffsetY: CGFloat = scrollView.contentOffset.y + headerHeight
            let isCollapsed = headerHeight == minHeight
            let isExpanded = headerHeight == maxHeight
            
            let alreadyCollapsed = viewModel.lastScrollOffsetClean < cleanOffsetY && isCollapsed
            let alreadyExpanded  = viewModel.lastScrollOffsetClean > cleanOffsetY && isExpanded
            let sbTitle = viewModel.headerVC?.scoreboardBtnTitle ?? ""
            
            if alreadyCollapsed || alreadyExpanded {
                /// Represents scrolling where the direction and offset has no effect on the header, such as continuing to scroll down with fully collapsed header
                if alreadyCollapsed {
                    viewModel.lastScrollReverseOffset = nil
                } else if alreadyExpanded {
                    if let reverse = viewModel.lastScrollReverseOffset, cleanOffsetY < reverse {
                        viewModel.lastScrollReverseOffset = cleanOffsetY
                    } else {
                        viewModel.lastScrollReverseOffset = nil
                    }
                }
                viewModel.lastScrollOffsetClean = cleanOffsetY

                if alreadyCollapsed, sbTitle.contains("Hide") { viewModel.headerVC?.updateScoreboardBtnTitle(false) }

                return
            }
            
            // Determines the point where an expanded header can begin collapsing, i.e. the instant you begin scrolling back up
            if headerHeight == maxHeight, cleanOffsetY > viewModel.lastScrollOffsetClean, viewModel.lastScrollReverseOffset == nil, cleanOffsetY > minHeight { viewModel.lastScrollReverseOffset = cleanOffsetY }
            viewModel.lastScrollOffsetClean = cleanOffsetY
            
            let maxLimit = ((scrollView.frame.origin.y - maxHeight) + minHeight)
            let minLimit = min(scrollView.frame.origin.y, ((scrollView.frame.origin.y - max(0.0, maxHeight + scrollView.contentOffset.y)) + (viewModel.lastScrollReverseOffset ?? 0.0)))
            liftingHeaderOriginY = max(maxLimit, minLimit)
            
            if !isCollapsed, !isExpanded, sbTitle.contains("Show") { viewModel.headerVC?.updateScoreboardBtnTitle(true) }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Fixes an issue with lifting header overlapping content when the table doesn't have enough rows to fill the screen
        let tableContentHeight = scrollView.contentSize.height + scrollView.contentInset.top
        let requiredHeight = scrollView.frame.height + (viewModel.maxOperatingHeight - viewModel.minOperatingHeight)
        let result = max(0.0, requiredHeight - tableContentHeight)
        if scrollView.contentInset.bottom > result { scrollView.contentInset.bottom = result }
    }
    
    func expandLiftingHeader(_ willExpand: Bool = true) {
        DispatchQueue.main.async { [self] in
            
            guard let tableView = tableView else { return }
            let minHeight: CGFloat = viewModel.minOperatingHeight
            let maxHeight: CGFloat = viewModel.maxOperatingHeight
            
            let newHeaderOrigin = (willExpand ? 0.0 : minHeight - maxHeight) + tableView.frame.origin.y
            let headerOriginDiff = liftingHeaderOriginY-newHeaderOrigin
            UIView.animate(withDuration: 0.35) {
                liftingHeaderOriginY = newHeaderOrigin
                tableView.contentOffset.y += headerOriginDiff
            }
            viewModel.lastScrollOffsetClean = tableView.contentOffset.y + currentHeaderHeight
            viewModel.headerVC?.updateScoreboardBtnTitle(willExpand)
        }
    }
    
    func updateLiftingHeaderNoAnimation() {
        DispatchQueue.main.async { [self] in
            UIView.animate(withDuration: 0.35) { [self] in
                let maxH = viewModel.maxOperatingHeight
                liftingHeader?.frame.size.height = maxH
                viewModel.lastScrollOffsetClean = 0.0
                liftingHeaderOriginY = tableView?.frame.origin.y ?? 97.0
                tableView?.contentOffset.y = -maxH
                tableView?.contentInset.top = maxH
            } completion: { _ in
                updateBottomInsetSpacing()
                tableView?.beginUpdates()
                tableView?.endUpdates()
            }
        }
    }
    
    private func updateBottomInsetSpacing() {
        guard let tableView = tableView, tableView.contentSize.height > 40.0 else { return }
        
        let numSections = viewModel.numberSections()
        let numRows = (0..<numSections).map({viewModel.numberRows($0)+1}).reduce(0,+)
        
        if numRows < 10 {
            let tableContentHeight = tableView.contentSize.height + tableView.contentInset.top
            let requiredHeight = tableView.frame.height + (viewModel.maxOperatingHeight - viewModel.minOperatingHeight)
            let result = max(0.0, requiredHeight - tableContentHeight)
            
            if viewModel.lastScrollOffsetClean > 0 {
                let insetDiff = result - tableView.contentInset.bottom
                var newOffset = tableView.contentOffset
                newOffset.y += insetDiff
                tableView.setContentOffset(newOffset, animated: true)
            }
            
            tableView.contentInset.bottom = result
        } else {
            tableView.contentInset.bottom = 0.0
        }
    }
}

// MARK: - FilterView Delegate Methods

extension EventDetailsViewController: FilterViewDelegate {
    func didSelectItem(_ index: Int) {
        viewModel.clearCollapsedSections()
        viewModel.clearSectionsShowingAllRows()
        viewModel.setSelectedMktCollectionIndex(index)
        
        DispatchQueue.main.async { [self] in
            tableView?.reloadData()
            updateBottomInsetSpacing()
        }
    }
}

// MARK: - EVD Delegate Methods (For EVD Header)

extension EventDetailsViewController: EVDHeaderDelegate {
 
    func scoreboardFinishedLoading(_ sbHeight: CGFloat) {
        
        DispatchQueue.main.async { [self] in
            if viewModel.maxOperatingHeight == 60.0 {
                print("\n\n\t\t scoreboard finished loading... \(sbHeight.shortStr)\n")
                viewModel.updateLiftingHeader(.scoreboardDown(sbHeight))
            }
        }
    }
}
