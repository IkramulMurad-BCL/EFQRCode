//
//  ShapeDraw+SVG.swift
//  EFQRCode
//
//  Created by Dey device -5 on 6/10/25.
//

import Foundation

//func drawShape(id: String, x: Int, y: Int, width: Int, height: Int, svgString: String) -> String {
//    // For smaller size inside the module
//    let centerX: CGFloat = x.cgFloat + width.cgFloat / 2.0
//    let centerY: CGFloat = y.cgFloat + height.cgFloat / 2.0
//    
//    let shrinkFactor: CGFloat = 1.0 // 100% of cell space
//    let actualDrawingWidth: CGFloat = width.cgFloat * shrinkFactor
//    let actualDrawingHeight: CGFloat = height.cgFloat * shrinkFactor
//    let normalizedSize: CGFloat = 100.0
//    
//    guard let mainShape = extractMainShape(from: svgString) else {
//        return ""
//    }
//    
//    if mainShape.contains("path") {
//        var rawPath = ""
//        guard let range = mainShape.range(of: #"d="([^"]+)""#, options: .regularExpression) else {
//            return ""
//        }
//        
//        let fullMatch = mainShape[range] // d="..."
//        let dValue = fullMatch.dropFirst(3).dropLast(1) // remove d=" and closing "
//        //print(dValue)
//        
//        rawPath = String(dValue)
//        
//        let (bbox, normalizedHeartPath) = normalizeSvgPath(rawPath, targetSize: 100)
//        let cx = (bbox.minX + bbox.maxX) / 2
//        let cy = (bbox.minY + bbox.maxY) / 2
//        
//        let scaleX = actualDrawingWidth / normalizedSize
//        let scaleY = actualDrawingHeight / normalizedSize
//        
//        let str = """
//        <path key="\(id)"
//              d="\(normalizedHeartPath)"
//              stroke="black"
//              stroke-width="1"
//              transform="translate(\(centerX),\(centerY))
//                         scale(\(scaleX),\(scaleY)) translate(\(-cx), \(-cy))"/>
//        """
//        //print(str)
//        return str
//    } else if mainShape.contains("polygon") {
////                centerX -= size.cgFloat / 2.0
////                centerY -= size.cgFloat / 2.0
//        let attributes = parseSVGAttributes(from: mainShape)
//        let pointsString = attributes["points"] ?? "0"
//        let transformx = attributes["transform"] ?? ""
//        let rotate = extractRotate(from: transformx)
//        let points = parseRawPoints(from: pointsString)
//
//        let (minX, minY, w, h) = boundingBox(of: points)
//        let (rw, rh) = rotatedBoundingBox(width: w, height: h, angleDegrees: rotate)
//        
//        let cx = minX + w/2
//        let cy = minY + h/2
//        let centeredPoints = points.map { p in
//            (p.x - cx, p.y - cy)   // shift to center
//        }
//        let centeredPointsString = centeredPoints.map { "\($0.0),\($0.1)" }.joined(separator: " ")
//        
//        let normalizedSize = max(rw, rh)
//        let scaleX = actualDrawingWidth / normalizedSize
//        let scaleY = actualDrawingHeight / normalizedSize
//        
//        let transform = """
//        translate(\(centerX),\(centerY)) scale(\(scaleX),\(scaleY)) rotate(\(rotate))
//        """
//
//        let finalPolygon = """
//        <polygon points="\(centeredPointsString)" transform="\(transform)"/>
//        """
//        //print(finalPolygon)
//        return finalPolygon
//    } else if mainShape.contains("rect") {
////                centerX -= size.cgFloat / 2.0
////                centerY -= size.cgFloat / 2.0
//        
//        let rectAttributes = parseSVGAttributes(from: mainShape)
//        let width = CGFloat(Double(rectAttributes["width"] ?? "0") ?? 0)
//        let height = CGFloat(Double(rectAttributes["height"] ?? "0") ?? 0)
//        let rx = CGFloat(Double(rectAttributes["rx"] ?? "0") ?? 0)
//        let ry = CGFloat(Double(rectAttributes["ry"] ?? "0") ?? 0)
//        let transformx = rectAttributes["transform"] ?? ""
//        
//        let rotate = extractRotate(from: transformx)
//        //print("transform: \(transformx)\nrotate: \(rotate)")
//        
//        let (rw, rh) = rotatedBoundingBox(width: width, height: height, angleDegrees: rotate)
//        let normalizedSize = max(rw, rh)
//        let scaleX = actualDrawingWidth / normalizedSize
//        let scaleY = actualDrawingHeight / normalizedSize
//        let halfW = width / 2.0
//        let halfH = height / 2.0
//        let transform = """
//        translate(\(centerX),\(centerY)) scale(\(scaleX),\(scaleY)) rotate(\(rotate)) 
//        """
//        let finalRect = """
//        <rect x="\(-halfW)" y="\(-halfH)" width="\(width)" height="\(height)" rx="\(rx)" ry="\(ry)" transform="\(transform)"/>
//        """
//        //print(finalRect)
//        return finalRect
//    } else {
////                centerX -= size.cgFloat / 2.0
////                centerY -= size.cgFloat / 2.0
//        
//        let attributes = parseSVGAttributes(from: mainShape)
//        let cx = CGFloat(Double(attributes["cx"] ?? "0") ?? 0)
//        let cy = CGFloat(Double(attributes["cy"] ?? "0") ?? 0)
//        let r = CGFloat(Double(attributes["r"] ?? "0") ?? 0)
//        let scaleX = actualDrawingWidth / (r * 2)
//        let scaleY = actualDrawingHeight / (r * 2)
//        //use cx, cy if required, translating centerX, centerY does the job
//        let str = """
//                <circle key="\(id)"
//                        cx="0"
//                        cy="0"
//                        r="\(r)"
//                        stroke="black"
//                        stroke-width="1"
//                        transform="translate(\(centerX),\(centerY))
//                                           scale(\(scaleX),\(scaleY))"/>
//                """
//        print(str)
//        return str
//    }
//}

func drawShape(
    id: String,
    x: Int,
    y: Int,
    width: Int,
    height: Int,
    svgString: String
) -> String {

    guard let viewBox = extractViewBox(from: svgString),
          let inner = extractInnerSVG(from: svgString),
          let vb = parseViewBox(viewBox) else {
        return "<!-- invalid svg -->"
    }

    let moduleX = CGFloat(x)
    let moduleY = CGFloat(y)
    let targetWidth = CGFloat(width)
    let targetHeight = CGFloat(height)

    // Original SVG center inside its coordinate system
    let originCX = vb.minX + vb.width / 2
    let originCY = vb.minY + vb.height / 2

    // Scaling to fit given module-space width & height
    let scaleX = targetWidth / vb.width
    let scaleY = targetHeight / vb.height

    // Final placement: center of the module block
    let finalCenterX = moduleX + targetWidth / 2
    let finalCenterY = moduleY + targetHeight / 2

    return """
    <g id="shape_\(id)"
       transform="
         translate(\(finalCenterX), \(finalCenterY))
         scale(\(scaleX), \(scaleY))
         translate(-\(originCX), -\(originCY))
       ">
       \(inner)
    </g>
    """
}

func extractViewBox(from svg: String) -> String? {
    guard let range = svg.range(of: "viewBox=\"") else { return nil }
    let after = svg[range.upperBound...]
    guard let end = after.firstIndex(of: "\"") else { return nil }
    return String(after[..<end])
}

func extractInnerSVG(from svg: String) -> String? {
    guard let start = svg.range(of: ">")?.upperBound,
          let end = svg.range(of: "</svg>")?.lowerBound else { return nil }
    return String(svg[start..<end])
}

struct ViewBox { let minX: CGFloat; let minY: CGFloat; let width: CGFloat; let height: CGFloat }

func parseViewBox(_ viewBox: String) -> ViewBox? {
    let comps = viewBox.split(separator: " ").compactMap { CGFloat(Double($0) ?? 0) }
    guard comps.count == 4 else { return nil }
    return ViewBox(minX: comps[0], minY: comps[1], width: comps[2], height: comps[3])
}
