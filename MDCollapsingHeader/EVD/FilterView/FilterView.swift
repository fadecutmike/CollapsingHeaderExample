//
//  FilterView.swift
//  WH_CZR_SBK
//
//  Created by Michael Dimore on 7/8/21.
//  Copyright © 2020 Johnson Liu. All rights reserved.
//

import UIKit

private var filterLayout: UICollectionViewFlowLayout {
    let layout                  = UICollectionViewFlowLayout()
    layout.scrollDirection      = .horizontal
    layout.estimatedItemSize    = .init(width: 80.0, height: 50.0)
    layout.sectionInset         = .init(top: 11.0, left: 16.0, bottom: 11.0, right: 16.0)
    layout.minimumLineSpacing   = 8.0
    layout.minimumInteritemSpacing = 8.0
    
    return layout
}

// MARK: - Base FilterView class supporting single and multi filter elements

class FilterViewBase: UIView {
    public private(set) var filterColView: UICollectionView = .init(frame: .zero, collectionViewLayout: filterLayout)
    var filterOptionsCount: Int { 0 }
    var cellType: WHCell { .filterViewCell }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if subviews.count == 0 {
            setupCollectionView()
            initialSetup()
        }
    }
    
    /// Override to perform setup on subclasses
    func initialSetup() {}
    
    private func setupCollectionView() {
        filterColView.registerWHCell(cellType)
        filterColView.delegate                       = self
        filterColView.dataSource                     = self
        filterColView.backgroundColor                = .czkColor(.bg)
        filterColView.showsVerticalScrollIndicator   = false
        filterColView.showsHorizontalScrollIndicator = false

        addSubview(filterColView)
        filterColView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            filterColView.leadingAnchor.constraint(equalTo: leadingAnchor),
            filterColView.trailingAnchor.constraint(equalTo: trailingAnchor),
            filterColView.bottomAnchor.constraint(equalTo: bottomAnchor),
            filterColView.topAnchor.constraint(equalTo: topAnchor)
        ])
    }
}

// MARK: - UICollectionView methods
extension FilterViewBase: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { filterOptionsCount }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)  -> UICollectionViewCell {
        let row  = indexPath.row
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellType.reuseId, for: indexPath)
        cell.tag = row+100
        
        if let multiFilter = self as? FilterViewMultiSelect, let multiCell = cell as? FilterDataCellMultiSelect {
            multiCell.configMultiCell(multiFilter.multiFilterOptions[row])
        } else if let singleCell = cell as? FilterDataCell, let fView = self as? FilterView {
            singleCell.displayData(fView.filterOptions[row].title, fView.currentIndexSelected == row, indexPath, filterOptionsCount, fView.customAccessibilitySuffix)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let singleSelectFilter = self as? FilterView {
            singleSelectFilter.setSelectedIndex(indexPath.row)
        } else if let multiSelectFilter = self as? FilterViewMultiSelect {
            multiSelectFilter.cellTapped(indexPath.row)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let multiSelectFilter = self as? FilterViewMultiSelect { multiSelectFilter.cellTapped(indexPath.row) }
    }
}

// MARK: - Single-Select FilterView

/// Single select FilterView control. Only one option can be selected at a time and cannot be configured
class FilterView: FilterViewBase {
    
    weak var filterDelegate               : FilterViewDelegate?
    override var filterOptionsCount       : Int { filterOptions.count }
    private(set) var filterOptions        : [FilterOption] = []
    private(set) var currentIndexSelected : Int = -1
    
    var customAccessibilitySuffix: String? {
        didSet { DispatchQueue.main.async { self.filterColView.reloadData() } }
    }
    
    func clearFilterOptions() { filterOptions.removeAll() }

    func setSelectedIndex(_ index: Int) {
        currentIndexSelected = index
        var cellRect: CGRect?
        
        if let cells = filterColView.visibleCells as? [FilterDataCell] {
            for cell in cells {
                if cell.position?.row == currentIndexSelected {
                    cell.setSelectedState(true)
                    cellRect = cell.frame
                } else if cell.filterOptionIsSelected {
                    cell.setSelectedState(false)
                }
            }
        }
        
        // Checks if filter option cell is fully onscreen, if not (cut off on left or right) then the collectionView will automatically scroll to bring the cell fully on screen
        if let cRect = cellRect, let scrollRect = filterColView.horizFullyOnScreenXOffset(cRect) {
            UIView.animate(withDuration: 0.2) {
                self.filterColView.scrollRectToVisible(scrollRect, animated: true)
            } completion: { _ in
                self.filterDelegate?.didSelectItem(index)
            }
        } else {
            self.filterDelegate?.didSelectItem(index)
        }
    }

    func addData(_ newData: [SingleSelectFilter], _ defaultFilterIndex: Int? = nil) {
        if filterOptions.map({$0.title}).joined() != newData.map({$0.title}).joined() { filterOptions = newData }
        if let defIdx = defaultFilterIndex { currentIndexSelected = defIdx }
        
        DispatchQueue.main.async { self.filterColView.reloadData() }
    }
}
