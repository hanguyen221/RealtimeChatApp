//
//  ChatLogController.swift
//  RealtimeChatApp
//
//  Created by Ha Nguyen on 8/16/17.
//  Copyright © 2017 Ha Nguyen. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            
            observeMesseges()
        }
    }
    
    var messages = [Message]()
    
    func observeMesseges() {
        guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else {
            return
        }
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(toId)
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            
            let messageId = snapshot.key
            let messagesRef = Database.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                guard let dictionary = snapshot.value as? [String: Any] else {
                    return
                }
                
                let message = Message(dictionary: dictionary)
                message.setValuesForKeys(dictionary)
                
                self.messages.append(message)
                
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                }
                
            }, withCancel: nil)
            
        }, withCancel: nil)
    }
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.backgroundColor = .white
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .interactive
        
        setupKeyboardObserver()
        
        let dismissKeyboardRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(dismissKeyboardRecognizer)
    }
    
    lazy var inputContainerView: ChatInputContainerView = {
        let chatInputContainerView = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        chatInputContainerView.chatLogController = self
        return chatInputContainerView
    }()
    
    func handleUploadTap() {
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        
        
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL {
            handleVideoSelectedForUrl(url: videoUrl)
        } else {
            handleImageSelectedForInfo(info)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func handleVideoSelectedForUrl(url: URL) {
        let fileName = "\(NSUUID().uuidString).mov"
        let uploadTask = Storage.storage().reference().child("message_movies").child(fileName).putFile(from: url, metadata: nil, completion: { (metadata, error) in
            
            if error != nil {
                print(error!)
                return
            }
            
            if let videoUrl = metadata?.downloadURL()?.absoluteString {
                
                if let thumbnailImage = self.thumbnailImageForFileUrl(url) {
                    
                    self.uploadToFirebaseStorageUsingImage(thumbnailImage, completion: { (imageUrl) in
                        
                        let properties: [String: Any] = ["imageUrl": imageUrl, "imageWidth": thumbnailImage.size.width, "imageHeight": thumbnailImage.size.height, "videoUrl": videoUrl]
                        self.sendMessageWithProperties(properties: properties)
                    })
                }
            }
        })
        
        uploadTask.observe(.progress) { (snapshot) in
            if let completedUnitCount = snapshot.progress?.completedUnitCount {
                self.navigationItem.title = String(completedUnitCount)
            }
        }
        
        uploadTask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }
    }
    
    private func thumbnailImageForFileUrl(_ fileUrl: URL) -> UIImage? {
        
        let asset = AVAsset(url: fileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)
        } catch let err {
            print(err)
        }
        
        return nil
    }
    
    private func handleImageSelectedForInfo(_ info: [String: Any]) {
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage =  info[UIImagePickerControllerOriginalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            
            uploadToFirebaseStorageUsingImage(selectedImage, completion: { (imageUrl) in
                self.sendMessageWithImageUrl(imageUrl: imageUrl, image: selectedImage)
            })
        }

    }
    
    private func uploadToFirebaseStorageUsingImage(_ image: UIImage, completion: @escaping (String) -> ()) {
        let imageName = NSUUID().uuidString
        let ref = Storage.storage().reference().child("message_images").child("\(imageName).jpg")
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
            ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                
                if error != nil {
                    print(error!)
                    return
                }
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    completion(imageUrl)
                }
            })
        }
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func setupKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: .UIKeyboardDidShow, object: nil)
    }
    
    func handleKeyboardDidShow() {
        if messages.count > 0 {
            let indexPath = IndexPath(item: messages.count - 1, section: 0)
            collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func handleKeyboardWillShow(notification: NSNotification) {
        let keyboardFrame = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
        let keyboardDuration = (notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
        
        //move the area up
        containerViewBottomAnchor?.constant = -keyboardFrame!.height
        UIView.animate(withDuration: keyboardDuration!, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func handleKeyboardWillHide(notification: NSNotification) {
        
        //move the area down
        let keyboardDuration = (notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
        
        containerViewBottomAnchor?.constant = 0
        UIView.animate(withDuration: keyboardDuration!, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        cell.chatLogController = self
        
        let message = messages[indexPath.item]
        
        cell.message = message
        cell.textView.text = message.text
        
        setupCell(cell: cell, message: message)
        
        if let text = message.text {
            //a text mes
            cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: text).width + 32
            cell.textView.isHidden = false
        } else if message.imageUrl != nil {
            // an image mes
            cell.bubbleWidthAnchor?.constant = 200
            cell.textView.isHidden = true
        }
        
        if message.videoUrl != nil {
            cell.playButton.isHidden = false
        } else {
            cell.playButton.isHidden = true
        }
        
        return cell
    }
    
    private func setupCell(cell: ChatMessageCell, message: Message) {
        
        if let profileImageUrl = self.user?.profileImageUrl {
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        if message.fromId == Auth.auth().currentUser?.uid {
            //blue
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = .white
            cell.profileImageView.isHidden = true
            
            cell.bubbleLeftAnchor?.isActive = false
            cell.bubbleRightAnchor?.isActive = true
        } else {
            //gray
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = .black
            
            cell.bubbleRightAnchor?.isActive = false
            cell.bubbleLeftAnchor?.isActive = true
            cell.profileImageView.isHidden = false
        }
        
        if let messageImageUrl = message.imageUrl {
            cell.messageImageView.loadImageUsingCacheWithUrlString(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = .clear
        } else {
            cell.messageImageView.isHidden = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 80
        
        let message = messages[indexPath.item]
        
        if let text = message.text {
            height = estimateFrameForText(text: text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
            
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        
        
        let width = UIScreen.main.bounds.width
        return CGSize(width: width , height: height)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
        
    }
    
    private func estimateFrameForText(text: String) -> CGRect {
        
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
        
    }
    
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    func handleSend() {
        
        let properties = ["text": inputContainerView.inputTextField.text!]
        sendMessageWithProperties(properties: properties)
        
    }
    
    private func sendMessageWithImageUrl(imageUrl: String, image: UIImage) {
        
        let properties = ["imageUrl": imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height] as [String : Any]
        sendMessageWithProperties(properties: properties)
    }
    
    private func sendMessageWithProperties(properties: [String: Any]) {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toId = (user?.id)!
        let fromId = (Auth.auth().currentUser?.uid)!
        let timestamp: NSNumber = NSNumber(value: Date().timeIntervalSince1970)
        var values = ["toId": toId, "fromId": fromId, "timestamp": timestamp] as [String : Any]
        
        properties.forEach { values.updateValue($0.value, forKey: $0.key) }
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error!)
                return
            }
            
            self.inputContainerView.inputTextField.text = nil
            
            let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId: 1])
            
            let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
            recipientUserMessagesRef.updateChildValues([messageId: 1])
        }
    }
    
    var startingFrame: CGRect?
    var blackBackgroundView: UIView?
    var startingImageView: UIImageView?
    
    // custom zooming logic
    func performZoomInForImageView(startingImageView: UIImageView) {
        
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.backgroundColor = .red
        zoomingImageView.image = startingImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            
            blackBackgroundView = UIView(frame: keyWindow.frame)
            blackBackgroundView?.backgroundColor = .black
            blackBackgroundView?.alpha = 0
            self.inputContainerView.alpha = 0
            keyWindow.addSubview(blackBackgroundView!)
            
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.blackBackgroundView?.alpha = 1
                let height = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
                
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomingImageView.center = keyWindow.center
                
            }, completion: { (completed) in
            })
        }
    }
    
    func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        if let zoomOutImageView = tapGesture.view {
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackgroundView?.alpha = 0
                self.inputContainerView.alpha = 1
                
            }, completion: { (completed) in
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
            })
            
        }
    }
}




















