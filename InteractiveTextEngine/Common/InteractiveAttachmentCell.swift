//
//  InteractiveAttachmentCell.swift
//  InteractiveTextEngine
//
//  Created by 김범수 on 2018. 3. 22..
//

import Foundation

extension InteractiveAttachmentCell {
    
    public func isRelated(to attachment: InteractiveTextAttachment) -> Bool {
        return (relatedAttachment?.uniqueID ?? "") == attachment.uniqueID
    }

    func sync(to bounds: CGRect) {
        if bounds.offsetBy(dx: 0, dy: lineFragmentPadding).insetBy(dx: 1, dy: 0) != frame {
            let padding = lineFragmentPadding
            DispatchQueue.main.async { [weak self] in
                self?.frame = bounds.offsetBy(dx: 0, dy: padding).insetBy(dx: 1, dy: 0)
            }
        }
    }
    

    open func prepareForReuse() {
    }
    
    public func changeSize(to size: CGSize) {
        guard let relatedAttachment = relatedAttachment else {return}
        relatedAttachment.currentSize = size
    }
}

