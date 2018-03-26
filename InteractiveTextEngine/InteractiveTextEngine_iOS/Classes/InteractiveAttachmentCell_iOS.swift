//
//  InteractiveAttachmentCell_iOS.swift
//  InteractiveTextEngine
//
//  Created by 김범수 on 2018. 3. 23..
//

import UIKit

open class InteractiveAttachmentCell: UIView {

    let uniqueID = UUID().uuidString
    var reuseIdentifier: String!
    var lineFragmentPadding: CGFloat!
    
    weak var relatedAttachment: InteractiveTextAttachment?
}
