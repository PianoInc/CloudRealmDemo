//
//  MemoViewController.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 2..
//  Copyright © 2018년 piano. All rights reserved.
//

import UIKit
import RealmSwift
import InteractiveTextEngine_iOS
import CloudKit

class MemoViewController: UIViewController {
    
    var textView: FastTextView!
    internal var kbHeight: CGFloat?
    var memo: RealmNoteModel!
    var initialImageRecordNames: Set<String>!
    var isSaving = false
    var id: String!
    var recordName: String!
    var synchronizer: NoteSynchronizer!
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNotification()
        //tint = 007aff
        textView = FastTextView(frame: CGRect.zero, textContainer: nil)
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textView.translatesAutoresizingMaskIntoConstraints = false
        addTextView(textView: textView)

        id = memo.id
        recordName = memo.recordName
        textView.memo = memo
        textView.adjustsFontForContentSizeCategory = true

        textView.interactiveDelegate = self
        textView.interactiveDatasource = self
        
        
        textView.textDragDelegate = self
        textView.textDropDelegate = self
        textView.pasteDelegate = self
        textView.delegate = self
        textView.register(nib: UINib(nibName: "TextImageCell", bundle: nil), forCellReuseIdentifier: "textImageCell")
        

        initialImageRecordNames = []
      
        synchronizer = NoteSynchronizer(textView: textView)
        synchronizer.registerToCloud()
        

        do {
            let jsonDecoder = JSONDecoder()
            let attributes = try jsonDecoder.decode([PianoAttribute].self, from: memo.attributes)

            textView.set(string: memo.content, with: attributes)

            let imageRecordNames = attributes.map { attribute -> String in
                if case let .image(id, _, _) = attribute.style {return id}
                else {return ""}
            }.filter{!$0.isEmpty}

            initialImageRecordNames = Set<String>(imageRecordNames)
        } catch {
            print(error)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        saveText()
        unRegisterNotification()
        removeGarbageImages()
        

        synchronizer.unregisterFromCloud()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func addTextView(textView: FastTextView) {
        view.addSubview(textView)
        let constraint1 = NSLayoutConstraint(item: textView, attribute: .top, relatedBy: .equal,
                                             toItem: self.view.safeAreaLayoutGuide,
                                             attribute: .top, multiplier: 1.0, constant: 0)
        
        let constraint2 = NSLayoutConstraint(item: textView, attribute: .leading, relatedBy: .equal,
                                             toItem: self.view.safeAreaLayoutGuide,
                                             attribute: .leading, multiplier: 1.0, constant: 0)
        
        let constraint3 = NSLayoutConstraint(item: textView, attribute: .trailing, relatedBy: .equal,
                                             toItem: self.view.safeAreaLayoutGuide,
                                             attribute: .trailing, multiplier: 1.0, constant: 0)
        
        let constraint4 = NSLayoutConstraint(item: textView, attribute: .bottom, relatedBy: .equal,
                                             toItem: self.view.safeAreaLayoutGuide,
                                             attribute: .bottom, multiplier: 1.0, constant: 0)
        
        view.addConstraints([constraint1, constraint2, constraint3, constraint4])
    }

    private func addPhotoView(){
        let nib = UINib(nibName: "PhotoView", bundle: nil)
        let photoView: PhotoView = nib.instantiate(withOwner: nil, options: nil).first as! PhotoView
        photoView.delegate = self
        photoView.frame.size.height = 66
        photoView.frame.size.width = self.view.bounds.width
        
        photoView.fetchImages()
        textView.inputView = photoView
        textView.reloadInputViews()
        
    }
    
    private func removePhotoView(){
        textView.inputView = nil
        textView.reloadInputViews()
    }


    @objc func saveText() {
        
        DispatchQueue.main.async {
            if self.isSaving || self.textView.isSyncing {
                return
            }
            
            self.isSaving = true
            
            let (string, attributes) = self.textView.get()
            
            DispatchQueue.global().async {
                let jsonEncoder = JSONEncoder()
                
                guard let data = try? jsonEncoder.encode(attributes) else {return}
                
                let kv: [String: Any] = ["content": string, "attributes": data]
                
                ModelManager.update(id: self.id, type: RealmNoteModel.self, kv: kv) { [weak self] error in
                    if let error = error {print(error)}
                    else {print("happy")}
                    self?.isSaving = false
                }
            }
        }

    }

    @IBAction func albumButtonTouched(_ sender: UIButton) {

//        saveText()
        sender.isSelected = !sender.isSelected

        if sender.isSelected {
            addPhotoView()
        } else {
            removePhotoView()
        }
//        presentShare(sender)
    }

    private func removeGarbageImages() {
        let (_, attributes) = textView.attributedText.getStringWithPianoAttributes()

        let imageRecordNames = attributes.map { attribute -> String in
                if case let .image(id, _, _) = attribute.style {return id}
                else {return ""}
            }.filter{!$0.isEmpty}

        let currentImageRecordNames = Set<String>(imageRecordNames)
        initialImageRecordNames.subtract(currentImageRecordNames)

        let deletedImageRecordNames = Array<String>(initialImageRecordNames)

        if memo.isShared {
            //get zoneID from record
            let coder = NSKeyedUnarchiver(forReadingWith: textView.memo.ckMetaData)
            coder.requiresSecureCoding = true
            guard let record = CKRecord(coder: coder) else {fatalError("Data poluted!!")}
            coder.finishDecoding()
            CloudManager.shared.deleteInSharedDB(recordNames: deletedImageRecordNames, in: record.recordID.zoneID) { error in
                guard error == nil else { return }
            }
        } else {
            CloudManager.shared.deleteInPrivateDB(recordNames: deletedImageRecordNames) { error in
                guard error == nil else { return print(error!) }
            }
        }
    }
    
}

extension MemoViewController: InteractiveTextViewDelegate, InteractiveTextViewDataSource {
    func textView(_ textView: InteractiveTextView, attachmentForCell attachment: InteractiveTextAttachment) -> InteractiveAttachmentCell {
        //나중엔 attachment 의 클래스별로 새로운 셀 dequeue
        
        let cell = textView.dequeueReusableCell(withIdentifier: "textImageCell")
        guard let imageCell = cell as? TextImageCell,
            let attachment = attachment as? FastTextAttachment else {return cell}
        imageCell.imageView.image = attachment.tempImage

        
        return imageCell
    }
    
    
}


extension MemoViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {

        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(saveText), userInfo: nil, repeats: false)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return !self.textView.isSyncing
    }
}




extension MemoViewController: PhotoViewDelegate {
    
    func photoView(url: URL, image: UIImage) {
        
        let resizedImage = image.resizeImage(size: CGSize(width: 300, height: 200))!
        


        let identifier = textView.memo.id + url.absoluteString
        
        let noteRecordName = memo.recordName
        DispatchQueue.global(qos: .userInteractive).async {
            if let realm = try? Realm(),
                let _ = realm.object(ofType: RealmImageModel.self, forPrimaryKey: identifier) {
                //ImageModel exist!!
            } else {
                let newImageModel = RealmImageModel.getNewModel(noteRecordName: noteRecordName, image: image)
                newImageModel.id = identifier

                ModelManager.saveNew(model: newImageModel) { error in }
            }
        }
        
        //현재 커서 위치의 왼쪽, 오른쪽에 각각 개행이 없으면 먼저 넣어주기
        //우선 왼쪽 범위, 오른쪽 범위가 각각 존재하는 지도 체크해야함.
        
        //왼쪽 범위가 존재하고 && 왼쪽에 개행이 아니면 개행 삽입하기
        textView.insertNewLineToLeftSideIfNeeded(location: textView.selectedRange.location)

        let attachment = FastTextAttachment()
        attachment.imageID = identifier
        attachment.currentSize = resizedImage.size
        attachment.tempImage = resizedImage

        let attrString = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
        textView.textStorage.replaceCharacters(in: textView.selectedRange, with: attrString)
        
        textView.selectedRange = NSMakeRange(textView.selectedRange.location + 1, 0)
        
        //오른쪽 범위가 존재하고 오른쪽에 개행이 아니면 개행 삽입하기
        textView.insertNewlineToRightSideIfNeeded(location: textView.selectedRange.location)
        
        textView.scrollRangeToVisible(textView.selectedRange)
    }
}


extension MemoViewController {
    internal func registerNotification(){
        NotificationCenter.default.addObserver(self, selector: #selector(MemoViewController.keyboardWillShow(notification:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MemoViewController.keyboardWillHide(notification:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MemoViewController.keyboardDidHide(notification:)), name: Notification.Name.UIKeyboardDidHide, object: nil)
    }
    
    internal func unRegisterNotification(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(notification: Notification){
        guard let userInfo = notification.userInfo,
            let kbFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue,
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval
            else { return }
        
        
        kbHeight = UIScreen.main.bounds.height - kbFrame.origin.y
        let bottom = UIScreen.main.bounds.height - kbFrame.origin.y + 40
        textView.contentInset.bottom = bottom
        textView.scrollIndicatorInsets.bottom = bottom
        
        UIView.animate(withDuration: duration) { [weak self] in
            self?.view.layoutIfNeeded()
        }
        
    }
    
    @objc internal func keyboardWillHide(notification: Notification){
        guard let userInfo = notification.userInfo,
            let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue else { return }
        kbHeight = nil
        textView.scrollIndicatorInsets.bottom = 0
        UIView.animate(withDuration: duration) { [weak self] in
            self?.textView.contentInset = UIEdgeInsets.zero
            self?.view.layoutIfNeeded()
        }
    }
    @objc internal func keyboardDidHide(notification: Notification){
        textView.inputView = nil
    }
}


extension MemoViewController: UICloudSharingControllerDelegate, UIPopoverPresentationControllerDelegate {
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        print(error)
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        return memo.title
    }
    
    func presentShare(_ sender: UIButton) {
        let record = memo.getRecord()
        let share = CKShare(rootRecord: record)
        share[CKShareTitleKey] = "Some title" as CKRecordValue?
        share[CKShareTypeKey] = "Some type" as CKRecordValue?
        let sharingController = UICloudSharingController (preparationHandler: {(UICloudSharingController, handler:
            @escaping (CKShare?, CKContainer?, Error?) -> Void) in
            let modifyOp = CKModifyRecordsOperation(recordsToSave:
                [record, share], recordIDsToDelete: nil)
            modifyOp.savePolicy = CKRecordSavePolicy.changedKeys
            modifyOp.modifyRecordsCompletionBlock = { (record, recordID,
                error) in
                handler(share, CKContainer.default(), error)
            }
            CKContainer.default().privateCloudDatabase.add(modifyOp)
        })
        sharingController.availablePermissions = [.allowReadWrite,
                                                  .allowPublic]
        
        sharingController.delegate = self
        
        if (UI_USER_INTERFACE_IDIOM() == .phone) {
            
            self.present(sharingController, animated:true, completion:nil)
            
        }
            //for iPad
        else {
            // Change Rect as required
            let contentViewController = sharingController
            
            contentViewController.preferredContentSize = CGSize(width: 500, height: 550)
            contentViewController.modalPresentationStyle = .popover;
            
            
            let presentationController = contentViewController.popoverPresentationController
            presentationController?.delegate = self
            presentationController?.permittedArrowDirections = .up
            presentationController?.sourceView = sender
            presentationController?.sourceRect = sender.bounds
            
            self.present(contentViewController, animated: true, completion: nil)
        }
        
    }
}

extension MemoViewController: UITextDragDelegate, UITextDropDelegate {
    func textDraggableView(_ textDraggableView: UIView & UITextDraggable, itemsForDrag dragRequest: UITextDragRequest) -> [UIDragItem] {
        let location = textView.offset(from: textView.beginningOfDocument, to: dragRequest.dragRange.start)
        let length = textView.offset(from: dragRequest.dragRange.start, to: dragRequest.dragRange.end)
        
        let attributedString = NSAttributedString(attributedString:
                    textView.textStorage.attributedSubstring(from: NSMakeRange(location, length)))
        
        let itemProvider = NSItemProvider(object: attributedString)
        
        
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = dragRequest.dragRange
        
        return [dragItem]
    }

    func textDraggableView(_ textDraggableView: UIView & UITextDraggable, dragPreviewForLiftingItem item: UIDragItem, session: UIDragSession) -> UITargetedDragPreview? {
        
        guard let textRange = item.localObject as? UITextRange else { return nil }
        let location = textView.offset(from: textView.beginningOfDocument, to: textRange.start)
        let length = textView.offset(from: textRange.start, to: textRange.end)
        let range = NSMakeRange(location, length)
        
        let preview: UIView
        let bounds = textView.layoutManager.boundingRect(forGlyphRange: range, in: textView.textContainer)
        if let attachment = textView.attributedText.attribute(.attachment, at: range.location, effectiveRange: nil) as? InteractiveTextAttachment {
            //make it blurred
            preview = UIImageView(image: attachment.getPreviewForDragInteraction())
        } else {
            preview = UILabel(frame: bounds)
            (preview as! UILabel).attributedText = textView.textStorage.attributedSubstring(from: range)
        }
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let target = UIDragPreviewTarget(container: textView, center: center)
        
        return UITargetedDragPreview(view: preview, parameters: UIDragPreviewParameters(), target: target)
    }
    
    func textDroppableView(_ textDroppableView: UIView & UITextDroppable, willBecomeEditableForDrop drop: UITextDropRequest) -> UITextDropEditability {
        
        return (textView.isSyncing || isSaving) ? .no : .yes
    }
    
    func textDroppableView(_ textDroppableView: UIView & UITextDroppable, proposalForDrop drop: UITextDropRequest) -> UITextDropProposal {
        return UITextDropProposal(operation: .move)
    }
    
    
    func textDroppableView(_ textDroppableView: UIView & UITextDroppable, dropSessionDidEnd session: UIDropSession) {
        saveText()
    }
}

extension MemoViewController: UITextPasteDelegate {
    func textPasteConfigurationSupporting(_ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting, combineItemAttributedStrings itemStrings: [NSAttributedString], for textRange: UITextRange) -> NSAttributedString {
        
        if itemStrings.count == 1 {
            let attributedString = itemStrings[0]
            
            if let attachment = attributedString.attribute(.attachment, at: 0, effectiveRange: nil) as? InteractiveTextAttachment {
                let newAttr = NSAttributedString(attachment: attachment.getCopyForDragInteraction())
                return newAttr
            }
        }
        
        return itemStrings.reduce(NSMutableAttributedString()) { (result, attr) -> NSMutableAttributedString in
            result.append(attr)
            return result
        }
    }
}
