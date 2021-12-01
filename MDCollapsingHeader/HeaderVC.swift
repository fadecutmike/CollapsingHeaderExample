//
//  HeaderVC.swift
//  MDCollapsingHeader
//
//  Created by Michael Dimore on 11/30/21.
//

import UIKit

protocol EVDHeaderDelegate: AnyObject {
    func btnPressed()
}

class HeaderVC: UIViewController {
    
    weak var delegate: EVDHeaderDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func headerButtonPressed(_ sender: UIButton) {
        delegate?.btnPressed()
    }
}
