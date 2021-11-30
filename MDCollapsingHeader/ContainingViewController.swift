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
        didSet {
            fullyExpandedHeightConstraint.constant = fullyExpandedHeightVal
            expandedHeightDiff = fullyExpandedHeightVal - oldValue
        }
    }
    
    private(set) var expandedHeightDiff: CGFloat = 0.0
    
    /// The CGFloat value that controls the top elevator lift constraint of the HeaderView
    private(set) var headerTopLiftVal: CGFloat = 0.0 {
        didSet { headerTopLiftConstraint.constant = headerTopLiftVal }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        updateHeaderHeights()
        
        // Use offset of `fullExpandedHeightVal` to fully expand Header on load. Use zero for a collapsed Header
        tableView.setContentOffset(.init(x: 0.0, y: fullExpandScrollVal), animated: false)
    }
    
    func updateHeaderHeights(_ minHeight: CGFloat? = nil, _ maxHeight: CGFloat? = nil) {
        if let val = minHeight { fullyCollapsedHeightVal = val }
        if let val = maxHeight { fullyExpandedHeightVal = val }
        
        if fullyCollapsedHeightVal + fullyExpandedHeightVal == 0.0 {
            fullyCollapsedHeightVal = fullyCollapsedHeightConstraint.constant
            fullyExpandedHeightVal  = fullyExpandedHeightConstraint.constant
        }
        
        tableView.contentInset = .init(top: fullyExpandedHeightVal, left: 0.0, bottom: 0.0, right: 0.0)
    }
    
    private var fullExpandScrollVal: CGFloat { fullyCollapsedHeightVal - fullyExpandedHeightVal }
    
    @IBAction func headerButtonPressed(_ sender: UIButton) {
        let shouldCollapse = fullyExpandedHeightVal > 300.0
        fullyExpandedHeightVal = shouldCollapse ? 250.0 : 375.0
        sender.setTitle("\(shouldCollapse ? "Show" : "Hide") Scoreboard", for: .normal)
        
        UIView.animate(withDuration: 0.35) { [self] in
            if !shouldCollapse { tableView.contentOffset.y -= expandedHeightDiff }
            updateTableAndHeader(tableView.contentOffset.y)
            view.layoutIfNeeded()
        }
    }
    
    /// Makes changes to Header top contstraint and tableView contentInset to achieve collapsable Header effect
    /// - Parameter yOffset: CGFloat offset value
    private func updateTableAndHeader(_ yOffset: CGFloat) {
        let newHeightVal: CGFloat = fullExpandScrollVal - yOffset
        headerTopLiftVal = min(0.0, max(fullExpandScrollVal, newHeightVal))
        
        let insetTopVal: CGFloat = min(max(0.0, -yOffset), fullyExpandedHeightVal - fullyCollapsedHeightVal)
        tableView.contentInset = .init(top: insetTopVal, left: 0.0, bottom: 0.0, right: 0.0)
    }
}

// MARK:- ScrollViewContaining Delegate

extension ContainingViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateTableAndHeader(scrollView.contentOffset.y)
        headerView.backgroundColor = headerTopLiftVal == fullExpandScrollVal ? .orange : .systemIndigo
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
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
