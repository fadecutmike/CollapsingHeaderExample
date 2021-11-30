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
    @IBOutlet weak var headerTopLiftConstraint: NSLayoutConstraint!
        
    /// The CGFloat value that controls the top elevator lift constraint of the HeaderView
    @IBOutlet weak var fullyCollapsedHeightConstraint: NSLayoutConstraint!
    private(set) var fullyCollapsedHeightVal: CGFloat = 0.0 {
        didSet { fullyCollapsedHeightConstraint.constant = fullyCollapsedHeightVal }
    }
    
    /// The CGFloat value that controls the top elevator lift constraint of the HeaderView
    @IBOutlet weak var fullyExpandedHeightConstraint: NSLayoutConstraint!
    private(set) var fullyExpandedHeightVal: CGFloat = 0.0 {
        didSet { fullyExpandedHeightConstraint.constant = fullyExpandedHeightVal }
    }
    
    /// The CGFloat value that controls the top elevator lift constraint of the HeaderView
    private(set) var headerTopLiftVal: CGFloat = 0.0 {
        didSet { headerTopLiftConstraint.constant = headerTopLiftVal }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        updateHeaderHeights()
        tableView.setContentOffset(.init(x: 0.0, y: 0.0), animated: false)
    }
    
    func updateHeaderHeights(_ minHeight: CGFloat? = nil, _ maxHeight: CGFloat? = nil) {
        if let val = minHeight { fullyCollapsedHeightVal = val }
        if let val = maxHeight { fullyExpandedHeightVal = val }
        
        if fullyCollapsedHeightVal + fullyExpandedHeightVal == 0.0 {
            fullyCollapsedHeightVal = fullyCollapsedHeightConstraint.constant
            fullyExpandedHeightVal  = fullyExpandedHeightConstraint.constant
        }
        
        // adjust the scroll view's top inset to account for scrolling the header offscreen
        tableView.contentInset = .init(top: fullyExpandedHeightVal, left: 0.0, bottom: 0.0, right: 0.0)
    }
    
    private var maxScrollVal: CGFloat { fullyCollapsedHeightVal - fullyExpandedHeightVal }
}

// MARK:- ScrollViewContaining Delegate

extension ContainingViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let newHeightVal: CGFloat = maxScrollVal - scrollView.contentOffset.y
        headerTopLiftVal = min(0.0, max(maxScrollVal, newHeightVal))
        
        let insetTopVal: CGFloat = min(max(0.0, -scrollView.contentOffset.y), fullyExpandedHeightVal - fullyCollapsedHeightVal)
        scrollView.contentInset = .init(top: insetTopVal, left: 0.0, bottom: 0.0, right: 0.0)
        
        print("\t\t scrollViewDidScroll - cont.off.y: \(scrollView.contentOffset.y.shortStr),\t inset.top: \(scrollView.contentInset.top.shortStr),\t headerTop.con: \(headerTopLiftVal.shortStr)")

        // Changes color of header depending on collapse state
        headerView.backgroundColor = headerTopLiftVal == maxScrollVal ? .orange : .systemIndigo
    }
}

// MARK:- TableView delegate and datasource methods

extension ContainingViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView)                                -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)    -> Int { 100 }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0.0 }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = "\(indexPath.row)"
        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { UITableView.automaticDimension }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        fullyCollapsedHeightVal = fullyCollapsedHeightVal < 200.0 ? 220.0 : 140.0
        UIView.animate(withDuration: 0.5) { [self] in
            view.layoutIfNeeded()
            let newHeightVal: CGFloat = maxScrollVal - tableView.contentOffset.y
            headerTopLiftVal = min(0.0, max(maxScrollVal, newHeightVal))
            
            let insetTopVal: CGFloat = min(max(0.0, -tableView.contentOffset.y), fullyExpandedHeightVal - fullyCollapsedHeightVal)
            tableView.contentInset = .init(top: insetTopVal, left: 0.0, bottom: 0.0, right: 0.0)
        }
    }
}
