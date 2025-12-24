//
//  Dot.swift
//  EFQRCode
//
//  Created by Dey device -5 on 13/10/25.
//

import QRCodeSwift
import Foundation
import SDWebImageWebPCoder

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
}

public enum AssetLessDotLineCap: String, Codable {
    case none
    case angular
    case rounded
}

public protocol Dot {
    func draw(in renderContext: QRRenderContext)
}

public class AssetBased: Dot {
    private var imageCache: [String: UIImage] = [:]
    
    public let styleWebpNamesDict: [AssetBasedDotGroupingStyle: [String]]
    
    public init(styleWebpNamesDict: [AssetBasedDotGroupingStyle : [String]]) {
        self.styleWebpNamesDict = styleWebpNamesDict
    }
    
    public func draw(in renderContext: QRRenderContext) {
        let qrcode = renderContext.qrcode
        let nCount = Int(renderContext.moduleCount)
        var available = Array(repeating: Array(repeating: true, count: nCount), count: nCount)
        let typeTable = qrcode.model.getTypeTable()
        
        for y in 0..<nCount {
            for x in 0..<nCount {
                if !qrcode.model.isDark(x, y) || !available[x][y] { continue }
                
                switch typeTable[x][y] {
                case .posCenter:
                    break
                    
                case .posOther:
                    break
                    
                default:
                    add(x: x, y: y, nCount: nCount, qrCode: qrcode, available: &available, typeTable: typeTable, context: renderContext)
                }
            }
        }
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
    
    private func cachedDotImage(named name: String) -> UIImage? {
        if let img = imageCache[name] {
            return img
        }

        guard
            let url = Bundle.main.url(forResource: name, withExtension: "webp"),
            let data = NSData(contentsOf: url),
            let image = SDImageWebPCoder.shared.decodedImage(with: data as Data?)
        else {
            return nil
        }

        imageCache[name] = image
        return image
    }
    
    public func add(x: Int, y: Int, nCount: Int, qrCode: QRCode, available: inout [[Bool]], typeTable: [[QRPointType]], context: QRRenderContext) {
        guard available[x][y] else { return }

        let moduleSize = context.moduleSize
        let quietZonePixel = context.quietZonePixel
        let scale = context.scale
        
        for style in [AssetBasedDotGroupingStyle.twoByTwo, AssetBasedDotGroupingStyle.oneByOne] {
            let (w, h) = style.size
            if x > nCount - w || y > nCount - h { continue }
            
            if !isGroupValid(
                x: x, y: y,
                w: w, h: h,
                qrCode: qrCode,
                available: available,
                typeTable: typeTable
            ) {
                continue
            }
            
            guard
                let names = styleWebpNamesDict[style],
                let name = names.randomElement(),
                let dotImage = cachedDotImage(named: name)
            else {
                break
            }
            
            for dx in 0..<w {
                for dy in 0..<h {
                    available[x + dx][y + dy] = false
                }
            }
            
            let pixelX = quietZonePixel + CGFloat(x) * moduleSize
            let pixelY = quietZonePixel + CGFloat(y) * moduleSize

            let dotWidth = CGFloat(w) * moduleSize
            let dotHeight = CGFloat(h) * moduleSize

            let drawRect = CGRect(
                x: pixelX / scale,
                y: pixelY / scale,
                width: dotWidth / scale,
                height: dotHeight / scale
            )

            dotImage.draw(in: drawRect)
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
    
    @inline(__always)
    func disableAA(_ ctx: CGContext) {
        ctx.setAllowsAntialiasing(false)
        ctx.setShouldAntialias(false)
    }

    @inline(__always)
    func enableAA(_ ctx: CGContext) {
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
    }
    
    public func draw(in renderContext: QRRenderContext) {
        let ctx = renderContext.context
        ctx.setAllowsAntialiasing(false)
        ctx.setShouldAntialias(false)
        ctx.interpolationQuality = .none
        
        let qrcode = renderContext.qrcode
        let nCount = Int(renderContext.moduleCount)
        var available = Array(repeating: Array(repeating: true, count: nCount), count: nCount)
        let typeTable = qrcode.model.getTypeTable()
        
        for y in 0..<nCount {
            for x in 0..<nCount {
                if !qrcode.model.isDark(x, y) || !available[x][y] { continue }
                
                switch typeTable[x][y] {
                case .posCenter:
                    break
                    
                case .posOther:
                    break
                    
                default:
                    add(x: x, y: y, nCount: nCount, qrCode: qrcode, available: &available, typeTable: typeTable, context: renderContext)
                }
            }
        }
    }
    
    public func add(x: Int, y: Int, nCount: Int, qrCode: QRCode, available: inout [[Bool]], typeTable: [[QRPointType]], context: QRRenderContext) {
        guard qrCode.model.isDark(x, y) else { return }
        guard available[x][y] else { return }
        
        switch groupingLogic {
        case .none:
            drawSingle(x: x, y: y, available: &available, context: context)
            context.context.fillPath()
        case .horizontal:
            drawHorizontal(x: x, y: y, nCount: nCount, qrCode: qrCode, available: &available, context: context)
            
        case .vertical:
            drawVertical(x: x, y: y, nCount: nCount, qrCode: qrCode, available: &available, context: context)
        }
    }
    
    private func drawSingle(x: Int, y: Int, available: inout [[Bool]], context: QRRenderContext) {
        drawBlackRect(x: x, y: y, w: 1, h: 1, context: context)
        available[x][y] = false
    }

    private func drawHorizontal(x: Int, y: Int, nCount: Int, qrCode: QRCode, available: inout [[Bool]], context: QRRenderContext) {
        var length = 1
        var nx = x + 1

        while nx < nCount,
              qrCode.model.isDark(nx, y),
              available[nx][y] {
            length += 1
            nx += 1
        }
        
        if length == 1 {
            drawSingleUnit(x: x, y: y, lineCap: lineCap, context: context)
        } else {
            drawHorizontalStartCap(in: context, x: x, y: y, lineCap: lineCap)
            if length > 2 {
                drawBlackRect(x: x + 1, y: y, w: length - 2, h: 1, context: context)
            }
            drawHorizontalEndCap(in: context, x: x + length - 1, y: y, lineCap: lineCap)
        }
        
        // mark consumed
        print("start print")
        for dx in 0..<length {
            print("x: \(x + dx), y: \(y)")
            available[x+dx][y] = false
        }
    }
    
    func drawBlackRect(x: Int, y: Int, w: Int, h: Int, context: QRRenderContext) {
        let moduleSize = context.moduleSize
        let quietZonePixel = context.quietZonePixel
        let scale = context.scale
        let ctx = context.context
        
        let pixelX = quietZonePixel + CGFloat(x) * moduleSize
        let pixelY = quietZonePixel + CGFloat(y) * moduleSize

        let dotWidth = CGFloat(w) * moduleSize
        let dotHeight = CGFloat(h) * moduleSize

        let drawRect = CGRect(
            x: pixelX / scale,
            y: pixelY / scale,
            width: dotWidth / scale,
            height: dotHeight / scale
        )

        ctx.setFillColor(UIColor.black.cgColor)
        ctx.addRect(drawRect)
        //ctx.fill(drawRect)
    }

    private func drawVertical(x: Int, y: Int, nCount: Int, qrCode: QRCode, available: inout [[Bool]], context: QRRenderContext) {
        var length = 1
        var ny = y + 1

        while ny < nCount,
              qrCode.model.isDark(x, ny),
              available[x][ny] {
            length += 1
            ny += 1
        }

        for dy in 0..<length { available[x][y+dy] = false }

        enableAA(context.context)
        if length == 1 {
            drawSingleUnit(x: x, y: y, lineCap: lineCap, context: context)
        } else {
            drawVerticalStartCap(in: context, x: x, y: y, lineCap: lineCap)
            if length > 2 {
                drawBlackRect(x: x, y: y + 1, w: 1, h: length - 2, context: context)
            }
            drawVerticalEndCap(in: context, x: x, y: y + length - 1, lineCap: lineCap)
        }
        context.context.fillPath()
    }

    func drawSingleUnit(x: Int, y: Int, lineCap: AssetLessDotLineCap, context: QRRenderContext) {
        let moduleSize = context.moduleSize
        let quietZonePixel = context.quietZonePixel
        let scale = context.scale
        let ctx = context.context
        ctx.setFillColor(UIColor.black.cgColor)

        let pixelX = quietZonePixel + CGFloat(x) * moduleSize
        let pixelY = quietZonePixel + CGFloat(y) * moduleSize

        let dotWidth = CGFloat(1) * moduleSize
        let dotHeight = CGFloat(1) * moduleSize

        let drawRect = CGRect(
            x: pixelX / scale,
            y: pixelY  / scale,
            width: dotWidth  / scale,
            height: dotHeight / scale
        )

        switch lineCap {
        case .rounded:
            let center = CGPoint(
                    x: drawRect.midX,
                    y: drawRect.midY
            )
            
            let radius = min(drawRect.width, drawRect.height) / 2
            
//            ctx.saveGState()
//            enableAA(ctx)
            ctx.addArc(
                center: center,
                radius: radius,
                startAngle: 0,
                endAngle: .pi * 2,
                clockwise: false
            )
//            ctx.fillPath()
//            ctx.restoreGState()
        case .angular:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: drawRect.midX, y: drawRect.minY)) // Top
            path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.midY)) // Right
            path.addLine(to: CGPoint(x: drawRect.midX, y: drawRect.maxY)) // Bottom
            path.addLine(to: CGPoint(x: drawRect.minX, y: drawRect.midY)) // Left
            path.closeSubpath()
            
            ctx.addPath(path)
            ctx.fillPath()
        default:
            drawBlackRect(x: x, y: y, w: 1, h: 1, context: context)
        }
    }
    
    func drawHorizontalStartCap(
        in context: QRRenderContext,
        x: Int, y: Int,
        lineCap: AssetLessDotLineCap
    ) {
        let moduleSize = context.moduleSize
        let quietZonePixel = context.quietZonePixel
        let scale = context.scale
        let ctx = context.context
        ctx.setFillColor(UIColor.black.cgColor)
        
        let pixelX = quietZonePixel + CGFloat(x) * moduleSize
        let pixelY = quietZonePixel + CGFloat(y) * moduleSize

        let dotWidth = CGFloat(1) * moduleSize
        let dotHeight = CGFloat(1) * moduleSize

        let drawRect = CGRect(
            x: pixelX / scale,
            y: pixelY  / scale,
            width: dotWidth / scale,
            height: dotHeight / scale
        )
        
        switch lineCap {

        case .angular:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: drawRect.minX, y: drawRect.midY))
            path.addLine(to: CGPoint(x: drawRect.midX, y: drawRect.minY))
            path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.minY))
            path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.maxY))
            path.addLine(to: CGPoint(x: drawRect.midX, y: drawRect.maxY))
            path.closeSubpath()

            ctx.addPath(path)
            ctx.fillPath()

        case .rounded:
            // Half circle (left side)
            ctx.saveGState()
            enableAA(ctx)
            ctx.addArc(
                center: CGPoint(x: drawRect.midX, y: drawRect.midY),
                radius: drawRect.height / 2,
                startAngle: .pi / 2,
                endAngle: -.pi / 2,
                clockwise: false
            )
            ctx.closePath()
            ctx.fillPath()
            ctx.restoreGState()

            // Right rectangle
            ctx.fill(
                CGRect(
                    x: drawRect.midX,
                    y: drawRect.minY,
                    width: drawRect.width / 2,
                    height: drawRect.height
                )
            )

        case .none:
            ctx.fill(drawRect)
        }
    }
    
    func drawHorizontalEndCap(
        in context: QRRenderContext,
        x: Int, y: Int,
        lineCap: AssetLessDotLineCap
    ) {
        let moduleSize = context.moduleSize
        let quietZonePixel = context.quietZonePixel
        let scale = context.scale
        let ctx = context.context
        ctx.setFillColor(UIColor.black.cgColor)
        
        let pixelX = quietZonePixel + CGFloat(x) * moduleSize
        let pixelY = quietZonePixel + CGFloat(y) * moduleSize

        let dotWidth = CGFloat(1) * moduleSize
        let dotHeight = CGFloat(1) * moduleSize

        let drawRect = CGRect(
            x: pixelX / scale,
            y: pixelY / scale,
            width: dotWidth / scale,
            height: dotHeight / scale
        )
        switch lineCap {

        case .angular:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: drawRect.minX, y: drawRect.minY))
            path.addLine(to: CGPoint(x: drawRect.midX, y: drawRect.minY))
            path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.midY))
            path.addLine(to: CGPoint(x: drawRect.midX, y: drawRect.maxY))
            path.addLine(to: CGPoint(x: drawRect.minX, y: drawRect.maxY))
            path.closeSubpath()

            ctx.addPath(path)
            ctx.fillPath()

        case .rounded:
            // Left rectangle
            ctx.fill(
                CGRect(
                    x: drawRect.minX,
                    y: drawRect.minY,
                    width: drawRect.width / 2,
                    height: drawRect.height
                )
            )
            
            // Half circle (right side)
            ctx.saveGState()
            enableAA(ctx)
            ctx.addArc(
                center: CGPoint(x: drawRect.midX, y: drawRect.midY),
                radius: drawRect.height / 2,
                startAngle: -.pi / 2,
                endAngle: .pi / 2,
                clockwise: false
            )
            ctx.closePath()
            ctx.fillPath()
            ctx.restoreGState()

        case .none:
            ctx.fill(drawRect)
        }
    }

    func drawVerticalStartCap(
        in context: QRRenderContext,
        x: Int, y: Int,
        lineCap: AssetLessDotLineCap
    ) {
        let moduleSize = context.moduleSize
        let quietZonePixel = context.quietZonePixel
        let scale = context.scale
        let ctx = context.context
        ctx.setFillColor(UIColor.black.cgColor)

        let pixelX = quietZonePixel + CGFloat(x) * moduleSize
        let pixelY = quietZonePixel + CGFloat(y) * moduleSize

        let drawRect = CGRect(
            x: pixelX / scale,
            y: pixelY / scale,
            width: moduleSize / scale,
            height: moduleSize / scale
        )

        switch lineCap {

        case .angular:
            // Diamond pointing up
            let path = CGMutablePath()
            path.move(to: CGPoint(x: drawRect.midX, y: drawRect.minY))       // Top
            path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.midY))   // Right
            path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.maxY))   // Bottom-right
            path.addLine(to: CGPoint(x: drawRect.minX, y: drawRect.maxY))   // Bottom-left
            path.addLine(to: CGPoint(x: drawRect.minX, y: drawRect.midY))   // Left
            path.closeSubpath()

            ctx.addPath(path)
            ctx.fillPath()

        case .rounded:
            // Bottom rectangle
//            ctx.fill(
//                CGRect(
//                    x: drawRect.minX,
//                    y: drawRect.midY,
//                    width: drawRect.width,
//                    height: drawRect.height / 2
//                )
//            )
            ctx.addRect(CGRect(
                x: drawRect.minX,
                y: drawRect.midY,
                width: drawRect.width,
                height: drawRect.height / 2
            ))

            // Top half-circle
//            ctx.saveGState()
//            enableAA(ctx)
            ctx.addArc(
                center: CGPoint(x: drawRect.midX, y: drawRect.midY),
                radius: drawRect.width / 2,
                startAngle: .pi,
                endAngle: 0,
                clockwise: false
            )
            ctx.closePath()
//            ctx.fillPath()
//            ctx.restoreGState()

        case .none:
            ctx.fill(drawRect)
        }
    }

    func drawVerticalEndCap(
        in context: QRRenderContext,
        x: Int, y: Int,
        lineCap: AssetLessDotLineCap
    ) {
        let moduleSize = context.moduleSize
        let quietZonePixel = context.quietZonePixel
        let scale = context.scale
        let ctx = context.context
        ctx.setFillColor(UIColor.black.cgColor)

        let pixelX = quietZonePixel + CGFloat(x) * moduleSize
        let pixelY = quietZonePixel + CGFloat(y) * moduleSize

        let drawRect = CGRect(
            x: pixelX / scale,
            y: pixelY / scale,
            width: moduleSize / scale,
            height: moduleSize / scale
        )

        switch lineCap {

        case .angular:
            // Diamond pointing down
            let path = CGMutablePath()
            path.move(to: CGPoint(x: drawRect.minX, y: drawRect.minY))       // Top-left
            path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.minY))   // Top-right
            path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.midY))   // Right
            path.addLine(to: CGPoint(x: drawRect.midX, y: drawRect.maxY))   // Bottom
            path.addLine(to: CGPoint(x: drawRect.minX, y: drawRect.midY))   // Left
            path.closeSubpath()

            ctx.addPath(path)
            ctx.fillPath()

        case .rounded:
            // Top rectangle
//            ctx.fill(
//                CGRect(
//                    x: drawRect.minX,
//                    y: drawRect.minY,
//                    width: drawRect.width,
//                    height: drawRect.height / 2
//                )
//            )
            ctx.addRect(CGRect(
                x: drawRect.minX,
                y: drawRect.minY,
                width: drawRect.width,
                height: drawRect.height / 2
            ))

            // Bottom half-circle
//            ctx.saveGState()
//            enableAA(ctx)
            ctx.addArc(
                center: CGPoint(x: drawRect.midX, y: drawRect.midY),
                radius: drawRect.width / 2,
                startAngle: 0,
                endAngle: .pi,
                clockwise: false
            )
            ctx.closePath()
//            ctx.fillPath()
//            ctx.restoreGState()

        case .none:
            ctx.fill(drawRect)
        }
    }

}
