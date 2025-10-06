//
//  SVGPath.swift
//  EFQRCode
//
//  Created by Dey device -5 on 6/10/25.
//

import Foundation

private enum Coordinates {
    case absolute
    case relative
}

fileprivate typealias SVGCommandBuilder = ([CGFloat], SVGCommand?, Coordinates) -> SVGCommand
private let numberSet = NSCharacterSet(charactersIn: "-.0123456789eE")
private let numberFormatter = NumberFormatter()

public class SVGPath {
    public var commands: [SVGCommand] = []
    private var builder: SVGCommandBuilder = moveTo
    private var coords: Coordinates = .absolute
    private var strideLength: Int = 2
    private var numbers = ""
    
    public init(_ string: String) {
        commands.reserveCapacity(200)
        for char in string {
            switch char {
            case "M": use(.absolute, strideLength: 2, builder: moveTo)
            case "m": use(.relative, strideLength: 2, builder: moveTo)
            case "L": use(.absolute, strideLength: 2, builder: lineTo)
            case "l": use(.relative, strideLength: 2, builder: lineTo)
            case "V": use(.absolute, strideLength: 1, builder: lineToVertical)
            case "v": use(.relative, strideLength: 1, builder: lineToVertical)
            case "H": use(.absolute, strideLength: 1, builder: lineToHorizontal)
            case "h": use(.relative, strideLength: 1, builder: lineToHorizontal)
            case "Q": use(.absolute, strideLength: 4, builder: quadBroken)
            case "q": use(.relative, strideLength: 4, builder: quadBroken)
            case "T": use(.absolute, strideLength: 2, builder: quadSmooth)
            case "t": use(.relative, strideLength: 2, builder: quadSmooth)
            case "C": use(.absolute, strideLength: 6, builder: cubeBroken)
            case "c": use(.relative, strideLength: 6, builder: cubeBroken)
            case "S": use(.absolute, strideLength: 4, builder: cubeSmooth)
            case "s": use(.relative, strideLength: 4, builder: cubeSmooth)
            case "Z": use(.absolute, strideLength: 0, builder: close)
            case "z": use(.relative, strideLength: 0, builder: close)
            default: numbers.append(char)
            }
        }
        finishLastCommand()
    }
    
    private func use(_ coords: Coordinates, strideLength: Int, builder: @escaping SVGCommandBuilder) {
        finishLastCommand()
        self.builder = builder
        self.coords = coords
        self.strideLength = strideLength
    }
    
    private func finishLastCommand() {
        for command in take(numbers: SVGPath.parseNumbers(numbers: numbers), strideLength: strideLength, coords: coords, last: commands.last, callback: builder) {
            commands.append(coords == .relative ? command.relativeTo(commandSequence: commands) : command)
        }
        numbers = ""
    }
}

public extension SVGPath {
    class func parseNumbers(numbers: String) -> [CGFloat] {
        numberFormatter.numberStyle = .decimal
        numberFormatter.allowsFloats = true
        numberFormatter.decimalSeparator = "."
        var all: [String] = []
        var curr = ""
        var last = ""
        var isDecimal = false
        
        for char in numbers.unicodeScalars {
            let next = String(char)
            
            if (next == "-" && last != "" && last != "E" && last != "e") || (next == "." && isDecimal) {
                if curr.utf16.count > 0 {
                    all.append(curr)
                    isDecimal = false
                }
                curr = next
            } else if numberSet.longCharacterIsMember(char.value) {
                curr += next
            } else if curr.utf16.count > 0 {
                all.append(curr)
                curr = ""
                isDecimal = false
            }
            last = next
            
            if last == "." {
                isDecimal = true
            }
        }
        
        all.append(curr)
        return all
            .filter {
                numberFormatter.number(from: $0) != nil
            }
            .map {
                CGFloat((numberFormatter.number(from: $0)?.floatValue)!)
        }
    }
}

fileprivate func take(numbers: [CGFloat], strideLength: Int, coords: Coordinates, last: SVGCommand?, callback: SVGCommandBuilder) -> [SVGCommand] {
    var out: [SVGCommand] = []
    var lastCommand: SVGCommand? = last
    var nums: [CGFloat] = [0, 0, 0, 0, 0, 0]
    if strideLength == 0 {
        lastCommand = callback(nums, lastCommand, coords)
        out.append(lastCommand!)
    } else {
        let count = (numbers.count / strideLength) * strideLength
        for i in stride(from: 0, to: count, by: strideLength) {
            for j in 0..<strideLength {
                nums[j] = numbers[i + j]
            }
            lastCommand = callback(nums, lastCommand, coords)
            out.append(lastCommand!)
        }
    }
    return out
}

// MARK: Mm - Move

private func moveTo(numbers: [CGFloat], last: SVGCommand?, coords: Coordinates) -> SVGCommand {
    return SVGCommand(numbers[0], numbers[1], type: .move)
}

// MARK: Ll - Line

private func lineTo(numbers: [CGFloat], last: SVGCommand?, coords: Coordinates) -> SVGCommand {
    return SVGCommand(numbers[0], numbers[1], type: .line)
}

// MARK: Vv - Vertical Line

private func lineToVertical(numbers: [CGFloat], last: SVGCommand?, coords: Coordinates) -> SVGCommand {
    return SVGCommand(coords == .absolute ? last?.point.x ?? 0 : 0, numbers[0], type: .line)
}

// MARK: Hh - Horizontal Line

private func lineToHorizontal(numbers: [CGFloat], last: SVGCommand?, coords: Coordinates) -> SVGCommand {
    return SVGCommand(numbers[0], coords == .absolute ? last?.point.y ?? 0 : 0, type: .line)
}

// MARK: Qq - Quadratic Curve To

private func quadBroken(numbers: [CGFloat], last: SVGCommand?, coords: Coordinates) -> SVGCommand {
    return SVGCommand(numbers[0], numbers[1], numbers[2], numbers[3])
}

// MARK: Tt - Smooth Quadratic Curve To

private func quadSmooth(numbers: [CGFloat], last: SVGCommand?, coords: Coordinates) -> SVGCommand {
    var lastControl = last?.control1 ?? CGPoint()
    let lastPoint = last?.point ?? CGPoint()
    if (last?.type ?? .line) != .quadCurve {
        lastControl = lastPoint
    }
    var control = lastPoint - lastControl
    if coords == .absolute {
        control = control + lastPoint
    }
    return SVGCommand(control.x, control.y, numbers[0], numbers[1])
}

// MARK: Cc - Cubic Curve To

private func cubeBroken(numbers: [CGFloat], last: SVGCommand?, coords: Coordinates) -> SVGCommand {
    return SVGCommand(numbers[0], numbers[1], numbers[2], numbers[3], numbers[4], numbers[5])
}

// MARK: Ss - Smooth Cubic Curve To

private func cubeSmooth(numbers: [CGFloat], last: SVGCommand?, coords: Coordinates) -> SVGCommand {
    var lastControl = last?.control2 ?? CGPoint()
    let lastPoint = last?.point ?? CGPoint()
    if (last?.type ?? .line) != .cubeCurve {
        lastControl = lastPoint
    }
    var control = lastPoint - lastControl
    if coords == .absolute {
        control = control + lastPoint
    }
    return SVGCommand(control.x, control.y, numbers[0], numbers[1], numbers[2], numbers[3])
}

// MARK: Zz - Close Path

private func close(numbers: [CGFloat], last: SVGCommand?, coords: Coordinates) -> SVGCommand {
    return SVGCommand()
}
