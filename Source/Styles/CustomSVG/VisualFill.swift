//
//  ColorGradientMask.swift
//  EFQRCode
//
//  Created by Dey device -5 on 13/10/25.
//

import UIKit

public protocol VisualFill {
    
}

public class SolidColor: VisualFill {
    public init(with hex: String) {
        
    }
}

public class LinearGradient: VisualFill {
    public init(with hex1: String, hex2: String) {
        
    }
}

public class ImageMask: VisualFill {
    public init(with image: UIImage) {
        
    }
}
