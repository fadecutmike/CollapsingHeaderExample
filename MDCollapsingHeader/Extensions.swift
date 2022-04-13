//
//  Extensions.swift
//  MDCollapsingHeader
//
//  Created by mad on 2/19/22.
//

import UIKit

extension Numeric where Self == Float {
    var dollars: String { String(format: "$%.2f", self) }
    var twoDecimalString: String { String(format: "%.2f", self) }
    var dollarOrCents: String {
        if self < 1 { return "\(self.twoDecimalString)c" }
        else { return "$\(self.cleanCommaString)"}
    }
    var cleanCommaString: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 2
        return numberFormatter.string(from: NSNumber(value: self)) ?? ""
    }
    
    func round(nearest: Float) -> Float {
        let n = 1/nearest
        return (self*n).rounded()/n
    }
    
    func limit(_ minVal: Float = 0.0, _ maxVal: Float = 1.0) -> Float {
        max(minVal, min(maxVal, self))
    }
}

extension Numeric where Self == CGFloat {
    var twoDecimalString : String { String(format: "%.2f", self) }
    var shortStr         : String { String(format: "%.0f", self) }
    func shortDigitStr(_ limit: Int) -> String { String(format: "%\(limit).f", self) }
}

extension Numeric where Self == Double {
    var dollars: String { String(format: "$%.2f", self) }
    var twoDecimalString: String { String(format: "%.2f", self) }
    private var percentInt: String { String(format: "%.0f", self*100.0) }
    var percentString: String { "\(percentInt)%" }
    var spread: String {
        let prefix = self >= 0 ? "+" : "-"
        return String(format: "%@%.1f", prefix, abs(self))
    }

    var dollarsToPennies: Int {
        var tmpstr = "\(String(format: "%.2f", arguments: [self]))"
        tmpstr = tmpstr.replacingOccurrences(of: ".", with: "")
        return Int(tmpstr) ?? 0
    }

    var marketLineStr: String { "\(self <= 0 ? "":"+")\(self)" }
    var dollarsOrCents: String {
        if self < 1 { return "$\(self.twoDecimalString)c" }
        else { return "$\(self.cleanCommaString)"}
    }
    var cleanCommaString: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 2
        return numberFormatter.string(from: NSNumber(value: self)) ?? ""
    }
    var intValue: Int    { Int(self) }
    var strValue: String { "\(self)" }
    var shortStr: String { String(format: "%.0f", self) }
    
    var signedSpreadStr: String {
        let formatter            = spreadNumFormatter
        formatter.positivePrefix = "+"               // Show + sign when the value is a positive number
        return formatter.string(for: self) ?? ""
    }

    var spreadStr: String { spreadNumFormatter.string(for: self) ?? "" }
    
    private var spreadNumFormatter: NumberFormatter {
        let numberFormatter                      = NumberFormatter()
        numberFormatter.numberStyle              = .decimal          // Set defaults to the formatter that are common for showing decimal numbers
        numberFormatter.maximumSignificantDigits = 4
        numberFormatter.minimumSignificantDigits = 1
        return numberFormatter
    }
    
    func round(nearest: Double) -> Double {
        let n = 1/nearest
        return (self*n).rounded()/n
    }
    
    func limit(_ minVal: Double = 0.0, _ maxVal: Double = 1.0) -> Double {
        max(minVal, min(maxVal, self))
    }
}
extension Numeric where Self == Int {
    var dollars      : String  { String(format: "$%.2f", Double(self)/100.0) }
    var dollarsShort : String  { String(format: "$%.0f", Double(self)/100.0) }
    var boolValue    : Bool    { self != 0 }
    var strValue     : String  { "\(self)" }
    var cgFltVal     : CGFloat { CGFloat(self) }
    var wagerDollars : Double  { Double(self)/100.0 }

    public func penniesToDollars() -> String {
        let dollars = Int(self/100)
        let cents   = Int(self%100)
        return "\(dollars).\(cents < 10 ? "0" : "")\(cents)"
    }

    var threeDigStr     : String { String(format: "%03.f", Double(self)) }
    var secondsFromDays : Int    { self*24*60*60 }
}

extension Bool {
    var intValue : Int     { self ? 1 : 0 }
    var dblValue : Double  { self ? 1.0 : 0.0 }
    var fltValue : CGFloat { self ? 1.0 : 0.0 }
    var strValue : String  { self ? "true" : "false" }
    var flipped  : Bool    { (1-intValue).boolValue }
}

private let upCaseChars = CharacterSet.uppercaseLetters

extension String {
   
    /// Convert camel-case names to words eg. for display labels
    /// - Returns: camel-cased string
    func camelCaseToWords() -> String { unicodeScalars.reduce("") { $0 + ((upCaseChars.contains($1) && $0.count > 0) ? " ":"") + String($1) } }
    
    func snakeCased() -> String? {
        let regex = try? NSRegularExpression(pattern: "([a-z0-9])([A-Z])", options: [])
        return regex?.stringByReplacingMatches(in: self, options: [], range: .init(location: 0, length: count), withTemplate: "$1_$2").lowercased()
    }

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
            return upperCase ? result.uppercased() : result
        }
        return upperCase ? str.prefix(4).uppercased() : String(str.prefix(4))
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

private let suffixToRemove = ["spread", "six pack", "money line", "total points"].map({" \($0)"})
private let capNum = ["st", "nd", "rd", "th"]

extension NSObject {
    /// Returns a string of an objects class/type
    var objTypeName: String { String(describing: type(of: self)) }
    
    /// Returns a memory address as a string for the object on which it is called
    var memAddress: String { "\(Unmanaged.passUnretained(self).toOpaque())" }
}

extension String {
    func dateFmtStr(_ date: Date = Date()) -> String {
        let df = DateFormatter()
        df.dateFormat = self
        return df.string(from: date)
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

// MARK: - UIColor helper methods

extension UIColor {
    
    /// Quickly get an RGBA UIColor
    /// - Parameters:
    ///   - r: red Int
    ///   - g: green Int
    ///   - b: blue Int
    ///   - a: alpha CGFloat
    /// - Returns: UIColor object
    class func rgba(_ r: Int, _ g: Int, _ b: Int, _ a: CGFloat = 1.0) -> UIColor {
        assert(r >= 0 && r <= 255, "Invalid red component")
        assert(g >= 0 && g <= 255, "Invalid green component")
        assert(b >= 0 && b <= 255, "Invalid blue component")
        return UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: CGFloat(a))
    }
    
    class func randomColor(_ a: CGFloat = 1.0) -> UIColor {
        let r: Int = .random(in: 0...255)
        var g: Int = .random(in: 0...255)
        var b: Int = .random(in: 0...255)
        
        if abs(r-g) < 50 { g = r>=205 ? r-50 : r+50 }
        if r+g+b > 650 {
            g /= 2
            b = 15
        } else if r+b+g < 200 {
            g *= 2
            b = 250
        }
        return UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: CGFloat(a))
    }
}

// MARK: - Hex Color methods

extension UIColor {
    
    /// UIColor from hex string
    /// - Parameter hex: hex string of desired color
    /// - Returns: UIColor object from inputted hex string
    class func hex(_ hex: String) -> UIColor {

        var rgb       : (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) = (0, 0, 0, 0)
        let hexString : String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().replacingOccurrences(of: "#", with: "")
        var hexNumber : UInt64 = 0
        let scanner = Scanner(string: hexString)
        
        guard [6, 8].contains(hexString.count) else { fatalError("Invalid hex string length for UIColor.hex init...") }
        
        if scanner.scanHexInt64(&hexNumber) {
            switch hexString.count {
            case 8: rgb = ( r: CGFloat((hexNumber & 0xff000000) >> 24) / 255,
                            g: CGFloat((hexNumber & 0x00ff0000) >> 16) / 255,
                            b: CGFloat((hexNumber & 0x0000ff00) >> 8)  / 255,
                            a: CGFloat( hexNumber & 0x000000ff)        / 255)
                
            case 6: rgb = ( r: CGFloat((hexNumber & 0xff0000) >> 16) / 255,
                            g: CGFloat((hexNumber & 0x00ff00) >> 8)  / 255,
                            b: CGFloat((hexNumber & 0x0000ff))       / 255,
                            a: 1.0)
            default: fatalError("Invalid hex string for UIColor.hex init...")
            }
        }
        return UIColor.init(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: rgb.a)
    }
}

extension Date {

    enum DateFormat: String {
        case fullMonthName = "MMMM dd, yyyy hh:mm a"
        case yearFourDigits = "yyyy-MM-dd'T'HH:mm:ss"
        case yearFourDigitsWithMilliseconds = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    }
    
    var is21YearsOrOlder: Bool { abs(timeIntervalSinceNow) >= 662256000 }

    var timeNow: String { "hh:mm:ss".dateFmtStr(self) }

    static var timestampNow: String { "hh:mm:ss.SSS".dateFmtStr(Date()) }

    /// Determines if the associated time of a date is on the hour with minutes == 0 (e.g. 1PM)
    var timeIsOnTheHour: Bool { Calendar.current.component(.minute, from: self) == 0 }

    var eventsStartDateHeaderTitle: String {
        let cal = Calendar.current
        let dateString = cal.isDateInToday(self) ? "today" : cal.isDateInTomorrow(self) ? "tomorrow" : "MMM d".dateFmtStr(self)
        return dateString.uppercased()
    }

    /// Method used for FilterView Date filter
    /// - Returns: Number of days since current date
    func numOfDaysAgo() -> Int {
        let cal = Calendar.current
        let fromDate = cal.startOfDay(for: self)
        let toDate = cal.startOfDay(for: Date())
        let numberOfDays = cal.dateComponents([.day], from: fromDate, to: toDate)

        return numberOfDays.day!
    }

    /// String representing the Month and Day
    var monthDayStr: String { "MMdd".dateFmtStr(self) }

    static func getDateDaysAgo(_ numDays: Int) -> Date {
        Date().addingTimeInterval(TimeInterval(-1*numDays.secondsFromDays))
    }

    static func formatted(fromString string: String, usingFormat format: DateFormat) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format.rawValue

        return dateFormatter.date(from: string) ?? Date()
    }

    static func formatted(fromDate date: Date, usingFormat format: DateFormat) -> String {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = format.rawValue
        return dateFormatter.string(from: date)
    }

    func cleanCustomDate(_ isFromDate: Bool) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)

        components.hour   = isFromDate ? 0 : 23
        components.minute = isFromDate ? 0 : 59
        components.second = isFromDate ? 0 : 59

        return calendar.date(from: components)
    }
    
}

extension Date {
    /// Parameter to determine if cashout loading indicator was displayed on screen for a specificied minimum amount of time
    var minCashoutLoadingDelay: Double { max(1.0 - Date().timeIntervalSince(self), 0.0) }
}

extension Sequence where Iterator.Element: Hashable {

    func unique() -> [Iterator.Element] {
        guard let result = NSOrderedSet(array: compactMap({ $0 })).array as? [Iterator.Element] else { fatalError("Sequence ext - 'func unique()' failed...") }
        return result
    }

    func returnAsSet() -> Set<Element> { Set<Element>(self) }
}

extension Array where Element: Sequence {
    var flat     : [Element.Element] { joined().map({$0}) }
    var flatCmpt : [Element.Element] { joined().compactMap({$0}) }
}

extension Array where Element: Hashable {

    func subtracted(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        return Array(thisSet.subtracting(other))
    }

    func intersection(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        return Array(thisSet.intersection(other))
    }
}

extension Array where Element == String {

    /// Market title live checker
    /// - Parameter isLive: whether a market is live or not
    /// - Returns: Title name with 'LIVE' appended or not depending on the event state
    func liveCheck(_ isLive: Bool) -> Self { map({"\($0)\(isLive ? " LIVE" : "")"}) }

    /// Uppercasing for array of string
    /// - Returns: Array of uppercased strings
    func upCased() -> Self { map({$0.uppercased()}) }
}

protocol Reorderable {
    associatedtype OrderElement: Equatable
    var orderElement: OrderElement { get }
}

extension Array where Element: Reorderable {
    func reorder(by preferredOrder: [Element.OrderElement]) -> [Element] {
        sorted {
            guard let first = preferredOrder.firstIndex(of: $0.orderElement) else { return false }
            guard let second = preferredOrder.firstIndex(of: $1.orderElement) else { return true }

            return first < second
        }
    }
}

// MARK: - Pack update helper methods

extension Array where Element == UpdatablePackElement {
    var allSPBtns: [UISixPackButton] { compactMap({ $0.spBtns }).flat }
}

public extension UIImage {
    
    /// Programatically tinit UIImage
    /// - Parameter color: The color used to overlay the non transparent pixels within an image
    /// - Returns: A new UIImage with the non transparent pixels overlayed with the color input
    func tinted(_ color: UIColor) -> UIImage? {
        defer { UIGraphicsEndImageContext() }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        color.setFill()
        withRenderingMode(.alwaysTemplate).draw(in: .init(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// Generates a flat color UIImage
    /// - Parameters:
    ///   - color: Image Fill color
    ///   - size: Size of desired image
    /// - Returns: Color filled UIImage of specified size
    class func imageWith(_ color: UIColor, _ size: CGSize = .init(width: 1.0, height: 5.0)) -> UIImage? {
        defer { UIGraphicsEndImageContext() }
        UIGraphicsBeginImageContext(size)
        color.setFill()
        UIGraphicsGetCurrentContext()?.fill(.init(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    class func layeredImage(_ imageA: UIImage, _ imageB: UIImage) -> UIImage? {
        guard let imgA = imageA.cgImage, let imgB = imageB.cgImage else { fatalError() }
        defer { UIGraphicsEndImageContext() }
        let imgSize = imageA.size.width*imageA.size.height > imageB.size.width*imageB.size.height ? imageA.size : imageB.size
        UIGraphicsBeginImageContextWithOptions(imgSize, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        context?.draw(imgA, in: .init(origin: .zero, size: imgSize))
        context?.draw(imgB, in: .init(origin: .zero, size: imgSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// Scale an image bounded by a max width
    func scaleTo(maxWidth width: CGFloat) -> UIImage {
        guard size != .zero else {
            print("WARNING: attempting to scale a zero sized image")
            return self
        }
        let ratio = width / size.width
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
