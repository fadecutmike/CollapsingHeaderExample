//
//  EVDCompactMarketCell.swift
//  WH_CZR_SBK
//
//  Created by mad on 3/17/22.
//  Copyright © 2022 Caesar's Entertainment. All rights reserved.
//

import UIKit

class EVDCompactMarketCell: UITableViewCell {
    
    @IBOutlet var packButtons  : [UISixPackButton]?
    @IBOutlet var btnTopLabels : [UILabel]?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        packButtons?.forEach({$0.prepBtnForReuse()})
        btnTopLabels?.forEach({$0.text = nil})
    }

    func configCell(_ rowData: EVDRowData) {
        guard [1,2,3].contains(rowData.selections.count) else { fatalError() }
        let market = rowData.market
        
        packButtons?.enumerated().forEach({ (idx, btn) in
            let btnLabel = btnTopLabels?[idx]
            let shouldDisplayPack = idx < rowData.selections.count
            btn.isHidden = !shouldDisplayPack
            btnLabel?.isHidden = !shouldDisplayPack
            
            if shouldDisplayPack {
                let sel = rowData.selections[idx]
                btnLabel?.text = sel.teamAbbreviation ?? sel.name.rp
//                btn.highlightIndicatorBar.alpha = WHLookup.highlightedSelectionIds.contains(sel.id) ? 1.0 : 0.0
                
                let selVS: CZSourceType = sel.price != nil ? .selectionPrice : .selectionName
                let mktType = SixPackMarketType.mktTypeScan(market)
                
                if mktType == .other {
                    btn.configBtn(.centered(.init(selVS), nil), market, sel)
                } else {
                    let valSource = mktType.czValSource
                    var lineTwo: CZLineConfig?
                    if let vsTwo = valSource.lineTwo { lineTwo = .init(vsTwo) }
                    btn.configBtn(.centered(.init(valSource.lineOne), lineTwo), market, sel)
                }

                btn.accessibilityLabel = "\(btnLabel?.text ?? "err") \(btn.allAttrTextJoined.replacingOccurrences(of: "\n", with: ""))"
            }
            
        })
    }
}

extension EVDCompactMarketCell: UpdatablePackElement {
    var spBtns: [UISixPackButton] { packButtons ?? [] }
}
