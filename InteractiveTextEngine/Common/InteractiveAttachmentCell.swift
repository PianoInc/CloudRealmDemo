//
//  InteractiveAttachmentCell.swift
//  InteractiveTextEngine
//
//  Created by 김범수 on 2018. 3. 22..
//

import Foundation

extension InteractiveAttachmentCell {

    func sync(to bounds: CGRect) {
        if bounds != frame.offsetBy(dx: 0, dy: lineFragmentPadding) {
            
            let lineFragment = lineFragmentPadding ?? 0
            DispatchQueue.main.async { [weak self] in
                self?.frame = bounds.offsetBy(dx: 0, dy: lineFragment)
            }
        }
    }

    open func prepareForReuse() {
    }
    
    //TODO: add change Size

}

