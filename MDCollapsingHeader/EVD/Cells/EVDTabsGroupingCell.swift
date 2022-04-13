//
//  EVDTabsGroupingCell.swift
//  WH_CZR_SBK
//
//  Created by Michael Dimore on 2/4/22.
//  Copyright © 2021 Caesar's Entertainment. All rights reserved.
//

import WHSportsbook
import UIKit

class EVDTabsGroupingCell: UITableViewCell {
    
    @IBOutlet var tabButtons: [UIButton]?
    @IBOutlet var selectionIndicator: UIView?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
    
    @IBAction func tabButtonPressed(_ sender: UIButton) {
        if let idx = tabButtons?.firstIndex(of: sender) {
            
        }
    }
}
