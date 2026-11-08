//
//  TintTwin.swift
//  EFQRCode
//

import UIKit
import SDWebImageWebPCoder

/// Eyes and dots drawn from their `<name>_tint` twin instead of the coloured asset. Masking coloured
/// artwork let only part of the fill through, so those parts came out paler than the plain dots.
final class TintCollector {
    private var shapes: [(image: UIImage, rect: CGRect)] = []
    
    var isEmpty: Bool { shapes.isEmpty }
    
    /// False when `name` has no twin, so the caller draws the original.
    func add(twinOf name: String, in rect: CGRect) -> Bool {
        guard let twin = TintTwin.image(for: name) else { return false }
        shapes.append((twin, rect))
        return true
    }
    
    /// Hard light against the fill: a twin's main grey becomes the fill exactly, darker greys
    /// darken it and lighter ones fade it to white.
    func paint(over base: UIImage, fill: UIImage, size: CGSize, format: UIGraphicsImageRendererFormat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let canvas = CGRect(origin: .zero, size: size)
        
        let layer = renderer.image { _ in
            for shape in shapes { shape.image.draw(in: shape.rect) }
        }
        let painted = renderer.image { _ in
            fill.draw(in: canvas)
            layer.draw(in: canvas, blendMode: .hardLight, alpha: 1)
            layer.draw(in: canvas, blendMode: .destinationIn, alpha: 1)
            fill.draw(in: canvas, blendMode: .destinationIn, alpha: 1)
        }
        return renderer.image { _ in
            base.draw(in: canvas)
            painted.draw(in: canvas)
        }
    }
}

enum TintTwin {
    // Holds misses too, so parts without a twin don't search the bundle on every restyle.
    private static var cache: [String: UIImage?] = [:]
    private static let cacheLock = NSLock()
    
    /// The twin with its main grey moved to 50%, where hard light returns the fill unchanged.
    static func image(for name: String) -> UIImage? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        if let cached = cache[name] { return cached }
        
        var twin: UIImage?
        if let url = Bundle.main.url(forResource: "\(name)_tint", withExtension: "webp"),
           let data = try? Data(contentsOf: url),
           let image = SDImageWebPCoder.shared.decodedImage(with: data)?.cgImage,
           let normalized = normalized(image) {
            twin = UIImage(cgImage: normalized)
        }
        cache.updateValue(twin, forKey: name)
        return twin
    }
    
    private static func normalized(_ image: CGImage) -> CGImage? {
        let width = image.width
        let height = image.height
        guard var pixels = rgbaPixels(of: image, width: width, height: height) else { return nil }
        
        let main = mainGrey(of: pixels)
        for i in stride(from: 0, to: pixels.count, by: 4) {
            let alpha = CGFloat(pixels[i + 3]) / 255
            guard alpha > 0 else { continue }
            
            let grey = min(CGFloat(greyLevel(pixels, at: i)) / 255 / alpha, 1)
            let level = grey <= main
                ? 0.5 * (main > 0 ? grey / main : 1)
                : 0.5 + 0.5 * (grey - main) / (1 - main)
            let value = UInt8((level * alpha * 255).rounded())
            pixels[i] = value
            pixels[i + 1] = value
            pixels[i + 2] = value
        }
        
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: sRGB,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }
    
    /// The most common opaque grey; the designs draw the part's body in it.
    private static func mainGrey(of pixels: [UInt8]) -> CGFloat {
        var histogram = [Int](repeating: 0, count: 64)
        for i in stride(from: 0, to: pixels.count, by: 4) where pixels[i + 3] == 255 {
            histogram[greyLevel(pixels, at: i) / 4] += 1
        }
        guard let bin = histogram.indices.max(by: { histogram[$0] < histogram[$1] }) else { return 0 }
        
        var sum = 0
        var count = 0
        for i in stride(from: 0, to: pixels.count, by: 4) where pixels[i + 3] == 255 && greyLevel(pixels, at: i) / 4 == bin {
            sum += greyLevel(pixels, at: i)
            count += 1
        }
        return count > 0 ? CGFloat(sum) / CGFloat(count) / 255 : 0
    }
    
    private static func greyLevel(_ pixels: [UInt8], at i: Int) -> Int {
        (Int(pixels[i]) + Int(pixels[i + 1]) + Int(pixels[i + 2])) / 3
    }
    
    private static let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
    
    /// Premultiplied RGBA, top row first.
    private static func rgbaPixels(of image: CGImage, width: Int, height: Int) -> [UInt8]? {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: sRGB,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drawn ? pixels : nil
    }
}
