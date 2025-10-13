//
//  Dot.swift
//  EFQRCode
//
//  Created by Dey device -5 on 13/10/25.
//

enum DotGroupingStyle {
    case none
    case single
    case group(Int)
}

class Dot {
    let svgString: String
    let groupingStyle: DotGroupingStyle
    
    init(svgString: String, groupingStyle: DotGroupingStyle) {
        self.svgString = svgString
        self.groupingStyle = groupingStyle
    }
}
