//
//  UITableView+Extensions.swift
//  WH_CZR_SBK
//
//  Created by Michael Dimore on 7/14/21.
//  Copyright © 2021 Caesar's Entertainment. All rights reserved.
//

import UIKit

// MARK: - Register helpers
extension UITableView {

    /// Method for registering WHCell enum cases with one line
    /// - Parameter cell: WHCell enum case
    func registerWHCell(_ cell: WHCell) {
        register(cell.nib, forCellReuseIdentifier: cell.reuseId)
    }

    func registerWHCells(_ cells: [WHCell]) {
        cells.forEach { registerWHCell($0) }
    }

    /// Register method specifically for custom Header/Footers
    /// - Parameter cell: WHCell enum case
    func registerWHCellHeaderFooter(_ cell: WHCell) {
        register(cell.nib, forHeaderFooterViewReuseIdentifier: cell.reuseId)
    }
}

// MARK: - AutoScroll reload section
extension UITableView {
    /// Method for identifying whether a tableView section header is partly on screen - either cut off on top, or on bottom. Ignores section headers that are fully displayed
    /// - Parameter section: The tableView section to be reloaded
    /// - Returns: CGFloat value that can be added to the contentOffset.y value of a tableView to bring the section header in question fully on screen
    func sectionFullyDisplayedOffset(_ section: Int) -> CGFloat? {
        if section == 0 { return contentOffset.y == 0 ? nil : -contentOffset.y }

        let headerRect = rectForHeader(inSection: section)
        var cell = visibleCells.first(where: { indexPath(for: $0) == IndexPath(row: 0, section: section)  })
        if cell == nil { cell = visibleCells.last }

        // If tableView is using headerViews, add the headerView height to offset, check value against max offset for table
        let rectHeight = (cell?.frame.height ?? 0) + headerRect.height

        let gettingCutOnTop = headerRect.origin.y - (contentOffset.y + 4.0)
        if gettingCutOnTop < 0 { return max(gettingCutOnTop, -contentOffset.y) }

        let tooFarDown = (headerRect.maxY + rectHeight + 4.0) - bounds.maxY
        if tooFarDown - rectHeight/4.0 > 0 {
            let maxOffset = contentSize.height - bounds.height + contentInset.bottom
            return min(tooFarDown, maxOffset)
        }

        return nil
    }

    /// Method which checks if the tableView should scroll before reloading a section in order to bring it fully on screen
    /// - Parameter section: The tableView section to be reloaded
    func autoScrollReloadSection(_ section: Int) {

        if let offsetVal = sectionFullyDisplayedOffset(section) {
            UIView.animate(withDuration: 0.1) {
                self.contentOffset.y += offsetVal
            } completion: { _ in
                self.reloadSections([section], with: .automatic)
            }
        } else {
            reloadSections([section], with: .automatic)
        }
    }
}

// MARK: - Refresh control UITableView
extension UITableView {
    
    func setupCustomEVDRefreshControl(_ handler: @escaping () -> ()) {
        let refresh = UIRefreshControl(frame: .zero, primaryAction: .init(handler: { _ in handler() }))
        refreshControl = refresh
    }
    
    func finishAndResetRefreshControl(_ offsetY: CGFloat) {
        DispatchQueue.main.async { [weak self] in
            if self?.refreshControl?.isRefreshing ?? false {
                self?.setContentOffset(.init(x: self?.contentOffset.x ?? 0.0, y: offsetY), animated: true)
                self?.refreshControl?.endRefreshing()
            }
        }
    }

    func setupRefreshControl(_ handler: @escaping () -> Void) {
        let refresh = UIRefreshControl(frame: .zero, primaryAction: UIAction(handler: { [weak self] _ in
            handler()
            
            self?.resetRefreshControl(2.0)
        }))
        refreshControl = refresh
    }

    // TODO: Ensure Dispatch call below is neccesary, remove if not
    
    /// Resets tableView UIRefreshControl (pull to refresh control)
    /// - Parameter delay: optional parameter defining a delay in seconds
    func resetRefreshControl(_ delay: Double = 0.0) {
        DispatchQueue.main.asyncAfter(deadline: .now()+delay) { [weak self] in
            if self?.refreshControl?.isRefreshing ?? false {
                UIView.animate(withDuration: 0.35) {
                    if (self?.superview?.next?.objTypeName ?? "") != "EventDetailsViewController" {
                        self?.contentOffset = .zero
                        self?.refreshControl?.endRefreshing()
                    }
                }
            }
        }
    }
}

// MARK: Loggin extension
extension UITableView {
    // for extracting label of the selected index
    public func labelText(for indexPath:IndexPath) -> String? {
        guard let cell = self.cellForRow(at: indexPath) else { return nil }
        
        // go through any stack views
        // TODO: find a recusive way to loop through subviews and pick out which ones have subviews
        let stacks = cell.contentView.subviews.compactMap { $0 as? UIStackView }
        var stackLabels:[UILabel] = []
        for stack in stacks {
            stackLabels += stack.subviews.compactMap { $0 as? UILabel }
        }
        
        // then any labels on the cell
        let labels = cell.contentView.subviews.compactMap { $0 as? UILabel }
        let finalLabels = labels + stackLabels
        
        // if theres more than one, we smack em together for now
        var labelTexts = ""
        for label in finalLabels {
            if let text = label.text { labelTexts.append(" \(text)") }
        }
        
        return !labelTexts.isEmpty ? labelTexts : nil
    }
}
