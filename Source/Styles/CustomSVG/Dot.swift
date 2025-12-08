//
//  Dot.swift
//  EFQRCode
//
//  Created by Dey device -5 on 13/10/25.
//

import QRCodeSwift
import Foundation

public enum AssetBasedDotGroupingStyle: String, Codable, CaseIterable {
    case threeByThree = "3x3"
    case twoByTwo = "2x2"
    case threeByOne = "3x1"
    case oneByThree = "1x3"
    case twoByOne = "2x1"
    case oneByTwo = "1x2"
    case oneByOne = "1x1"

    var size: (Int, Int) {
        let comps = self.rawValue.split(separator: "x")
        return (Int(comps[0]) ?? 1, Int(comps[1]) ?? 1)
    }
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
    public let styleSvgsDict: [AssetBasedDotGroupingStyle: [String]]
    
    public init(styleSvgsDict: [AssetBasedDotGroupingStyle : [String]]) {
        self.styleSvgsDict = styleSvgsDict
    }
    
    private func isGroupValid(
        x: Int,
        y: Int,
        w: Int,
        h: Int,
        qrCode: QRCode,
        available: [[Bool]],
        typeTable: [[QRPointType]]
    ) -> Bool {
        for dx in 0..<w {
            for dy in 0..<h {
                if !qrCode.model.isDark(x+dx, y+dy) { return false }
                if !available[x + dx][y + dy] { return false }
                //if typeTable[x + dx][y + dy] != .data { return false }
            }
        }
        return true
    }
    
    public func add(x: Int, y: Int, nCount: Int, qrCode: QRCode, available: inout [[Bool]], typeTable: [[QRPointType]], pointList: inout [String], idCount: inout Int) {
        if available[x][y] == false { return }
        
        for style in AssetBasedDotGroupingStyle.allCases {
            
            let (w, h) = style.size
            
            // Check bounds
            if x > nCount - w || y > nCount - h { continue }
            
            // Validate modules are dark, available, correct type
            if !isGroupValid(
                x: x, y: y,
                w: w, h: h,
                qrCode: qrCode,
                available: available,
                typeTable: typeTable
            ) {
                continue
            }
            
            let svgArray = styleSvgsDict[style]
            let svg = svgArray?.randomElement() ?? ""
            guard let url = Bundle.main.url(forResource: svg, withExtension: "svg"),
                  let svgString = try? String(contentsOf: url, encoding: .utf8) else {
                return
            }
            
            pointList.append(
                drawShape(id: "\(idCount)", x: x, y: y, width: w, height: h, svgString: svgString)
            )
            idCount += 1
            
            for dx in 0..<w {
                for dy in 0..<h {
                    available[x + dx][y + dy] = false
                }
            }
            
            break
        }
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
