//
//  Util+SVG.swift
//  EFQRCode
//
//  Created by Dey device -5 on 6/10/25.
//

import Foundation
import UIKit

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
