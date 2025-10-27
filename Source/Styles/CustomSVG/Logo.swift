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
        nil
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
