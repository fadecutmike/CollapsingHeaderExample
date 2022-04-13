//
//  ContainingViewController.swift
//  TestCollapsingHeader
//
//  Created by Samuel Shiffman on 9/25/20.
//

import UIKit

// MARK: - Containing ViewController
class ContainingViewController: UIViewController, HeaderDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var liftingHeader: UIView!
    var headerVC: HeaderVC!
            
    /// The largest size the Header can expand to
    var maxOperatingHeight: CGFloat = 376.0
    
    /// The smallest height the Header will collapse to
    private(set) var minOperatingHeight: CGFloat = 156.0
    
    /// Tracks the contentOffset.y value of the tableView and applies an adjustment to account for LiftingHeader so only positive values starting at zero are returned
    var lastScrollOffsetClean: CGFloat = 0.0
    
    /// A parameter for keeping track of the point when the tableView begins scrolling upward to collapse the LiftingHeader
    var lastScrollReverseOffset: CGFloat?
    
    /// A helper parameter which calculates the effictive current height of the LiftingHeader
    var currentHeaderHeight: CGFloat { (liftingHeaderOriginY + liftingHeader.frame.height) - tableView.frame.origin.y }
    
    /// Value which directly sets the origin.y parameter on the LiftingHeader
    lazy var liftingHeaderOriginY: CGFloat = tableView.frame.origin.x {
        didSet { liftingHeader.frame.origin.y = liftingHeaderOriginY }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
                        
        tableView.setContentOffset(.init(x: 0.0, y: -maxOperatingHeight), animated: false)
        tableView.contentInset.top = maxOperatingHeight
        liftingHeaderOriginY = tableView.frame.origin.y
        
        // By default, open with header fully expanded
        expandLiftingHeader()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let vc = segue.destination as? HeaderVC {
            vc.delegate = self
            headerVC = vc
        }
    }
}

// MARK: - ScrollViewContaining Delegate

extension ContainingViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if (scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating) {
            let headerHeight: CGFloat = currentHeaderHeight
                        
            // Normalized scroll offset.y value accounting for headerHeight and returning only positive offset values
            let cleanOffsetY: CGFloat = scrollView.contentOffset.y + headerHeight
            let alreadyCollapsed = lastScrollOffsetClean < cleanOffsetY && headerHeight == minOperatingHeight
            let alreadyExpanded  = lastScrollOffsetClean > cleanOffsetY && headerHeight == maxOperatingHeight
                        
            if alreadyCollapsed || alreadyExpanded {
                /// Represents scrolling where the direction and offset has no effect on the header, such as continuing to scroll down with fully collapsed header
                lastScrollReverseOffset = nil
                lastScrollOffsetClean = cleanOffsetY
                                                
                let sbTitle = headerVC.sbButton.title(for: .normal) ?? ""
                if alreadyCollapsed, sbTitle.contains("Hide") {
                    headerVC.sbButton.setTitle("Show Scoreboard", for: .normal)
                } else if alreadyExpanded, sbTitle.contains("Show") {
                    headerVC.sbButton.setTitle("Hide Scoreboard", for: .normal)
                }
                
                return
            }
            
            // Determines the point where an expanded header can begin collapsing, i.e. the instant you begin scrolling back up
            if headerHeight == maxOperatingHeight, cleanOffsetY > lastScrollOffsetClean, lastScrollReverseOffset == nil, cleanOffsetY > minOperatingHeight { lastScrollReverseOffset = cleanOffsetY }
            lastScrollOffsetClean = cleanOffsetY
            
            let maxLimit = ((tableView.frame.origin.y - maxOperatingHeight) + minOperatingHeight)
            let minLimit = min(tableView.frame.origin.y, ((tableView.frame.origin.y - max(0.0, maxOperatingHeight + scrollView.contentOffset.y)) + (lastScrollReverseOffset ?? 0.0)))
            liftingHeaderOriginY = max(maxLimit, minLimit)
        }
    }
        
    func btnPressed() {
        expandLiftingHeader(currentHeaderHeight < maxOperatingHeight)
        UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
    }
    
    func expandLiftingHeader(_ willExpand: Bool = true) {
        DispatchQueue.main.async { [self] in
            headerVC.sbButton.setTitle("\(willExpand ? "Hide" : "Show") Scoreboard", for: .normal)
            UIView.animate(withDuration: 0.35) { [self] in
                let newHeaderOrigin = (willExpand ? 0.0 : minOperatingHeight - maxOperatingHeight) + tableView.frame.origin.y
                let headerOriginDiff = liftingHeaderOriginY-newHeaderOrigin
                liftingHeaderOriginY = newHeaderOrigin
                tableView.contentOffset.y += headerOriginDiff
                lastScrollOffsetClean = tableView.contentOffset.y + currentHeaderHeight
            }
        }
    }
}


// MARK: - TableView delegate and datasource methods

extension ContainingViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)    -> Int     { 110 }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0.0 }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath)   -> CGFloat { UITableView.automaticDimension }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)     -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = "\(indexPath.row)"
        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
