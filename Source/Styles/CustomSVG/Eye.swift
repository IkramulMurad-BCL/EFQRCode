//
//  Eye.swift
//  EFQRCode
//
//  Created by Dey device -5 on 13/10/25.
//

import Foundation
import SDWebImageWebPCoder

public class Eye {
    let eyeImage: UIImage?
    let eyeWebp: String
    
    public init(eyeWebp: String = "") {
        self.eyeWebp = eyeWebp
        self.eyeImage = nil
    }
    
    public init(image: UIImage) {
        self.eyeWebp = ""
        self.eyeImage = image
    }
    
    func draw(in ctx: QRRenderContext) {
        let eyeSize = ctx.moduleSize * 7

        let positions = [
            CGPoint(x: ctx.quietZonePixel, y: ctx.quietZonePixel),
            CGPoint(x: ctx.size.width - ctx.quietZonePixel - eyeSize, y: ctx.quietZonePixel),
            CGPoint(x: ctx.quietZonePixel, y: ctx.size.height - ctx.quietZonePixel - eyeSize)
        ]

        guard let image = loadImage() else { return }
        
        for pos in positions {
            let drawRect = CGRect(
                x: pos.x / ctx.scale,
                y: pos.y / ctx.scale,
                width: eyeSize / ctx.scale,
                height: eyeSize / ctx.scale
            )
            
            image.draw(in: drawRect)
        }
    }
    
    private func loadImage() -> UIImage? {
        // Prefer UIImage if provided
        if let img = eyeImage {
            return img
        }
        
        // Fallback to WebP
        guard
            let webpUrl = Bundle.main.url(forResource: eyeWebp, withExtension: "webp"),
            let data = NSData(contentsOf: webpUrl),
            let eyeImage = SDImageWebPCoder.shared.decodedImage(with: data as Data?)
        else {
            return nil
        }
        
        return eyeImage
    }
}
