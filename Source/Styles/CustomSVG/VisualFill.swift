//
//  ColorGradientMask.swift
//  EFQRCode
//
//  Created by Dey device -5 on 13/10/25.
//

import UIKit

public enum GradientDirection: String, CaseIterable, Codable {
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


/// How a source image maps onto the box it is asked for. Gallery pictures are rarely square while
/// the QR canvas and the logo slot both are, so filling the box stretches them out of shape.
public enum ImageContentMode {
    case scaleToFill
    case scaleAspectFit
    case scaleAspectFill
}

extension UIImage {
    /// Aspect-fill overflows the box on one axis; the renderer's own bounds clip it.
    func draw(in rect: CGRect, mode: ImageContentMode) {
        guard size.width > 0, size.height > 0 else { return draw(in: rect) }

        let factor: CGFloat
        switch mode {
        case .scaleToFill:
            return draw(in: rect)
        case .scaleAspectFit:
            factor = min(rect.width / size.width, rect.height / size.height)
        case .scaleAspectFill:
            factor = max(rect.width / size.width, rect.height / size.height)
        }

        let scaled = CGSize(width: size.width * factor, height: size.height * factor)
        draw(in: CGRect(x: rect.midX - scaled.width / 2,
                        y: rect.midY - scaled.height / 2,
                        width: scaled.width,
                        height: scaled.height))
    }
}

public protocol VisualFill {
    func asImage(size: CGSize, scale: CGFloat) -> UIImage?
    func asImage(size: CGSize, scale: CGFloat, mode: ImageContentMode) -> UIImage?
}

public extension VisualFill {
    /// Colours and gradients cover any box exactly, so the mode only matters to the image fills
    /// that override this.
    func asImage(size: CGSize, scale: CGFloat, mode: ImageContentMode) -> UIImage? {
        asImage(size: size, scale: scale)
    }
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
    public var startColor: UIColor
    public var endColor: UIColor
    public var direction: GradientDirection
    
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
        asImage(size: size, scale: scale, mode: .scaleToFill)
    }
    
    public func asImage(size: CGSize, scale: CGFloat, mode: ImageContentMode) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size), mode: mode)
        }
    }
}

public class AnimatedImage: VisualFill {
    public let frames: [UIImage]
    public let duration: TimeInterval

    public var frameCount: Int { frames.count }

    public func frame(at index: Int, size: CGSize, scale: CGFloat, mode: ImageContentMode = .scaleToFill) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            frames[index].draw(in: CGRect(origin: .zero, size: size), mode: mode)
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
        asImage(size: size, scale: scale, mode: .scaleToFill)
    }

    public func asImage(size: CGSize, scale: CGFloat, mode: ImageContentMode) -> UIImage? {
        let resizedFrames = frames.map { frame in
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            return renderer.image { _ in
                frame.draw(in: CGRect(origin: .zero, size: size), mode: mode)
            }
        }

        return UIImage.animatedImage(with: resizedFrames, duration: duration)
    }
}
