//
//  CGFloat+Operator.swift
//  EFQRCode
//
//  Created by Dey device -5 on 6/10/25.
//

import Foundation

func +(a: CGPoint, b: CGPoint) -> CGPoint {
    return CGPoint(x: a.x + b.x, y: a.y + b.y)
}

func -(a: CGPoint, b: CGPoint) -> CGPoint {
    return CGPoint(x: a.x - b.x, y: a.y - b.y)
}
