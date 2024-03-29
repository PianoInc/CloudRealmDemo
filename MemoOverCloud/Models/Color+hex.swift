//
// Created by 김범수 on 2018. 2. 23..
// Copyright (c) 2018 piano. All rights reserved.
//

import UIKit

extension UIColor {

    /// Init UIColor with hex string
    convenience init(hex: String) {
        let scan = Scanner(string: hex.trimmingCharacters(in: .newlines))
        var color: UInt32 = 0
        scan.scanHexInt32(&color)
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        let red = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue = CGFloat(b) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }

    var hexString: String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0

        return String(format:"%06x", rgb)
    }
}