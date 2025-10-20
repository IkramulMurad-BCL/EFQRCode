//
//  ColorGradientMask.swift
//  EFQRCode
//
//  Created by Dey device -5 on 13/10/25.
//

import UIKit

public enum GradientDirection {
    case topToBottom
    case leftToRight
    case topLeftToBottomRight
    case topRightToBottomLeft

    var points: (start: CGPoint, end: CGPoint) {
        switch self {
        case .topToBottom:
            return (CGPoint(x: 0.5, y: 0.0), CGPoint(x: 0.5, y: 1.0))
        case .leftToRight:
            return (CGPoint(x: 0.0, y: 0.5), CGPoint(x: 1.0, y: 0.5))
        case .topLeftToBottomRight:
            return (CGPoint(x: 0.0, y: 0.0), CGPoint(x: 1.0, y: 1.0))
        case .topRightToBottomLeft:
            return (CGPoint(x: 1.0, y: 0.0), CGPoint(x: 0.0, y: 1.0))
        }
    }
}


public protocol VisualFill {
    func asImage(size: CGSize) -> UIImage?
}

public class SolidColor: VisualFill {
    public let color: UIColor
    
    public init(with hex: String) {
        self.color = UIColor(hex: hex)
    }
    
    public func asImage(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

public class LinearGradient: VisualFill {
    public let startColor: UIColor
    public let endColor: UIColor
    public let direction: GradientDirection
    
    public init(with hex1: String, hex2: String, direction: GradientDirection = .topToBottom) {
        self.startColor = UIColor(hex: hex1)
        self.endColor = UIColor(hex: hex2)
        self.direction = direction
    }
    
    public func asImage(size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cgContext = context.cgContext
            let colors = [startColor.cgColor, endColor.cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colors,
                                            locations: [0.0, 1.0]) else { return }
            
            let (start, end) = direction.points
            let startPoint = CGPoint(x: start.x * size.width, y: start.y * size.height)
            let endPoint = CGPoint(x: end.x * size.width, y: end.y * size.height)
            
            cgContext.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        }
    }
}

public class ImageMask: VisualFill {
    public let image: UIImage
    
    public init(with image: UIImage) {
        self.image = image
    }
    
    public func asImage(size: CGSize) -> UIImage? {
        return image
    }
}
