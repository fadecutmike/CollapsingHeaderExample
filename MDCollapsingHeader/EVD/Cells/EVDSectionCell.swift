//
//  EVDSectionCell.swift
//  WH_CZR_SBK
//
//  Created by Mike Dimore on 1/20/22.
//  Copyright © 2021 Caesar's Entertainment. All rights reserved.
//

import UIKit

class EVDSectionCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel : UILabel!
    @IBOutlet weak var arrowIcon  : UIImageView!
    @IBOutlet weak var sgpIcon    : UIImageView!
    @IBOutlet weak var heightCon  : NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setFontProxima(.bold(18.0))
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        sgpIcon.isHidden = true
    }
    
    func updateBottomSpacing(_ isExpanded: Bool) {
        heightCon.constant = [60.0, 72.0][isExpanded.intValue]
    }
    
    func updateBottomSpacingForSixPack(_ isExpanded: Bool) {
        heightCon.constant = [60.0, 50.0][isExpanded.intValue]
    }
}
