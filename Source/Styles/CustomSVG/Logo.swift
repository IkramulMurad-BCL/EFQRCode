//
//  Logo.swift
//  EFQRCode
//
//  Created by Dey device -5 on 13/10/25.
//

import UIKit

public protocol Logo {
    var adjustment: LogoAdjustment { get set }
    func asImage(size: CGSize) -> UIImage?
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
}

public class TextLogo: Logo {
    public var adjustment: LogoAdjustment
    
    let content: String
    let font: UIFont
    let visualFill: VisualFill
    
    public init(adjustment: LogoAdjustment, content: String, font: UIFont, visualFill: VisualFill) {
        self.adjustment = adjustment
        self.content = content
        self.font = font
        self.visualFill = visualFill
    }
    
    public func asImage(size: CGSize) -> UIImage? {
        nil
    }
}
