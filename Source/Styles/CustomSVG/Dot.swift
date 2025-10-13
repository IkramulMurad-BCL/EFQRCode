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

public class Dot {
    let svgString: String
    let groupingStyle: DotGroupingStyle
    
    init(svgString: String = "<rect width=\"1\" height=\"1\"/>", groupingStyle: DotGroupingStyle = .none) {
        self.svgString = svgString
        self.groupingStyle = groupingStyle
    }
}
