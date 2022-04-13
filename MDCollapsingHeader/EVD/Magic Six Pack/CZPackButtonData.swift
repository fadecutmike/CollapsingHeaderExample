//
//  CZPackButtonData.swift
//  MDCollapsingHeader
//
//  Created by mad on 2/20/22.
//

import UIKit
import WHSportsbook

typealias FontColor = (font: UIFont, color: UIColor)

enum CZSourceType: String, Equatable {
    case selectionPrice, selectionName, marketLine, marketOverUnder
    
    var isMarketType : Bool { rawValue.lowercased().contains("market") }
    var defaultFont  : WHFont.Proxima { .medium(14.0) }
    var defaultColor : UIColor { isMarketType ? .white : .green }
}

enum CZLayoutZone: String, Equatable, CaseIterable {
    case leading, centered, trailing
    
    var caseName: String { rawValue }
    
    func getLinePosition(_ isLineTwo: Bool = false) -> CZLinePosition {
        switch self {
            case .leading:  return isLineTwo ? .leadingLineTwo  : .leadingLineOne
            case .centered: return isLineTwo ? .centeredLineTwo : .centeredLineOne
            case .trailing: return isLineTwo ? .trailingLineTwo : .trailingLineOne
        }
    }
}

enum CZLinePosition: Int, Equatable, CaseIterable {
    case leadingLineOne, leadingLineTwo, centeredLineOne, centeredLineTwo, trailingLineOne, trailingLineTwo
    
    static let stringCases = ["leadingLineOne", "leadingLineTwo", "centeredLineOne", "centeredLineTwo", "trailingLineOne", "trailingLineTwo"]
    var caseName: String { Self.stringCases[rawValue] }
    
    var getLayoutZone: CZLayoutZone {
        switch self {
            case .leadingLineOne, .leadingLineTwo:   return .leading
            case .centeredLineOne, .centeredLineTwo: return .centered
            case .trailingLineOne, .trailingLineTwo: return .trailing
        }
    }
}

struct CZLineConfig: Equatable {
    var source : CZSourceType
    var color  : UIColor
    var font   : WHFont.Proxima
    
    var outputStyle : FontColor { (.proxima(font), .black) }
    
    /// Initializes a CZPackLineContent element
    /// - Parameters:
    ///   - sourceType: Enum specifying the content source (i.e. `.selectionPrice` should use a selection.price property when loading or updating)
    ///   - textColor: UIColor case for text color of line
    ///   - fontStyle: WHFont.Proxima case for font style of line
    init(_ sourceType: CZSourceType, _ textColor: UIColor? = nil, _ fontStyle: WHFont.Proxima? = nil) {
        self.source = sourceType
        self.color  = textColor ?? sourceType.defaultColor
        self.font   = fontStyle ?? sourceType.defaultFont
    }
    
    init(_ sourceType: CZSourceType, _ textColor: UIColor) { self.init(sourceType, textColor, nil) }
    init(_ sourceType: CZSourceType, _ fontStyle: WHFont.Proxima) { self.init(sourceType, nil, fontStyle) }
    init(_ sourceType: CZSourceType) { self.init(sourceType, nil, nil) }
    
    var caseName: String { "sourceType: \(source.rawValue),\t" }
}

struct CZLineValue: Equatable {
    let position : CZLinePosition
    var text     : String = ""
    
    var caseName: String { "\(position.caseName.contains("Two") ? "lineTwo" : "lineOne"): \(text),\t" }
}

struct CZLine: Equatable {
    var labelContent : CZLineConfig
    var labelValue   : CZLineValue
    
    var caseName: String { "line: \(labelValue.caseName), \(labelContent.caseName),\t" }
    
    /// Initializes a CZPack Line element
    /// - Parameters:
    ///   - content: CZPackLineContent element
    ///   - linePosition: Enum describing the alignment and the position/index of the line (e.g. `.centerLineTwo` represents the second line of the center layout zone)
    init(_ content: CZLineConfig, _ linePosition: CZLinePosition = .centeredLineOne) {
        self.labelContent = content
        self.labelValue   = .init(position: linePosition)
    }
}

struct CZPackButtonData {
    var allLines : [CZLine]
    var caseName : String {
        "CZPackButtonData: \(allLines.map({$0.caseName}).joined(separator: ",\t "))"
    }
    
    init(_ lines: [CZLine]){ self.allLines = lines }
    
    static func centered(_ lineOne: CZLineConfig, _ lineTwo: CZLineConfig?) -> CZPackButtonData { .init(.centerOnly([lineOne, lineTwo].compactMap({$0}))) }
    static func leftAligned(_ lineOne: CZLineConfig, _ lineTwo: CZLineConfig?) -> CZPackButtonData { .init(.leftOnly([lineOne, lineTwo].compactMap({$0}))) }
    static func rightAligned(_ lineOne: CZLineConfig, _ lineTwo: CZLineConfig?) -> CZPackButtonData { .init(.rightOnly([lineOne, lineTwo].compactMap({$0}))) }
    
    static func leftAndRightAligned(_ lhsLineOne: CZLineConfig, _ lhsLineTwo: CZLineConfig?, _ rhsLineOne: CZLineConfig, _ rhsLineTwo: CZLineConfig?) -> CZPackButtonData {
        .init(.leftAndRight([lhsLineOne, lhsLineTwo].compactMap({$0}), [rhsLineOne, rhsLineTwo].compactMap({$0})))
    }
}

// MARK: - CZPack Equatable conformance

extension CZPackButtonData: Equatable {
    static func == (lhs: CZPackButtonData, rhs: CZPackButtonData) -> Bool { lhs.caseName == rhs.caseName }
}

// MARK: - CZPack static instance methods

extension Array where Element == CZLine {
     
    static func centerOnly(_ lines: [CZLineConfig]) -> [CZLine] { generateLinesForZone(lines, .centered) }
    static func leftOnly(_ lines: [CZLineConfig])   -> [CZLine] { generateLinesForZone(lines, .leading) }
    static func rightOnly(_ lines: [CZLineConfig])  -> [CZLine] { generateLinesForZone(lines, .trailing) }
    static func leftAndRight(_ lhsLines: [CZLineConfig], _ rhsLines: [CZLineConfig]) -> [CZLine] {
        generateLinesForZone(lhsLines, .leading) + generateLinesForZone(rhsLines, .trailing)
    }
    
    private static func generateLinesForZone(_ lines: [CZLineConfig], _ layoutZone: CZLayoutZone) -> [CZLine] {
        guard let lineA = lines.first else { fatalError("Failed to create \(String(describing: self))") }
        if lines.count > 1, let lineB = lines.last {
            return [CZLine(lineA, layoutZone.getLinePosition()), CZLine(lineB, layoutZone.getLinePosition(true))].compactMap({$0})
        } else {
            return [.init(lineA, layoutZone.getLinePosition())]
        }
    }
}

struct CZPackDataContext {
    var mspOwnerButtonTag: MSPPackButtonTag?
    var teamNames: CZTeamNameStrings?
    var moneyLineMkt: WHSportsbook.Market?
    
    init(_ mspTag: MSPPackButtonTag?, _ teamNames: CZTeamNameStrings?, _ moneyLineMarket: WHSportsbook.Market?) {
        self.mspOwnerButtonTag = mspTag
        self.teamNames = teamNames
        self.moneyLineMkt = moneyLineMarket
    }
}

struct CZTeamNameStrings {
    enum PackTeamType: String, Equatable, CaseIterable { case isBlankOrNil, isHome, isAway, specialCase }
    let home: String
    let away: String
    
    func teamType(_ selName: String?) -> PackTeamType {
        guard let selName = selName, selName.count > 1 else { return .isBlankOrNil }
        return selName == home ? .isHome : selName == away ? .isAway : .specialCase
    }
    
    init?(_ homeTeamName: String?, _ awayTeamName: String?) {
        guard let ht = homeTeamName, let at = awayTeamName else { return nil }
        self.home = ht.replacePipes()
        self.away = at.replacePipes()
    }
    
    init(_ homeTeamName: String, _ awayTeamName: String) {
        self.home = homeTeamName.replacePipes()
        self.away = awayTeamName.replacePipes()
    }
    
    init(_ event: WHSportsbook.Event?) {
        guard let teams = event?.teamSelections else { fatalError() }
        self.init(teams.home.name, teams.away.name)
    }
}

protocol CZPackDataOwner {
    var market: WHSportsbook.Market? { get set }
    var selection: WHSportsbook.Selection? { get set }
    var packDataContext: CZPackDataContext? { get set }
    var packType: CZPackButtonData? { get set }
}

extension CZPackButtonData {

    internal func getRefreshedAttrColors() -> [(NSAttributedString, CZLayoutZone)] {
        var result: [(NSAttributedString, CZLayoutZone)] = []
        for lines in linesByLayoutZone where lines.count > 0 {
            
            // The layout of the zone for this loop
            let contentResults = lines.map({($0.labelValue.text, $0.labelContent.outputStyle)})
            let pack = (contentResults.map({$0.0}), contentResults.map({$0.1}))
            result.append((WHAttr.getPackVal(pack.0, pack.1), lines.first!.labelValue.position.getLayoutZone))
        }
        
        return result
    }
    
    internal mutating func generateAttrStrings(_ owner: CZPackDataOwner) -> [(NSAttributedString, CZLayoutZone)] {
        var result: [(NSAttributedString, CZLayoutZone)] = []
        for lines in linesByLayoutZone where lines.count > 0 {
            
            // The layout of the zone for this loop
            var contentResults: [(String, FontColor)] = []
            for line in lines {
                let update = (updateLineText(line, owner), line.labelContent.outputStyle)
                contentResults.append(update)
                if let idx = allLines.firstIndex(where: {$0.labelValue.position == line.labelValue.position}) { allLines[idx].labelValue.text = update.0 }
            }
            
            let pack = (contentResults.map({$0.0}), contentResults.map({$0.1}))
            result.append((WHAttr.getPackVal(pack.0, pack.1), lines.first!.labelValue.position.getLayoutZone))
        }
        
        return result
    }
    
    private var linesByLayoutZone: [[CZLine]] {
        // Creates 'left', 'center' and 'right' content pack zone arrays with up to two lines for each zone. (max of two active zone, e.g. left+right)
        CZLayoutZone.allCases.compactMap({ layout in allLines.filter({$0.labelValue.position.getLayoutZone == layout}) })
    }
    
    private func updateLineText(_ updateLine: CZLine, _ owner: CZPackDataOwner) -> String {
        guard let sel = owner.selection else { fatalError() }
        let src = updateLine.labelContent.source
        let selName = sel.name.replacePipes()
        
        if src.isMarketType {
            guard let mkt = owner.market, let dataContext = owner.packDataContext, let line = mkt.line else { fatalError("CZPackContent failed for marketLine") }
                        
            if src == .marketLine {
                if mkt.selections.count == 2 {
                    guard let mspTag = dataContext.mspOwnerButtonTag, let moneyLineMkt = dataContext.moneyLineMkt else {
                        if let otherSel = mkt.selections.first(where: {$0.id != sel.id}), let price = sel.price, let otherPrice = otherSel.price {
                            let positiveLineVal = abs(line)
                            return (price.d > otherPrice.d ? positiveLineVal : positiveLineVal  * -1.0).spread
                        }
                        
                        return line.spread
                    }
                    
                    let mlSel = moneyLineMkt.selections[mspTag.selectionIdx]
                    guard let otherMLSel = moneyLineMkt.selections.first(where: {$0.id != mlSel.id}) else { return line.spread }
                    
                    var showAsPositive = mspTag.isUpperPack
                    if let price = mlSel.price, let otherPrice = otherMLSel.price {
                        showAsPositive = price.d > otherPrice.d
                    }
                    
                    let positiveLineVal = abs(line)
                    return (showAsPositive ? positiveLineVal : positiveLineVal  * -1.0).spread
                }
                
                return line.spread
            }
            
            if src == .marketOverUnder {
                if mkt.selections.count == 2 {
                    if ["over", "under"].contains(sel.type) {
                        return "\(sel.type == "over" ? "O" : "U") \(line)"
                    } else if let mspTag = dataContext.mspOwnerButtonTag {
                        return "\(mspTag.isUpperPack ? "O" : "U") \(line)"
                    }
                }
                return line.strValue
            }
        }
        
        if src == .selectionPrice {
            guard let price = sel.price else { fatalError("CZPackContentSource, selectionPrice failed") }
            return price.americanOdds
        }
        
        return (sel.teamAbbreviation ?? selName).replacePipes()
    }
}

