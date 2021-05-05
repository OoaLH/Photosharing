//
//  CaptionViewController.swift
//  P1
//
//  Created by 张翌璠 on 2020-02-05.
//  Copyright © 2020 张翌璠. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import MLKit

class CaptionViewController: UIViewController {
    var index: Int? = nil
    var indexG: Int? = nil
    @IBOutlet var captionTextField: UITextField!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var photoImageView: UIImageView!
    @IBOutlet var hashSwitch: UISwitch!
    @IBOutlet var hashTagsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if index != nil {
            photoImageView.image = picImages[0]
        }
        else if indexG != nil {
            photoImageView.image = picImagesGlobal[0]
        }
        
        toggleHash()
        hashSwitch.addTarget(self, action: #selector(toggleHash), for:.valueChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func toggleHash() {
        if hashSwitch.isOn {
            let image = VisionImage(image: photoImageView.image!)
            let options = ImageLabelerOptions()
            options.confidenceThreshold = 0.7
            let labeler = ImageLabeler.imageLabeler(options: options)
            labeler.process(image) { [unowned self] labels, error in
                guard error == nil, let labels = labels else { return }
                var labelText = ""
                for label in labels {
                    labelText = labelText + label.text + " "
                }
                
                hashTagsLabel.text = labelText
            }
        }
        else {
            self.hashTagsLabel.text = " "
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.origin.y == 0 { view.frame.origin.y -= keyboardSize.height/2
            }
        }
    }
    @objc func keyboardWillHide(notification: NSNotification) {
        if ((notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            if view.frame.origin.y != 0 {
                view.frame.origin.y = 0
            }
        }
    }
    
    @IBAction func cancel(_ sender: UIButton) {
        if index != nil{
            picImages.remove(at: 0)
        }
        else if indexG != nil {
            picImagesGlobal.remove(at: 0)
        }
        self.dismiss(animated: true)
    }
    
    @IBAction func post(_ sender: UIButton) {
        let timestamp = "\(Int(Date.timeIntervalSinceReferenceDate * 1000))"
        let path = [uid! + "/" + timestamp + ".jpg"]
        
        let storageRef = storage.reference(withPath: uid! + "/" + timestamp + ".jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        guard let picData = photoImageView.image?.jpegData(compressionQuality: 0.7) else { return }
        if index != nil {
            var newImage = [photoImageView.image]
            newImage.append(contentsOf: picImagesGlobal)
            picImagesGlobal = newImage as! [UIImage]
            
        }
        else if indexG != nil {
            var newImage = [photoImageView.image]
            newImage.append(contentsOf: picImages)
            picImages = newImage as! [UIImage]
        }
        picRefsGlobal = path + picRefsGlobal
        picRefs = path + picRefs
        
        addPhoto(timestamp: timestamp, caption: captionTextField.text)
        _ = storageRef.putData(picData, metadata: metadata) { [unowned self] (metadata, error) in
            if let error = error {
                showAlert(msg: "Error uploading: \(error)")
                return
            }
        }
        dismiss(animated: true)
    }
    
    private func addPhoto(timestamp: String, caption: String?) {
        // [START add_alan_turing]
        // Add a second document with a generated ID.
        guard let uid = uid else {
            return
        }
        ref = db.collection("photos").addDocument(data: [
            "uid": uid,
            "storageRef": uid + "/" + timestamp + ".jpg",
            "timestamp": timestamp,
            "caption": caption ?? "",
            "icon": false,
            "hashTag": hashTagsLabel.text ?? ""
        ]) { [unowned self] err in
            if let err = err {
                showAlert(msg: err.localizedDescription)
            } else {
                
            }
        }
    }
}

extension CaptionViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
}
