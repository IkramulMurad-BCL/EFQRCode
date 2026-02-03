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
    
    public func setCacheImage(_ image: UIImage, forKey key: String) {
        imageCache[key] = image
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
                continue
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
    public let unitSize: CGSize
    
    public init(groupingLogic: AssetLessDotGroupingStyle, lineCap: AssetLessDotLineCap, unitSize: CGSize = CGSize(width: 1, height: 1)) {
        self.groupingLogic = groupingLogic
        self.lineCap = lineCap
        self.unitSize = unitSize
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
        ctx.setFillColor(UIColor.black.cgColor)
        
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
        case .horizontal:
            drawHorizontal(x: x, y: y, nCount: nCount, qrCode: qrCode, available: &available, context: context)
            
        case .vertical:
            drawVertical(x: x, y: y, nCount: nCount, qrCode: qrCode, available: &available, context: context)
        }
        context.context.fillPath()
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
        
        for dx in 0..<length { available[x+dx][y] = false }
        
        if length == 1 {
            drawSingleUnit(x: x, y: y, lineCap: lineCap, context: context)
        } else {
            let ctx = context.context
            ctx.saveGState()
            enableAA(ctx)
            
            drawHorizontalStartCap(in: context, x: x, y: y, lineCap: lineCap)
            if length > 2 {
                drawBlackRect(x: x + 1, y: y, w: length - 2, h: 1, context: context)
            }
            drawHorizontalEndCap(in: context, x: x + length - 1, y: y, lineCap: lineCap)
            
            ctx.fillPath()
            ctx.restoreGState()
        }
    }
    
    func drawBlackRect(x: Int, y: Int, w: Int, h: Int, context: QRRenderContext) {
        let moduleSize = context.moduleSize
        let quietZonePixel = context.quietZonePixel
        let scale = context.scale
        let ctx = context.context
        
        let pixelX = quietZonePixel + CGFloat(x) * moduleSize
        let pixelY = quietZonePixel + CGFloat(y) * moduleSize
        
        let rectCenterX = pixelX + w.cgFloat * moduleSize / 2
        let rectCenterY = pixelY + h.cgFloat * moduleSize / 2
        
        let dotWidth = CGFloat(w) * unitSize.width * moduleSize
        let dotHeight = CGFloat(h) * unitSize.height * moduleSize
        
        let drawRect = CGRect(
            x: (rectCenterX - dotWidth / 2) / scale,
            y: (rectCenterY - dotHeight / 2) / scale,
            width: dotWidth / scale,
            height: dotHeight / scale
        )
        
        ctx.addRect(drawRect)
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

        if length == 1 {
            drawSingleUnit(x: x, y: y, lineCap: lineCap, context: context)
        } else {
            let ctx = context.context
            ctx.saveGState()
            enableAA(ctx)
            
            drawVerticalStartCap(in: context, x: x, y: y, lineCap: lineCap)
            if length > 2 {
                drawBlackRect(x: x, y: y + 1, w: 1, h: length - 2, context: context)
            }
            drawVerticalEndCap(in: context, x: x, y: y + length - 1, lineCap: lineCap)
            
            ctx.fillPath()
            ctx.restoreGState()
        }
    }

    func drawSingleUnit(x: Int, y: Int, lineCap: AssetLessDotLineCap, context: QRRenderContext) {
        let moduleSize = context.moduleSize
        let quietZonePixel = context.quietZonePixel
        let scale = context.scale
        let ctx = context.context
        ctx.saveGState()
        enableAA(ctx)

        let pixelX = quietZonePixel + CGFloat(x) * moduleSize
        let pixelY = quietZonePixel + CGFloat(y) * moduleSize

        let rectCenterX = pixelX + moduleSize / 2
        let rectCenterY = pixelY + moduleSize / 2
        
        let minUnitSize = min(unitSize.width, unitSize.height)
        let width = minUnitSize * moduleSize
        let height = minUnitSize * moduleSize
        
        let drawRect = CGRect(
            x: (rectCenterX - width / 2) / scale,
            y: (rectCenterY - height / 2) / scale,
            width: width / scale,
            height: height / scale
        )

        switch lineCap {
        case .rounded:
            let center = CGPoint(
                    x: drawRect.midX,
                    y: drawRect.midY
            )
            
            let radius = min(drawRect.width, drawRect.height) / 2
            
            
            ctx.addArc(
                center: center,
                radius: radius,
                startAngle: 0,
                endAngle: .pi * 2,
                clockwise: false
            )
            
        case .angular:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: drawRect.midX, y: drawRect.minY)) // Top
            path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.midY)) // Right
            path.addLine(to: CGPoint(x: drawRect.midX, y: drawRect.maxY)) // Bottom
            path.addLine(to: CGPoint(x: drawRect.minX, y: drawRect.midY)) // Left
            path.closeSubpath()
            
            ctx.addPath(path)
        default:
            drawBlackRect(x: x, y: y, w: 1, h: 1, context: context)
        }
        
        ctx.fillPath()
        ctx.restoreGState()
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

        let pixelX = quietZonePixel + CGFloat(x) * moduleSize
        let pixelY = quietZonePixel + CGFloat(y) * moduleSize

        let rectCenterX = pixelX + moduleSize / 2
        let rectCenterY = pixelY + moduleSize / 2
        
        let width = unitSize.width * moduleSize
        let height = unitSize.height * moduleSize
        
        let drawRect = CGRect(
            x: (rectCenterX - width / 2) / scale,
            y: (rectCenterY - height / 2) / scale,
            width: width / scale,
            height: height / scale
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

        case .rounded:
            // Half circle (left side)
            ctx.addArc(
                center: CGPoint(x: drawRect.midX, y: drawRect.midY),
                radius: drawRect.height / 2,
                startAngle: .pi / 2,
                endAngle: -.pi / 2,
                clockwise: false
            )
            ctx.closePath()

            // Right rectangle
            ctx.addRect(CGRect(
                x: drawRect.midX,
                y: drawRect.minY,
                width: drawRect.width / 2,
                height: drawRect.height
            ))

        case .none:
            ctx.addRect(drawRect)
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

        let pixelX = quietZonePixel + CGFloat(x) * moduleSize
        let pixelY = quietZonePixel + CGFloat(y) * moduleSize

        let rectCenterX = pixelX + moduleSize / 2
        let rectCenterY = pixelY + moduleSize / 2
        
        let width = unitSize.width * moduleSize
        let height = unitSize.height * moduleSize
        
        let drawRect = CGRect(
            x: (rectCenterX - width / 2) / scale,
            y: (rectCenterY - height / 2) / scale,
            width: width / scale,
            height: height / scale
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

        case .rounded:
            // Left rectangle
            ctx.addRect(CGRect(
                x: drawRect.minX,
                y: drawRect.minY,
                width: drawRect.width / 2,
                height: drawRect.height
            ))
            
            // Half circle (right side)
            ctx.addArc(
                center: CGPoint(x: drawRect.midX, y: drawRect.midY),
                radius: drawRect.height / 2,
                startAngle: -.pi / 2,
                endAngle: .pi / 2,
                clockwise: false
            )
            ctx.closePath()

        case .none:
            ctx.addRect(drawRect)
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

        let pixelX = quietZonePixel + CGFloat(x) * moduleSize
        let pixelY = quietZonePixel + CGFloat(y) * moduleSize

        let rectCenterX = pixelX + moduleSize / 2
        let rectCenterY = pixelY + moduleSize / 2
        
        let width = unitSize.width * moduleSize
        let height = unitSize.height * moduleSize
        
        let drawRect = CGRect(
            x: (rectCenterX - width / 2) / scale,
            y: (rectCenterY - height / 2) / scale,
            width: width / scale,
            height: height / scale
        )

        switch lineCap {

        case .angular:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: drawRect.midX, y: drawRect.minY))       // Top
            path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.midY))   // Right
            path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.maxY))   // Bottom-right
            path.addLine(to: CGPoint(x: drawRect.minX, y: drawRect.maxY))   // Bottom-left
            path.addLine(to: CGPoint(x: drawRect.minX, y: drawRect.midY))   // Left
            path.closeSubpath()

            ctx.addPath(path)

        case .rounded:
            // Top half-circle
            ctx.addArc(
                center: CGPoint(x: drawRect.midX, y: drawRect.midY),
                radius: drawRect.width / 2,
                startAngle: .pi,
                endAngle: 0,
                clockwise: false
            )
            ctx.closePath()
            
            // Bottom rectangle
            ctx.addRect(CGRect(
                x: drawRect.minX,
                y: drawRect.midY,
                width: drawRect.width,
                height: drawRect.height / 2
            ))
        case .none:
            ctx.addRect(drawRect)
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

        let pixelX = quietZonePixel + CGFloat(x) * moduleSize
        let pixelY = quietZonePixel + CGFloat(y) * moduleSize

        let rectCenterX = pixelX + moduleSize / 2
        let rectCenterY = pixelY + moduleSize / 2
        
        let width = unitSize.width * moduleSize
        let height = unitSize.height * moduleSize
        
        let drawRect = CGRect(
            x: (rectCenterX - width / 2) / scale,
            y: (rectCenterY - height / 2) / scale,
            width: width / scale,
            height: height / scale
        )

        switch lineCap {

        case .angular:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: drawRect.minX, y: drawRect.minY))       // Top-left
            path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.minY))   // Top-right
            path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.midY))   // Right
            path.addLine(to: CGPoint(x: drawRect.midX, y: drawRect.maxY))   // Bottom
            path.addLine(to: CGPoint(x: drawRect.minX, y: drawRect.midY))   // Left
            path.closeSubpath()

            ctx.addPath(path)

        case .rounded:
            // Top rectangle
            ctx.addRect(CGRect(
                x: drawRect.minX,
                y: drawRect.minY,
                width: drawRect.width,
                height: drawRect.height / 2
            ))

            // Bottom half-circle
            ctx.addArc(
                center: CGPoint(x: drawRect.midX, y: drawRect.midY),
                radius: drawRect.width / 2,
                startAngle: 0,
                endAngle: .pi,
                clockwise: false
            )
            ctx.closePath()

        case .none:
            ctx.addRect(drawRect)
        }
    }

}
