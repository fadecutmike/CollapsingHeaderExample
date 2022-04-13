//
//  FilterDataCell.swift
//  WH_CZR_SBK
//
//  Created by Michael Dimore on 07/14/21.
//  Copyright © 2021 Caesar's Entertainment. All rights reserved.
//

import UIKit

/// Tag/Pill element for horizontally scrolling filter control on HomePage (TopCompetitions
class FilterDataCell: UICollectionViewCell {

    @IBOutlet var filterDataLabel: UILabel!
    override var isSelected: Bool {
        didSet { showAsSelected(isSelected) }
    }

    var filterContainer: UIView? { filterDataLabel.superview }

    private var position: (row: Int, count: Int)?

    override func awakeFromNib() {
        super.awakeFromNib()

        filterContainer?.layer.borderWidth = 0.5
        filterContainer?.clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let con = filterContainer { con.layer.cornerRadius = con.layer.frame.height/2.0 }
    }

    func displayData(title: String, isSelected: Bool, itemIndexPath: IndexPath, numberOfItems: Int) {
        position = (row: itemIndexPath.row, count: numberOfItems)
        filterDataLabel.text = title
        showAsSelected(isSelected)
    }

    private func showAsSelected(_ isSelected: Bool) {
        filterDataLabel.textColor = isSelected ? .black : .gray
        filterContainer?.backgroundColor = isSelected ? .yellow : .clear
    }
}

@IBDesignable class PaddingLabel: UILabel {

    @IBInspectable var topInset: CGFloat    = 3.0
    @IBInspectable var bottomInset: CGFloat = 3.0
    @IBInspectable var leftInset: CGFloat   = 0.0
    @IBInspectable var rightInset: CGFloat  = 0.0

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + leftInset + rightInset,
                      height: size.height + topInset + bottomInset)
    }

    override var bounds: CGRect {
        didSet {
            // ensures this works within stack views if multi-line
            preferredMaxLayoutWidth = bounds.width - (leftInset + rightInset)
        }
    }
}
