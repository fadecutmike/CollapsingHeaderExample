//
//  WHAttr.swift
//  WH_CZR_SBK
//
//  Created by Serxhio Gugo on 10/21/20.
//  Copyright © 2020 Caesar's Entertainment. All rights reserved.
//

import UIKit

struct WHAttr {
    static func str(_ text: String? = nil) -> NSAttributedString {
        NSAttributedString(string: text ?? "")
    }

    static func getAttrString(text: String, isBold: Bool = false, _ aFont: UIFont = WHFont.Proxima.medium(16.0).font) -> NSAttributedString {
        getCustomStr(text: text, isBold ? .czkColor(.foreground) : .czkColor(.foreground), aFont)
    }
    
    static func getCustomStr(text: String, _ color: UIColor = .czkColor(.foreground), _ aFont: UIFont = WHFont.Proxima.medium(16.0).font) -> NSAttributedString {

        let attributedText = NSMutableAttributedString(string: text, attributes: [
            .font: aFont,
            .foregroundColor: color
        ])

        return attributedText
    }

    static func getVal(_ topValue: String, _ bottomValue: String? = nil, _ isTopBold: Bool = false) -> NSAttributedString {

        let finalAttributedString = NSMutableAttributedString(attributedString: getAttrString(text: topValue, isBold: isTopBold))

        if let bVal = bottomValue, bVal.count > 0 {
            finalAttributedString.append(getAttrString(text: "\n\(bVal)", isBold: false))
        }

        return finalAttributedString
    }
    
    static func getMarketTitle(_ text: String) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: text, attributes: [
            .font: WHFont.Proxima.regular(14.0).font,
            .foregroundColor: UIColor.czkColor(.foreground)
        ])

        return attributedText
    }

    static func makeAttributed(title: String, value: String) -> NSAttributedString {
        let titleAttributedText = NSMutableAttributedString(string: title, attributes: [
            .font: WHFont.Proxima.bold(16.0).font,
            .foregroundColor: UIColor.czkColor(.foreground)
        ])

        let valueAttributedText = NSMutableAttributedString(string: " \(value)", attributes: [
            .font: WHFont.Proxima.semiBold(16.0).font,
            .foregroundColor: UIColor.czkColor(.foreground)
        ])

        titleAttributedText.append(valueAttributedText)
        return titleAttributedText
    }
}

// MARK: - Utility methods allowing font specification
extension WHAttr {
    static let defaultFont = WHFont.Proxima.medium(16.0).font

    static func getPackAttrString(text: String, font: UIFont?, color: UIColor) -> NSAttributedString {
        guard let font = font else { fatalError("font failed to load!") }

        let attributedText = NSMutableAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: color
        ])

        return attributedText
    }

    static func getPackVal(_ lines: [String], _ fontsAndColors: [FontColor] = [(defaultFont, .czkColor(.foreground))]) -> NSAttributedString {

        guard let topValue = lines.first, let topFont = fontsAndColors.first else { fatalError("getPackVal Error!") }
        
        let finalAttributedString = NSMutableAttributedString(attributedString: getPackAttrString(text: topValue, font: topFont.font, color: topFont.color))

        if lines.count > 1, let bottomValue = lines.last, bottomValue.count > 0, let fcTwo = fontsAndColors.last {
            finalAttributedString.append(getPackAttrString(text: "\n\(bottomValue)", font: fcTwo.font, color: fcTwo.color))
        }

        return finalAttributedString
    }
    
    static func getPackOutputAttrString(_ lines: [String], _ fontsAndColors: [FontColor] = [(defaultFont, .czkColor(.foreground))]) -> NSAttributedString {

        guard let topValue = lines.first, let topFont = fontsAndColors.first else { fatalError("getPackVal Error!") }
        
        let finalAttributedString = NSMutableAttributedString(attributedString: getPackAttrString(text: topValue, font: topFont.font, color: topFont.color))

        if lines.count > 1, let bottomValue = lines.last, bottomValue.count > 0, let fcTwo = fontsAndColors.last {
            finalAttributedString.append(getPackAttrString(text: "\n\(bottomValue)", font: fcTwo.font, color: fcTwo.color))
        }

        return finalAttributedString
    }
}

extension WHAttr {
    static func getCashout(_ amount: String) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: "Cashed Out ", attributes: [
            .font: WHFont.Proxima.regular(18.0).font,
            .foregroundColor: UIColor.czkColor(.foreground)
        ])

        attributedText.append(NSAttributedString(string: amount, attributes: [
            .font: WHFont.Proxima.regular(18.0).font,
            .foregroundColor: UIColor.czkColor(.successState)
        ]))

        return attributedText
    }
    
    /// Attributed string generator for Open Bets ParleyLeg PreGame label
    /// - Parameters:
    ///   - eventStartDate: The event start date as a Date object
    ///   - rhsText: The Team1 vs. Team2 text for the event
    ///   - showFinalResult: Indicates whether or not a result has been finalized, and date should not be shown
    /// - Returns: Attributed and formated string
    static func getAttrPregameLeg(_ eventStartDate: Date, _ rhsText: String, _ showFinalResult: Bool = false) -> NSAttributedString {
        let attributedText = NSMutableAttributedString()
        let evDateFmt = DateFormatter()
        evDateFmt.dateFormat = "h:mma, dd MMM | "
        
        if !showFinalResult {
            attributedText.append(NSMutableAttributedString(string: evDateFmt.string(from: eventStartDate), attributes: [
                .font: WHFont.Proxima.regular(16.0).font,
                .foregroundColor: UIColor.czkColor(.foreground)
            ]))
        }
        else {
            attributedText.append(NSMutableAttributedString(string: "Final Result | ", attributes: [
                .font: WHFont.Proxima.regular(16.0).font,
                .foregroundColor: UIColor.czkColor(.foreground)
            ]))
        }

        attributedText.append(NSAttributedString(string: rhsText, attributes: [
            .font: WHFont.Proxima.regular(16.0).font,
            .foregroundColor: UIColor.czkColor(.info)
        ]))

        return attributedText
    }
}

// MARK: - My Bonus Activity

extension WHAttr {
    static func getBonusAttrType(_ title: String, _ type: String) -> NSAttributedString {
        
        let attributedText = NSMutableAttributedString(string: title, attributes: [
            .font: WHFont.Proxima.bold(14.0).font,
            .foregroundColor: UIColor.czkColor(.foreground)
        ])

        attributedText.append(NSAttributedString(string: "\n\(type)", attributes: [
            .font: WHFont.Proxima.regular(14.0).font,
            .foregroundColor: UIColor.czkColor(.foreground)
        ]))

        return attributedText
    }
    
    static func getBonusTimestamp(_ title: String, _ time: String) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: title, attributes: [
            .font: WHFont.Proxima.bold(14).font,
            .foregroundColor: UIColor.czkColor(.info)
        ])
        
        attributedText.append(NSAttributedString(string: " \(time)", attributes: [
            .font: WHFont.Proxima.regular(14.0).font,
            .foregroundColor: UIColor.czkColor(.info)
        ]))
        
        return attributedText
    }
}

// Mark: - Caesar rewards attributed strings for credits
extension WHAttr {
    static func getCredits(creditNumber: String, tier: String) -> NSAttributedString {
        
        let attributedText = NSMutableAttributedString(string: creditNumber, attributes: [
            .font: WHFont.Proxima.bold(14.0).font,
            .foregroundColor: UIColor.czkColor(.foreground)
        ])

        attributedText.append(NSAttributedString(string: tier, attributes: [
            .font: WHFont.Proxima.bold(14.0).font,
            .foregroundColor: UIColor.czkColor(.info)
        ]))

        return attributedText
    }
}

// MARK: - Image attachments for attributed strings

extension WHAttr {
    static func getImgAttachStr(_ img: UIImage) -> NSMutableAttributedString {
        let imgAttach = NSTextAttachment(image: img)
        imgAttach.bounds = CGRect(x: 0.0, y: -4.0, width: img.size.width, height: img.size.height)
        let completeText = NSMutableAttributedString(string: "")
        completeText.append(NSAttributedString(attachment: imgAttach))
        return completeText
    }
}

// MARK: - Attributed strings for EVD

extension WHAttr {
    
    static func getEVDNavTitle(_ text: String, _ color: UIColor = .czkColor(.foreground), _ isBold: Bool = true) -> NSMutableAttributedString {
        getEVDNavTitleCustomFont(text, color, isBold ? .bold(14.0) : .medium(12.0))
    }
    
    static func getEVDNavTitleCustomFont(_ text: String, _ color: UIColor = .czkColor(.foreground), _ fontStyle: WHFont.Proxima = .bold(14.0)) -> NSMutableAttributedString {
        let attributedText = NSMutableAttributedString(string: text, attributes: [
            .font: fontStyle.font,
            .foregroundColor: color
        ])

        return attributedText
    }
    
    static func getEVDImgAttachStr(_ img: UIImage) -> NSMutableAttributedString {

        let imgAttach = NSTextAttachment(image: img)
        imgAttach.bounds = CGRect(x: 0.0, y: -1.5, width: img.size.width, height: img.size.height)
        let attributedText = NSMutableAttributedString(string: "")
        attributedText.append(NSAttributedString(attachment: imgAttach))
        return attributedText
    }
    
    static func getEVDSectionHeader(_ titleText: String, _ addSGPBadge: Bool = false) -> NSMutableAttributedString {
        
        let result = NSMutableAttributedString(attributedString: getCustomStr(text: titleText, .czkColor(.foreground), .refrigerator(.bold(20.0))))
        if addSGPBadge { result.append(getCustomStr(text: "   SGP", .czkColor(.primary), .refrigerator(.extraBold(16.0)))) }
        
        return result
    }
}

// MARK: - Team name abbreviation attr string

extension WHAttr {
    static func getTeamNameOneLine(_ abbreviation: String, _ shortName: String) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: getCustomStr(text: abbreviation, .czkColor(.foreground), .refrigerator(.bold(18.0))))
        result.append(NSMutableAttributedString(attributedString: getCustomStr(text: " \(shortName)", .czkColor(.foreground), .refrigerator(.bold(18.0)))))
        
        return result
    }
    
    static func getTeamNameTwoLines(_ abbreviation: String, _ shortName: String) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: getCustomStr(text: abbreviation, .czkColor(.foreground), .refrigerator(.regular(16.0))))
        result.append(NSMutableAttributedString(attributedString: getCustomStr(text: "\n\(shortName)", .czkColor(.foreground), .refrigerator(.bold(18.0)))))
        
        return result
    }
    
    static func getTitle(_ text: String) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: text, attributes: [
            .font: WHFont.Refrigerator.bold(16.0).font,
            .foregroundColor: UIColor.czkColor(.foreground)
        ])

        return attributedText
    }
}

extension WHAttr {
    static func getStep4Header(p1: String, p2: String, p3: String) -> NSAttributedString {
        
        let attributedText = NSMutableAttributedString(string: p1, attributes: [
            .font: WHFont.Proxima.regular(16.0).font,
            .foregroundColor: UIColor.czkColor(.foreground)
        ])

        attributedText.append(NSAttributedString(string: p2, attributes: [
            .font: WHFont.Proxima.bold(16.0).font,
            .foregroundColor: UIColor.czkColor(.foreground)
        ]))
        
        attributedText.append(NSAttributedString(string: p3, attributes: [
            .font: WHFont.Proxima.regular(16.0).font,
            .foregroundColor: UIColor.czkColor(.foreground)
        ]))

        return attributedText
    }
}
