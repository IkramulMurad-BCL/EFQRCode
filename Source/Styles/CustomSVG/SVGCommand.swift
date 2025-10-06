//
//  File.swift
//  EFQRCode
//
//  Created by Dey device -5 on 6/10/25.
//

import Foundation

public struct SVGCommand {
    public var point: CGPoint
    public var control1: CGPoint
    public var control2: CGPoint
    public var type: Kind
    
    public enum Kind {
        case move
        case line
        case cubeCurve
        case quadCurve
        case close
    }
    
    public init() {
        let point = CGPoint()
        self.init(point, point, point, type: .close)
    }
    
    public init(_ x: CGFloat, _ y: CGFloat, type: Kind) {
        let point = CGPoint(x: x, y: y)
        self.init(point, point, point, type: type)
    }
    
    public init(_ cx: CGFloat, _ cy: CGFloat, _ x: CGFloat, _ y: CGFloat) {
        let control = CGPoint(x: cx, y: cy)
        self.init(control, control, CGPoint(x: x, y: y), type: .quadCurve)
    }
    
    public init(_ cx1: CGFloat, _ cy1: CGFloat, _ cx2: CGFloat, _ cy2: CGFloat, _ x: CGFloat, _ y: CGFloat) {
        self.init(CGPoint(x: cx1, y: cy1), CGPoint(x: cx2, y: cy2), CGPoint(x: x, y: y), type: .cubeCurve)
    }
    
    public init(_ control1: CGPoint, _ control2: CGPoint, _ point: CGPoint, type: Kind) {
        self.point = point
        self.control1 = control1
        self.control2 = control2
        self.type = type
    }
    
    public func relativeTo(commandSequence: [SVGCommand]) -> SVGCommand {
        if let lastOp = commandSequence.last {
            if lastOp.type == .close {
                //we need to offset from the last Move command, not the current point if we have a relative Move after a Close
                var lastMove: SVGCommand?
                
                for i in (1...commandSequence.count).reversed() {
                    lastMove = commandSequence[i - 1]
                    if lastMove?.type == .move {
                        break;
                    }
                }
                
                if lastMove != nil {
                    return SVGCommand(control1 + lastMove!.point, control2 + lastMove!.point, point + lastMove!.point, type: type)
                }
            } else {
                //return relative to the point on the last operation
                return SVGCommand(control1 + lastOp.point, control2 + lastOp.point, point + lastOp.point, type: type)
            }
        }
        
        return self
    }
}
