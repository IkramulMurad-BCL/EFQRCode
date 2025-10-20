//
//  ColorGradientMask.swift
//  EFQRCode
//
//  Created by Dey device -5 on 13/10/25.
//

import UIKit

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
    
    public init(with hex1: String, hex2: String) {
        self.startColor = UIColor(hex: hex1)
        self.endColor = UIColor(hex: hex2)
    }
    
    public func asImage(size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cgContext = context.cgContext
            let colors = [startColor.cgColor, endColor.cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }
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
