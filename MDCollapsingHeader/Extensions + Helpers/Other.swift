//
//  Other.swift
//  MDCollapsingHeader
//
//  Created by testaccount on 4/13/22.
//

import UIKit

/// Some ViewModels need access to a UITableView from their owner ViewController, this protocol allows for that access
protocol TableViewOwner: AnyObject { var tableViewRef: UITableView? { get } }

/// Some ViewModels need access to a UICollectionView from their owner ViewController, this protocol allows for that access
protocol CollectionViewOwner: AnyObject { var collectionViewRef: UICollectionView? { get } }

// MARK: - Single Select Filter Option

/// Filter option for standard FilterView supporting only single selection.
struct SingleSelectFilter: FilterOption {
    var title: String
    var description: String { title }
    init(_ text: String) { self.title = text }
}

protocol FilterOption: CustomStringConvertible { var title: String { get } }

protocol FilterViewDelegate: AnyObject { func didSelectItem(_ index: Int) }
