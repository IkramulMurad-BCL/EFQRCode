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
    public let color: UIColor

    public init(with hex: String) {
        self.color = UIColor(hex: hex)
    }
}

public class LinearGradient: VisualFill {
    public let startColor: UIColor
    public let endColor: UIColor

    public init(with hex1: String, hex2: String) {
        self.startColor = UIColor(hex: hex1)
        self.endColor = UIColor(hex: hex2)
    }
}

public class ImageMask: VisualFill {
    public let image: UIImage

    public init(with image: UIImage) {
        self.image = image
    }
}
