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
    
    override func writeQRCode(qrcode: QRCode) throws -> [String] {
        let nCount = qrcode.model.moduleCount
        var available = Array(repeating: Array(repeating: true, count: nCount), count: nCount)
        let typeTable = qrcode.model.getTypeTable()
        
        var idCount = 0
        var pointList: [String] = []
        
        for y in 0..<nCount {
            for x in 0..<nCount {
                if !qrcode.model.isDark(x, y) || !available[x][y] { continue }

//                switch typeTable[x][y] {
//                case .posCenter:
//                    if params.eye.svgString.isEmpty {
//                        pointList.append("<rect key=\"\(idCount)\" width=\"3\" height=\"3\" x=\"\(x.cgFloat - 1)\" y=\"\(y.cgFloat - 1)\"/>")
//                    } else {
////                        let originalEyeSVG = params.eye.svgString
////                        let eyeSVG = forceSVGToBlack(originalEyeSVG)
////                        let newTransform = "translate(\(x.cgFloat - 3), \(y.cgFloat - 3)) scale(\(7.cgFloat/160.cgFloat))"
////                        let updatedEyeSVG = replacingTransform(in: eyeSVG, with: newTransform)
////
////                        pointList.append(updatedEyeSVG)
//                    }
//                    idCount += 1
//                    
//                    break
//                    
//                case .posOther:
//                    print("posOther: \(y),\(x)")
//                    if params.eye.svgString.isEmpty {
//                        pointList.append("<rect x=\"\(x)\" y=\"\(y)\" width=\"1\" height=\"1\"/>")
//                        idCount += 1
//                    }
//                    break
//
//                default:
//                    break
//                    //params.dot.add(x: x, y: y, nCount: nCount, qrCode: qrcode, available: &available, typeTable: typeTable, pointList: &pointList, idCount: &idCount)
//                }
            }
        }

        return pointList
    }
    
    func forceSVGToBlack(_ svg: String) -> String {
        var result = svg

//        // Replace any `fill` that is NOT white → black
//        result = result.replacingOccurrences(
//            of: #"fill\s*=\s*["'](?!#?[Ff]{3,6}|white|WHITE)[^"']+["']"#,
//            with: "fill=\"#000000\"",
//            options: .regularExpression
//        )
//
//        // Replace any `stroke` that is NOT white → black
//        result = result.replacingOccurrences(
//            of: #"stroke\s*=\s*["'](?!#?[Ff]{3,6}|white|WHITE)[^"']+["']"#,
//            with: "stroke=\"#000000\"",
//            options: .regularExpression
//        )
//
//        result = result.replacingOccurrences(
//            of: #"fill-opacity\s*=\s*["'][^"']+["']"#,
//            with: #"fill-opacity="1""#,
//            options: .regularExpression
//        )
//
//        result = result.replacingOccurrences(
//            of: #"stroke-opacity\s*=\s*["'][^"']+["']"#,
//            with: #"stroke-opacity="1""#,
//            options: .regularExpression
//        )

        return result
    }
    
    func replacingTransform(in svg: String, with newTransform: String) -> String {
        var result = svg

        // 1) Find the first opening <g ...> tag
        let gOpenPattern = #"<g\b[^>]*>"#
        guard let gRegex = try? NSRegularExpression(pattern: gOpenPattern, options: []) else {
            return svg
        }
        let fullRange = NSRange(result.startIndex..., in: result)
        guard let match = gRegex.firstMatch(in: result, options: [], range: fullRange),
              let tagRange = Range(match.range, in: result) else {
            return svg
        }

        var tag = String(result[tagRange])

        // 2) If tag already has a transform attribute, replace it; otherwise insert one
        let transformPattern = #"transform\s*=\s*"[^"]*""#
        if let transRegex = try? NSRegularExpression(pattern: transformPattern, options: []) {
            let tagNSRange = NSRange(tag.startIndex..., in: tag)

            if transRegex.firstMatch(in: tag, options: [], range: tagNSRange) != nil {
                // Replace existing transform attribute (safe - we rebuild tag string)
                tag = transRegex.stringByReplacingMatches(in: tag, options: [], range: tagNSRange, withTemplate: #"transform="\#(newTransform)""#)
            } else {
                // Insert transform before closing '>'
                if let insertIdx = tag.lastIndex(of: ">") {
                    tag.insert(contentsOf: #" transform="\#(newTransform)""#, at: insertIdx)
                }
            }
        }

        // 3) Replace the original tag with the modified one
        result.replaceSubrange(tagRange, with: tag)
        return result
    }

    func isSquareDarkAndAvailable(x: Int, y: Int, size: Int, qrcode: QRCode, available: [[Bool]], typeTable: [[QRPointType]]) -> Bool {
        for dx in 0..<size {
            for dy in 0..<size {
                if !qrcode.model.isDark(x+dx, y+dy) { return false }
                if !available[x+dx][y+dy] { return false }
                if typeTable[x+dx][y+dy] != .data { return false }
            }
        }
        return true
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
