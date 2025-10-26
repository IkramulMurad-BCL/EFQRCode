//
//  Logo.swift
//  EFQRCode
//
//  Created by Dey device -5 on 13/10/25.
//

import UIKit

public protocol Logo {
    var adjustment: LogoAdjustment { get set }
}

public class ImageLogo: Logo {
    public var adjustment: LogoAdjustment
    let image: UIImage
    
    public init(adjustment: LogoAdjustment, image: UIImage) {
        self.adjustment = adjustment
        self.image = image
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
}
