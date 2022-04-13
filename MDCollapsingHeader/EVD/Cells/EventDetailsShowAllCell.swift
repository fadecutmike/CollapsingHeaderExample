//
//  EventDetailsShowAllCell.swift
//  WH_CZR_SBK
//
//  Created by Samuel Goldsmith on 11/1/21.
//  Copyright © 2021 Caesar's Entertainment. All rights reserved.
//

import UIKit

protocol EVDShowAllDelegate: AnyObject {
    func didTapFooter(_ section: Int)
}

class EventDetailsShowAllCell: UITableViewCell {
    
    @IBOutlet weak var showAllBtn: UIButton!
    var section: Int = -1
    weak var delegate: EVDShowAllDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        delegate = nil
        section = -1
    }

    @IBAction func showAllBtnTapped(_ sender: UIButton) {
        delegate?.didTapFooter(section)
    }
}
