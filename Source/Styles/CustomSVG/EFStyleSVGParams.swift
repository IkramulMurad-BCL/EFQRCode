//
//  EFStyleSVGParams.swift
//  EFQRCode
//
//  Created by Dey device -5 on 6/10/25.
//

import CoreGraphics

public class EFStyleSVGParams: EFStyleParams {
    public static let defaultBackdrop: EFStyleParamBackdrop = EFStyleParamBackdrop()
    
    // SVG customization options
    public let dotSVG: String?
    public let eyeSVG: String?
    public let qrColor: String?
    public let qrGradient: Gradient?
    public let backgroundColor: CGColor
    
    public init(
        icon: EFStyleParamIcon? = nil,
        backdrop: EFStyleParamBackdrop = EFStyleSVGParams.defaultBackdrop,
        dotSVG: String? = "<rect width=\"1\" height=\"1\"/>",
        eyeSVG: String? = nil,
        qrColor: String? = nil,
        qrGradient: Gradient? = nil,
        backgroundColor: CGColor = CGColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    ) {
        
        self.dotSVG = dotSVG
        self.eyeSVG = eyeSVG
        self.qrColor = qrColor
        self.qrGradient = qrGradient
        self.backgroundColor = backgroundColor
        super.init(icon: icon, backdrop: backdrop)
    }
    
    func copyWith(
        icon: EFStyleParamIcon? = nil,
        backdrop: EFStyleParamBackdrop? = nil,
        dotSVG: String? = nil,
        eyeSVG: String? = nil,
        qrColor: String? = nil,
        qrGradient: Gradient? = nil,
        backgroundColor: CGColor? = nil
    ) -> EFStyleSVGParams {
        return EFStyleSVGParams(
            icon: icon ?? self.icon,
            backdrop: backdrop ?? self.backdrop,
            dotSVG: dotSVG ?? self.dotSVG,
            eyeSVG: eyeSVG ?? self.eyeSVG,
            qrColor: qrColor ?? self.qrColor,
            qrGradient: qrGradient ?? self.qrGradient,
            backgroundColor: backgroundColor ?? self.backgroundColor
        )
    }
}
