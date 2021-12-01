//
//  ContainingViewController.swift
//  TestCollapsingHeader
//
//  Created by Samuel Shiffman on 9/25/20.
//

import UIKit

// MARK:- Containing ViewController
class ContainingViewController: UIViewController, EVDHeaderDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    /// The CGFloat value that controls the top elevator lift constraint of the HeaderView
    @IBOutlet weak var fullyExpandedHeightConstraint: NSLayoutConstraint!
    
    /// Active Header height
    private(set) var headerOperatingHeightVal: CGFloat = 0.0 {
        didSet { fullyExpandedHeightConstraint.constant = headerOperatingHeightVal }
    }
    
    /// The largest size the Header can expand to
    lazy var maxOperatingHeight: CGFloat = fullyExpandedHeightConstraint.constant {
        didSet {
            headerOperatingHeightVal = maxOperatingHeight
            expandedHeightDiff = maxOperatingHeight - oldValue
        }
    }
    
    /// The smallest height the Header will collapse to
    private(set) var minOperatingHeight: CGFloat = 72.0
    
    /// Parameter that stores `oldValue` values from `maxOperatingDiff` didSet property observer
    /// Easily close expanded elements like a scoreboard webView
    private(set) var expandedHeightDiff: CGFloat = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
                        
        // By default, open with header fully expanded
        expandHeaderFully()
    }
    
    func updateHeaderHeights(_ minHeight: CGFloat? = nil, _ maxHeight: CGFloat? = nil) {
        if let val = minHeight { minOperatingHeight = val }
        if let val = maxHeight { maxOperatingHeight = val }
    }
    
    private func expandHeaderFully() {
        headerOperatingHeightVal   = maxOperatingHeight
        tableView.contentOffset.y  = -maxOperatingHeight
        tableView.contentInset.top = maxOperatingHeight
    }
    
    private func collapseScoreboard() {
        tableView.contentInset.top += expandedHeightDiff
        tableView.contentOffset.y  += expandedHeightDiff
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let vc = segue.destination as? HeaderVC { vc.delegate = self }
    }
}

// MARK:- ScrollViewContaining Delegate

extension ContainingViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if (scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating) {
            headerOperatingHeightVal   = computeFloatVal(headerOperatingHeightVal)
            tableView.contentInset.top = computeFloatVal(tableView.contentInset.top)
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
    
    private func computeFloatVal(_ input: CGFloat) -> CGFloat {
        let modVal: CGFloat = tableView.contentInset.top + tableView.contentOffset.y
        let result: CGFloat = max(minOperatingHeight, input - modVal)
        return min(maxOperatingHeight, result)
    }
    
    func btnPressed() {
        let shouldCollapse = maxOperatingHeight > 300.0
        maxOperatingHeight = shouldCollapse ? 250.0 : 376.0
        _ = expandedHeightDiff > 0 ? expandHeaderFully() : collapseScoreboard()
        UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
    }
}

// MARK:- TableView delegate and datasource methods

extension ContainingViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)    -> Int { 110 }
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
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
