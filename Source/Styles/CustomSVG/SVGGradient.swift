//
//  Gradient.swift
//  EFQRCode
//
//  Created by Dey device -5 on 7/10/25.
//

enum GradientStartingPoint {
    case topLeading
    case topTrailing
    case top
    case left
}

public struct SVGGradient {
    let startingColor: String
    let endingColor: String
    let startingPoint: GradientStartingPoint
    
    func getSVGString() -> String {
        var x1 = 0, x2 = 0, y1 = 0, y2 = 0
        switch startingPoint {
        case .topLeading:
            x2 = 100
            y2 = 100
        case .topTrailing:
            x1 = 100
            y2 = 100
        case .top:
            y2 = 100
        case .left:
            x2 = 100
        }
        
        return """
        <defs>
        <linearGradient id="qrGradient" x1="\(x1)%" y1="\(y1)%" x2="\(x2)%" y2="\(y2)%">
        <stop offset="0%" stop-color="\(startingColor)"/>
        <stop offset="100%" stop-color="\(endingColor)"/>
        </linearGradient>
        </defs>
        """
    }
}
