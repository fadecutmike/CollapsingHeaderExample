//
//  HeaderVC.swift
//  MDCollapsingHeader
//
//  Created by Michael Dimore on 11/30/21.
//

import UIKit

protocol HeaderDelegate: AnyObject {
    func btnPressed()
}

class HeaderVC: UIViewController {
    
    weak var delegate: HeaderDelegate?
    @IBOutlet var sbButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func headerButtonPressed(_ sender: UIButton) {
        delegate?.btnPressed()
    }
}
