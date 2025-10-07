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
        
        let color = params.qrColor ?? "black"
        var idCount = 0
        var pointList: [String] = []
        pointList.append("<g fill=\"\(color)\">")
        
        for y in 0..<nCount {
            for x in 0..<nCount {
                if !qrcode.model.isDark(x, y) || !available[x][y] { continue }

                switch typeTable[x][y] {
                case .posCenter:
                    pointList.append("<rect key=\"\(idCount)\" width=\"3\" height=\"3\" x=\"\(x.cgFloat - 1)\" y=\"\(y.cgFloat - 1)\"/>")
                    idCount += 1
                    
                    break
                    
                case .posOther:
                    pointList.append("<rect x=\"\(x)\" y=\"\(y)\" width=\"1\" height=\"1\"/>")
                    idCount += 1
                    break

                default:
                    //Normal modules, try grouping
                    if x <= nCount - 3 && y <= nCount - 3 && isSquareDarkAndAvailable(x: x, y: y, size: 3, qrcode: qrcode, available: available, typeTable: typeTable) {
                        pointList.append(drawShape(id: "\(idCount)", x: x, y: y, size: 3, svgString: params.dotSVG!))
                        idCount += 1
                        for dx in 0..<3 { for dy in 0..<3 { available[x+dx][y+dy] = false } }
                        continue
                    }

                    if x <= nCount - 2 && y <= nCount - 2 && isSquareDarkAndAvailable(x: x, y: y, size: 2, qrcode: qrcode, available: available, typeTable: typeTable) {
                        pointList.append(drawShape(id: "\(idCount)", x: x, y: y, size: 2, svgString: params.dotSVG!))
                        idCount += 1
                        for dx in 0..<2 { for dy in 0..<2 { available[x+dx][y+dy] = false } }
                        continue
                    }


                    // Single module
//                    if x == 7 {
                        //pointList.append("<rect fill=\"red\" x=\"\(x)\" y=\"\(y)\" width=\"1\" height=\"1\"/>")
                        pointList.append(drawShape(id: "\(idCount)", x: x, y: y, size: 1, svgString: params.dotSVG!))
                        idCount += 1
                        available[x][y] = false
//                    }
                }
            }
        }
        pointList.append("</g>")
        return pointList
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
