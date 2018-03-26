//
//  InteractiveAttachmentCell.swift
//  InteractiveTextEngine
//
//  Created by 김범수 on 2018. 3. 22..
//

import Foundation

class InteractiveAttachmentCellDispatcher {

    weak var superView: InteractiveTextView?

    //reuse identifier: Nibs
    private var nibs: [String: UINib] = [:]
    
    // identifier: array of cells
    private var idleCells: [String: [String: InteractiveAttachmentCell]] = [:]

    // identifier: array of cells
    private var workingCells: [String: [String: InteractiveAttachmentCell]] = [:]

    // List of attachments
    private var attachments: [String: InteractiveTextAttachment] = [:]

    private let dispatchQueue = DispatchQueue.global(qos: .utility)

    func visibleRectChanged(rect: CGRect) {
        //Notify!

        attachments.values.forEach{ $0.checkForVisibility(visibleBounds: rect) }

    }

    func add(attachment: InteractiveTextAttachment) {
        
        attachment.delegate = self
        attachments[attachment.uniqueID] = attachment
        
    }

    func remove(attachmentID: String) {
        if let attachment = attachments[attachmentID] {
            attachment.delegate = nil
            needToEndDisplay(attachment: attachment)
        }
        attachments.removeValue(forKey: attachmentID)
    }
    
    func register(nib: UINib?, forCellReuseIdentifier identifier: String) {
        guard let nib = nib else {return}
        nibs[identifier] = nib
        
        idleCells[identifier] = [:]
        workingCells[identifier] = [:]
    }
    
    func dequeueReusableCell(withIdentifier identifier: String) -> InteractiveAttachmentCell {
        if let cell = idleCells[identifier]?.popFirst() {
            return cell.value
        } else {
            guard let nib = nibs[identifier],
                let textView = superView else {fatalError("Nib is not registered for identifier\"\(identifier)\"")}
            
            for object in nib.instantiate(withOwner: nil, options: nil) {
                if let cell = object as? InteractiveAttachmentCell {
                    cell.frame = CGRect.zero
                    
                    cell.lineFragmentPadding = 8
                    
                    textView.insertSubview(cell, at: 0)
                    
                    idleCells[identifier]?[cell.uniqueID] = cell
                    cell.reuseIdentifier = identifier
                    
                    return cell
                }
            }
            fatalError("There is no InteractiveAttachmentCell class registered in Nib \(nib.description)")
        }
    }
}

extension InteractiveAttachmentCellDispatcher: InteractiveTextAttachmentDelegate {
    
    func needToDisplay(attachment: InteractiveTextAttachment) {
        
        if attachment.relatedCell != nil { return }
        //get cell from delegate
        guard let textView = superView,
            let cell = textView.interactiveDatasource?.textView(textView, attachmentForCell: attachment) else {return}
        
        cell.prepareForReuse()
        
        idleCells[cell.reuseIdentifier]?.removeValue(forKey: cell.uniqueID)
        workingCells[cell.reuseIdentifier]?[cell.uniqueID] = cell
        
        //link cell with attribute
        cell.relatedAttachment = attachment
        attachment.relatedCell = cell
        
        //willDisplayCell
        textView.interactiveDelegate?.textView?(textView, willDisplay: cell)
        //sync frame
        let bounds = attachment.currentBounds ?? CGRect.zero
        cell.frame = bounds.offsetBy(dx: 0, dy: textView.textContainer.lineFragmentPadding)
        
        //didDisplayCell
        textView.interactiveDelegate?.textView?(textView, didDisplay: cell)
    }

    func needToEndDisplay(attachment: InteractiveTextAttachment) {
        guard let textView = superView,
            let cell = attachment.relatedCell else {return}
        
        
        attachment.relatedCell = nil
        cell.relatedAttachment = nil
        
        //willEndDisplayCell
        textView.interactiveDelegate?.textView?(textView, willEndDisplaying: cell)
        
        cell.frame = CGRect.zero
        
        //get cell and put it in idle
        workingCells[cell.reuseIdentifier]?.removeValue(forKey: cell.uniqueID)
        idleCells[cell.reuseIdentifier]?[cell.uniqueID] = cell
        
        //didEndDisplayCell
        textView.interactiveDelegate?.textView?(textView, didEndDisplaying: cell)
    }
    
    func invalidateDisplay(range: NSRange) {
        DispatchQueue.main.async { [weak self] in
            self?.superView?.layoutManager.invalidateDisplay(forCharacterRange: range)
        }
    }
}


