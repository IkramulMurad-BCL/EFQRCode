//
//  EFStyleSVGParams.swift
//  EFQRCode
//
//  Created by Dey device -5 on 6/10/25.
//

import CoreGraphics

public class EFStyleSVGParams: EFStyleParams {
    public static let defaultBackdrop: EFStyleParamBackdrop = EFStyleParamBackdrop()
    
    /// Bumped whenever the dot, eye or a fill is set, so a renderer can keep what it drew for them
    /// across logo edits. Mutating one of those objects in place must be followed by setting it again.
    public private(set) var styleRevision = 0
    
    // SVG customization options
    public var dot: Dot { didSet { styleRevision &+= 1 } }
    public var eye: Eye { didSet { styleRevision &+= 1 } }
    public var foreground: VisualFill { didSet { styleRevision &+= 1 } }
    public var background: VisualFill { didSet { styleRevision &+= 1 } }
    public var logo: Logo
    
    public func setForeground(_ visualFill: VisualFill) {
        self.foreground = visualFill
    }
    
    public func setBackground(_ visualFill: VisualFill) {
        self.background = visualFill
    }
    
    public func setLogo(_ logo: Logo) {
        self.logo = logo
    }
    
    public func setDot(_ dot: Dot) {
        self.dot = dot
    }
    
    public func setEye(_ eye: Eye) {
        self.eye = eye
    }
    
    public func setEyesTranslucentWhiteBack(_ needBack: Bool) {
        self.eye.needTranslucentWhiteBack = needBack
        styleRevision &+= 1 // Eye is a class, so `eye`'s didSet doesn't see this
    }
    
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
