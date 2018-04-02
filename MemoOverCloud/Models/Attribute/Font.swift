//
// Created by 김범수 on 2018. 3. 28..
// Copyright (c) 2018 piano. All rights reserved.
//

import UIKit

struct FontTraits: OptionSet {
    let rawValue: Int

    static let bold = FontTraits(rawValue: 1 << 0)
    static let italic = FontTraits(rawValue: 1 << 1)

    func toSymbolicTraits() -> UIFontDescriptorSymbolicTraits {
        var traits: UIFontDescriptorSymbolicTraits = []
        if self.contains(.bold) {traits.insert(.traitBold)}
        if self.contains(.italic) {traits.insert(.traitItalic)}

        return traits
    }
}


struct PianoFontAttribute: Hashable {
    static func ==(lhs: PianoFontAttribute, rhs: PianoFontAttribute) -> Bool {
        return lhs.traits == rhs.traits
    }
    
    let traits: FontTraits

    var hashValue: Int {
        return traits.rawValue
    }

    init?(font: UIFont) {
        var traits: FontTraits = []
        if font.fontDescriptor.symbolicTraits.contains(.traitBold) { traits.insert(.bold) }
        if font.fontDescriptor.symbolicTraits.contains(.traitItalic) { traits.insert(.italic) }

        self.traits = traits
    }

    func getFont() -> UIFont {

        return FontManager.shared.getFont(for: .body, with: traits)
    }
}

extension PianoFontAttribute: Codable {

    private enum CodingKeys: String, CodingKey {
        case traits
    }


    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let optionInt = try values.decode(Int.self, forKey: .traits)

        self.traits = FontTraits(rawValue: optionInt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(traits.rawValue, forKey: .traits)
    }
}
