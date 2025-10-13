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

class ImageLogo: Logo {
    var adjustment: LogoAdjustment
    
    init(adjustment: LogoAdjustment) {
        self.adjustment = adjustment
    }
}

class TextLogo: Logo {
    var adjustment: LogoAdjustment
    
    let content: String
    let font: UIFont
    let visualFill: VisualFill
    
    init(adjustment: LogoAdjustment, content: String, font: UIFont, visualFill: VisualFill) {
        self.adjustment = adjustment
        self.content = content
        self.font = font
        self.visualFill = visualFill
    }
}
