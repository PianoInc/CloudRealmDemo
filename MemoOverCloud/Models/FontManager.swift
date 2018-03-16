//
// Created by 김범수 on 2018. 3. 16..
// Copyright (c) 2018 piano. All rights reserved.
//

import Foundation
import UIKit

class FontManager {
    static let shared = FontManager()
    var customFont: UIFont?

    private init() {}

    func register(font: UIFont) {
        customFont = font
    }

    func getFont(for style: UIFontTextStyle) -> UIFont {
        if let customFont = customFont {
            let metric = UIFontMetrics(forTextStyle: style)
            return metric.scaledFont(for: customFont)
        } else {
            return UIFont.preferredFont(forTextStyle: style)
        }
    }


    static func isStyle(_ style: UIFontTextStyle, font: UIFont) -> Bool {
        let baseFont = UIFont.preferredFont(forTextStyle: style)
        return font.pointSize == baseFont.pointSize
    }


}