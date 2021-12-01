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
    
    /// The CGFloat value that controls the top elevator lift constraint of the HeaderView
    @IBOutlet weak var fullyExpandedHeightConstraint: NSLayoutConstraint!
    private(set) var headerOperatingHeightVal: CGFloat = 0.0 {
        didSet { fullyExpandedHeightConstraint.constant = headerOperatingHeightVal }
    }
    
    lazy var maxOperatingHeight: CGFloat = fullyExpandedHeightConstraint.constant {
        didSet {
            headerOperatingHeightVal = maxOperatingHeight
            expandedHeightDiff = maxOperatingHeight - oldValue
        }
    }
    
    var minOperatingHeight: CGFloat = 72.0
    private(set) var expandedHeightDiff: CGFloat = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
                
        if headerOperatingHeightVal == 0.0 {
            DispatchQueue.main.async { [self] in
                headerOperatingHeightVal = fullyExpandedHeightConstraint.constant
            }
        }
        
        expandHeaderFully()
    }
    
    func updateHeaderHeights(_ minHeight: CGFloat? = nil, _ maxHeight: CGFloat? = nil) {
        if let val = minHeight { minOperatingHeight = val }
        if let val = maxHeight { maxOperatingHeight = val }
    }
        
    @IBAction func headerButtonPressed(_ sender: UIButton) {
        
        DispatchQueue.main.async { [self] in
            let shouldCollapse = maxOperatingHeight > 300.0
            maxOperatingHeight = shouldCollapse ? 250.0 : 376.0
            
            print("\n\t\t btnPressed - yOff: \(tableView.contentOffset.y.shortStr), exHDiff: \(expandedHeightDiff.shortStr),\t fullyExpVal: \(headerOperatingHeightVal.shortStr)\n")
            sender.setTitle("\(shouldCollapse ? "Show" : "Hide") Scoreboard", for: .normal)
        }
        
        if expandedHeightDiff > 0 {
            expandHeaderFully()
        } else {
            collapseScoreboard()
        }
        
        UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
    }
    
    private func expandHeaderFully() {
        DispatchQueue.main.async { [self] in
            print("\n\t\t expandHeaderFully(1) began - yOff: \(tableView.contentOffset.y.shortStr), yInset: \(tableView.contentInset.top.shortStr),\t expandDiff: \(expandedHeightDiff.shortStr)")
            self.tableView.contentInset.top = maxOperatingHeight
            self.tableView.contentOffset.y = maxOperatingHeight
            print("\t\t expandHeaderFully(2) ended - yOff: \(tableView.contentOffset.y.shortStr), yInset: \(tableView.contentInset.top.shortStr),\t expandDiff: \(expandedHeightDiff.shortStr)\n")
        }
    }
    
    private func collapseScoreboard() {
        DispatchQueue.main.async { [self] in
            print("\n\t\t collapseScoreboard(1) began - yOff: \(tableView.contentOffset.y.shortStr), yInset: \(tableView.contentInset.top.shortStr),\t expandDiff: \(expandedHeightDiff.shortStr)")
            tableView.contentInset.top += expandedHeightDiff
            tableView.contentOffset.y += expandedHeightDiff
            print("\n\t\t collapseScoreboard(2) ended - yOff: \(tableView.contentOffset.y.shortStr), yInset: \(tableView.contentInset.top.shortStr),\t expandDiff: \(expandedHeightDiff.shortStr)")
        }
    }
}

// MARK:- ScrollViewContaining Delegate

extension ContainingViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if (scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating) {
            
            let modVal       : CGFloat = scrollView.contentInset.top + scrollView.contentOffset.y
            let insetTop     : CGFloat = max(minOperatingHeight, tableView.contentInset.top - modVal)
            let headerHeight : CGFloat = max(minOperatingHeight, headerOperatingHeightVal - modVal)
            
            print("didScroll - insetTop: \(insetTop.shortStr),\t headerH: \(headerHeight.shortStr)")
            
            tableView.contentInset.top = min(maxOperatingHeight, insetTop)
            headerOperatingHeightVal = min(maxOperatingHeight, headerHeight)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate { finishedScrollSmoothHeaderUpdate() }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        finishedScrollSmoothHeaderUpdate()
    }
        
    private func finishedScrollSmoothHeaderUpdate() {
        DispatchQueue.main.async { [self] in
            UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
        }
    }
}

// MARK:- TableView delegate and datasource methods

extension ContainingViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView)                                -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)    -> Int { 3 }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0.0 }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = "\(indexPath.row)"
        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 18.0 }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
