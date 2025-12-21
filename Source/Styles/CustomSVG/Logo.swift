//
//  Logo.swift
//  EFQRCode
//
//  Created by Dey device -5 on 13/10/25.
//

import UIKit

public enum LogoData {
    case image(mask: ImageMask?)
    case text(content: String, font: UIFont, visualFill: VisualFill)
    case textVisualFill(visualFill: VisualFill)
}

public protocol Logo {
    var adjustment: LogoAdjustment { get set }
    func asImage(size: CGSize) -> UIImage?
    
    func updateLogo(with data: LogoData)
    func updateAdjustment(adjustment: LogoAdjustment)
    
    func logoRect(using size: CGSize, scale: CGFloat, quietZonePixel: CGFloat) -> (CGRect, CGRect)
    func logoPath(using logoRect: inout CGRect, logoRectWithMargin: inout CGRect, size: CGSize, scale: CGFloat, quietZonePixel: CGFloat) -> (UIBezierPath, UIBezierPath, UIBezierPath?)
}

public extension Logo {
    func logoRect(using size: CGSize, scale: CGFloat = 1.0, quietZonePixel: CGFloat) -> (CGRect, CGRect) {
        let sizeFactor = adjustment.size
        let marginFactor = adjustment.margin
        
        let logoWidth = size.width * sizeFactor
        let logoHeight = logoWidth
        let margin = size.width * marginFactor
        var logoRectWithMargin: CGRect
        var logoRect: CGRect
        
        switch adjustment.position {
        case .bottomRight:
            let pixelSize = 1.0 / scale
            let qzp = floor(quietZonePixel / pixelSize) * pixelSize

            logoRectWithMargin = CGRect(
                x: size.width - logoWidth - margin - qzp,
                y: size.height - logoHeight - margin - qzp,
                width: logoWidth + margin * 2,
                height: logoHeight + margin * 2
            )
            logoRect = CGRect(x: logoRectWithMargin.minX + margin, y: logoRectWithMargin.minY + margin, width: logoWidth, height: logoWidth)
        case .center:
            fallthrough
        default:
            logoRectWithMargin = CGRect(
                x: (size.width - logoWidth) / 2 - margin,
                y: (size.height - logoHeight) / 2 - margin,
                width: logoWidth + margin * 2,
                height: logoHeight + margin * 2
            )
            logoRect = logoRectWithMargin.insetBy(dx: margin, dy: margin)
        }
        
        return (logoRect, logoRectWithMargin)
    }
    
    func logoPath(using logoRect: inout CGRect, logoRectWithMargin: inout CGRect, size: CGSize, scale: CGFloat, quietZonePixel: CGFloat) -> (UIBezierPath, UIBezierPath, UIBezierPath?) {
        let logoPath: UIBezierPath
        let logoHolderPath: UIBezierPath
        var scanAssistFramePath: UIBezierPath? = nil
        
        let sizeFactor = adjustment.size
        let logoWidth = size.width * sizeFactor
        let logoHeight = logoWidth
        
        let marginFactor = adjustment.margin
        let margin = size.width * marginFactor
        
        switch adjustment.style {
        case .round:
            logoHolderPath = UIBezierPath(ovalIn: logoRectWithMargin)
            logoPath = UIBezierPath(ovalIn: logoRect)
        case .roundedRect:
            logoHolderPath = UIBezierPath(roundedRect: logoRectWithMargin, cornerRadius: logoRectWithMargin.width * 0.2)
            logoPath = UIBezierPath(roundedRect: logoRect, cornerRadius: logoWidth * 0.2)
        case .rect:
            logoHolderPath = UIBezierPath(rect: logoRectWithMargin)
            logoPath = UIBezierPath(rect: logoRect)
        case .scanAssistRect:
            switch adjustment.position {
            case .center:
                logoRectWithMargin = CGRect(x: (size.width - logoWidth) / 2,
                                            y: (size.height - logoHeight) / 2,
                                            width: logoWidth,
                                            height: logoHeight)
            case .bottomRight:
                let pixelSize = 1.0 / scale
                let qzp = floor(quietZonePixel / pixelSize) * pixelSize
                
                logoRectWithMargin = CGRect(x: size.width - logoWidth - qzp,
                                            y: size.height - logoHeight - qzp,
                                            width: logoWidth,
                                            height: logoHeight)
            }
            let padding = margin
            let assistFrameWidth: CGFloat = logoRectWithMargin.width * 0.07
            logoRect = CGRect(x: logoRectWithMargin.minX + assistFrameWidth + padding,
                              y: logoRectWithMargin.minY + assistFrameWidth + padding,
                              width: logoRectWithMargin.width - assistFrameWidth * 2 - padding * 2,
                              height: logoRectWithMargin.height - assistFrameWidth * 2 - padding * 2)
            
            logoHolderPath = UIBezierPath(rect: logoRectWithMargin)
            logoPath = UIBezierPath(rect: logoRect)
            scanAssistFramePath = createScanAssistFramePath(rect: logoRectWithMargin, cornerRadius: 0, lineWidth: assistFrameWidth)
            
        case .scanAssistRoundedRect:
            switch adjustment.position {
            case .center:
                logoRectWithMargin = CGRect(x: (size.width - logoWidth) / 2,
                                            y: (size.height - logoHeight) / 2,
                                            width: logoWidth,
                                            height: logoHeight)
            case .bottomRight:
                let pixelSize = 1.0 / scale
                let qzp = floor(quietZonePixel / pixelSize) * pixelSize
                
                logoRectWithMargin = CGRect(x: size.width - logoWidth - qzp,
                                            y: size.height - logoHeight - qzp,
                                            width: logoWidth,
                                            height: logoHeight)
            }
            let padding = margin
            let assistFrameWidth: CGFloat = logoRectWithMargin.width * 0.07
            logoRect = CGRect(x: logoRectWithMargin.minX + assistFrameWidth + padding,
                              y: logoRectWithMargin.minY + assistFrameWidth + padding,
                              width: logoRectWithMargin.width - assistFrameWidth * 2 - padding * 2,
                              height: logoRectWithMargin.height - assistFrameWidth * 2 - padding * 2)
                        
            let cornerRadius = logoRectWithMargin.width * 0.2
            logoHolderPath = UIBezierPath(roundedRect: logoRectWithMargin, cornerRadius: cornerRadius)
            logoPath = UIBezierPath(roundedRect: logoRect, cornerRadius: logoRect.width * 0.2)
            scanAssistFramePath = createScanAssistFramePath(rect: logoRectWithMargin, cornerRadius: cornerRadius, lineWidth: assistFrameWidth)
        }
        
        return (logoPath, logoHolderPath, scanAssistFramePath)
    }
    
    private func createScanAssistFramePath(rect: CGRect, cornerRadius: CGFloat, lineWidth: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        let cornerLength = rect.width * 0.25 // Length of each L-shape arm
        
        // Adjust for line width so strokes are drawn inside the rect
        let inset = lineWidth / 2
        let drawingRect = rect.insetBy(dx: inset, dy: inset)
        
        let availableRadius = min(cornerRadius, cornerLength - lineWidth)
        let adjustedCornerRadius = min(availableRadius, drawingRect.width / 2, drawingRect.height / 2)
        if adjustedCornerRadius > 0 {
            // Top Left Corner - rounded L shape
            path.move(to: CGPoint(x: drawingRect.minX, y: drawingRect.minY + cornerLength))
            path.addLine(to: CGPoint(x: drawingRect.minX, y: drawingRect.minY + adjustedCornerRadius))
            path.addArc(withCenter: CGPoint(x: drawingRect.minX + adjustedCornerRadius, y: drawingRect.minY + adjustedCornerRadius),
                        radius: adjustedCornerRadius,
                        startAngle: .pi,
                        endAngle: .pi * 1.5,
                        clockwise: true)
            path.addLine(to: CGPoint(x: drawingRect.minX + cornerLength, y: drawingRect.minY))
            
            // Top Right Corner - rounded L shape
            path.move(to: CGPoint(x: drawingRect.maxX - cornerLength, y: drawingRect.minY))
            path.addLine(to: CGPoint(x: drawingRect.maxX - adjustedCornerRadius, y: drawingRect.minY))
            path.addArc(withCenter: CGPoint(x: drawingRect.maxX - adjustedCornerRadius, y: drawingRect.minY + adjustedCornerRadius),
                        radius: adjustedCornerRadius,
                        startAngle: .pi * 1.5,
                        endAngle: 0,
                        clockwise: true)
            path.addLine(to: CGPoint(x: drawingRect.maxX, y: drawingRect.minY + cornerLength))
            
            // Bottom Right Corner - rounded L shape
            path.move(to: CGPoint(x: drawingRect.maxX, y: drawingRect.maxY - cornerLength))
            path.addLine(to: CGPoint(x: drawingRect.maxX, y: drawingRect.maxY - adjustedCornerRadius))
            path.addArc(withCenter: CGPoint(x: drawingRect.maxX - adjustedCornerRadius, y: drawingRect.maxY - adjustedCornerRadius),
                        radius: adjustedCornerRadius,
                        startAngle: 0,
                        endAngle: .pi * 0.5,
                        clockwise: true)
            path.addLine(to: CGPoint(x: drawingRect.maxX - cornerLength, y: drawingRect.maxY))
            
            // Bottom Left Corner - rounded L shape
            path.move(to: CGPoint(x: drawingRect.minX + cornerLength, y: drawingRect.maxY))
            path.addLine(to: CGPoint(x: drawingRect.minX + adjustedCornerRadius, y: drawingRect.maxY))
            path.addArc(withCenter: CGPoint(x: drawingRect.minX + adjustedCornerRadius, y: drawingRect.maxY - adjustedCornerRadius),
                        radius: adjustedCornerRadius,
                        startAngle: .pi * 0.5,
                        endAngle: .pi,
                        clockwise: true)
            path.addLine(to: CGPoint(x: drawingRect.minX, y: drawingRect.maxY - cornerLength))
        } else {
            // Square version (no corner radius)
            // Top Left Corner - proper L shape
            path.move(to: CGPoint(x: drawingRect.minX, y: drawingRect.minY + cornerLength))
            path.addLine(to: CGPoint(x: drawingRect.minX, y: drawingRect.minY))
            path.addLine(to: CGPoint(x: drawingRect.minX + cornerLength, y: drawingRect.minY))
            
            // Top Right Corner - proper L shape
            path.move(to: CGPoint(x: drawingRect.maxX - cornerLength, y: drawingRect.minY))
            path.addLine(to: CGPoint(x: drawingRect.maxX, y: drawingRect.minY))
            path.addLine(to: CGPoint(x: drawingRect.maxX, y: drawingRect.minY + cornerLength))
            
            // Bottom Right Corner - proper L shape
            path.move(to: CGPoint(x: drawingRect.maxX, y: drawingRect.maxY - cornerLength))
            path.addLine(to: CGPoint(x: drawingRect.maxX, y: drawingRect.maxY))
            path.addLine(to: CGPoint(x: drawingRect.maxX - cornerLength, y: drawingRect.maxY))
            
            // Bottom Left Corner - proper L shape
            path.move(to: CGPoint(x: drawingRect.minX + cornerLength, y: drawingRect.maxY))
            path.addLine(to: CGPoint(x: drawingRect.minX, y: drawingRect.maxY))
            path.addLine(to: CGPoint(x: drawingRect.minX, y: drawingRect.maxY - cornerLength))
        }
        
        path.lineWidth = lineWidth
        path.lineCapStyle = .square
        path.lineJoinStyle = .miter
        
        return path
    }
}

public class ImageLogo: Logo {
    public var adjustment: LogoAdjustment
    var imageMask: ImageMask?
    
    public init(adjustment: LogoAdjustment, imageMask: ImageMask? = nil) {
        self.adjustment = adjustment
        self.imageMask = imageMask
    }
    
    public func asImage(size: CGSize) -> UIImage? {
        imageMask?.asImage(size: size)
    }
    
    public func updateAdjustment(adjustment: LogoAdjustment) {
        self.adjustment = adjustment
    }
    
    public func updateLogo(with data: LogoData) {
        switch data {
        case .image(let mask):
            self.imageMask = mask
        case .text:
            // ignore text data for image logo
            break
        default:
            break
        }
    }
}

public class TextLogo: Logo {
    public var adjustment: LogoAdjustment
    
    var content: String
    var font: UIFont
    var visualFill: VisualFill
    
    public init(adjustment: LogoAdjustment, content: String, font: UIFont, visualFill: VisualFill) {
        self.adjustment = adjustment
        self.content = content
        self.font = font
        self.visualFill = visualFill
    }
    
    private func calculateMaxFontSizeToFit(
        text: String,
        size: CGSize,
        fontName: String,
        fontDescriptor: UIFontDescriptor,
        max: CGFloat = 500
    ) -> CGFloat {
        
        var low: CGFloat = 1
        var high: CGFloat = max
        var best: CGFloat = 1
        
        while low <= high {
            let mid = (low + high)/2
            let testFont = UIFont(descriptor: fontDescriptor, size: mid)
            
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.lineBreakMode = .byWordWrapping
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: testFont,
                .paragraphStyle: paragraph
            ]
            
            // Use .greatestFiniteMagnitude for height to get true multi-line bounds
            let bounding = text.boundingRect(
                with: CGSize(width: size.width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            )
            
            // Add small tolerance for rendering differences
            let tolerance: CGFloat = 2.0
            if bounding.width <= size.width + tolerance && bounding.height <= size.height + tolerance {
                best = mid
                low = mid + 0.5
            } else {
                high = mid - 0.5
            }
        }
        
        return best
    }
    
    
    public func asImage(size: CGSize) -> UIImage? {
        // 1️⃣ Create visual fill image (full size)
        guard let fillImage = visualFill.asImage(size: size, scale: 1) else { return nil }
        
        // 2️⃣ Calculate max font size to fit text inside `size`
        let maxFontSize: CGFloat = calculateMaxFontSizeToFit(
            text: content,
            size: size,
            fontName: font.fontName,
            fontDescriptor: font.fontDescriptor
        )
        
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // STEP 1 — Draw the text as a *mask* into alpha channel
            ctx.saveGState()
            
            // Draw black text into alpha channel (mask)
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.lineBreakMode = .byWordWrapping
            
            // Use maxFontSize, but keep weight/italic from original font
            let maskedFont = UIFont(descriptor: font.fontDescriptor, size: maxFontSize)
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: maskedFont,
                .paragraphStyle: paragraph,
                .foregroundColor: UIColor.black   // important: mask uses alpha
            ]
            
            // Measure text bounds
            let textBounds = content.boundingRect(
                with: CGSize(width: size.width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            )
            
            let origin = CGPoint(
                x: (size.width - textBounds.width) / 2,
                y: (size.height - textBounds.height) / 2
            )
            
            let drawRect = CGRect(origin: origin, size: textBounds.size)
            
            // Draw text into image context
            content.draw(in: drawRect, withAttributes: attributes)
            
            // Extract the text mask
            let mask = ctx.makeImage()   // Alpha channel represents text shape
            
            ctx.restoreGState()
            
            guard let maskRef = mask else { return }
            
            //
            // STEP 2 — Clip the context with text mask
            //
            ctx.saveGState()
            
            // Flip vertical axis to correct upside-down
            ctx.translateBy(x: 0, y: size.height)
            ctx.scaleBy(x: 1.0, y: -1.0)
            ctx.clip(to: CGRect(origin: .zero, size: size), mask: maskRef)
            
            //
            // STEP 3 — Draw visual fill inside the text
            //
            fillImage.draw(in: CGRect(origin: .zero, size: size))
            
            ctx.restoreGState()
        }
    }
    
    
    public func updateAdjustment(adjustment: LogoAdjustment) {
        self.adjustment = adjustment
    }
    
    public func updateLogo(with data: LogoData) {
        switch data {
        case .textVisualFill(let visualFill):
            self.visualFill = visualFill
        case .text(let content, let font, let visualFill):
            self.content = content
            self.font = font
            self.visualFill = visualFill
        
        case .image:
            // ignore image data for text logo
            break
        }
    }
}
