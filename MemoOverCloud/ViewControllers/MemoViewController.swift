//
//  MemoViewController.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 2..
//  Copyright © 2018년 piano. All rights reserved.
//

import UIKit
import RealmSwift
import FlangeTextEngine
import CloudKit

class MemoViewController: UIViewController {
    
    @IBOutlet weak var textView: FastTextView!
    internal var kbHeight: CGFloat?
    var memo: RealmNoteModel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerKeyboardNotification()
        
        textView.memo = memo
        textView.adjustsFontForContentSizeCategory = true

        textView.flangeDelegate = self
        textView.delegate = self

        do {
            let jsonDecoder = JSONDecoder()
            let attributes = try jsonDecoder.decode([PianoAttribute].self, from: memo.attributes)
            
            textView.set(string: memo.content, with: attributes)
        } catch {
            print(error)
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveText()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        //TODO: make async
        let (string, attributes) = textView.get()
        let jsonEncoder = JSONEncoder()

        guard let data = try? jsonEncoder.encode(attributes) else {return}

        let kv: [String: Any] = ["content": string, "attributes": data]
        
        ModelManager.update(model: textView.memo, kv: kv) { error in
            if let error = error {print(error)}
            else {print("happy")}
        }

    }

    
    @IBAction func albumButtonTouched(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected

        if sender.isSelected {
            addPhotoView()
        } else {
            removePhotoView()
        }
//        presentShare(sender)
    }
    
}

extension MemoViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        saveText()
    }
}

extension MemoViewController: FlangeTextViewDelegate {
    func requestImage(for attachment: FlangeTextAttachment, range: NSRange) {
        guard let attachment = (attachment as? FastTextAttachment) else {return}
        
        if let image = LocalCache.shared.getImage(id: attachment.imageID + "thumb") {
            attachment.image = image
            textView.reloadRange(for: range)
            return
        } else {
            LocalCache.shared.updateThumbnailCacheWithID(id: attachment.imageID + "thumb", width: attachment.width, height: attachment.height) { image in
                DispatchQueue.main.async { [weak self] in
                    attachment.image = image
                    //TODO: reload whole visible range
                    self?.textView.reloadRange(for: range)
                }
            }
            return
        }
    }

}


extension MemoViewController: PhotoViewDelegate {
    
    func photoView(url: URL, image: UIImage) {
        
        let resizedImage: UIImage!
        if image.size.width > UIScreen.main.bounds.width {
            let width = UIScreen.main.bounds.width / 2
            let height = image.size.height * width / image.size.width
            resizedImage = image.resizeImage(size: CGSize(width: width, height: height)) ?? UIImage()
        } else {
            resizedImage = image
        }


        let identifier = textView.memo.id + url.absoluteString
        
        let noteRecordName = memo.recordName
        DispatchQueue.global(qos: .userInteractive).async {
            if let realm = try? Realm(),
                let _ = realm.object(ofType: RealmImageModel.self, forPrimaryKey: identifier) {
                //ImageModel exist!!
            } else {
                let newImageModel = RealmImageModel.getNewModel(noteRecordName: noteRecordName, image: image)
                newImageModel.id = identifier

                ModelManager.save(model: newImageModel) {error in }
            }
        }
        
        //현재 커서 위치의 왼쪽, 오른쪽에 각각 개행이 없으면 먼저 넣어주기
        //우선 왼쪽 범위, 오른쪽 범위가 각각 존재하는 지도 체크해야함.
        
        //왼쪽 범위가 존재하고 && 왼쪽에 개행이 아니면 개행 삽입하기
        textView.insertNewLineToLeftSideIfNeeded(location: textView.selectedRange.location)

        let attachment = FastTextAttachment()
        attachment.imageID = identifier
        attachment.width = resizedImage.size.width
        attachment.height = resizedImage.size.height

        let attrString = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
        textView.textStorage.replaceCharacters(in: textView.selectedRange, with: attrString)
        
        textView.selectedRange = NSMakeRange(textView.selectedRange.location + 1, 0)
        
        //오른쪽 범위가 존재하고 오른쪽에 개행이 아니면 개행 삽입하기
        textView.insertNewlineToRightSideIfNeeded(location: textView.selectedRange.location)
        
        textView.scrollRangeToVisible(textView.selectedRange)
    }
}


extension MemoViewController {
    internal func registerKeyboardNotification(){
        NotificationCenter.default.addObserver(self, selector: #selector(MemoViewController.keyboardWillShow(notification:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MemoViewController.keyboardWillHide(notification:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MemoViewController.keyboardDidHide(notification:)), name: Notification.Name.UIKeyboardDidHide, object: nil)
    }
    
    internal func unRegisterKeyboardNotification(){
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
