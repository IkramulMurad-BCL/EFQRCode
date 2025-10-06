//
//  CGPath+SVGPath.swift
//  EFQRCode
//
//  Created by Dey device -5 on 6/10/25.
//

import CoreGraphics

public extension CGPath {
    func getSvgPath(stroke: String = "black", fill: String = "black") -> String {
//        return """
//            <path d="\(svgPath)" stroke="\(stroke)" fill="\(fill)" />
//        """
        return svgPath
    }
    
    var svgPath: String {
        var result = ""
        
        applyWithBlock() { element in
            let el = element.pointee
            switch(el.type) {
            case .moveToPoint:
                result += String(format: "M%f,%f", el.points[0].x, el.points[0].y)
            case .addLineToPoint:
                result += String(format: "L%f,%f", el.points[0].x, el.points[0].y)
            case .addQuadCurveToPoint:
                result += String(format: "Q%f,%f,%f,%f", el.points[0].x, el.points[0].y, el.points[1].x, el.points[1].y)
            case .addCurveToPoint:
                result += String(format: "C%f,%f,%f,%f,%f,%f", el.points[0].x, el.points[0].y, el.points[1].x, el.points[1].y, el.points[2].x, el.points[2].y)
            case .closeSubpath:
                result += "Z"
            default:
                // shouldn't hit this. but if we do, ignore it
                break
            }
        }
        
        return result
    }
    
    // Convert SVG path to CGPath
    static func fromSvgPath(svgPath: String) -> CGPath? {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        let commands = SVGPath(svgPath).commands
        for command in commands {
            switch command.type {
            case .move: path.move(to: CGPoint(x: command.point.x, y: command.point.y))
            case .line: path.addLine(to: CGPoint(x: command.point.x, y: command.point.y))
            case .quadCurve: path.addQuadCurve(to: CGPoint(x: command.point.x, y: command.point.y), control: CGPoint(x: command.control1.x, y: command.control1.y))
            case .cubeCurve: path.addCurve(to: CGPoint(x: command.point.x, y: command.point.y), control1: CGPoint(x: command.control1.x, y: command.control1.y), control2: CGPoint(x: command.control2.x, y: command.control2.y))
            case .close: path.closeSubpath()
            }
        }
        return path
    }
}
