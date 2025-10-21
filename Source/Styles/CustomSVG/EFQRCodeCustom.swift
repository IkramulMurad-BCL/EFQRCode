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
    
    public override func toImage(width: CGFloat, insets: UIEdgeInsets = .zero) throws -> UIImage {
        let qrImage = try super.toImage(width: width)
        
        guard let style = self.style as? EFQRCodeStyleSVG else {
            throw EFQRCodeError.cannotCreateUIImage
        }
        let params = style.params
        
        let size = qrImage.size
        let scale = qrImage.scale
        
        let backgroundImage = params.background.asImage(size: size, scale: scale)
        let foregroundImage = params.foreground.asImage(size: size, scale: scale)
        
        // 3️⃣ Apply mask for foreground (QR shape)
        guard let qrMaskImage = qrImage.cgImage,
              let fgMask = createMaskedImage(source: foregroundImage, mask: qrMaskImage) else {
            throw EFQRCodeError.cannotCreateUIImage
        }
        
        // 4️⃣ Composite both layers
        let finalImage = UIGraphicsImageRenderer(size: size, format: {
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            return format
        }()).image { _ in
            // Draw background first
            backgroundImage?.draw(in: CGRect(origin: .zero, size: size))
            // Then draw masked foreground on top
            UIImage(cgImage: fgMask, scale: scale, orientation: .up).draw(in: CGRect(origin: .zero, size: size))
        }
        
        return finalImage
    }
    
    private func createMaskedImage(source: UIImage?, mask: CGImage) -> CGImage? {
        guard let src = source?.cgImage else { return nil }
        return mask.masking(src)
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
              let gradientCI = CIImage(image: maskImage) else { return nil }

        var mask = qrCI
        if isForeGround {
            // Invert the QR so that black = visible area for the mask
            mask = qrCI.applyingFilter("CIColorInvert")
        }

        // Blend gradient into the QR's black parts
        let output = gradientCI.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputMaskImageKey: mask,
            kCIInputBackgroundImageKey: CIImage(color: .white).cropped(to: qrCI.extent)
        ])

        let context = CIContext()
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
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
