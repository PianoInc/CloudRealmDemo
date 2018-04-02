//
//  InteractiveTextView_iOS.swift
//  InteractiveTextEngine_iOS
//
//  Created by 김범수 on 2018. 3. 22..
//

import Foundation
import CoreText


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
        super.init(coder: aDecoder)
    }

    open override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        let newTextView = InteractiveTextView(frame: self.frame)

        //get constraints
        var constraints: Array<NSLayoutConstraint> = []
        self.constraints.forEach {
            let firstItem: AnyObject!, secondItem: AnyObject!

            if let unwrappedFirst = $0.firstItem as? InteractiveTextView, unwrappedFirst == self {
                firstItem = self
            } else {
                firstItem = $0.firstItem
            }

            if let unwrappedSecond = $0.secondItem as? InteractiveTextView, unwrappedSecond == self {
                secondItem = self
            } else {
                secondItem = $0.secondItem
            }

            constraints.append(
                    NSLayoutConstraint(item: firstItem,
                            attribute: $0.firstAttribute,
                            relatedBy: $0.relation,
                            toItem: secondItem,
                            attribute: $0.secondAttribute,
                            multiplier: $0.multiplier,
                            constant: $0.constant))
        }



        newTextView.addConstraints(constraints)
        newTextView.autoresizingMask = self.autoresizingMask
        newTextView.translatesAutoresizingMaskIntoConstraints = self.translatesAutoresizingMaskIntoConstraints


        newTextView.autocorrectionType = self.autocorrectionType
        newTextView.attributedText = self.attributedText
        newTextView.backgroundColor = self.backgroundColor
        newTextView.dataDetectorTypes = self.dataDetectorTypes
        newTextView.returnKeyType = self.returnKeyType
        newTextView.keyboardAppearance = self.keyboardAppearance
        newTextView.keyboardDismissMode = self.keyboardDismissMode
        newTextView.keyboardType = self.keyboardType

        return newTextView
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
