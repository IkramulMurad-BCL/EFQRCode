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
              qrCode.model.isDark(nx, y),
              available[nx][y] {
            length += 1
            nx += 1
        }

        // mark consumed
        for dx in 0..<length { available[x+dx][y] = false }
        
        var svg = ""
        if length == 1 {
            svg.append(getSingleUnit(x: x, y: y, lineCap: lineCap, idCount: idCount))
        } else {
            let startX = CGFloat(x)
            let endX = CGFloat(x + length - 1)
            let yPos = CGFloat(y)
            
            svg += getHorizontalStartCap(x: startX, y: yPos, lineCap: lineCap, id: idCount)
            idCount += 1
            
            if length > 2 {
                let midX = startX + 1
                let midWidth = CGFloat(length - 2)
                
                svg += """
                    <rect key="\(idCount)" x="\(midX)" y="\(yPos)" width="\(midWidth)" height="1"/>
                    """
                idCount += 1
            }
            
            
            svg += getHorizontalEndCap(x: endX, y: yPos, lineCap: lineCap, id: idCount)
            idCount += 1
        }
        
        pointList.append(svg)
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
              qrCode.model.isDark(x, ny),
              available[x][ny] {
            length += 1
            ny += 1
        }

        for dy in 0..<length { available[x][y+dy] = false }

        var svg = ""
        if length == 1 {
            svg.append(getSingleUnit(x: x, y: y, lineCap: lineCap, idCount: idCount))
        } else {
            let xPos = CGFloat(x)
            let endY = CGFloat(y + length - 1)
            let startY = CGFloat(y)
            
            svg += getVerticalStartCap(x: xPos, y: startY, lineCap: lineCap, id: idCount)
            idCount += 1
            
            if length > 2 {
                let midY = startY + 1
                let midHeight = CGFloat(length - 2)
                
                svg += """
                    <rect key="\(idCount)" x="\(xPos)" y="\(midY)" width="1" height="\(midHeight)"/>
                    """
                idCount += 1
            }
            
            
            svg += getVerticalEndCap(x: xPos, y: endY, lineCap: lineCap, id: idCount)
            idCount += 1
        }
        
        pointList.append(svg)
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
              qrCode.model.isDark(nx, ny),
              available[nx][ny] {
            length += 1
            nx += 1; ny += 1
        }

        for i in 0..<length { available[x+i][y+i] = false }

//        let cap = svgLineCap()
//        let str = """
//            <line key="\(idCount)" x1="\(x.cgFloat+0.3)" y1="\(y.cgFloat+0.3)" x2="\(x.cgFloat+length.cgFloat-0.3)" y2="\(y.cgFloat+length.cgFloat-0.3)" stroke="black" stroke-width="1" stroke-linecap="\(cap)"/>
//        """
//        pointList.append(str)
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
              qrCode.model.isDark(nx, ny),
              available[nx][ny] {
            length += 1
            nx -= 1; ny += 1
        }

        for i in 0..<length { available[x-i][y+i] = false }

//        let cap = svgLineCap()
//        let str = """
//            <line key="\(idCount)" x1="\(x.cgFloat+0.7)" y1="\(y.cgFloat+0.3)" x2="\(x.cgFloat-length.cgFloat+0.7)" y2="\(y.cgFloat+length.cgFloat-0.3)" stroke="black" stroke-width="1" stroke-linecap="\(cap)"/>
//        """
//        pointList.append(str)
        idCount += 1
    }

    func getSingleUnit(x: Int, y: Int, lineCap: AssetLessDotLineCap, idCount: Int) -> String {
        switch lineCap {
        case .rounded:
            return "<circle key=\"\(idCount)\" cx=\"\(x.cgFloat + 0.5)\" cy=\"\(y.cgFloat + 0.5)\" r=\"0.5\"/>"
        case .angular:
            let p1 = "\(x.cgFloat + 0.5),\(y.cgFloat)"         // Top
            let p2 = "\(x.cgFloat + 1),\(y.cgFloat + 0.5)"     // Right
            let p3 = "\(x.cgFloat + 0.5),\(y.cgFloat + 1)"     // Bottom
            let p4 = "\(x.cgFloat),\(y.cgFloat + 0.5)"         // Left
            
            return """
                    <polygon key="\(idCount)"
                             points="\(p1) \(p2) \(p3) \(p4)"
                             />
                    """
        default:
            return "<rect key=\"\(idCount)\" x=\"\(x)\" y=\"\(y)\" width=\"1\" height=\"1\"/>"
        }
    }
    
    func getHorizontalStartCap(x: CGFloat, y: CGFloat, lineCap: AssetLessDotLineCap, id: Int) -> String {
        switch lineCap {
        case .angular:
            return """
            <polygon key="\(id)" points="\(x),\(y+0.5) \(x+0.5),\(y) \(x+1),\(y) \(x+1),\(y+1) \(x+0.5),\(y+1)"/>
            """
        case .rounded:
            return """
                <path key="\(id)" d="M \(x+0.5) \(y)
                                     A 0.5 0.5 0 0 0 \(x+0.5) \(y+1)
                                     Z" />

                <rect key="\(id)_r" x="\(x+0.5)" y="\(y)" width="0.5" height="1"/>
                """
        case .none:
            return """
            <rect key="\(id)" x="\(x)" y="\(y)" width="1" height="1"/>
            """
        }
    }
    
    func getHorizontalEndCap(x: CGFloat, y: CGFloat, lineCap: AssetLessDotLineCap, id: Int) -> String {
        switch lineCap {
        case .angular:
            return """
            <polygon key="\(id)" points="\(x),\(y) \(x+0.5),\(y) \(x+1),\(y+0.5) \(x+0.5),\(y+1) \(x),\(y+1)"/>
            """
        case .rounded:
            return """
            <rect key="\(id)_l" x="\(x)" y="\(y)" width="0.5" height="1"/>
            <path key="\(id)" d="M \(x+0.5) \(y) A 0.5 0.5 0 0 1 \(x+0.5) \(y+1) Z" />
            """
        case .none:
            return """
            <rect key="\(id)" x="\(x)" y="\(y)" width="1" height="1"/>
            """
        }
    }
    
    func getVerticalStartCap(x: CGFloat, y: CGFloat, lineCap: AssetLessDotLineCap, id: Int) -> String {
        switch lineCap {
        case .angular:
            // Diamond, top of vertical line
            return """
            <polygon key="\(id)" points="\(x+0.5),\(y) \(x+1),\(y+0.5) \(x+1),\(y+1) \(x),\(y+1) \(x),\(y+0.5)"/>
            """
        case .rounded:
            // Top half-circle, facing up
            return """
            <path key="\(id)" d="M \(x) \(y+0.5)
                                 A 0.5 0.5 0 0 1 \(x+1) \(y+0.5)
                                 Z" />
            <rect key="\(id)_b" x="\(x)" y="\(y+0.5)" width="1" height="0.5"/>
            """
        case .none:
            return """
            <rect key="\(id)" x="\(x)" y="\(y)" width="1" height="1"/>
            """
        }
    }

    func getVerticalEndCap(x: CGFloat, y: CGFloat, lineCap: AssetLessDotLineCap, id: Int) -> String {
        switch lineCap {
        case .angular:
            // Diamond, bottom of vertical line
            return """
            <polygon key="\(id)" points="\(x),\(y) \(x+1),\(y) \(x+1),\(y+0.5) \(x+0.5),\(y+1) \(x),\(y+0.5)"/>
            """
        case .rounded:
            // Bottom half-circle, facing down
            return """
            <rect key="\(id)_t" x="\(x)" y="\(y)" width="1" height="0.5"/>
            <path key="\(id)" d="M \(x) \(y+0.5)
                                 A 0.5 0.5 0 0 0 \(x+1) \(y+0.5)
                                 Z" />
            """
        case .none:
            return """
            <rect key="\(id)" x="\(x)" y="\(y)" width="1" height="1"/>
            """
        }
    }

}
