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
//                    pointList.append("<rect x=\"\(x + dx)\" y=\"\(y + dy)\" width=\"1\" height=\"1\" fill=\"red\"/>")
//                    idCount += 1
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
        guard qrCode.model.isDark(x, y) else { return }
        guard available[x][y] else { return }
        
        switch groupingLogic {
        case .none:
            drawSingle(x: x, y: y, available: &available, pointList: &pointList, idCount: &idCount)
            
        case .horizontal:
            drawHorizontal(x: x, y: y, nCount: nCount, qrCode: qrCode,
                           available: &available, pointList: &pointList, idCount: &idCount)
            
        case .vertical:
            drawVertical(x: x, y: y, nCount: nCount, qrCode: qrCode,
                         available: &available, pointList: &pointList, idCount: &idCount)
            
        case .diagonalTopLeftToBottomRight:
            drawDiagonalTLBR(x: x, y: y, nCount: nCount, qrCode: qrCode,
                             available: &available, pointList: &pointList, idCount: &idCount)
            
        case .diagonalTopRightToBottomLeft:
            drawDiagonalTRBL(x: x, y: y, nCount: nCount, qrCode: qrCode,
                             available: &available, pointList: &pointList, idCount: &idCount)
        }
    }
    
    private func drawSingle(
        x: Int, y: Int,
        available: inout [[Bool]],
        pointList: inout [String],
        idCount: inout Int
    ) {
        pointList.append("<rect key=\"\(idCount)\" x=\"\(x)\" y=\"\(y)\" width=\"1\" height=\"1\"/>")
        idCount += 1
        available[x][y] = false
    }

    private func drawHorizontal(
        x: Int, y: Int, nCount: Int, qrCode: QRCode,
        available: inout [[Bool]],
        pointList: inout [String], idCount: inout Int
    ) {
        var length = 1
        var nx = x + 1

        while nx < nCount,
              qrCode.model.isDark(x, y),
              available[nx][y] {
            length += 1
            nx += 1
        }

        // mark consumed
        for dx in 0..<length { available[x+dx][y] = false }

        // Draw line from (x, y) to (x + length, y)
        let cap = svgLineCap()
        let str = """
            <line key="\(idCount)" x1="\(x.cgFloat)" y1="\(y.cgFloat+0.5)" x2="\(x.cgFloat+length.cgFloat)" y2="\(y.cgFloat+0.5)" stroke="black" stroke-width="1" stroke-linecap="\(cap)"/>
        """
        pointList.append(str)
        idCount += 1
    }

    private func drawVertical(
        x: Int, y: Int, nCount: Int, qrCode: QRCode,
        available: inout [[Bool]],
        pointList: inout [String], idCount: inout Int
    ) {
        var length = 1
        var ny = y + 1

        while ny < nCount,
              qrCode.model.isDark(x, y),
              available[x][ny] {
            length += 1
            ny += 1
        }

        for dy in 0..<length { available[x][y+dy] = false }

        let cap = svgLineCap()
        let str = """
            <line key="\(idCount)" x1="\(x.cgFloat+0.5)" y1="\(y.cgFloat)" x2="\(x.cgFloat+0.5)" y2="\(y.cgFloat+length.cgFloat)" stroke="black" stroke-width="1" stroke-linecap="\(cap)"/>
        """
        pointList.append(str)
        idCount += 1
    }

    private func drawDiagonalTLBR(
        x: Int, y: Int, nCount: Int, qrCode: QRCode,
        available: inout [[Bool]],
        pointList: inout [String], idCount: inout Int
    ) {
        var length = 1
        var nx = x + 1
        var ny = y + 1

        while nx < nCount, ny < nCount,
              qrCode.model.isDark(x, y),
              available[nx][ny] {
            length += 1
            nx += 1; ny += 1
        }

        for i in 0..<length { available[x+i][y+i] = false }

        let cap = svgLineCap()
        let str = """
            <line key="\(idCount)" x1="\(x.cgFloat+0.3)" y1="\(y.cgFloat+0.3)" x2="\(x.cgFloat+length.cgFloat-0.3)" y2="\(y.cgFloat+length.cgFloat-0.3)" stroke="black" stroke-width="1" stroke-linecap="\(cap)"/>
        """
        pointList.append(str)
        idCount += 1
    }

    private func drawDiagonalTRBL(
        x: Int, y: Int, nCount: Int, qrCode: QRCode,
        available: inout [[Bool]],
        pointList: inout [String], idCount: inout Int
    ) {
        var length = 1
        var nx = x - 1
        var ny = y + 1

        while nx >= 0, ny < nCount,
              qrCode.model.isDark(x, y),
              available[nx][ny] {
            length += 1
            nx -= 1; ny += 1
        }

        for i in 0..<length { available[x-i][y+i] = false }

        let cap = svgLineCap()
        let str = """
            <line key="\(idCount)" x1="\(x.cgFloat+0.7)" y1="\(y.cgFloat+0.3)" x2="\(x.cgFloat-length.cgFloat+0.7)" y2="\(y.cgFloat+length.cgFloat-0.3)" stroke="black" stroke-width="1" stroke-linecap="\(cap)"/>
        """
        pointList.append(str)
        idCount += 1
    }

    private func svgLineCap() -> String {
        switch lineCap {
        case .none: return "butt"
        case .angular: return "square"
        case .rounded: return "round"
        }
    }
}
