//
//  ShapeDraw+SVG.swift
//  EFQRCode
//
//  Created by Dey device -5 on 6/10/25.
//

import Foundation

func drawShape(id: String, x: Int, y: Int, size: Int, fillColor: String = "black", svgString: String) -> String {
    // For smaller size inside the module
    let centerX: CGFloat = x.cgFloat + size.cgFloat / 2.0
    let centerY: CGFloat = y.cgFloat + size.cgFloat / 2.0
    
    let shrinkFactor: CGFloat = 1.0 // 100% of cell space
    let actualDrawingSize: CGFloat = CGFloat(size) * shrinkFactor
    let normalizedSize: CGFloat = 100.0
    
    guard let mainShape = extractMainShape(from: svgString) else {
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
        
        //use cx, cy if required, translating centerX, centerY does the job
        let str = """
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
        print(str)
        return str
    }
}
