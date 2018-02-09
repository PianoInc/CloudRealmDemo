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

extension NSAttributedString {
    
    func getTagRanges() -> [(NSRange, String)] {
        let markup = self.string
        
        
        guard let regex = try? NSRegularExpression(pattern: "(.*?)(<[^>]+>|\\Z)",
                                                   options: [.caseInsensitive,
                                                             .dotMatchesLineSeparators]) else {return []}
        let chunks = regex.matches(in: markup,
                                   options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                   range: NSRange(location: 0, length: markup.count))
        
        return chunks.map { (chunk) -> (NSRange, String)? in
            guard let markupRange = markup.range(from: chunk.range) else { return nil }
            let parts = markup[markupRange].components(separatedBy: "<")
            

            guard parts.count > 1, let tag = parts.last, tag.hasPrefix(ImageTag.tagName) else {return nil}
            
            let range =  markup.index(markupRange.upperBound, offsetBy: -tag.count-1) ..< markupRange.upperBound
            let adjustedTag = String(markup[range])
            //      range |========|
            //              |length|
            
            return (markup.nsRange(from: range), adjustedTag)
            }.flatMap{$0 != nil ? [$0!]: []}
    }
}

