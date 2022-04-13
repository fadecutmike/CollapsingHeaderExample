//
//  EVDAltSpreadCell.swift
//  WH_CZR_SBK
//
//  Created by mdimore on 12/20/21.
//  Copyright © 2021 Caesar's Entertainment. All rights reserved.
//

import UIKit
import WHSportsbook

class EVDAltSpreadCell: UITableViewCell {
    
    @IBOutlet weak var lhsBtn       : UISixPackButton?
    @IBOutlet weak var rhsBtn       : UISixPackButton?
    @IBOutlet weak var lhsTeamLabel : UILabel?
    @IBOutlet weak var rhsTeamLabel : UILabel?
    @IBOutlet weak var lhsIconImage : UIImageView?
    @IBOutlet weak var rhsIconImage : UIImageView?
    @IBOutlet weak var altSlider    : UISlider?
    
    @IBOutlet weak var sliderTickContainer : UIStackView?
    @IBOutlet weak var sliderTrackWidth    : NSLayoutConstraint?
    
    var showSliderTicks     : Bool     = false
    var sliderStepIntervals : [Double] = []
    var trackRect           : CGRect   = .zero
    var lastValue           : Double?
    var linePriceIntervals  : [WHSportsbook.LinePrice] = [] {
        didSet {
            sliderStepIntervals     = linePriceIntervals.map({$0.line})
            sMin                    = Float(sliderStepIntervals.min() ?? 0.0)
            sMax                    = Float(sliderStepIntervals.max() ?? 10.0)
            lastValue               = nil
            startPoint              = nil
            startPercent            = nil
            altSlider?.minimumValue = sMin
            altSlider?.maximumValue = sMax
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        altSlider?.alpha = 0.0

        if (altSlider?.gestureRecognizers?.count ?? 0) == 0 {
            // Tap gesture for min/max value images enabling incrementing or decrementing by individual steps on tap
            let sliderTap = UITapGestureRecognizer(target: self, action: #selector(didTapSlider(_:)))
            altSlider?.addGestureRecognizer(sliderTap)
        }

        if showSliderTicks {
            sliderTickContainer?.isHidden = false
            if (sliderTickContainer?.arrangedSubviews.count ?? 0) == 0 { for _ in 1...20 { addSliderTicks() } }
        }
    }
    
    override func prepareForReuse() {
        altSlider?.alpha = 0.0
        [lhsBtn, rhsBtn].compactMap({$0}).prepareButtonsForReuse()
        linePriceIntervals = []
        if showSliderTicks { sliderTickContainer?.arrangedSubviews.forEach({$0.isHidden = true}) }
    }
    
    func configSliderCell(_ market: WHSportsbook.Market, _ lhsTeam: WHSportsbook.Selection, _ rhsTeam: WHSportsbook.Selection) {
        guard let movingLines = market.movingLines else { return }// fatalError("Failed to load movingLines for slider market") }
        [lhsBtn, rhsBtn].enumerated().forEach({ (idx, btn) in btn?.market = market; btn?.selection = idx == 0 ? lhsTeam : rhsTeam })
        linePriceIntervals = movingLines.linePrices.filter({ $0.active })
        configLabels((lhsTeam, rhsTeam))
        DispatchQueue.main.async { [self] in
            uiSetup()
            trackRect = altSlider?.trackRect(forBounds: altSlider?.bounds ?? .zero) ?? .zero
            configPackButtons()
        
            if showSliderTicks {
                sliderTrackWidth?.constant = trackRect.width-22.0
                if sliderStepIntervals.count > 0, let subViews = sliderTickContainer?.arrangedSubviews, subViews.count > 0 {
                    subViews[0..<min(subViews.count, sliderStepIntervals.count)].forEach({$0.isHidden = false})
                    let newSpacing = ((trackRect.width-21.0)-CGFloat(sliderStepIntervals.count))/CGFloat(sliderStepIntervals.count)
                    sliderTickContainer?.spacing = newSpacing
                }
            }
        }
    }
        
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let roundedVal = Double(sender.value.round(nearest: 0.5))
        thumbBox?.center.x = sender.thumbRect(forBounds: .zero, trackRect: trackRect, value: sender.value).midX
        guard roundedVal != lastValue else { return }
        
        if let nearestStepIndex = sliderStepIntervals.firstIndex(of: roundedVal), nearestStepIndex < linePriceIntervals.count {
            let linePrice = linePriceIntervals[nearestStepIndex]
            if let lhsSel = linePrice.selections.first, let rhsSel = linePrice.selections.last {
                lastValue = linePrice.line

                let isOverUnder = [lhsSel, rhsSel].map({$0.selectionType.lowercased()}).contains("under")
                let lines : (lhs: Double, rhs: Double) = isOverUnder ? (linePrice.line, linePrice.line) : (linePrice.line, linePrice.line * -1.0)
                let text  : (lhs: String, rhs: String) = isOverUnder ? ("U "+lines.lhs.spreadStr, "O "+lines.rhs.spreadStr) : (lines.lhs.signedSpreadStr, lines.rhs.signedSpreadStr)
                
                //Temporary, need to hook back up
                //
                
//                lhsBtn?.updatePackBtnForSlider(.leftRight((left: (sliderLineStyle(text.lhs), nil), right: (customPriceStyle(), nil))), lines.lhs, lhsSel.price)
//                lhsBtn?.updatePackBtnForSlider(.leftRight((left: (sliderLineStyle(text.lhs), nil), right: (customPriceStyle(), nil))), lines.lhs, lhsSel.price)
//                
//                rhsBtn?.updatePackBtnForSlider(.leftRight((left: (sliderLineStyle(text.rhs), nil), right: (customPriceStyle(), nil))), lines.rhs, rhsSel.price)
            }
        }
    }
    
    @objc func didTapSlider(_ sender: UITapGestureRecognizer) {
        guard let lastVal = lastValue,
              let minRect = altSlider?.minimumValueImageRect(forBounds: altSlider?.bounds ?? .zero),
              let maxRect = altSlider?.maximumValueImageRect(forBounds: altSlider?.bounds ?? .zero),
              let lastStepIndex = sliderStepIntervals.firstIndex(of: lastVal) else { return }
        
        var newValue: Double?
        if minRect.contains(sender.location(in: altSlider)), lastStepIndex > 0 {
            newValue = linePriceIntervals[lastStepIndex-1].line
        } else if maxRect.contains(sender.location(in: altSlider)), lastStepIndex < linePriceIntervals.count-1 {
            newValue = linePriceIntervals[lastStepIndex+1].line
        }
        
        if let val = newValue, let slider = altSlider {
            slider.setValue(Float(val), animated: true)
            sliderValueChanged(slider)
        }
    }
    
    @IBAction func touchUpInside(_ sender: UISlider) {
        guard let lastVal = lastValue else { fatalError() }
        /// Performs 'snapping' to last interval value
        sender.setValue(Float(lastVal), animated: true)
        thumbBox?.center.x = sender.thumbRect(forBounds: .zero, trackRect: trackRect, value: Float(lastVal)).midX
    }
    
    private var sMin         : Float = 0.0
    private var sMax         : Float = 10.0
    private var thumbBox     : UIView?
    private var startPoint   : CGPoint?
    private var startPercent : Float?
    
    /// Method to perform updating of UISlider using pan gesture on much larger view which tracks slider thumb
    /// - Parameter sender: pan gesture when `ThumbBox` is dragged
    @objc func didPanThumbBox(_ sender: UIPanGestureRecognizer) {
        guard let slider = altSlider else { fatalError() }
        let point = sender.location(in: slider)
        if sender.state == .began {
            guard let lastVal = lastValue else { fatalError() }
            startPoint   = point                             // The point in slider where pan gesture started
            startPercent = (Float(lastVal)-sMin)/(sMax-sMin) // The slider value percentage when pan gesture started
        } else if [.ended, .cancelled, .failed].contains(sender.state) {
            startPoint   = nil
            startPercent = nil
            touchUpInside(slider)
            return
        }
        
        guard let sPoint = startPoint, let sPercent = startPercent else { fatalError() }
        
        let changedPercent = Float((point.x-sPoint.x)/trackRect.width) // The percent value changed relative to where pan started (+ or -)
        let newValue       = ((sPercent+changedPercent).limit()*(sMax-sMin))+sMin
        slider.setValue(newValue, animated: false)
        sliderValueChanged(slider)
    }
}

// MARK: - Private methods

extension EVDAltSpreadCell {
    
    private func configLabels(_ teams: (lhsTeam: WHSportsbook.Selection, rhsTeam: WHSportsbook.Selection)) {
        let labels = [lhsTeamLabel, rhsTeamLabel].compactMap({$0}).enumerated()
        let isOverUnder = linePriceIntervals.compactMap({$0.selections.first?.selectionType}).map({$0.lowercased()}).contains("under")

        if isOverUnder {
            [lhsIconImage, rhsIconImage].forEach({$0?.image = nil})
            labels.forEach({$0.element.text = $0.offset == 0 ? "Under" : "Over"})
        } else {
            for (idx, label) in labels {
                var txt: String = "\(idx % 2 == 0 ? "Home" : "Away") Team"
                let team = idx % 2 == 0 ? teams.lhsTeam : teams.rhsTeam
                let img = UIImage(named: team.logoImage.replacePipes())
                txt = team.teamAbbreviation?.replacePipes() ?? team.name.abbrvTeam()
                
                label.text                = txt
                let teamLogoImgView       = idx % 2 == 0 ? lhsIconImage : rhsIconImage
                teamLogoImgView?.image    = img
                teamLogoImgView?.isHidden = img == nil ? true : false
            }
        }
    }
    
    private func configPackButtons() {
        guard let slider = altSlider, sliderStepIntervals.count > 0 else { fatalError() }
        let defaultSliderValue = Float(sliderStepIntervals[sliderStepIntervals.count/2])
        if thumbBox == nil {
            thumbBox = .init(frame: slider.thumbRect(forBounds: .zero, trackRect: trackRect, value: defaultSliderValue).insetBy(dx: -25.0, dy: -8.0))
            thumbBox?.backgroundColor = .clear
            thumbBox?.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPanThumbBox(_:))))
            if let tBox = thumbBox { slider.addSubview(tBox) }
        }
        
        slider.setValue(defaultSliderValue, animated: false)
        sliderValueChanged(slider)
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.15, delay: 0.2, options: .beginFromCurrentState) { self.altSlider?.alpha = 1.0 }
        }
    }
    
    private func addSliderTicks() {
        let tick = UIView(frame: .zero)
        tick.isHidden = true
        tick.backgroundColor = .green
        tick.translatesAutoresizingMaskIntoConstraints = false
        tick.widthAnchor.constraint(equalToConstant: 1.0).isActive = true
        sliderTickContainer?.addArrangedSubview(tick)
    }
    
    private func uiSetup() {
        let color: UIColor = .black
        guard let minImg = UIImage(named: "altSliderIconLHS")?.tinted(color),
              let maxImg = UIImage(named: "altSliderIconRHS")?.tinted(color),
              let circleImg = UIImage(named: "sliderValueCircle")?.tinted(.white) else { return }
        
        // Constructs `-` and `+` min/max value images with layered circle image (different tint)
        altSlider?.minimumValueImage = .layeredImage(circleImg, minImg)
        altSlider?.maximumValueImage = .layeredImage(circleImg, maxImg)
        
        altSlider?.setMinimumTrackImage(.imageWith(.czkColor(.info)), for: .normal)
        altSlider?.setMaximumTrackImage(.imageWith(.czkColor(.info)), for: .normal)
        altSlider?.setThumbImage(UIImage(named: "altSliderThumb"), for: .normal)
    }
}
