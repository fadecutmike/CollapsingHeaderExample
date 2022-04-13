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
