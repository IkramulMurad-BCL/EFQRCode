//
//  ColorGradientMask.swift
//  EFQRCode
//
//  Created by Dey device -5 on 13/10/25.
//

import UIKit

public enum GradientDirection: String, Codable {
    case topToBottom = "top_to_bottom"
    case leftToRight = "left_to_right"
    case topLeftToBottomRight = "top_left_to_bottom_right"
    case topRightToBottomLeft = "top_right_to_bottom_left"

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
    func asImage(size: CGSize, scale: CGFloat) -> UIImage?
}

public class SolidColor: VisualFill {
    public let color: UIColor
    
    public init(with hex: String) {
        self.color = UIColor(hex: hex)
    }
    
    public func asImage(size: CGSize, scale: CGFloat = 1.0) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
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
    
    public func asImage(size: CGSize, scale: CGFloat = 1.0) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        return renderer.image { context in
            let colors = [startColor.cgColor, endColor.cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colors,
                                            locations: [0.0, 1.0]) else { return }
            
            let (start, end) = direction.points
            let startPoint = CGPoint(x: start.x * size.width, y: start.y * size.height)
            let endPoint = CGPoint(x: end.x * size.width, y: end.y * size.height)
            
            context.cgContext.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        }
    }
}

public class ImageMask: VisualFill {
    public let image: UIImage
    
    public init(with image: UIImage) {
        self.image = image
    }
    
    public func asImage(size: CGSize, scale: CGFloat = 1.0) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

public class AnimatedImage: VisualFill {
    public let frames: [UIImage]
    public let duration: TimeInterval

    public var frameCount: Int { frames.count }

    public func frame(at index: Int, size: CGSize, scale: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            frames[index].draw(in: CGRect(origin: .zero, size: size))
        }
    }

    public init(frames: [UIImage], duration: TimeInterval) {
        self.frames = frames
        self.duration = duration
    }

    public convenience init?(fileURL: URL) {
        guard
            let data = try? Data(contentsOf: fileURL),
            let source = CGImageSourceCreateWithData(data as CFData, nil)
        else { return nil }

        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var totalDuration: TimeInterval = 0

        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            images.append(UIImage(cgImage: cgImage))

            let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any]
            let gif = props?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let delay = gif?[kCGImagePropertyGIFUnclampedDelayTime] as? Double
                ?? gif?[kCGImagePropertyGIFDelayTime] as? Double
                ?? 0.1
            totalDuration += delay
        }

        self.init(frames: images, duration: totalDuration)
    }

    public func asImage(size: CGSize, scale: CGFloat = 1.0) -> UIImage? {
        let resizedFrames = frames.map { frame in
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            return renderer.image { _ in
                frame.draw(in: CGRect(origin: .zero, size: size))
            }
        }

        return UIImage.animatedImage(with: resizedFrames, duration: duration)
    }
}
