//
//  EFQRCodeStyleSVG+Generate.swift
//  EFQRCode
//
//  Created by Dey device -5 on 8/10/25.
//

import UIKit

// MARK: - Gradient Style Configuration
public class EFQRCodeCustomGenerator: EFQRCode.Generator {
    public init(content: String, style: EFQRCodeStyle) throws {
        guard let data = content.data(using: .utf8) else {
            throw EFQRCodeError.text(content, incompatibleWithEncoding: .utf8)
        }
        try super.init(data, errorCorrectLevel: .h, style: style)
    }
    
    func addEyes(to qrImage: UIImage, quietZonePixel: CGFloat, moduleCount: CGFloat, eyeName: String) -> UIImage {
        let scale = qrImage.scale
        let width = qrImage.size.width * scale
        let moduleSize = (width - quietZonePixel * 2) / moduleCount
        let eyeSize = moduleSize * 7
        
        let positions = [
            CGPoint(x: quietZonePixel, y: quietZonePixel),
            CGPoint(x: width - quietZonePixel - eyeSize, y: quietZonePixel),
            CGPoint(x: quietZonePixel, y: width - quietZonePixel - eyeSize)
        ]
        
        guard let eyeImage = UIImage(named: eyeName) else {
            return qrImage
        }
        
        let renderer = UIGraphicsImageRenderer(size: qrImage.size)
        let result = renderer.image { ctx in
            qrImage.draw(in: CGRect(origin: .zero, size: qrImage.size))
            for pos in positions {
                let rect = CGRect(x: pos.x / scale, y: pos.y / scale, width: eyeSize / scale, height: eyeSize / scale)
                eyeImage.draw(in: rect)
            }
        }
        
        return result
    }

    
    public override func toImage(width: CGFloat, insets: UIEdgeInsets = .zero) throws -> UIImage {
        let qrImageRaw = try super.toImage(width: width)
        
        guard let style = self.style as? EFQRCodeStyleSVG else {
            throw EFQRCodeError.cannotCreateUIImage
        }
        let params = style.params
        
        let moduleCount = CGFloat(qrcode.model.moduleCount)
        let quietzone = params.backdrop.quietzone ?? EFEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        let quietZonePixel = (width / (moduleCount + quietzone.left + quietzone.right)) * quietzone.left
        
        let qrImage = addEyes(to: qrImageRaw, quietZonePixel: quietZonePixel, moduleCount: moduleCount, eyeName: params.eye.eyeName)
        let size = qrImage.size
        let scale = qrImage.scale
        
        let backgroundImage = params.background.asImage(size: size, scale: scale)
        let foregroundImage = params.foreground.asImage(size: size, scale: scale)
        
        let logoImage = params.logo.asImage(size: CGSize(width: 100, height: 100))
        let position = params.logo.adjustment.position
        let sizeFactor = params.logo.adjustment.size
        let marginFactor = params.logo.adjustment.margin
        let styleType = params.logo.adjustment.style
        
        // 3️⃣ Apply mask for foreground (QR shape)
        var maskedForeground: UIImage? = nil
        if let fg = foregroundImage {
            let freshQR = isFreshQR(foreground: params.foreground, background: params.background)
            if freshQR {
                maskedForeground = qrImage
            } else {
                maskedForeground = applyMask(qrImage: qrImage, maskImage: fg, isForeGround: true)
                if maskedForeground == nil {
                    throw EFQRCodeError.cannotCreateUIImage
                }
            }
        }
        
        let logoWidth = size.width * sizeFactor
        let logoHeight = logoWidth
        let margin = size.width * marginFactor
        var logoRectWithMargin: CGRect
        var logoRect: CGRect
        
        switch position {
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
        
        let logoPath: UIBezierPath
        let logoHolderPath: UIBezierPath
        var scanAssistFramePath: UIBezierPath? = nil
        
        switch styleType {
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
            switch position {
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
            switch position {
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
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        maskedForeground?.draw(in: CGRect(origin: .zero, size: size))
        let fgContext = UIGraphicsGetCurrentContext()!
        fgContext.setBlendMode(.clear)
        fgContext.addPath(logoHolderPath.cgPath)
        fgContext.fillPath()

        fgContext.setBlendMode(.normal)
        let updatedMaskedForeground = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // 4️⃣ Composite all layers
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let finalImage = UIGraphicsImageRenderer(size: size, format: format).image { context in
            backgroundImage?.draw(in: CGRect(origin: .zero, size: size))
            
            if let logoImage {
                // Optional: fill with white or background tone
//                context.cgContext.setFillColor(UIColor.red.cgColor)
//                context.cgContext.addPath(logoHolderPath.cgPath)
//                context.cgContext.fillPath()
                
                // 4️⃣ Draw masked QR on top
                updatedMaskedForeground?.draw(in: CGRect(origin: .zero, size: size))
                
                if let scanAssistFramePath = scanAssistFramePath {
                    context.cgContext.setStrokeColor(UIColor.red.cgColor)
                    context.cgContext.setLineWidth(scanAssistFramePath.lineWidth)
                    context.cgContext.addPath(scanAssistFramePath.cgPath)
                    context.cgContext.strokePath()
                }
                
                // 5️⃣ Draw logo with style clipping
                logoPath.addClip()
                logoImage.draw(in: logoRect)
            } else {
                maskedForeground?.draw(in: CGRect(origin: .zero, size: size))
            }
        }
        
        return finalImage
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

        
    private func createGradientImageMatching(_ referenceImage: UIImage, startColor: UIColor, endColor: UIColor) -> UIImage {
        let logicalSize = referenceImage.size
        let scale = referenceImage.scale
        
        let renderer = UIGraphicsImageRenderer(size: logicalSize, format: {
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            return format
        }())
        
        return renderer.image { context in
            let colors = [startColor.cgColor, endColor.cgColor]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colorLocations: [CGFloat] = [0.0, 1.0]
            
            guard let gradient = CGGradient(colorsSpace: colorSpace,
                                          colors: colors as CFArray,
                                          locations: colorLocations) else { return }
            
            let startPoint = CGPoint(x: 0, y: 0)
            let endPoint = CGPoint(x: 0, y: logicalSize.height)
            
            context.cgContext.drawLinearGradient(gradient,
                                               start: startPoint,
                                               end: endPoint,
                                               options: [])
        }
    }

    func applyMask(qrImage: UIImage, maskImage: UIImage, isForeGround: Bool = true) -> UIImage? {
        guard let qrCI = CIImage(image: qrImage),
              let fillCI = CIImage(image: maskImage) else { return nil }

        var mask = qrCI
        if isForeGround {
            // Invert the QR so that black = visible area for the mask
            mask = qrCI.applyingFilter("CIColorInvert")
        }

        let transparentBackground = CIImage(color: .clear).cropped(to: qrCI.extent)

        // Blend gradient into the QR's black parts
        let output = fillCI.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputMaskImageKey: mask,
            kCIInputBackgroundImageKey: transparentBackground
        ])

        let context = CIContext()
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: qrImage.scale, orientation: .up)
    }
    
    func isFreshQR(foreground: VisualFill, background: VisualFill) -> Bool {
        guard
            let fg = (foreground as? SolidColor)?.color,
            let bg = (background as? SolidColor)?.color
        else {
            return false
        }
        
        return fg.isApproximatelyBlack && bg.isApproximatelyWhite
    }
}

// MARK: - UIColor Extension for Hex Support
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

extension UIColor {
    var isApproximatelyBlack: Bool {
        var white: CGFloat = 0
        getWhite(&white, alpha: nil)
        return white < 0.1 // near black
    }
    
    var isApproximatelyWhite: Bool {
        var white: CGFloat = 0
        getWhite(&white, alpha: nil)
        return white > 0.9 // near white
    }
}
