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
    let dot: Dot
    let eye: Eye
    let foreground: VisualFill
    let background: VisualFill
    let logo: Logo
    
    public init(
        icon: EFStyleParamIcon? = nil,
        backdrop: EFStyleParamBackdrop = EFStyleSVGParams.defaultBackdrop,
        dot: Dot,
        eye: Eye,
        foreground: VisualFill,
        background: VisualFill,
        logo: Logo
    ) {
        self.dot = dot
        self.eye = eye
        self.foreground = foreground
        self.background = background
        self.logo = logo
        super.init(icon: icon, backdrop: backdrop)
    }
    
    func copyWith(
        icon: EFStyleParamIcon? = nil,
        backdrop: EFStyleParamBackdrop? = nil,
        dot: Dot? = nil,
        eye: Eye? = nil,
        foreground: VisualFill? = nil,
        background: VisualFill? = nil,
        logo: Logo? = nil
    ) -> EFStyleSVGParams {
        return EFStyleSVGParams(
            icon: icon ?? self.icon,
            backdrop: backdrop ?? self.backdrop,
            dot: dot ?? self.dot,
            eye: eye ?? self.eye,
            foreground: foreground ?? self.foreground,
            background: background ?? self.background,
            logo: logo ?? self.logo
        )
    }
}
