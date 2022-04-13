//
//  EventDetailTableCell.swift
//  WH_CZR_SBK
//
//  Created by Josh Kimmelman on 4/12/21.
//  Copyright © 2021 Caesar's Entertainment. All rights reserved.
//

import WHSportsbook
import UIKit

class EventDetailMarketSelectionCell: UITableViewCell {
    
    @IBOutlet weak var bottomSpacerHeight: NSLayoutConstraint?
    @IBOutlet weak var buttonStackWidth: NSLayoutConstraint?
    
    @IBOutlet weak var titleView   : UILabel?
    @IBOutlet weak var buttonStack : UIStackView?
    var isTabsGroupCell            : Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleView?.font = .refrigerator(.bold(18.0))
        titleView?.isAccessibilityElement = false
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleView?.text = nil
        isTabsGroupCell = false
        spBtns.forEach({$0.prepBtnForReuse()})
    }
    
    /// Adds a bit of space to bottom of EVD cell if Show More/Less button isn't display and it is the last cell for a section
    /// - Parameter shouldAddSpacing: Bool determining whether to add spacing or not
    func adjustBottomSpace(_ shouldAddSpacing: Bool) {
        bottomSpacerHeight?.constant = shouldAddSpacing ? 68.0 : 54.0
        layoutIfNeeded()
    }
    
//    override func customCZKLogic() {
//        titleView?.textColor = .czkColor(isTabsGroupCell ? .info : .foreground)
//    }
    
    func populate(market: WHSportsbook.Market?, _ selections: WHSportsbook.Selections?, _ customText: String? = nil, _ adjustedData: EVDSectionData? = nil, _ abbrevNames: TeamNamesData?) {
        guard let buttonStack = buttonStack,
              let market = market else {
                  return
              }
        
        let fullTitleText = customText ?? (selections?.first?.teamAbbreviation ?? selections?.first?.name ?? "err").replacePipes()
        var titleText = fullTitleText
                
        if market.metadata?.marketDisplayType == "tabs", let tabNames = market.metadata?.tabs, tabNames.count == 2 {
            isTabsGroupCell = true
            titleView?.textColor = .czkColor(.info)

            if let tabFilterTextMap = adjustedData?.evdRows.compactMap({$0.tabFilterText?.rp}), tabFilterTextMap.count > 0 {
                
                let displayingTabOneData = tabFilterTextMap.recursiveContains(tabNames[0])
                let displayingTabTwoData = tabFilterTextMap.recursiveContains(tabNames[1])
                if displayingTabOneData != displayingTabTwoData {
                    let selectedTabIdx = displayingTabOneData ? 0 : 1
                    let strippedText = titleText.replacingOccurrences(of: "\(tabNames[selectedTabIdx]) ", with: " ")
                    titleText = strippedText
                }
            } else if let abbrevNames = abbrevNames {
                let aNames = [abbrevNames.teamOne, abbrevNames.teamTwo]
                for tabName in tabNames where aNames.compactMap({$0.teamName}).contains(tabName) {
                    if let abbr = aNames.first(where: {$0.teamName == tabName}) {
                        let strippedText = titleText.replacingOccurrences(of: tabName, with: abbr.teamAbbreviation ?? abbr.teamShortName ?? abbr.teamNickName ?? "err")
                        titleText = strippedText
                    }
                }
            }
        } else {
            isTabsGroupCell = false
            titleView?.textColor = .czkColor(.foreground)
        }
        
        titleView?.text = titleText
        
        buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for sel in selections ?? [] {
            let button = UISixPackButton(frame: .zero)
//            button.highlightIndicatorBar.alpha = WHLookup.highlightedSelectionIds.contains(sel.id) ? 1.0 : 0.0
            
            let selVS: CZSourceType = sel.price != nil ? .selectionPrice : .selectionName
            if market.metadata?.marketDisplayType == "tabs" {
                if market.metadata?.player != nil {
                    button.configBtn(.centered(.init(.selectionName, .foreground), .init(.selectionPrice)), market, sel)
                } else {
                    button.configBtn(.centered(.init(.selectionPrice, .primary), nil), market, sel)
                }
            } else {
                button.configBtn(.centered(.init(selVS), nil), market, sel)
            }
            
            let marketTitle = (market.name ?? market.displayName ?? sel.name).rp.replacingOccurrences(of: fullTitleText, with: "")
            button.accessibilityLabel = "\(fullTitleText) \(marketTitle) Data: \(button.allAttrTextJoined.replacingOccurrences(of: "\n", with: ""))"
            
            buttonStack.addArrangedSubview(button)
        }
        
        let btnCount = buttonStack.arrangedSubviews.count
        buttonStackWidth?.constant = btnCount == 1 ? 109.0 : btnCount == 2 ? 160.0 : 210.0
    }
}

extension EventDetailMarketSelectionCell: UpdatablePackElement {
    var spBtns: [UISixPackButton] { (buttonStack?.arrangedSubviews ?? []).compactMap({$0 as? UISixPackButton}) }
}
