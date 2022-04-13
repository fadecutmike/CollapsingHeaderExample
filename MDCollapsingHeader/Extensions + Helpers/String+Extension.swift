//
//  String.swift
//  WH_CZR_SBK
//
//  Created by Daniel Tepper on 7/21/20.
//  Copyright © 2020 Caesar's Entertainment. All rights reserved.
//

import UIKit

private let upCaseChars = CharacterSet.uppercaseLetters

extension String {

    /// Returns a string uppercasing the first letter only.
    func capitalizeFirstLetter() -> String { prefix(1).uppercased() + dropFirst() }

    var floatNumValue  : Float  { Float(self)  ?? 0.0 }
    var doubleNumValue : Double { Double(self) ?? 0.0 }
    var intNumValue    : Int    { Int(self)    ?? 0 }

    /// Applies phone number pattern 888-888-8888
    func applyPatternOnNumbers(pattern: String, replacementCharacter: Character) -> String {
        var pureNumber = self.replacingOccurrences( of: "[^0-9]", with: "", options: .regularExpression)
        for index in 0 ..< pattern.count {
            guard index < pureNumber.count else { return pureNumber }
            let stringIndex = String.Index(utf16Offset: index, in: pattern)
            let patternCharacter = pattern[stringIndex]
            guard patternCharacter != replacementCharacter else { continue }
            pureNumber.insert(patternCharacter, at: stringIndex)
        }
        return pureNumber
    }

    /// Generates an abbreviated name. (Mainly used for Soccer Upcoming)
    /// - Returns: Abbreviated version of team name
    func abbrv(_ upperCase: Bool = true) -> Self {
        let str = replacePipes()
        let parts = str.components(separatedBy: " ").filter({$0.count > 0})
        if parts.count > 1, let last = parts.last {
            let result = "\(parts[0].prefix(1)). \(last.prefix(3))"
            let final = upperCase ? result.uppercased() : result
            if final == "UNDE" { return "UNDER" }
            return final
        }
        
        let final = upperCase ? str.prefix(4).uppercased() : String(str.prefix(4))
        if final == "UNDE" { return "UNDER" }
        return final
    }

    func abbrvTeam(_ upperCase: Bool = true) -> Self {
        let str = replacePipes()
        if count < 18 { return upperCase ? str.uppercased() : str }

        let parts = str.components(separatedBy: " ").filter({$0.count > 0})
        guard let back = parts.last else { return upperCase ? str.uppercased() : str }

        if parts.count > 1 {
            let front = parts.count == 3 ? "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased() : "\(parts[0].prefix(3))\(parts[0].count > 3 ? ".":"")"
            return upperCase ? "\(front) \(back)".uppercased() : "\(front) \(back)"
        }

        return upperCase ? str.uppercased() : str
    }
    
    /// Shortcut for replacePipes() method (heavily used in MSPBaseCell)
    var rp: String { replacePipes() }
    
    /// Shortcut for replacing pipes and returning lowercased result as string
    var low: String { lowercased() }
    
    /// Shortcut for replacing pipes and returning lowercased result as string
    var rpLow: String { replacePipes().lowercased() }

    /// Returns a string without the pipes " | "
    func replacePipes() -> Self { replacingOccurrences(of: "|", with: "") }
    
    /// Returns a string with all the occurences of commas "," removed
    func removeCommas() -> Self { replacingOccurrences(of: ",", with: "") }
    
    /// Returns a string with all the occurences of empty spaces " " replaced  a hyphen "-"
    func hyphenated() -> Self { replacingOccurrences(of: " ", with: "-") }
    
    /// Returns a string with all the occurences of periods "." removed
    func removePeriods() -> Self { replacingOccurrences(of: ".", with: "") }
    
    /// Returns a string with all the occurences of newlines "/n" replaced with spaces
    func replaceNewlinesWithSpaces() -> Self { replacingOccurrences(of: "\n", with: " ") }

    /// Returns itself plus repeating spaces if neccessary based on self.count and the specified limit val. Intended for generating clean console logs with lines matching up despite length differences
    /// - Parameter limit: The largest length of the string, upper length limit.
    /// - Returns: String plus spaces as needed
    func selfPlusGap(_ limit: Int = 22, _ sepChar: String = ",", _ endChar: String = "\t") -> String {
        "\(self)\(sepChar)\(String(repeating: " ", count: max(0, limit - count)))\(endChar)"
    }
    
    func replaceAllSpaces(_ replaceText: String) -> String? {
        guard let strRange = range(of: self),
                let regex = try? NSRegularExpression(pattern: #"\s+"#, options: []) else { return nil }
        
        var result = self
        let replaceRanges = regex.matches(in: self, range: NSRange(strRange, in: self)).compactMap({ Range($0.range, in: self) })
        for repRange in replaceRanges {
            result = result.replacingCharacters(in: repRange, with: replaceText)
        }
        
        return result
    }
    
    func snakeCased() -> String { replaceAllSpaces("-") ?? hyphenated() }
    func removeDuplicateSpaces() -> String { replaceAllSpaces(" ") ?? self }
    
    func splitEventNameIntoTeamNames() -> TeamNames? {
        let evName = self.rp
        guard let strRange = evName.range(of: evName),
              let regex = try? NSRegularExpression(pattern: #"\b(\s)+([aA][tT]|[vV][sS])\.?(\s+)?"#, options: []) else { return nil }
        
        let regexFirstMatch = regex.rangeOfFirstMatch(in: evName, range: NSRange(strRange, in: evName))
        guard let sepStrRange = Range(regexFirstMatch, in: evName) else { return nil }
        
        let teamNames = evName.components(separatedBy: evName[sepStrRange])
        guard teamNames.count == 2 else { return nil }
        
        if teamNames[0].prefix(4).contains(" "), let numPre = try? NSRegularExpression(pattern: #"^\d+ "#, options: []), let teamOneRng = teamNames[0].range(of: teamNames[0]),
            let numberPrefix = Range(numPre.rangeOfFirstMatch(in: teamNames[0], range: NSRange(teamOneRng, in: teamNames[0])), in: teamNames[0]) {
            return (teamNames[0].replacingCharacters(in: numberPrefix, with: ""), teamNames[1])
        }
        
        return (teamNames[0], teamNames[1])
    }
    
    var capExcludingNumbers: String {
        var result = capitalized
        for cap in capNum { result = result.replacingOccurrences(of: cap.capitalized, with: cap) }
        return result
    }
    
    mutating func magicSixPackTrimSectionHeaderTitle() {
        let rangesToRemove = suffixToRemove.compactMap({lowercased().range(of: $0)})
        for range in rangesToRemove { replaceSubrange(range, with: []) }
    }

}

extension String {
    static var appVersion: String {
        guard let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"],
              let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"]
        else {
            return ""
        }
        return "v\(appVersion)(\(buildVersion))"
    }
}

private let suffixToRemove = ["spread", "six pack", "money line", "total points"].map({" \($0)"})
private let capNum = ["st", "nd", "rd", "th"]

extension UILabel {
    var stringCount: Int {
        if let attr = attributedText { return attr.string.count }
        return text?.count ?? 0
    }
    
    var textIsEmpty: Bool { stringCount == 0 }
    var labelNeedsContent: Bool { (isHidden || (superview?.isHidden ?? false)) ? false : stringCount == 0 }
}

extension Array where Element == String {
    func recursiveContains(_ containString: String) -> Bool {
        for str in self {
            if str.contains(containString) { return true }
        }
        
        return false
    }
}

extension NSObject {
    /// Returns a string of an objects class/type
    var objTypeName: String { String(describing: type(of: self)) }
    
    /// Returns a string of an objects class/type
    var objNameShort: String {
        let replacedComponents = String(describing: type(of: self)).bulkReplace([("ViewModel", "VM"), ("ViewController", "VC")]).titleCased.components(separatedBy: " ")
        return replacedComponents.map({ String($0.prefix(4)) }).joined()
    }
    
    /// Returns a memory address as a string for the object on which it is called
    var memAddressFull: String { "\(Unmanaged.passUnretained(self).toOpaque())" }
    
    /// Returns a short memory address (suffix(5)) as a string for the object on which it is called
    var memAdShort: String { String(memAddressFull.suffix(5)) }
}

extension String {
    /// Perform multiple replacements using an array
    /// - Parameter replaceKits: Array of tuples containing the target and replacement strings in a single element
    /// - Returns: Fully replaced string as specified with replaceKit inputs
    func bulkReplace(_ replaceKits: [(target: String, replacement: String)]) -> String {
        var result = self
        guard replaceKits.count > 0, result.count > 1 else { return result }
        
        for kit in replaceKits {
            let temp = result.replacingOccurrences(of: kit.target, with: kit.replacement)
            result = temp
        }
        
        return result
    }
    
    /// Converts a 'CamelCasedString' to a 'Title Cased String'. (space separated + capitalized)
    /// - Returns: 'titleCased' string  e.g. 'MagicSixPackCell' -> 'Magic Six Pack Cell'
    var titleCased: String {
        replacingOccurrences(of: "(\\p{UppercaseLetter}\\p{LowercaseLetter}|\\p{UppercaseLetter}+(?=\\p{UppercaseLetter}))", with: " $1", options: .regularExpression, range: range(of: self))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func dateFmtStr(_ date: Date = Date()) -> String {
        let df = DateFormatter()
        df.dateFormat = self
        return df.string(from: date)
    }
}

extension String {

    /// Assuming the current string is base64 encoded, this property returns a String
    /// initialized by converting the current string into Unicode characters, encoded to
    /// utf8. If the current string is not base64 encoded, nil is returned instead.
    var base64Decoded: String? {
        guard let base64 = Data(base64Encoded: self) else { return nil }
        let utf8 = String(data: base64, encoding: .utf8)
        return utf8
    }

    /// Returns a base64 representation of the current string, or nil if the
    /// operation fails.
    var base64Encoded: String? {
        let utf8 = self.data(using: .utf8)
        let base64 = utf8?.base64EncodedString()
        return base64
    }

}

extension IndexPath {
    /// Returns a clean short string detailing the IndexPath
    var printPath: String { "(s: \(section), r: \(row))" }
    
    /// Helper method to quickly return an IndexPath object
    /// - Parameters:
    ///   - row: The specified row as Int
    ///   - sect: Optional section value, defaults to 0 if not passed
    /// - Returns: IndexPath object
    static func getIdPath(_ row: Int, _ sect: Int? = nil) -> IndexPath { .init(row: row, section: sect ?? 0) }
}

extension CGRect {
    var printRect: String { "(x: \(origin.x.shortStr), y: \(origin.y.shortStr), W: \(size.width.shortStr), H: \(size.height.shortStr))" }
    var printRectSize: String { "(W: \(size.width.shortStr), H: \(size.height.shortStr))" }
    var printRectOrigin: String { "(x: \(origin.x.shortStr), y: \(origin.y.shortStr))" }
}

extension UIEdgeInsets {
    var printInsets: String { "(t: \(top.shortStr), l: \(left.shortStr), b: \(bottom.shortStr), r: \(right.shortStr))" }
}

extension CGSize {
    var printSize: String { "(W: \(width.shortStr), H: \(height.shortStr))" }
}

extension CGPoint {
    var printPoint: String { "(x: \(x.shortStr), y: \(y.shortStr))" }
}

extension UIGestureRecognizer.State {
    var stateCase: String {
        switch self {
        case .possible  : return "possible"
        case .began     : return "began"
        case .changed   : return "changed"
        case .ended     : return "ended"
        case .cancelled : return "cancelled"
        case .failed    : return "failed"
        default: return "unknown pan state..."
        }
    }
}
