//
//  InteractiveTextView_iOS.swift
//  InteractiveTextEngine_iOS
//
//  Created by 김범수 on 2018. 3. 22..
//

import Foundation

open class InteractiveTextView: UITextView {
    let dispatcher = InteractiveAttachmentCellDispatcher()
    private var contentOffsetObserver: NSKeyValueObservation?
    
    open weak var interactiveDatasource: InteractiveTextViewDataSource?
    open weak var interactiveDelegate: InteractiveTextViewDelegate?
    
    public var visibleBounds: CGRect {
        return CGRect(x: self.contentOffset.x, y:self.contentOffset.y,width: self.bounds.size.width,height: self.bounds.size.height)
    }
    
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        
        let newContainer = NSTextContainer(size: frame.size)
        let newLayoutManager = InteractiveLayoutManager()
        let newTextStorage = InteractiveTextStorage()
        
        newLayoutManager.addTextContainer(newContainer)
        newTextStorage.addLayoutManager(newLayoutManager)
        
        super.init(frame: frame, textContainer: newContainer)
        
        newTextStorage.textView = self
        dispatcher.superView = self
        self.backgroundColor = UIColor.clear
        setObserver()
    }
    
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented!!")
    }
    
    deinit {
        contentOffsetObserver?.invalidate()
        contentOffsetObserver = nil
    }
    
    func setObserver() {
        contentOffsetObserver = observe(\.contentOffset, options: [.old, .new, .prior]) {[weak self] (object, change) in
            guard let new = change.newValue, let old = change.oldValue else {return}
            if new != old {
                guard let visibleBounds = self?.visibleBounds else {return}
                self?.dispatcher.visibleRectChanged(rect: visibleBounds)
            }
        }
    }
}
