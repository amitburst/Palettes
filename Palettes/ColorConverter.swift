//
//  ColorConverter.swift
//  Palettes
//
//  Created by Amit Burstein on 12/3/14.
//  Copyright (c) 2014 Amit Burstein. All rights reserved.
//

class ColorConverter: NSObject {
    
    // MARK: Enumerations
    
    enum CopyType: Int {
        case HEX = 0, RGB = 1, RGBA = 2, HSL = 3, HSLA = 4, NSColorSwift = 5, NSColorObjC = 6, UIColorSwift = 7, UIColorObjC = 8
    }
    
    // MARK: Functions
    
    class func getColorString(index index: Int, rawHex: String) -> String {
        let hex = "0x\(rawHex)".withCString { strtoul($0, nil, 16) }
        let red = (hex & 0xFF0000) >> 16
        let green = (hex & 0x00FF00) >> 8
        let blue = (hex & 0x0000FF)
        
        switch index {
        case CopyType.HEX.rawValue:
            return "#\(rawHex.lowercaseString)"
        case CopyType.RGB.rawValue:
            return "rgb(\(red), \(green), \(blue))"
        case CopyType.RGBA.rawValue:
            return "rgba(\(red), \(green), \(blue), 1)"
        case CopyType.HSL.rawValue:
            let (h, s, l) = getHSLFromRGB(red: red, green: green, blue: blue)
            return "hsl(\(h), \(s)%, \(l)%)"
        case CopyType.HSLA.rawValue:
            let (h, s, l) = getHSLFromRGB(red: red, green: green, blue: blue)
            return "hsla(\(h), \(s)%, \(l)%, 1)"
        case CopyType.NSColorSwift.rawValue:
            let r = String(format: "%.3f", Float(red) / 255)
            let g = String(format: "%.3f", Float(green) / 255)
            let b = String(format: "%.3f", Float(blue) / 255)
            return "NSColor(red: \(r), green: \(g), blue: \(b), alpha: 1)"
        case CopyType.NSColorObjC.rawValue:
            let r = String(format: "%.3f", Float(red) / 255)
            let g = String(format: "%.3f", Float(green) / 255)
            let b = String(format: "%.3f", Float(blue) / 255)
            return "[NSColor colorWithRed:\(r) green:\(g) blue:\(b) alpha:1]"
        case CopyType.UIColorSwift.rawValue:
            let r = String(format: "%.3f", Float(red) / 255)
            let g = String(format: "%.3f", Float(green) / 255)
            let b = String(format: "%.3f", Float(blue) / 255)
            return "UIColor(red: \(r), green: \(g), blue: \(b), alpha: 1)"
        case CopyType.UIColorObjC.rawValue:
            let r = String(format: "%.3f", Float(red) / 255)
            let g = String(format: "%.3f", Float(green) / 255)
            let b = String(format: "%.3f", Float(blue) / 255)
            return "[UIColor colorWithRed:\(r) green:\(g) blue:\(b) alpha:1]"
        default:
            print("New color type added?")
            return ""
        }
    }
    
    class func getHSLFromRGB(red red: UInt, green: UInt, blue: UInt) -> (h: Int, s: Int, l: Int) {
        let r = CGFloat(red) / 255
        let g = CGFloat(green) / 255
        let b = CGFloat(blue) / 255
        let maxRGB = max(r, g, b)
        let minRGB = min(r, g, b)
        var h = (maxRGB + minRGB) / 2
        var s = h
        let l = h
        
        if minRGB == maxRGB {
            h = 0
            s = 0
        } else {
            let d = maxRGB - minRGB
            s = l > 0.5 ? d / (2 - maxRGB - minRGB) : d / (maxRGB + minRGB)
            switch maxRGB {
            case r:
                h = (g - b) / d + (g < b ? 6 : 0)
            case g:
                h = (b - r) / d + 2
            case b:
                h = (r - g) / d + 4
            default:
                print("Something bad happened...")
            }
            h /= 6
        }
        
        return (Int(round(h * 360)), Int(round(s * 100)), Int(round(l * 100)))
    }
    
}
