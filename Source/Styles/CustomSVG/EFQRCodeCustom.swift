//
//  EFQRCodeStyleSVG+Generate.swift
//  EFQRCode
//
//  Created by Dey device -5 on 8/10/25.
//

import UIKit
import QRCodeSwift

// MARK: - Gradient Style Configuration
public struct QRRenderContext {
    let context: CGContext
    let size: CGSize
    let scale: CGFloat
    
    let moduleCount: CGFloat
    let moduleSize: CGFloat
    let quietZonePixel: CGFloat
    
    let qrImage: UIImage
    let qrcode: QRCode
}

public class EFQRCodeCustomGenerator: EFQRCode.Generator {
    public init(content: String, style: EFQRCodeStyle) throws {
        guard let data = content.data(using: .utf8) else {
            throw EFQRCodeError.text(content, incompatibleWithEncoding: .utf8)
        }
        try super.init(data, errorCorrectLevel: .h, style: style)
    }
    
    public override func toImage(width: CGFloat, insets: UIEdgeInsets = .zero) throws -> UIImage {
        let qrImageEmpty = try super.toImage(width: width)
        
        guard let style = self.style as? EFQRCodeStyleSVG else {
            throw EFQRCodeError.cannotCreateUIImage
        }
        let params = style.params
    
        let size = qrImageEmpty.size
        let scale = qrImageEmpty.scale
        
        let moduleCount = CGFloat(qrcode.model.moduleCount)
        let quietzone = params.backdrop.quietzone ?? EFEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        let quietZonePixel = (width / (moduleCount + quietzone.left + quietzone.right)) * quietzone.left
        let width = size.width * scale
        let moduleSize = (width - quietZonePixel * 2) / moduleCount
        
        //*******************************************************************//
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        
        // Step 0: Generate raw QR image (white canvas + eyes + dots)
        let qrImageRaw = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let context = ctx.cgContext
            context.setFillColor(UIColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
            
            let renderContext = QRRenderContext(
                context: context,
                size: size,
                scale: scale,
                moduleCount: CGFloat(qrcode.model.moduleCount),
                moduleSize: moduleSize,
                quietZonePixel: quietZonePixel,
                qrImage: qrImageEmpty,
                qrcode: qrcode
            )
            
            params.eye.draw(in: renderContext)
            params.dot.draw(in: renderContext)
        }
        
        // Step 0.1
        var (logoRect, logoRectWithMargin) = params.logo.logoRect(using: size, scale: scale, quietZonePixel: quietZonePixel)
        let (logoPath, logoHolderPath, scanAssistFramePath) = params.logo.logoPath(using: &logoRect, logoRectWithMargin: &logoRectWithMargin, size: size, scale: scale, quietZonePixel: quietZonePixel)
        let logoImage = params.logo.asImage(size: CGSize(width: 100, height: 100))
        
        let backgroundImage = params.background.asImage(size: size, scale: scale)
        let foregroundImage = params.foreground.asImage(size: size, scale: scale)
        
        var maskedForeground: UIImage? = nil
        if let fg = foregroundImage {
            let freshQR = isFreshQR(foreground: params.foreground, background: params.background)
            if freshQR {
                maskedForeground = qrImageRaw
            } else {
                maskedForeground = applyMask(qrImage: qrImageRaw, maskImage: fg, isForeGround: true)
                if maskedForeground == nil {
                    throw EFQRCodeError.cannotCreateUIImage
                }
            }
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
        

        // Step 1: Main renderer (single pass)
        let finalQRImage = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let context = ctx.cgContext
            let rect = CGRect(origin: .zero, size: size)

            // 1️⃣ Background
            backgroundImage?.draw(in: rect)

            // 2️⃣ Mask foreground with raw QR image
            if logoImage != nil {
                updatedMaskedForeground?.draw(in: rect)
            } else {
                maskedForeground?.draw(in: rect)
            }

            // 4️⃣ Draw scan assist frame (optional)
            if let scanAssistFramePath {
                context.setStrokeColor(UIColor.red.cgColor)
                context.setLineWidth(scanAssistFramePath.lineWidth)
                context.addPath(scanAssistFramePath.cgPath)
                context.strokePath()
            }

            // 5️⃣ Draw logo
            if logoImage != nil {
                context.saveGState()
                logoPath.addClip()
                logoImage?.draw(in: logoRect)
                context.restoreGState()
            }
        }
        
        return finalQRImage
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
