//
//  EventDetailTableCell.swift
//  WH_CZR_SBK
//
//  Created by Josh Kimmelman on 4/12/21.
//  Copyright © 2021 Caesar's Entertainment. All rights reserved.
//

import Foundation
import WHSportsbook
import UIKit

class EventDetailTableCell: UITableViewCell {
    var titleView     : UILabel? { get { return self.contentView.viewWithTag(444) as? UILabel } }
    var headerStack   : UIStackView? { get { return self.contentView.viewWithTag(555) as? UIStackView } }
    var buttonStack   : UIStackView? { get { return self.contentView.viewWithTag(777) as? UIStackView } }
    var event         : WHSportsbook.Event?
    var market        : WHSportsbook.Market?
    var selections    : WHSportsbook.Selections = []
//    weak var delegate : MagicSixPackCellDelegate?

    @objc func tappedBetslipButton(_ sender: UISixPackButton) {
//        if let market = sender.market,
//           let selection = sender.selection, let vc = delegate {
//            sender.shouldHighlightIndicator(sender.highlightIndicatorBar.alpha == 0)
//            let betslipSelection = BetslipSelection(event: event ?? .init(market.eventId ?? ""), market: market, selection: selection)
//            vc.showBetslip(selection: betslipSelection)
//        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        selections      = []
//        delegate        = nil
        market          = nil
        titleView?.text = nil
        headerStack?.arrangedSubviews.forEach({ ($0 as? UILabel)?.text = nil })
        
        spBtns.prepareButtonsForReuse()
    }
}

extension EventDetailTableCell: UpdatablePackElement {
    var spBtns: [UISixPackButton] { (buttonStack?.arrangedSubviews ?? []).compactMap({$0 as? UISixPackButton}) }
}

class EventDetailMarketTemplateCell: EventDetailTableCell {
    func populate(event: WHSportsbook.Event?, market: WHSportsbook.Market?, selectionUpdate: DiffusionSelectionUpdate? = nil, marketUpdate: DiffusionMarketUpdate? = nil) {
        guard let market = market, let buttonStack = buttonStack, let headerStack = headerStack  else {
            print("WARNING! EventDetail header cell got a nil Market")
            return
        }

        selections = market.selections
        titleView?.text = market.displayName
        buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        headerStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        self.event = event
        self.market = market

        for selection in market.selections {
            let button = UISixPackButton(frame: CGRect(x: 0.0, y: 0.0, width: buttonStack.bounds.width/3 - 20, height: buttonStack.bounds.height))
            button.addTarget(self, action: #selector(tappedBetslipButton(_:)), for: .touchUpInside)
            
            let selVS: CZSourceType = selection.price != nil ? .selectionPrice : .selectionName
            if market.line != nil {
                button.configBtn(.centered(.init(.marketOverUnder), .init(selVS)), market, selection)
            } else {
                button.configBtn(.centered(.init(selVS), nil), market, selection)
            }
            
//            button.highlightIndicatorBar.alpha = WHLookup.highlightedSelectionIds.contains(selection.id) ? 1.0 : 0.0
            
            let title = UILabel()
            title.text = (selection.teamAbbreviation ?? selection.name).replacePipes()
            title.textAlignment = .center
            title.proximaSemiBold(size: 14.0)
            headerStack.addArrangedSubview(title)
            buttonStack.addArrangedSubview(button)
        }
    }
}

class EventDetailMarketSelectionCell: EventDetailTableCell {
    
    @IBOutlet weak var sgpIconImg: UIImageView?
    @IBOutlet weak var bottomSpacerHeight: NSLayoutConstraint?
    
    func populate(event: WHSportsbook.Event?, market: WHSportsbook.Market?, row: Int = 999, selectionUpdate: DiffusionSelectionUpdate? = nil, marketUpdate: DiffusionMarketUpdate? = nil, _ isLastCell: Bool? = false) {
        guard let buttonStack = buttonStack,
              let market = market,
              row < market.selections.count else {
            return
        }

        let selection = market.selections[row]
        selections = [selection]
        titleView?.text = (selection.teamAbbreviation ?? selection.name).replacePipes()
        buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        self.event = event
        self.market = market
        let button = UISixPackButton(frame: CGRect(x: 0.0, y: 0.0, width: buttonStack.bounds.width/3 - 20, height: buttonStack.bounds.height))
        button.addTarget(self, action: #selector(tappedBetslipButton(_:)), for: .touchUpInside)
        button.highlightIndicatorBar.alpha = WHLookup.highlightedSelectionIds.contains(selection.id) ? 1.0 : 0.0
        
        let selVS: CZSourceType = selection.price != nil ? .selectionPrice : .selectionName
        button.configBtn(.centered(.init(selVS), nil), market, selection)

        buttonStack.addArrangedSubview(button)
        
        let bottomH: CGFloat = (isLastCell ?? false) ? 20.0 : 4.0
        if (bottomSpacerHeight?.constant ?? 0.0) != bottomH {
            bottomSpacerHeight?.constant = bottomH
        }
    }
}

class EventDetailFooterCell: EventDetailTableCell {}
