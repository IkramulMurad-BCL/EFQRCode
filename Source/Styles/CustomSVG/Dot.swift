//
//  Dot.swift
//  EFQRCode
//
//  Created by Dey device -5 on 13/10/25.
//

import QRCodeSwift

public enum AssetBasedDotGroupingStyle: String, Codable {
    case oneByOne = "1x1"
    case oneByTwo = "1x2"
    case twoByOne = "2x1"
    case twoByTwo = "2x2"
    case threeByOne = "3x1"
    case oneByThree = "1x3"
}


public enum AssetLessDotGroupingStyle: String, Codable {
    case none
    case horizontal
    case vertical
    case diagonalTopLeftToBottomRight
    case diagonalTopRightToBottomLeft
}

public enum AssetLessDotLineCap: String, Codable {
    case none
    case angular
    case rounded
}

public protocol Dot {
    func add(x: Int, y: Int, nCount: Int, qrCode: QRCode, available: inout [[Bool]], typeTable: [[QRPointType]], pointList: inout [String], idCount: inout Int)
}

public struct AssetBased: Dot {
    public let styles: [AssetBasedDotGroupingStyle]
    public let svgs: [String]
    
    public init(styles: [AssetBasedDotGroupingStyle], svgs: [String]) {
        self.styles = styles
        self.svgs = svgs
    }
    
    public func add(x: Int, y: Int, nCount: Int, qrCode: QRCode, available: inout [[Bool]], typeTable: [[QRPointType]], pointList: inout [String], idCount: inout Int) {
        
    }
}

public struct AssetLess: Dot {
    public let groupingLogic: AssetLessDotGroupingStyle
    public let lineCap: AssetLessDotLineCap
    
    public init(groupingLogic: AssetLessDotGroupingStyle, lineCap: AssetLessDotLineCap) {
        self.groupingLogic = groupingLogic
        self.lineCap = lineCap
    }
    
    public func add(x: Int, y: Int, nCount: Int, qrCode: QRCode, available: inout [[Bool]], typeTable: [[QRPointType]], pointList: inout [String], idCount: inout Int) {
        
    }
}
