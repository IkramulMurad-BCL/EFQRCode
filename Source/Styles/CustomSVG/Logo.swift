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
}

public protocol Logo {
    var adjustment: LogoAdjustment { get set }
    func asImage(size: CGSize) -> UIImage?
    
    func updateLogo(with data: LogoData)
    func updateAdjustment(adjustment: LogoAdjustment)
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
    
    public func asImage(size: CGSize) -> UIImage? {
        guard let fillImage = visualFill.asImage(size: size, scale: 1) else { return nil }

        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let ctx = context.cgContext

            //
            // STEP 1 — Draw the text as a *mask* into alpha channel
            //
            ctx.saveGState()

            // Draw black text into alpha channel (mask)
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.lineBreakMode = .byWordWrapping

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .paragraphStyle: paragraph,
                .foregroundColor: UIColor.black   // important: mask uses alpha
            ]

            // Measure text bounds
            let textBounds = content.boundingRect(
                with: size,
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
