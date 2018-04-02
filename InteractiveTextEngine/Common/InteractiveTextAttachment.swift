//
//  InteractiveTextAttachment.swift
//  InteractiveTextEngine
//
//  Created by 김범수 on 2018. 3. 22..
//

import Foundation

open class InteractiveTextAttachment: NSTextAttachment {

    let uniqueID = UUID().uuidString

    private var isVisible = false
    private var currentCharacterIndex: Int!

    weak var relatedCell: InteractiveAttachmentCell?
    weak var delegate: InteractiveTextAttachmentDelegate?
    
    //Convenience initializer to make drag
    public init() {
        super.init(data: nil, ofType: nil)
    }
    
    public init(attachment: InteractiveTextAttachment) {
        super.init(data: nil, ofType: nil)
        
        self.delegate = attachment.delegate
        self.currentSize = attachment.currentSize
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var currentBounds: CGRect? {
        didSet {
            if oldValue == nil {
                //then request update
                self.isVisible = true
                delegate?.needToDisplay(attachment: self)
            }
            
            guard let myCell = relatedCell,
                    let bounds = currentBounds else {return}
            myCell.sync(to: bounds)
        }
    }
    
    open var currentSize: CGSize! {
        didSet {
            delegate?.invalidateDisplay(range: NSMakeRange(currentCharacterIndex, 1))
        }
    }
    
    public func getPreviewForDragInteraction() -> UIImage? {
        return relatedCell?.getScreenShot()
    }
    
    open func getCopyForDragInteraction() -> InteractiveTextAttachment {
        return InteractiveTextAttachment(attachment: self)
    }

    func checkForVisibility(visibleBounds: CGRect) {
        if let currentBounds = currentBounds {
            if currentBounds.intersects(visibleBounds) {
                if !isVisible {
                    isVisible = true
                    delegate?.needToDisplay(attachment: self)
                }
            } else {
                if isVisible {
                    isVisible = false
                    delegate?.needToEndDisplay(attachment: self)
                }
            }
        }
    }

    override open func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        currentCharacterIndex = charIndex
        return CGRect(x: 0, y: 0, width: currentSize.width, height: currentSize.height)
    }

}

// In order to react to dispatcher Notification
protocol InteractiveTextAttachmentDelegate: AnyObject {
    func needToDisplay(attachment: InteractiveTextAttachment)
    func needToEndDisplay(attachment: InteractiveTextAttachment)
    func invalidateDisplay(range: NSRange)
}
