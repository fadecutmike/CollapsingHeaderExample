//
//  File.swift
//  WH_CZR_SBK
//
//  Created by Serxhio Gugo on 3/2/21.
//  Copyright © 2021 Caesar's Entertainment. All rights reserved.
//

import UIKit

extension UICollectionView {

    /// Method for registering WHCell enum cases with one line
    /// - Parameter cell: WHCell enum case
    func registerWHCell(_ cell: WHCell) {
        self.register(cell.nib, forCellWithReuseIdentifier: cell.reuseId)
    }

    func registerWHCells(_ cells: [WHCell]) {
        cells.forEach { registerWHCell($0) }
    }

    func registerWHCellWithSupplementaryView(_ cell: WHCell) {
        self.register(cell.nib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: cell.reuseId)
    }

    var widestCellWidth: CGFloat { bounds.width - (contentInset.left + contentInset.right) }
}

// MARK: - Refresh control UICollectionView
extension UICollectionView {

    func setupRefreshControl(_ handler: @escaping () -> Void) {
        let refresh = UIRefreshControl(frame: .zero, primaryAction: UIAction(handler: { [weak self] _ in
            handler()
            
            self?.resetRefreshControl(2.0)
        }))
        refreshControl = refresh
    }

    /// Resets tableView UIRefreshControl (pull to refresh control)
    /// - Parameter delay: optional parameter defining a delay in seconds
    func resetRefreshControl(_ delay: Double = 0.0) {
        DispatchQueue.main.asyncAfter(deadline: .now()+delay) { [weak self] in
            if self?.refreshControl?.isRefreshing ?? false {
                UIView.animate(withDuration: 0.35) {
                    self?.contentOffset = .zero
                    self?.refreshControl?.endRefreshing()
                }
            }
        }
    }
}

// MARK: - FilterView Extensions
extension UICollectionView {
    func horizFullyOnScreenXOffset(_ rect: CGRect) -> CGRect? {
        let cutOnLeft = rect.minX - bounds.origin.x
        let cutOnRight = (bounds.origin.x + bounds.width) - rect.maxX
        guard let xOffset = cutOnLeft < 0 ? (cutOnLeft - 4.0) : cutOnRight < 0 ? abs(cutOnRight) + 4.0 : nil else { return nil }

        return .init(x: bounds.origin.x + xOffset, y: 0.0, width: bounds.width, height: bounds.height)
    }

    func updateItemLayout(_ shouldAnimate: Bool = false) {
        collectionViewLayout.invalidateLayout()
        if shouldAnimate {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: [.allowAnimatedContent]) { self.layoutIfNeeded() }
        } else {
            self.layoutIfNeeded()
        }
    }
}
