//
//  Eye.swift
//  EFQRCode
//
//  Created by Dey device -5 on 13/10/25.
//

import Foundation
import SDWebImageWebPCoder

public class Eye {
    public var needTranslucentWhiteBack = false
    private let eyeImages: [UIImage?]
    private let eyeWebpNames: [String?]
    
    /// Initialize with a single UIImage (used for all positions)
    public init(image: UIImage) {
        self.eyeImages = [image, image, image]
        self.eyeWebpNames = [nil, nil, nil]
    }
    
    /// Initialize with 3 UIImages (one for each position)
    public init(images: [UIImage?]) {
        var imgs: [UIImage?] = [nil, nil, nil]
        for (i, img) in images.enumerated() {
            if i < 3 { imgs[i] = img }
        }
        self.eyeImages = imgs
        self.eyeWebpNames = [nil, nil, nil]
    }
    
    /// Initialize with a single WebP name (used for all positions)
    public init(eyeWebp: String) {
        self.eyeImages = [nil, nil, nil]
        self.eyeWebpNames = [eyeWebp, eyeWebp, eyeWebp]
    }
    
    /// Initialize with 3 WebP names (one per position)
    public init(eyeWebps: [String]) {
        var names: [String?] = [nil, nil, nil]
        for (i, name) in eyeWebps.enumerated() {
            if i < 3 { names[i] = name }
        }
        self.eyeImages = [nil, nil, nil]
        self.eyeWebpNames = names
    }
    
    
    func draw(in ctx: QRRenderContext) {
        let eyeSize = ctx.moduleSize * 7
        let eyeBGSize = ctx.moduleSize * 8
        
        let positions = [
            CGPoint(x: ctx.quietZonePixel, y: ctx.quietZonePixel),
            CGPoint(x: ctx.size.width - ctx.quietZonePixel - eyeSize, y: ctx.quietZonePixel),
            CGPoint(x: ctx.quietZonePixel, y: ctx.size.height - ctx.quietZonePixel - eyeSize)
        ]
        
        let bgPositions = [
            CGPoint(x: ctx.quietZonePixel, y: ctx.quietZonePixel),
            CGPoint(x: ctx.size.width - ctx.quietZonePixel - eyeBGSize, y: ctx.quietZonePixel),
            CGPoint(x: ctx.quietZonePixel, y: ctx.size.height - ctx.quietZonePixel - eyeBGSize)
        ]
        
        for i in 0..<3 {
            if needTranslucentWhiteBack {
                let bgPos = bgPositions[i]
                let bgRect = CGRect(
                    x: bgPos.x / ctx.scale,
                    y: bgPos.y / ctx.scale,
                    width: eyeBGSize / ctx.scale,
                    height: eyeBGSize / ctx.scale
                )
                ctx.context.setFillColor(UIColor.white.withAlphaComponent(0.3).cgColor)
                ctx.context.fill(bgRect)
            }
            
            guard let image = loadImage(at: i) else { continue }
            
            let pos = positions[i]
            let drawRect = CGRect(
                x: pos.x / ctx.scale,
                y: pos.y / ctx.scale,
                width: eyeSize / ctx.scale,
                height: eyeSize / ctx.scale
            )
            
            image.draw(in: drawRect)
        }
    }
    
    /// Load image for position i (UIImage first, fallback to WebP)
    private func loadImage(at index: Int) -> UIImage? {
        if index >= eyeImages.count { return nil }
        
        if let img = eyeImages[index] { return img }
        
        if let webp = eyeWebpNames[index], !webp.isEmpty,
           let webpUrl = Bundle.main.url(forResource: webp, withExtension: "webp"),
           let data = NSData(contentsOf: webpUrl),
           let decoded = SDImageWebPCoder.shared.decodedImage(with: data as Data?) {
            return decoded
        }
        return nil
    }
}
