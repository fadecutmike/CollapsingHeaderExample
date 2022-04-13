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
    
    let bottomCoverView  = UIView()
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textAlignment = .center
        label.widthAnchor.constraint(lessThanOrEqualToConstant: 200).isActive = true
        return label
    }()
    
    /// Value which directly sets the origin.y parameter on the LiftingHeader
    lazy var liftingHeaderOriginY: CGFloat = (tableView?.frame.origin.y ?? 0.0) {
        didSet { liftingHeader?.frame.origin.y = liftingHeaderOriginY }
    }
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavBar()
        configureTableView()
        filterView?.filterDelegate = self
        
        DispatchQueue.main.async { [self] in
            viewModel.updateLiftingHeader(.liveNoScoreboard) // By default, only allow filterView in lifting header
        }
    }
        
//    class func newEVDVC(_ eventId: String) -> EventDetailsViewController {
////        let evd: WHVC = .eventDetails
////        guard eventId.count > 10, let vc = evd.board.instantiateViewController(withIdentifier: evd.vcId) as? EventDetailsViewController else { fatalError("Make new EVD VC failed! evId: \(eventId)") }
//        let vc = EventDetailsViewController
//        vc.viewModel = EventDetailsViewModel(eventId, vc)
//        return vc
//    }
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.backgroundColor = .czkColor(.bg)
        bottomCoverView.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        bottomCoverView.isHidden = true
    }
    
//    override func customCZKLogic() {
//        guard let newLiveIconImg = viewModel.navBarLiveIcon.tinted(.czkColor(.foreground)) else { fatalError() }
//        viewModel.navBarLiveIcon = newLiveIconImg
//        tableView?.reloadData()
//    }

    private func configureNavBar() {
        guard let navigationBar = navigationController?.navigationBar else { return }

        let statusBarCover = UIView(frame: CGRect(x: 0, y: -60, width: UIScreen.main.bounds.width, height: 60))
        statusBarCover.backgroundColor = UIColor.czkColor(.bg)
        navigationBar.addSubview(statusBarCover)
        
        bottomCoverView.backgroundColor = .czkColor(.bg)
        bottomCoverView.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.addSubview(bottomCoverView)
        bottomCoverView.leftAnchor.constraint(equalTo: navigationBar.leftAnchor).isActive = true
        bottomCoverView.rightAnchor.constraint(equalTo: navigationBar.rightAnchor).isActive = true
        bottomCoverView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
        bottomCoverView.heightAnchor.constraint(equalToConstant: 10).isActive = true
    }
    
    private lazy var footerHeightUpdateDebounce = Debouncer<()>(delay: 0.2) { [self] _ in
        guard let tableView = tableView else { return }
                
        let tableContentHeight = (tableView.contentSize.height + tableView.contentInset.top) - (tableView.tableFooterView?.frame.size.height ?? 0.0)
        let requiredHeight = tableView.frame.height + (viewModel.maxOperatingHeight - viewModel.minOperatingHeight)
        
        let newHeight = tableContentHeight < requiredHeight ? max(0.0, requiredHeight - tableContentHeight) : 0.0
        tableView.beginUpdates()
        if (tableView.tableFooterView?.frame.size.height ?? 0.0) != newHeight { tableView.tableFooterView?.frame.size.height = newHeight }
        tableView.endUpdates()
    }
    
    /// Method that dynamically updates the UITableViewFooterView height to allow for scrolling with bounce/inertia even if there isn't enough content in the table to allow for scrolling.
    /// This allows the user to still expand or collapse a live scoreboard or pre-game on all tabs/screens in EVD even if it only contains one market.
    private func processFooterHeight() {
        footerHeightUpdateDebounce.call(())
    }
    
    private func configureTableView() {
        tableView?.delegate   = self
        tableView?.dataSource = self
        tableView?.registerWHCells([.evdSelectionCell, .evdShowAllCell, .evdSectionCell, .evdAltSpreadCell, .evdTabsGroupingCell, .mspSixPackTableCell, .evdCompactCell])
        tableView?.backgroundColor = .clear
        
        tableView?.rowHeight = UITableView.automaticDimension
        tableView?.estimatedRowHeight = UITableView.automaticDimension
        
        let footer = UIView(frame: CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: 0.0))
        tableView?.tableFooterView = footer
        
//        tableView?.setupCustomEVDRefreshControl({ [weak self] in
//            self?.viewModel.loadEventDetails {
//                self?.tableView?.finishAndResetRefreshControl(-(self?.viewModel.minOperatingHeight ?? -100.0))
//            }
//        })
    }

    // MARK: - EventDetailMarketCellBuilderDelegate methods
    
    @objc func didTapHeader(_ sender: UITapGestureRecognizer) {
        guard let section = sender.view?.tag, section >= 0 else { fatalError("invalid header section tapped EVD...") }
        if !viewModel.collapsedSections.contains(section), viewModel.numberSections() < 8 {
            tableView?.tableFooterView?.frame.size.height += 600.0
            tableView?.contentOffset.y = -currentHeaderHeight
        }
        viewModel.updateCollapsedSection(section)
        tableView?.reloadSections([section], with: .automatic)
        processFooterHeight()
    }

    func didTapFooter(_ section: Int) {
        guard section >= 0 else { fatalError("invalid footer section tapped EVD...") }
        
        if viewModel.sectionsShowingAllRows.contains(section), let tv = tableView {
            
            let tableContentHeight = (tv.contentSize.height + tv.contentInset.top) - (tv.tableFooterView?.frame.size.height ?? 0.0)
            let requiredHeight = tv.frame.height + (viewModel.maxOperatingHeight - viewModel.minOperatingHeight)
            if tableContentHeight < requiredHeight || section == 0 {
                // Not enough tableView rows to fill screen or too close to top of tableView. Only scroll to minOperatingHeight
                tv.setContentOffset(.init(x: 0.0, y: -viewModel.minOperatingHeight), animated: true)
            } else {
                // 'Show Less' pressed, collapsing/removing rows
                tv.scrollToRow(at: .init(row: 0, section: section), at: .none, animated: true)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now()+0.25) { [self] in
                viewModel.updateShowingAllRowsSection(section)
                tableView?.reloadSections([section], with: .automatic)
            }
        } else {
            // 'Show More' pressed, expanding/adding rows
            viewModel.updateShowingAllRowsSection(section)
            tableView?.reloadSections([section], with: .automatic)
        }
        processFooterHeight()
    }
}

// MARK: - ViewModel Delegate Conformance

extension EventDetailsViewController: EventDetailsDelegate {
    
    func eventDetailLoaded() {
        if tableView?.refreshControl?.isRefreshing ?? false {
            UIView.animate(withDuration: 0.35) { self.tableView?.refreshControl?.endRefreshing() }
        }
        titleLabel.attributedText = viewModel.evdNavAttrTitle
        navigationItem.titleView = titleLabel
    }
    
    // Todo: Implement
    func applyLiveScoreUpdate() {
        titleLabel.attributedText = viewModel.evdNavAttrTitle
        navigationItem.titleView = titleLabel
    }
    
    func checkStatus() {
        guard let tableView = self.tableView else { return }
        if viewModel.eventDetails?.display == false && tableView.backgroundView == nil {
            // make background view with message
            let margin: CGFloat = 20.0
            let labelFrame = CGRect(x: margin, y: 0.0, width: tableView.frame.width - margin*2, height: tableView.frame.height)
            let label = UILabel(frame: labelFrame)
            label.text = "Sorry, it looks like this event is no longer available."
            label.numberOfLines = 0
            label.textAlignment = .center
            label.font = WHFont.Proxima.regular(28.0).font
            tableView.backgroundView = label
            self.liftingHeader?.isHidden = true
            tableView.reloadData()
        }
        else if tableView.backgroundView != nil {
            tableView.backgroundView = nil
            self.liftingHeader?.isHidden = false
            tableView.reloadData()
        }
    }

    var tableViewRef: UITableView? { tableView }
}

private var totalCurrentRowsForSection: [Int: Int] = [:]

extension EventDetailsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { viewModel.numberSections() }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let result = viewModel.numberRows(section)
        totalCurrentRowsForSection[section] = result
        return result
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section : Int = indexPath.section
        let row     : Int = indexPath.row
        
        guard let ev = viewModel.eventDetails, let tabData = viewModel.getEVDTabData(), let evdSection = viewModel.getEVDSectionData(section) else { return .init() }
        let isExpanded = !viewModel.collapsedSections.contains(section)
        let groupType = evdSection.groupType ?? .unGrouped
        
        if row == 0 {
            if groupType == .sixPack, tabData.filterTabTitle == "Popular", section == 0,
               let cell = tableView.dequeueReusableCell(withIdentifier: WHCell.mspSixPackTableCell.reuseId, for: indexPath) as? MSPTableViewCell {
                
                cell.configureMagicSixPackCell(ev, .textOnly, evdSection.popularSixPackMarkets)
                cell.mainTitleLabel.text = "Popular Bets"
                if cell.topSpaceConstraint.constant != 26.0 { cell.topSpaceConstraint.constant = 26.0 }
                cell.removeEVDTapGesture()
                cell.delegate = self
                return cell
            }
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: WHCell.evdSectionCell.reuseId, for: indexPath) as? EVDSectionCell {
                cell.contentView.tag = section
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapHeader(_:)))
                cell.contentView.addGestureRecognizer(tapGesture)
                cell.updateBottomSpacing(isExpanded, groupType)
                var showSGPBadge = false
                
                if groupType == .sixPack {
                    showSGPBadge = ev.byoEligible ?? false
                } else if let mktTab = (viewModel.eventDetails?.marketTabs ?? []).first(where: {$0.name == "Same Game Parlay"}), let mkId = evdSection.markets.first?.id {
                    showSGPBadge = mktTab.marketIds.contains(mkId)
                }
                
                cell.setLabelAttributedText(WHAttr.getEVDSectionHeader(evdSection.sectionHeaderTitle, showSGPBadge))
                return cell
            }
        }
        
        if row == 1 {
            if groupType == .slider, let homeTeam = ev.homeTeam, let awayTeam = ev.awayTeam, let market = evdSection.markets.first,
               let cell = tableView.dequeueReusableCell(withIdentifier: WHCell.evdAltSpreadCell.reuseId, for: indexPath) as? EVDAltSpreadCell {
                cell.configSliderCell(market, homeTeam, awayTeam)
                cell.lhsBtn?.addTarget(self, action: #selector(tappedBetslipButton(_:)), for: .touchUpInside)
                cell.rhsBtn?.addTarget(self, action: #selector(tappedBetslipButton(_:)), for: .touchUpInside)
                return cell
            }
            
            if groupType == .sixPack, let cell = tableView.dequeueReusableCell(withIdentifier: WHCell.mspSixPackTableCell.reuseId, for: indexPath) as? MSPTableViewCell {
                cell.configureMagicSixPackCell(ev, .allHidden, evdSection.markets)
                cell.removeEVDTapGesture()
                cell.trimMarketTitlesCategory()
                cell.delegate = self
                if cell.topSpaceConstraint.constant != 0.0 { cell.topSpaceConstraint.constant = 0.0 }
                return cell
            }
            
            if groupType == .tabs, let cell = tableView.dequeueReusableCell(withIdentifier: WHCell.evdTabsGroupingCell.reuseId, for: indexPath) as? EVDTabsGroupingCell {
                
                if let adjustedData = viewModel.adjustedSectionData["\(viewModel.selectedMktColIndex),\(section)"], viewModel.selectedMktColIndex < viewModel.evdTabsData.count {
                    let evdSections = viewModel.evdTabsData[viewModel.selectedMktColIndex].evdSections
                    guard section < evdSections.count else { fatalError() }
                    cell.configDataAdjustController(viewModel.selectedMktColIndex, section, evdSections[section], adjustedData, self)
                } else {
                    cell.configDataAdjustController(viewModel.selectedMktColIndex, section, evdSection, nil, self)
                }
                return cell
            }
        }
        
        let numOfDataRows = viewModel.numberOfEvdDataRows(evdSection)
        let totalCurrentRows = viewModel.numberRows(section)
        
        if numOfDataRows > 4, row == totalCurrentRows-1 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: WHCell.evdShowAllCell.reuseId, for: indexPath) as? EventDetailsShowAllCell {
                cell.section = section
                cell.delegate = self
                cell.showAllBtn.setTitle("Show \(viewModel.sectionsShowingAllRows.contains(section) ? "Less" : "\(numOfDataRows - 4) More")", for: .normal)
                return cell
            }
        }
        let rowDataIdx = min(evdSection.evdRows.count-1, row - viewModel.numberOfNonDataHeaderRows(evdSection))
        let rowData = evdSection.evdRows[rowDataIdx]
        
        if rowData.cellType == .evdCompactCell, let cell = tableView.dequeueReusableCell(withIdentifier: WHCell.evdCompactCell.reuseId) as? EVDCompactMarketCell {
            
            cell.configCell(rowData)
//            cell.packButtons?.forEach({ $0.addTarget(self, action: #selector(tappedBetslipButton(_:)), for: .touchUpInside) })
            return cell
        }
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: WHCell.evdSelectionCell.reuseId) as? EventDetailMarketSelectionCell {
            let customText = rowData.metadata?.player ?? rowData.selections.first?.name.rp
            cell.populate(market: rowData.market, rowData.selections, groupType == .tabs ? customText : nil, viewModel.adjustedSectionData["\(viewModel.selectedMktColIndex),\(section)"], viewModel.teamDataGroup)
            cell.spBtns.forEach({ $0.addTarget(self, action: #selector(tappedBetslipButton(_:)), for: .touchUpInside) })
            cell.adjustBottomSpace(numOfDataRows <= 4 && row == totalCurrentRows-1)
            cell.layoutIfNeeded()
            
            return cell
        }
                
        fatalError("EVD failed to construct cell")
    }
    
    @objc func tappedBetslipButton(_ sender: UISixPackButton) {
        //
    }
    
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        tableView.diffusionSubscribeCheck()
//    }
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
    
    func expandLiftingHeader(_ willExpand: Bool = true) {
        DispatchQueue.main.async { [self] in
            
            guard let tableView = tableView else { return }
            let minHeight: CGFloat = viewModel.minOperatingHeight
            let maxHeight: CGFloat = viewModel.maxOperatingHeight
            
            let newHeaderOrigin = (willExpand ? 0.0 : minHeight - maxHeight) + tableView.frame.origin.y
            let headerOriginDiff = liftingHeaderOriginY-newHeaderOrigin
            UIView.animate(withDuration: 0.35) {
                self.liftingHeaderOriginY = newHeaderOrigin
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
            } completion: { [self] _ in
                tableView?.reloadData()
                processFooterHeight()
            }
        }
    }
}

// MARK: - FilterView Delegate Methods

extension EventDetailsViewController: FilterViewDelegate {
    func didSelectItem(_ index: Int) {
        guard (tableView?.contentSize.height ?? 0.0) > 10.0 else {
            // If tableView content is zero, avoid offset adjustment code
            viewModel.setSelectedMktCollectionIndex(index)
            tableView?.reloadData()
            processFooterHeight()
            return
        }
        
        tableView?.tableFooterView?.frame.size.height += 600.0
        tableView?.contentOffset.y = -currentHeaderHeight
        UIView.animate(withDuration: 0.2, delay: 0.05, options: []) {
            // Hack to perform tableView reloadData sometime after above contentOffset. DispatchQueue resulted in crashes
        } completion: { [self] _ in
            viewModel.setSelectedMktCollectionIndex(index)
            tableView?.reloadData()
            processFooterHeight()
        }
    }
}

// MARK: - DiffableVCOwner

extension EventDetailsViewController: DiffableVCOwner {
    var vmRef: DiffusionUpdatableVM? { viewModel }
}

// MARK: - EVD Data Adjust Delegate (tab cells etc.)

extension EventDetailsViewController: EVDDataAdjustDelegate {
    func evdDataWasAdjusted(_ dataKey: String, _ section: Int, _ adjustedData: EVDSectionData?) {
        viewModel.adjustedSectionData[dataKey] = adjustedData
        tableView?.reloadSections([section], with: .automatic)
        processFooterHeight()
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
