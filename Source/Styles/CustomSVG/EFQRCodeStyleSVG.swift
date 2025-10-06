//
//  EFQRCodeStyleSVG.swift
//  EFQRCode
//
//  Created by Dey device -5 on 24/8/25.
//  Copyright © 2025 EyreFree. All rights reserved.
//

import UIKit
import CoreGraphics

import QRCodeSwift

public class EFQRCodeStyleSVG: EFQRCodeStyleBase {
    let params: EFStyleSVGParams
    
    public init(params: EFStyleSVGParams) {
        self.params = params
        super.init()
    }
    
    func extractMainShape(from svg: String, fillColor: String? = nil, strokeColor: String? = nil, strokeWidth: CGFloat? = nil) -> String? {
        // Find the first self-closing or standard shape tag
        let pattern = #"<(path|rect|circle|ellipse|polygon|polyline|line)\b[^>]*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: svg, options: [], range: NSRange(svg.startIndex..., in: svg)) else {
            return nil
        }
        
        var shapeTag = String(svg[Range(match.range, in: svg)!])
        //print("shapeTag: \n\(shapeTag)")
        
        // Remove existing fill/stroke/stroke-width attributes
        let cleanupPattern = #"(fill|stroke|stroke-width)="[^"]*""#
        if let cleanupRegex = try? NSRegularExpression(pattern: cleanupPattern, options: [.caseInsensitive]) {
            shapeTag = cleanupRegex.stringByReplacingMatches(in: shapeTag, options: [], range: NSRange(shapeTag.startIndex..., in: shapeTag), withTemplate: "")
        }
        //print("shapeTag removed attributes: \n\(shapeTag)")
        
        // Ensure it doesn't end with just ">" but " />" if self-closing is needed
        if !shapeTag.hasSuffix("/>") && !shapeTag.contains("</") {
            shapeTag = shapeTag.replacingOccurrences(of: ">", with: " />")
        }
        //print("shapeTag closing check: \n\(shapeTag)")
        
        // Inject updated attributes
        var extraAttributes = ""
        if let fill = fillColor { extraAttributes += " fill=\"\(fill)\"" }
        if let stroke = strokeColor { extraAttributes += " stroke=\"\(stroke)\"" }
        if let sw = strokeWidth { extraAttributes += " stroke-width=\"\(sw)\"" }
        
        // Insert extra attributes before the closing '/>'
        if let closeIndex = shapeTag.range(of: "/>", options: .backwards)?.lowerBound {
            shapeTag.insert(contentsOf: extraAttributes, at: closeIndex)
        } else if let closeIndex = shapeTag.lastIndex(of: ">") {
            // Fallback for non-self-closing tags
            shapeTag.insert(contentsOf: extraAttributes, at: closeIndex)
        }

        print("shapeTag final added attributes: \n\(shapeTag)")
        
        return shapeTag
    }
    
    func normalizeSvgPath(_ rawPath: String, targetSize: CGFloat) -> (CGRect, String) {
        // 1. Parse to a UIBezierPath
        let cgPath = CGPath.fromSvgPath(svgPath: rawPath)!
        let bezierPath = UIBezierPath(cgPath: cgPath)
        
        // 2. Compute bounding box
        let bbox = bezierPath.bounds
        let pathWidth = bbox.width
        let pathHeight = bbox.height
        
        // 3. Scale so the largest dimension matches targetSize
        let scale = targetSize / max(pathWidth, pathHeight)
        
        // 4. Translate to (0,0) and scale
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: -bbox.minX, y: -bbox.minY)
        transform = transform.scaledBy(x: scale, y: scale)
        
        let normalizedPath = bezierPath.cgPath.copy(using: &transform)!
        let normalizedPathBbox = normalizedPath.boundingBoxOfPath
        
        
        // 5. Export back to SVG path string
        return (normalizedPathBbox, normalizedPath.getSvgPath())
    }

    func parseSVGAttributes(from element: String) -> [String: String] {
        var attributes: [String: String] = [:]
        let pattern = #"(\w+)\s*=\s*"([^"]*)""#
        
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsElement = element as NSString
            for match in regex.matches(in: element, range: NSRange(location: 0, length: nsElement.length)) {
                let key = nsElement.substring(with: match.range(at: 1))
                let value = nsElement.substring(with: match.range(at: 2))
                attributes[key] = value
            }
        }
        return attributes
    }
    
    func extractRotate(from transform: String) -> Double {
        let pattern = #"rotate\((-?\d+(\.\d+)?)"#  // matches rotate(45) or rotate(-30.5)
        
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(transform.startIndex..<transform.endIndex,
                                in: transform)
            if let match = regex.firstMatch(in: transform, options: [], range: range) {
                if let numberRange = Range(match.range(at: 1), in: transform) {
                    return Double(transform[numberRange])!
                }
            }
        }
        return 0.0
    }
    
    func parseRawPoints(from string: String) -> [CGPoint] {
        let cleaned = string.replacingOccurrences(of: ",", with: " ")
        let parts = cleaned.split(separator: " ").compactMap { Double($0) }
        var points: [CGPoint] = []
        var i = 0
        while i + 1 < parts.count {
            points.append(CGPoint(x: parts[i], y: parts[i+1]))
            i += 2
        }
        return points
    }

    func boundingBox(of points: [CGPoint]) -> (minX: CGFloat, minY: CGFloat, width: CGFloat, height: CGFloat) {
        guard let first = points.first else { return (0,0,0,0) }
        var minX = first.x, maxX = first.x
        var minY = first.y, maxY = first.y
        
        for p in points {
            minX = min(minX, p.x)
            maxX = max(maxX, p.x)
            minY = min(minY, p.y)
            maxY = max(maxY, p.y)
        }
        
        return (minX, minY, maxX - minX, maxY - minY)
    }

    func rotatedBoundingBox(width w: CGFloat, height h: CGFloat, angleDegrees: CGFloat = 0.0) -> (CGFloat, CGFloat) {
        let theta = angleDegrees * .pi / 180.0
        let cosT = abs(cos(theta))
        let sinT = abs(sin(theta))
        
        let rotatedW = w * cosT + h * sinT
        let rotatedH = w * sinT + h * cosT
        
        return (rotatedW, rotatedH)
    }

    
    override func writeQRCode(qrcode: QRCode) throws -> [String] {
        var pointList: [String] = []
        let nCount = qrcode.model.moduleCount
        var available = Array(repeating: Array(repeating: true, count: nCount), count: nCount)
        var idCount = 0

        let typeTable = qrcode.model.getTypeTable()
        
        // Heart path from SVG
        func drawHeart(id: String, x: Int, y: Int, size: Int, fillColor: String = params.dotColor ?? "black") -> String {
            // For smaller size inside the module
            let centerX: CGFloat = x.cgFloat + size.cgFloat / 2.0
            let centerY: CGFloat = y.cgFloat + size.cgFloat / 2.0
            
            let shrinkFactor: CGFloat = 1.0 // 80% of cell space
            let actualDrawingSize: CGFloat = CGFloat(size) * shrinkFactor
            let normalizedSize: CGFloat = 100.0
            
            
            // normalizedHeartPath is the `d` value already scaled to 0–100 space
//            let rawPath = "M417.79,271.68c-6.27,6.39-11.16,14.68-18.26,21.79l-143.22,143.22L113.09,293.47c-7.1-7.1-11.99-15.4-18.26-21.79C-14.39,160.39,147.09,1.91,256.31,113.21c108.07-110.12,269.55,48.36,161.48,158.48Z"
            guard let mainShape = extractMainShape(from: params.dotSVG!) else {
                return ""
            }
            if mainShape.contains("path") {
                var rawPath = ""
                if let range = mainShape.range(of: #"d="([^"]+)""#, options: .regularExpression) {
                    let fullMatch = mainShape[range] // d="..."
                    let dValue = fullMatch.dropFirst(3).dropLast(1) // remove d=" and closing "
                    print(dValue)
                    
                    rawPath = String(dValue)
                }
                
                let (bbox, normalizedHeartPath) = normalizeSvgPath(rawPath, targetSize: 100)
                let cx = (bbox.minX + bbox.maxX) / 2
                let cy = (bbox.minY + bbox.maxY) / 2
                
                let scale = actualDrawingSize / normalizedSize
                let str = """
                <path key="\(id)"
                      d="\(normalizedHeartPath)"
                      stroke="black"
                      stroke-width="1"
                      fill="\(fillColor)"
                      transform="translate(\(centerX),\(centerY))
                                 scale(\(scale),\(scale)) translate(\(-cx), \(-cy))"/>
                """
                print(str)
                return str
            } else if mainShape.contains("polygon") {
//                centerX -= size.cgFloat / 2.0
//                centerY -= size.cgFloat / 2.0
                let attributes = parseSVGAttributes(from: mainShape)
                let pointsString = attributes["points"] ?? "0"
                let transformx = attributes["transform"] ?? ""
                let rotate = extractRotate(from: transformx)
                let points = parseRawPoints(from: pointsString)

                let (minX, minY, w, h) = boundingBox(of: points)
                let (rw, rh) = rotatedBoundingBox(width: w, height: h, angleDegrees: rotate)
                
                let cx = minX + w/2
                let cy = minY + h/2
                let centeredPoints = points.map { p in
                    (p.x - cx, p.y - cy)   // shift to center
                }
                let centeredPointsString = centeredPoints.map { "\($0.0),\($0.1)" }.joined(separator: " ")
                
                let normalizedSize = max(rw, rh)
                let scale = actualDrawingSize / normalizedSize
                
                let transform = """
                translate(\(centerX),\(centerY)) scale(\(scale),\(scale)) rotate(\(rotate))
                """

                let finalPolygon = """
                <polygon points="\(centeredPointsString)" transform="\(transform)"/>
                """
                print(finalPolygon)
                return finalPolygon
            } else if mainShape.contains("rect") {
//                centerX -= size.cgFloat / 2.0
//                centerY -= size.cgFloat / 2.0
                
                let rectAttributes = parseSVGAttributes(from: mainShape)
                let width = CGFloat(Double(rectAttributes["width"] ?? "0") ?? 0)
                let height = CGFloat(Double(rectAttributes["height"] ?? "0") ?? 0)
                let rx = CGFloat(Double(rectAttributes["rx"] ?? "0") ?? 0)
                let ry = CGFloat(Double(rectAttributes["ry"] ?? "0") ?? 0)
                let transformx = rectAttributes["transform"] ?? ""
                
                let rotate = extractRotate(from: transformx)
                print("transform: \(transformx)\nrotate: \(rotate)")
                
                let (rw, rh) = rotatedBoundingBox(width: width, height: height, angleDegrees: rotate)
                let normalizedSize = max(rw, rh)
                let scale = actualDrawingSize / normalizedSize
                let halfW = width / 2.0
                let halfH = height / 2.0
                let transform = """
                translate(\(centerX),\(centerY)) scale(\(scale),\(scale)) rotate(\(rotate)) 
                """
                let finalRect = """
                <rect fill="\(fillColor)" x="\(-halfW)" y="\(-halfH)" width="\(width)" height="\(height)" rx="\(rx)" ry="\(ry)" transform="\(transform)"/>
                """
                print(finalRect)
                return finalRect
            } else {
//                centerX -= size.cgFloat / 2.0
//                centerY -= size.cgFloat / 2.0
                
                let attributes = parseSVGAttributes(from: mainShape)
                let cx = CGFloat(Double(attributes["cx"] ?? "0") ?? 0)
                let cy = CGFloat(Double(attributes["cy"] ?? "0") ?? 0)
                let r = CGFloat(Double(attributes["r"] ?? "0") ?? 0)
                
                let str = """
                        <circle key="\(id)"
                                cx="\(cx)"
                                cy="\(cy)"
                                r="\(r)"
                                stroke="black"
                                stroke-width="1"
                                fill="\(fillColor)"
                                transform="translate(\(centerX),\(centerY))
                                           scale(\(actualDrawingSize / (r * 2)),\(actualDrawingSize / (r * 2)))"/>
                        """
                print(str)
                return """
                        <circle key="\(id)"
                                cx="0"
                                cy="0"
                                r="\(r)"
                                stroke="black"
                                stroke-width="1"
                                fill="\(fillColor)"
                                transform="translate(\(centerX),\(centerY))
                                           scale(\(actualDrawingSize / (r * 2)))"/>
                        """
            }
        }


        for y in 0..<nCount {
            for x in 0..<nCount {
                //print("x, y: (\(x), \(y))", separator: " -> ", terminator: " - ")
                if !qrcode.model.isDark(x, y) || !available[x][y] { continue }

                switch typeTable[x][y] {
                case .posCenter:
                    // Finder pattern center
//                    pointList.append(drawHeart(id: "\(idCount)", x: x, y: y, size: 3))
//                    idCount += 1
//                    for dx in 0..<3 { for dy in 0..<3 { available[x+dx][y+dy] = false } }
//
//                    pointList.append(drawHeart(id: "\(idCount)", x: x, y: y, size: 9, fillColor: "none"))
//                    idCount += 1
                    let positionAlpha = 1.0
                    let positionColor = params.dotColor ?? "black"
                    let posSize = 1.0
                    pointList.append("<rect key=\"\(idCount)\" opacity=\"\(positionAlpha)\" width=\"3\" height=\"3\" fill=\"\(positionColor)\" x=\"\(x.cgFloat - 1)\" y=\"\(y.cgFloat - 1)\"/>")
                    idCount += 1
                    pointList.append("<rect key=\"\(idCount)\" opacity=\"\(positionAlpha)\" fill=\"none\" stroke-width=\"\(1 * posSize)\" stroke=\"\(positionColor)\" x=\"\(x.cgFloat - 2.5)\" y=\"\(y.cgFloat - 2.5)\" width=\"6\" height=\"6\"/>")
                    idCount += 1
                    break
                    
                case .posOther:
//                    // Finder pattern border modules (could draw square or dots)
//                    pointList.append(drawHeart(id: "\(idCount)", x: x, y: y, size: 1))
//                    idCount += 1
//                    available[x][y] = false
                    break

                default:
//                    pointList.append("<circle opacity=\"1\" r=\"\(0.5 * Double.random(in: 0.5...1))\" key=\"\(idCount)\" fill=\"black\" cx=\"\(x.cgFloat + 0.5)\" cy=\"\(y.cgFloat + 0.5)\"/>")
//                    idCount += 1
                    func isSquareDarkAndAvailable(x: Int, y: Int, size: Int) -> Bool {
                        for dx in 0..<size {
                            for dy in 0..<size {
                                if !qrcode.model.isDark(x+dx, y+dy) { return false }
                                if !available[x+dx][y+dy] { return false }
                                if typeTable[x+dx][y+dy] != .data { return false }
                            }
                        }
                        return true
                    }

//                     Normal modules, try grouping
                    if x <= nCount - 3 && y <= nCount - 3 && isSquareDarkAndAvailable(x: x, y: y, size: 3) {
                        pointList.append(drawHeart(id: "\(idCount)", x: x, y: y, size: 3))
                        idCount += 1
                        for dx in 0..<3 { for dy in 0..<3 { available[x+dx][y+dy] = false } }
                        continue
                    }

                    if x <= nCount - 2 && y <= nCount - 2 && isSquareDarkAndAvailable(x: x, y: y, size: 2) {
                        //pointList.append("<rect fill=\"red\" x=\"\(x)\" y=\"\(y)\" width=\"2\" height=\"2\"/>")
                        pointList.append(drawHeart(id: "\(idCount)", x: x, y: y, size: 2))
                        idCount += 1
                        for dx in 0..<2 { for dy in 0..<2 { available[x+dx][y+dy] = false } }
                        continue
                    }


                    // Single module
//                    if x == 7 {
                        //pointList.append("<rect fill=\"red\" x=\"\(x)\" y=\"\(y)\" width=\"1\" height=\"1\"/>")
                        pointList.append(drawHeart(id: "\(idCount)", x: x, y: y, size: 1))
                        idCount += 1
                        available[x][y] = false
//                    }
                }
            }
        }

        return pointList
    }
    
    public override func writeIcon(qrcode: QRCode) throws -> [String] {
        return try params.icon?.write(qrcode: qrcode) ?? []
    }
    
    public override func viewBox(qrcode: QRCode) -> CGRect {
        return params.backdrop.viewBox(moduleCount: qrcode.model.moduleCount)
    }
    
    public override func generateSVG(qrcode: QRCode) throws -> String {
        let viewBoxRect: CGRect = viewBox(qrcode: qrcode)
        let (part1, part2) = try params.backdrop.generateSVG(qrcode: qrcode, viewBoxRect: viewBoxRect)
        
        return part1
        + (try writeQRCode(qrcode: qrcode)).joined()
        + (try writeIcon(qrcode: qrcode)).joined()
        + part2
    }
    
    public override func copyWith(
        iconImage: EFStyleParamImage? = nil,
        watermarkImage: EFStyleParamImage? = nil
    ) -> EFQRCodeStyleBase {
        let icon: EFStyleParamIcon? = params.icon?.copyWith(image: iconImage)
        return EFQRCodeStyleSVG(params: params.copyWith(icon: icon))
    }
    
    public override func getParamImages() -> (iconImage: EFStyleParamImage?, watermarkImage: EFStyleParamImage?) {
        return (params.icon?.image, nil)
    }
    
    public override func toQRCodeStyle() -> EFQRCodeStyle {
        return EFQRCodeStyle.svg(params: self.params)
    }
}
