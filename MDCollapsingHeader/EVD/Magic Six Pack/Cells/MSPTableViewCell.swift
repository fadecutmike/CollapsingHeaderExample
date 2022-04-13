//
//  MSPTableViewCell.swift
//  WH_CZR_SBK
//
//  Created by Michael Dimore on 2/12/22.
//  Copyright © 2022 Caesar's Entertainment. All rights reserved.
//

import UIKit
import WHSportsbook

class MSPTableViewCell: UITableViewCell, MSPBaseCell {
    
    @IBOutlet weak var mainTitleLabel: UILabel!
    @IBOutlet weak var topSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var sgpIcon: UIImageView!
    
    @IBOutlet var teamNameLbls: [UILabel]!
    @IBOutlet var teamScoresLbls: [UILabel]!
    @IBOutlet var teamLogoImgs: [UIImageView]!
    
    @IBOutlet var marketLabels: [UILabel]!
    @IBOutlet var upperPackBtns: [UISixPackButton]!
    @IBOutlet var lowerPackBtns: [UISixPackButton]!
    
    var event: WHSportsbook.Event?

    override func awakeFromNib() {
        super.awakeFromNib()
        allSixPackBtns.forEach({ $0.applyStyling() })
        
        if let teamsParent = upperTeamLbl.superview?.superview {
            mainTitleLabel.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openEventDetailsPage)))
            teamsParent.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openEventDetailsPage)))
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        prepareForReuseBaseMethod()
    }
    
    // MARK: - IB actions
    @objc func openEventDetailsPage() {
        //
    }

    @IBAction func packButtonPressed(_ sender: UISixPackButton) {
//        sender.shouldHighlightIndicator(sender.highlightIndicatorBar.alpha == 0)
    }
}

extension MSPTableViewCell: UpdatablePackElement {}
