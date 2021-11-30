//
//  ContainingViewController.swift
//  TestCollapsingHeader
//
//  Created by Samuel Shiffman on 9/25/20.
//

import UIKit

// MARK:- Containing ViewController
class ContainingViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    /// Header view or container for header view
    @IBOutlet weak var headerView: UIView!
    
    /// Constraint between the top of headerView and the top of the screen
    @IBOutlet weak var headerViewTop: NSLayoutConstraint!

    /// The minimum height of the header (fully collapsed header)
    let minHeight: CGFloat = 100.0
    
    /// The maximum height of the header (fully expanded header)
    let maxHeight: CGFloat = 500.0

    /// how far the header view gets scrolled offscreen
    var maxScrollAmount: CGFloat { maxHeight - minHeight }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // adjust the scroll view's top inset to account for scrolling the header offscreen
        tableView.contentInset = UIEdgeInsets(top: maxScrollAmount, left: 0.0, bottom: 0.0, right: 0.0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now()+2.0) { [self] in
            print("\n\n\t\t\t setting tableView.contentOffset to \(tableView.contentInset.top.shortStr)\n\n")
            tableView.setContentOffset(.init(x: 0.0, y: tableView.contentInset.top), animated: true)
            
            headerViewTop.constant = 0.0
            view.layoutIfNeeded()
            
        }
    }
}

// MARK:- ScrollViewContaining Delegate

extension ContainingViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        print("\t\t scrollViewDidScroll began(A) - cont.off.y: \(scrollView.contentOffset.y.shortStr),\t cont.ins.top: \(scrollView.contentInset.top.shortStr),\t\t headerViewTop.con: \(headerViewTop.constant.shortStr) ")
        
        // need to adjust the content offset to account for the content inset
        // negative because we are moving the header offscreen
        let newTopConstraintConstant = -(scrollView.contentOffset.y + scrollView.contentInset.top)
        headerViewTop.constant = min(0, max(-maxScrollAmount, newTopConstraintConstant))
        
        print("\t\t scrollViewDidScroll ended(B) - cont.off.y: \(scrollView.contentOffset.y.shortStr),\t cont.ins.top: \(scrollView.contentInset.top.shortStr),\t\t headerViewTop.con: \(headerViewTop.constant.shortStr) ")

        // handle color changes for collapsed state, check if scrollView is at the top
        headerView.backgroundColor = headerViewTop.constant == -maxScrollAmount ? .green : .systemIndigo
    }
}

// MARK:- TableView delegate and datasource methods

extension ContainingViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView)                                -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)    -> Int { 100 }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0.0 }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath) as! TVC
        cell.titleLabel.text = "\(indexPath.row)"
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { UITableView.automaticDimension }
}

// MARK:- TableView Cell
class TVC: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
}
