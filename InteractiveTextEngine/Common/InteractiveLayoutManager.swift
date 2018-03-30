//
//  InteractiveLayoutManager.swift
//  InteractiveTextEngine
//
//  Created by 김범수 on 2018. 3. 23..
//

import UIKit

class InteractiveLayoutManager: NSLayoutManager {
    
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        
        textStorage?.enumerateAttribute(.attachment, in: glyphsToShow,
                                        options: [.longestEffectiveRangeNotRequired, .reverse]) { (value, range, _) in
                                            guard let container = textContainer(forGlyphAt: range.location, effectiveRange: nil),
                                                let attachment = value as? InteractiveTextAttachment else {return}
                                            
                                            //Fix bounds for attachment!!
                                            
                                            let currentBounds = self.boundingRect(forGlyphRange: range, in: container)
                                            attachment.currentBounds = currentBounds
        }
        
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
    }
}
