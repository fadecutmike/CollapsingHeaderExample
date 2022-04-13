//
//  EVDTabsGroupingCell.swift
//  WH_CZR_SBK
//
//  Created by Michael Dimore on 2/4/22.
//  Copyright © 2021 Caesar's Entertainment. All rights reserved.
//

import WHSportsbook
import UIKit

class EVDTabsGroupingCell: UITableViewCell, EVDDataAdjustable {
    var filterTabIndex : Int = -1
    var sectionIndex   : Int = -1
    var originalData   : EVDSectionData?
    var delegate       : EVDDataAdjustDelegate?
    
    @IBOutlet var tabButtons         : [UIButton]?
    @IBOutlet var tabLabels          : [UILabel]?
    @IBOutlet var selectionIndicator : UIView?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        filterTabIndex = -1
        sectionIndex   = -1
        delegate       = nil
        originalData   = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        tabLabels?.forEach({$0.text = ""; $0.textAlignment = .center; $0.numberOfLines = 2 })
        tabButtons?.forEach({$0.setTitle(nil, for: .normal)})
    }
    
    func configDataAdjustController(_ filterTab: Int, _ section: Int, _ originalData:EVDSectionData, _ adjustedData: EVDSectionData?, _ delegate: EVDDataAdjustDelegate) {
        self.filterTabIndex = filterTab
        self.sectionIndex   = section
        self.originalData   = originalData
        self.delegate       = delegate

        // Set all tab button label text color to czk '.info' initially
        tabLabels?.forEach({ $0.setFontProxima(.bold(16.0)); $0.textColor = .czkColor(.info) })
        
        if let tabs = originalData.rootMetadata?.tabs, let tabOne = tabs.first, let tabTwo = tabs.last {
            tabLabels?[0].text = "All"
            tabLabels?[1].text = tabOne
            tabLabels?[2].text = tabTwo
        }
        
        configAdjustedData(adjustedData)
    }
    
    private func configAdjustedData(_ adjustedData: EVDSectionData?) {
        
        guard sectionIndex != -1, let ogData = originalData else { return }
        var selectedIdx = 0
        
        defer {
            tabLabels?[selectedIdx].setFontProxima(.extraBld(16.0))
            tabLabels?[selectedIdx].textColor = .czkColor(.foreground)
    
            DispatchQueue.main.async { [self] in
                selectionIndicator?.center.x = tabLabels?[selectedIdx].center.x ?? 0.0
            }
        }
        
        guard let tabNames = ogData.rootMetadata?.tabs, tabNames.count > 0,
              let tabFilterTextMap = adjustedData?.evdRows.compactMap({$0.tabFilterText?.rp}), tabFilterTextMap.count > 0 else { return }
        
        let displayingTabOneData = tabFilterTextMap.recursiveContains(tabNames[0])
        let displayingTabTwoData = tabFilterTextMap.recursiveContains(tabNames[1])
        if displayingTabOneData != displayingTabTwoData { selectedIdx = displayingTabOneData ? 1 : 2 }
    }
    
    @IBAction func tabButtonPressed(_ sender: UIButton) {

        guard let idx = tabButtons?.firstIndex(of: sender), let ogData = originalData, let tabNames = ogData.rootMetadata?.tabs else { fatalError() }

        var result: EVDSectionData? = nil
        if idx > 0 {
            guard idx > 0, idx-1 < tabNames.count else { fatalError() }
            let rows = ogData.evdRows.filter({($0.tabFilterText ?? "").rp.contains(tabNames[idx-1])})
            result = EVDSectionData(ogData.sectionHeaderTitle, rows, ogData.parentTabTitle)
        }
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3) { self.selectionIndicator?.center.x = self.tabLabels?[idx].center.x ?? 0.0 }
        }
        delegate?.evdDataWasAdjusted(adjustedDataKey, sectionIndex, result)
    }
}
