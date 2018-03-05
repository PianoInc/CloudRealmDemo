//
// Created by 김범수 on 2018. 2. 6..
// Copyright (c) 2018 piano. All rights reserved.
//

import Foundation

extension String {

    var nsString: NSString {
        return NSString(string: self)
    }

    func range(from range: NSRange) -> Range<String.Index>? {
        guard let from16 = utf16.index(utf16.startIndex,
                                       offsetBy: range.location,
                                       limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: range.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) else {
                return nil
        }
        
        return from ..< to
    }
    
    func nsRange(from range: Range<Index>) -> NSRange {
        return NSRange(range, in: self)
    }
}

extension NSString {

    var string: String {
        return String(self)
    }

}

