//
//  FilterView.swift
//  WH_CZR_SBK
//
//  Created by Michael Dimore on 7/8/21.
//  Copyright © 2020 Johnson Liu. All rights reserved.
//

import UIKit

private var filterLayout: UICollectionViewFlowLayout {
    let layout               = UICollectionViewFlowLayout()
    layout.scrollDirection   = .horizontal
    layout.estimatedItemSize = .init(width: 60.0, height: 34.0)
    layout.itemSize          = UICollectionViewFlowLayout.automaticSize
    layout.sectionInset      = .init(top: 0.0, left: 15.0, bottom: 0.0, right: 15.0)
    return layout
}

// MARK: - Base FilterView class supporting single and multi filter elements

class FilterViewBase: UIView {
    public private(set) var filterColView: UICollectionView = .init(frame: .zero, collectionViewLayout: filterLayout)
    var filterOptionsCount: Int { 0 }
    
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
        filterColView.register(.init(nibName: "FilterDataCell", bundle: nil), forCellWithReuseIdentifier: "FilterDataCell")
        filterColView.delegate                       = self
        filterColView.dataSource                     = self
        filterColView.backgroundColor                = .white
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterDataCell", for: indexPath)
        cell.tag = row+100
        
        if let singleCell = cell as? FilterDataCell, let singleFilter = self as? FilterView {
            singleCell.displayData(
                title: singleFilter.filterOptions[row].title,
                isSelected: singleFilter.currentIndexSelected == row,
                itemIndexPath: indexPath,
                numberOfItems: filterOptionsCount
            )
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let singleSelectFilter = self as? FilterView {
            collectionView.visibleCells.forEach({ $0.isSelected = $0.tag == indexPath.row+100 })
            singleSelectFilter.setSelectedIndex(indexPath.row)
        }
    }
}

protocol FilterOption: CustomStringConvertible { var title: String { get } }
protocol FilterViewDelegate: AnyObject { func didSelectItem(_ index: Int) }

// MARK: - Single Select Filter Option

/// Filter option for standard FilterView supporting only single selection.
struct SingleSelectFilter: FilterOption {
    var title: String
    var description: String { title }
    init(_ text: String) { self.title = text }
}

// MARK: - Single-Select FilterView

/// Single select FilterView control. Only one option can be selected at a time and cannot be configured
class FilterView: FilterViewBase {
    
    weak var filterDelegate               : FilterViewDelegate?
    override var filterOptionsCount       : Int { filterOptions.count }
    private(set) var filterOptions        : [FilterOption] = []
    private(set) var currentIndexSelected : Int = -1 {
        willSet {
            guard newValue != currentIndexSelected else { return }
            filterDelegate?.didSelectItem(newValue)
        }
    }
    
    func clearFilterOptions() { filterOptions.removeAll() }

    func setSelectedIndex(_ index: Int) {
        filterColView.setSelectedFilterIndex(index)
        currentIndexSelected = index
    }
    
    func addData(_ newData: [SingleSelectFilter], _ defaultFilterIndex: Int? = nil) {

        if filterOptions.map({$0.title}).joined() != newData.map({$0.title}).joined() { filterOptions = newData }
        if let defIdx = defaultFilterIndex {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.15) { self.setSelectedIndex(defIdx) }
        }
        
        filterColView.reloadData()
    }
}
