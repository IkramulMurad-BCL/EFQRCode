//
//  LogoAdjustment.swift
//  EFQRCode
//
//  Created by Dey device -5 on 13/10/25.
//

import Foundation

enum LogoStyle {
    case square
    case round
    case scanAssistRect
    case scanAssistRoundedRect
    case other
}

enum LogoPosition {
    case center
    case bottomRight
}

public class LogoAdjustment {
    let style: LogoStyle
    let position: LogoPosition
    let size: CGFloat
    let margin: CGFloat
    
    init(style: LogoStyle, position: LogoPosition, size: CGFloat, margin: CGFloat) {
        self.style = style
        self.position = position
        self.size = size
        self.margin = margin
    }
}
