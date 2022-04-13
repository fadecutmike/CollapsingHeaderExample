//
//  UISixPackButton.swift
//  WH_CZR_SBK
//
//  Created by Daniel Tepper on 10/7/20.
//  Copyright © 2020 Caesar's Entertainment. All rights reserved.
//

import UIKit
import WHSportsbook

class UISixPackButton: UIButton, CZPackDataOwner, HighlightableSelection {
    var market: WHSportsbook.Market? {
        didSet { oldMarket = oldValue == nil ? market : oldValue }
    }

    var selection: WHSportsbook.Selection? {
        didSet { oldSelection = oldValue == nil ? selection : oldValue }
    }

    private(set) var oldSelection: WHSportsbook.Selection?
    private(set) var oldMarket: WHSportsbook.Market?
        
    var packType: CZPackButtonData?
    var packDataContext: CZPackDataContext?
    
    var lhsLabel = UILabel()
    var rhsLabel = UILabel()
    var borderLayer: UIView = .init()
    
    var highlightIndicatorBar: UIView! = .init()
    var packColors: (bg: CZK.ThemeColor, border: CZK.ThemeColor) = (.secondary, .primaryStroke)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setTitle(nil, for: .normal)
    }

    private func setupLabel(_ label: UILabel) {
        if !subviews.contains(label) {
            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = 2
            label.backgroundColor = .clear
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: topAnchor),
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12.0),
                label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12.0),
                label.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
    }
    
    private func setupBorder() {
        if !subviews.contains(borderLayer) {
            borderLayer.isUserInteractionEnabled = false
            borderLayer.backgroundColor = .czkColor(packColors.bg)
            addSubview(borderLayer)
            
            borderLayer.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                borderLayer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 1.0),
                borderLayer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1.0),
                borderLayer.topAnchor.constraint(equalTo: topAnchor, constant: 1.0),
                borderLayer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1.0)
            ])
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if !subviews.contains(highlightIndicatorBar) {
            titleLabel?.numberOfLines = 2
            titleLabel?.textAlignment = .center
            
            highlightIndicatorBar.backgroundColor = .czkColor(.selected)
            highlightIndicatorBar.alpha = 0.0
            highlightIndicatorBar.frame = CGRect(x: 0.0, y: 0.0, width: 8.0, height: frame.size.height - 2.0)
            highlightIndicatorBar.center = .init(x: highlightIndicatorBar.center.x, y: center.y)
            addSubview(highlightIndicatorBar)
            highlightIndicatorBar.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                highlightIndicatorBar.topAnchor.constraint(equalTo: topAnchor, constant: 1.0),
                highlightIndicatorBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 1.0),
                highlightIndicatorBar.widthAnchor.constraint(equalToConstant: 8.0),
                highlightIndicatorBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1.0)
            ])
//            NotificationCenter.default.addObserver(self, selector: #selector(highlightDidChange(_:)), name: WHNotification.kHighlightedSelectionIdsChanged.name, object: nil)
        } else {
            bringSubviewToFront(highlightIndicatorBar)
        }
    }
    
    @objc func highlightDidChange(_ notification: Notification) {
//        if let selId = selection?.id { shouldHighlightIndicator(WHLookup.highlightedSelectionIds.contains(selId)) }
    }
    
    func configBtn(_ pType: CZPackButtonData, _ mkt: WHSportsbook.Market, _ sel: WHSportsbook.Selection, _ packContext: CZPackDataContext? = nil) {
        self.packType  = pType
        self.market    = mkt
        self.selection = sel
        self.packDataContext = packContext
        configData()
    }
    
    func updatePackBtnForSlider(_ pType: CZPackButtonData, _ updatedLine: Double, _ updatedPrice: WHSportsbook.Price) {
        selection?.updatePrice(updatedPrice)
        market?.updateLine(updatedLine)
        
        packType = pType
        configData()
    }
        
    private func configData() {
        setupLabel(lhsLabel)
        lhsLabel.textAlignment = .left
        setupLabel(rhsLabel)
        rhsLabel.textAlignment = .right

        applyStyling()
        processData()
        
        isAccessibilityElement = true
        let selectionId = selection?.id == nil ? "" : "/\(selection?.id ?? "selId Err..")"
        let selectorStr = "\(market?.eventId ?? "evId Err..")/\(market?.id ?? "mktId Err..")\(selectionId)"
        accessibilityValue = selectorStr
        accessibilityIdentifier = selectorStr
        accessibilityTraits = [.button]
    }

    func updateSixPackWithData(_ marketUpdate: DiffusionMarketUpdate? = nil, _ selUpdate: DiffusionSelectionUpdate? = nil) {
        if let mktUpdate = marketUpdate, let newVal = mktUpdate.line {
            market?.updateMarket(mktUpdate)
            if let oldVal = oldMarket?.line, oldVal != newVal {
                DispatchQueue.main.async { self.updateButtonBg(newVal>oldVal ? .czkColor(.successState) : .czkColor(.errState)) }
            }
        }

        if let selUpdate = selUpdate {
            let newVal = selUpdate.price.a
            selection?.updateSelection(selUpdate)
            if let oldVal = oldSelection?.price?.a, oldVal != newVal {
                DispatchQueue.main.async { self.updateButtonBg(newVal>oldVal ? .czkColor(.successState) : .czkColor(.errState)) }
            }
        }

        processData()
    }
    
    /// Generates Attributed Strings per layoutZone using the `text` property of each CZLine object. The purpose is to only update colors and possibly fonts without adjusting content
    func refreshLabelTextColors() {
        if let strings = packType?.getRefreshedAttrColors() { updateAttributedLabelText(strings) }
    }
    
    /// Fully updates Attributed strings content and colors
    private func processData() {
        if let strings = packType?.generateAttrStrings(self) { updateAttributedLabelText(strings) }
    }
    
    private func updateAttributedLabelText(_ attrStringsResult: [(NSAttributedString, CZLayoutZone)]?) {
        var dataValue = "Data: "
        if let attrStringsResult = attrStringsResult {
            
            for result in attrStringsResult {
                if !(selection?.active ?? true) || !(market?.active ?? true) {
                    lhsLabel.attributedText = nil
                    rhsLabel.attributedText = nil
                    setAttributedTitle(WHAttr.getPackAttrString(text: "🔐", font: .systemFont(ofSize: 10.0), color: .green), for: .normal)
                    dataValue += "Locked"
                } else {
                    switch result.1 {
                        case .leading: lhsLabel.attributedText  = result.0
                        case .centered: setAttributedTitle(result.0, for: .normal)
                        case .trailing: rhsLabel.attributedText = result.0
                    }
                    dataValue += result.0.string
                }
            }
        }
    
        let selectionId = selection?.id == nil ? "" : "/\(selection?.id ?? "selId Err..")"
        accessibilityLabel = (accessibilityLabel?.components(separatedBy: "Data:")[0] ?? "") + dataValue.components(separatedBy: .newlines).joined(separator: "/")
        accessibilityValue = "\(market?.eventId ?? "evId Err..")/\(market?.id ?? "mktId Err..")\(selectionId)"
    }

    func applyStyling() {
        setupBorder()
        backgroundColor = .czkColor(packColors.border)
        borderLayer.backgroundColor   = .czkColor(packColors.bg)
        bringSubviewToFront(highlightIndicatorBar)
        sendSubviewToBack(borderLayer)
        layoutIfNeeded()
    }
}

extension UISixPackButton {
    
    func updateButtonBg(_ color: UIColor) {
        DispatchQueue.main.async {
            self.animateBgColorChange(color, 0.0) { _ in
                self.animateBgColorChange(.czkColor(self.packColors.border), 0.2)
            }
        }
    }

    private func animateBgColorChange(_ color: UIColor, _ delay: TimeInterval = 0.0, _ completed: ((Bool) -> Void)? = nil) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.325, delay: delay, options: [], animations: {
                self.backgroundColor = color
            }, completion: completed)
        }
    }
    
    var allAttrTextJoined: String {
        [lhsLabel.attributedText?.string, attributedTitle(for: .normal)?.string, rhsLabel.attributedText?.string].compactMap({$0}).joined(separator: ", ")
    }
    
    func prepBtnForReuse() {
        self.market    = nil
        self.selection = nil
        
        self.titleLabel?.attributedText  = nil
        self.lhsLabel.attributedText     = nil
        self.rhsLabel.attributedText     = nil
        self.highlightIndicatorBar.alpha = 0.0
        self.isHidden = false

        self.packDataContext = nil
        self.packType        = nil
    }
}

extension Array where Element == UISixPackButton {
    /// Filter out UISixPackButtons that are hidden, have a hidden parent, or have a height less than 10 pts
    private var visibleOnly: [UISixPackButton] {
        filter({!$0.isHidden && !($0.superview?.isHidden ?? false && $0.frame.height > 10.0)})
    }

    var visMarkets: WHSportsbook.Markets { visibleOnly.compactMap({ $0.market }) }
}

protocol HighlightableSelection {
    var highlightIndicatorBar: UIView! { get set }
    func shouldHighlightIndicator(_ shouldShow: Bool)
}

extension HighlightableSelection {
    func shouldHighlightIndicator(_ shouldShow: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25) { self.highlightIndicatorBar.alpha = shouldShow ? 1.0 : 0.0 }
        }
    }
}
