//
//  EFQRCodeStyleSVG.swift
//  EFQRCode
//
//  Created by Dey device -5 on 24/8/25.
//  Copyright © 2025 EyreFree. All rights reserved.
//

import UIKit
import CoreGraphics

import QRCodeSwift

public class EFQRCodeStyleSVG: EFQRCodeStyleBase {
    let params: EFStyleSVGParams
    
    public init(params: EFStyleSVGParams) {
        self.params = params
        super.init()
    }
    
    override func writeQRCode(qrcode: QRCode) throws -> [String] {
        return []
    }
        
    public override func writeIcon(qrcode: QRCode) throws -> [String] {
        return try params.icon?.write(qrcode: qrcode) ?? []
    }
    
    public override func viewBox(qrcode: QRCode) -> CGRect {
        return params.backdrop.viewBox(moduleCount: qrcode.model.moduleCount)
    }
    
    public override func generateSVG(qrcode: QRCode) throws -> String {
        let viewBoxRect: CGRect = viewBox(qrcode: qrcode)
        let (part1, part2) = try params.backdrop.generateSVG(qrcode: qrcode, viewBoxRect: viewBoxRect)
        
        return part1
        + (try writeQRCode(qrcode: qrcode)).joined()
        + (try writeIcon(qrcode: qrcode)).joined()
        + part2
    }
    
    public override func copyWith(
        iconImage: EFStyleParamImage? = nil,
        watermarkImage: EFStyleParamImage? = nil
    ) -> EFQRCodeStyleBase {
        let icon: EFStyleParamIcon? = params.icon?.copyWith(image: iconImage)
        return EFQRCodeStyleSVG(params: params.copyWith(icon: icon))
    }
    
    public override func getParamImages() -> (iconImage: EFStyleParamImage?, watermarkImage: EFStyleParamImage?) {
        return (params.icon?.image, nil)
    }
    
    public override func toQRCodeStyle() -> EFQRCodeStyle {
        return EFQRCodeStyle.svg(params: self.params)
    }
}
