//
//  LogoAdjustment.swift
//  EFQRCode
//
//  Created by Dey device -5 on 13/10/25.
//

import Foundation

public enum LogoStyle {
    case rect
    case round
    case roundedRect
    case scanAssistRect
    case scanAssistRoundedRect
    case none
}

public enum LogoPosition {
    case center
    case bottomRight
}

public class LogoAdjustment {
    var style: LogoStyle
    var position: LogoPosition
    var size: CGFloat
    var margin: CGFloat
    
    public init(style: LogoStyle, position: LogoPosition, size: CGFloat, margin: CGFloat) {
        self.style = style
        self.position = position
        self.size = size
        self.margin = margin
    }
    
    public func updateStyle(style: LogoStyle) {
        self.style = style
    }
    
    public func updatePosition(position: LogoPosition) {
        self.position = position
    }
    
    public func updateSize(size: CGFloat) {
        self.size = size
    }
    
    public func updateMargin(margin: CGFloat) {
        self.margin = margin
    }
}
