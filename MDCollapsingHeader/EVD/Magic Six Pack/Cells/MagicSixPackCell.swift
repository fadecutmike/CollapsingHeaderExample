//
//  MagicSixPackCell.swift
//  WH_CZR_SBK
//
//  Created by Michael Dimore on 2/12/22.
//  Copyright © 2022 Caesar's Entertainment. All rights reserved.
//

import UIKit
import WHSportsbook

//protocol MagicSixPackCellDelegate: WHViewController {}

class MagicSixPackCell: UICollectionViewCell, MSPBaseCell {

    @IBOutlet weak var mainTitleLabel: UILabel!
    @IBOutlet weak var topSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var sgpIcon: UIImageView!
    
    @IBOutlet var teamNameLbls: [UILabel]!
    @IBOutlet var teamScoresLbls: [UILabel]!
    @IBOutlet var teamLogoImgs: [UIImageView]!
    
    @IBOutlet var marketLabels: [UILabel]!
    @IBOutlet var upperPackBtns: [UISixPackButton]!
    @IBOutlet var lowerPackBtns: [UISixPackButton]!
    
    var event         : WHSportsbook.Event?
    var mspLabelState : MSPMainLabelState = .standard
//    weak var delegate : MagicSixPackCellDelegate?
    var teamNamesData : TeamNamesData?
    var teamNames     : TeamNames?

    override func awakeFromNib() {
        super.awakeFromNib()
        allSixPackBtns.forEach({ $0.applyStyling() })
        mainTitleLabel.setFontProxima(.regular(14.0))
        
        if let teamsParent = upperTeamLbl.superview?.superview {
            mainTitleLabel.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openEventDetailsPage)))
            teamsParent.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openEventDetailsPage)))
        }
    }
    
//    override func customCZKLogic() {
//        allSixPackBtns.forEach({ $0.refreshLabelTextColors(); $0.applyStyling() })
//    }

    override func prepareForReuse() {
        super.prepareForReuse()
        prepareForReuseBaseMethod()
    }
    
    // MARK: - IB actions
    @objc func openEventDetailsPage() {
//        NavCoordinator.shared.request(type: .eventDetails(event?.id ?? "err"))
    }

    @IBAction func packButtonPressed(_ sender: UISixPackButton) {
//        if let market = sender.market, let event = self.event,
//           let selection = sender.selection, let vc = delegate {
//            let betslipSelection = BetslipSelection(event: event, market: market, selection: selection)
//            vc.showBetslip(selection: betslipSelection)
//        }
    }
}

extension MagicSixPackCell: UpdatablePackElement {}
