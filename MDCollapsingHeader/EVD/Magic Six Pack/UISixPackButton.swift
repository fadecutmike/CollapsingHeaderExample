//
//  UISixPackButton.swift
//  MDCollapsingHeader
//
//  Created by mad on 2/20/22.
//

import UIKit
import WHSportsbook

//protocol DiffusionSubscribable {
//    var market: WHSportsbook.Market? { get set }
//    var selection: WHSportsbook.Selection? { get set }
//    func applyUpdates(_ mktUpdate: DiffusionMarketUpdate?, _ selUpdate: DiffusionSelectionUpdate?)
//    func applyLiveScoreUpdate(_ livescoreUpdate: DiffusionLivescoreUpdate)
//}
//
//extension Array where Element == DiffusionSubscribable {
//    func topics(_ topicTypes: [WHDSubscribeType] = [.eventOnly, .marketOnly, .selectionOnly, .eventLivescore]) -> Set<WHDTopic> {
//        WHDTopic.fromMarketsAndSelections(compactMap({$0.market}), compactMap({$0.selection}), topicTypes).returnAsSet()
//    }
//}

class UISixPackButton: UIButton, CZPackDataOwner {
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
    
    var highlightIndicatorBar = UIView()
    var packColors: (bg: CZK.ThemeColor, border: CZK.ThemeColor) = (.secondary, .primaryStroke)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setTitle("", for: .normal)
        layer.borderWidth = 0.0
        layer.borderColor = nil
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
            borderLayer.backgroundColor   = .clear
            borderLayer.layer.borderWidth = 1.0
            borderLayer.layer.borderColor = UIColor.brown.cgColor
            addSubview(borderLayer)
            
            borderLayer.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                borderLayer.widthAnchor.constraint(equalTo: widthAnchor, constant: -1.0),
                borderLayer.heightAnchor.constraint(equalTo: heightAnchor, constant: -1.0),
                borderLayer.centerXAnchor.constraint(equalTo: centerXAnchor),
                borderLayer.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if !subviews.contains(highlightIndicatorBar) {
            highlightIndicatorBar.backgroundColor = .black
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

        } else {
            bringSubviewToFront(highlightIndicatorBar)
        }
    }
    
    func shouldHighlightIndicator(_ shouldShow: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25) { self.highlightIndicatorBar.alpha = shouldShow ? 1.0 : 0.0 }
        }
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
        accessibilityValue = "\(market?.eventId ?? "evId Err..")/\(market?.id ?? "mktId Err..")\(selectionId)"
        accessibilityTraits = [.button]
    }

    func updateSixPackWithData(_ marketUpdate: DiffusionMarketUpdate? = nil, _ selUpdate: DiffusionSelectionUpdate? = nil) {
        if let mktUpdate = marketUpdate, let newVal = mktUpdate.line {
            market?.updateMarket(mktUpdate)
            if let oldVal = oldMarket?.line, oldVal != newVal {
                DispatchQueue.main.async { self.updateButtonBg(newVal>oldVal ? .black : .black) }
            }
        }

        if let selUpdate = selUpdate {
            let newVal = selUpdate.price.a
            selection?.updateSelection(selUpdate)
            if let oldVal = oldSelection?.price?.a, oldVal != newVal {
                DispatchQueue.main.async { self.updateButtonBg(newVal>oldVal ? .black : .black) }
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
        if let attrStringsResult = attrStringsResult {
            for result in attrStringsResult {
                if !(selection?.active ?? true) || !(market?.active ?? true) {
                    lhsLabel.attributedText = nil
                    rhsLabel.attributedText = nil
                    setAttributedTitle(WHAttr.getPackAttrString(text: "🔐", font: .systemFont(ofSize: 10.0), color: .green), for: .normal)
                } else {
                    switch result.1 {
                        case .leading: lhsLabel.attributedText  = result.0
                        case .centered: setAttributedTitle(result.0, for: .normal)
                        case .trailing: rhsLabel.attributedText = result.0
                    }
                }
            }
        }
    
        let selectionId = selection?.id == nil ? "" : "/\(selection?.id ?? "selId Err..")"
        accessibilityValue = "\(market?.eventId ?? "evId Err..")/\(market?.id ?? "mktId Err..")\(selectionId)"
    }

    func applyStyling() {
        setupBorder()
        titleLabel?.numberOfLines = 2
        titleLabel?.textAlignment = .center
        backgroundColor = .black
        borderLayer.layer.borderColor = UIColor.brown.cgColor
        bringSubviewToFront(highlightIndicatorBar)
    }
}

extension UISixPackButton {
    
    func updateButtonBg(_ color: UIColor) {
        DispatchQueue.main.async {
            self.animateBgColorChange(color, 0.0) { _ in
                self.animateBgColorChange(.black, 0.2)
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
}

extension Array where Element == UISixPackButton {
    /// Filter out UISixPackButtons that are hidden, have a hidden parent, or have a height less than 10 pts
    private var visibleOnly: [UISixPackButton] {
        filter({!$0.isHidden && !($0.superview?.isHidden ?? false && $0.frame.height > 10.0)})
    }

    var visMarkets: WHSportsbook.Markets { visibleOnly.compactMap({ $0.market }) }
    
    func prepareButtonsForReuse() {
        forEach({ btn in
            btn.market    = nil
            btn.selection = nil
            btn.highlightIndicatorBar.alpha = 0.0
            btn.titleLabel?.attributedText  = WHAttr.getTitle("")
            btn.lhsLabel.attributedText = WHAttr.getTitle("")
            btn.rhsLabel.attributedText = WHAttr.getTitle("")
            btn.packType = nil
            btn.packDataContext = nil
        })
    }
}

