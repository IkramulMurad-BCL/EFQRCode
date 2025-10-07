//
//  Gradient.swift
//  EFQRCode
//
//  Created by Dey device -5 on 7/10/25.
//

enum GradientStartingPoint {
    case topLeading
    case topTrailing
    case top
    case left
}

public struct Gradient {
    let startingColor: String
    let endingColor: String
    let startingPoint: GradientStartingPoint
}
