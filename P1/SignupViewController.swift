//
//  signupViewController.swift
//  P1
//
//  Created by 张翌璠 on 2020-01-11.
//  Copyright © 2020 张翌璠. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import Photos

class SignupViewController: UIViewController, UINavigationControllerDelegate {
    @IBOutlet var inputemail: UITextField!
    @IBOutlet var inputpw: UITextField!
    @IBOutlet var inputcpw: UITextField!
    @IBOutlet var inputname: UITextField!
    @IBOutlet var inputbio: UITextField!
    
    @IBOutlet var icon: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                uid = user.uid
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        self.inputbio.delegate = self
        self.inputemail.delegate = self
        self.inputpw.delegate = self
        self.inputcpw.delegate = self
        self.inputname.delegate = self
        
        // [START setup]
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        // [END setup]
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.origin.y == 0 {
                view.frame.origin.y -= keyboardSize.height/2
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
    
    @IBAction func createAccount(_ sender: UIButton) {
        
        let email = inputemail.text
        if (email == "") {
            showAlert(msg: "Email can't be empty")
            return
        }
        let password = inputpw.text
        if (password == "") {
            showAlert(msg: "Password can't be empty")
            return
        }
        
        let cpw = inputcpw.text
        
        let name = inputname.text
        if (name == "") {
            showAlert(msg: "Username can't be empty")
            return
        }
        if (cpw != password) {
            showAlert(msg: "The two passwords are inconsistent")
            return
        }
        
        // [START create_user]
        Auth.auth().createUser(withEmail: email!, password: password!) { [unowned self] authResult, error in
            // [START_EXCLUDE]
            if let error = error {
                showAlert(msg: error.localizedDescription)
                return
            }
            if let user = authResult?.user, error == nil {
                sender.isUserInteractionEnabled = false
                uid = user.uid
            } else {
                showAlert(msg: error!.localizedDescription)
                return
            }
            addUser(name:name!)
            let storageRef = storage.reference(withPath: uid! + "/displayPic.jpg")
            addPhoto(timestamp:"\(Int(Date.timeIntervalSinceReferenceDate * 1000))")
            guard let iconData = icon.image!.jpegData(compressionQuality: 0.5) else { return }
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            _ = storageRef.putData(iconData, metadata: metadata) { (metadata, error) in
                if let error = error {
                    showAlert(msg: "Error uploading: \(error)")
                    return
                }
                performSegue(withIdentifier: "registeredIn", sender: self)
            }
            //self!.uploadSuccess(storageRef, storagePath: self!.uid! + "/displayPic.jpg")
        }
    }
    
    private func addUser(name:String) {
        // [START add_alan_turing]
        // Add a second document with a generated ID.
        let dataToSave:[String: Any] = [
            "Username": name,
            "Bio": inputbio.text ?? "",
            "displayPicPath": uid! + "/displayPic.jpg"
        ]
        ref = db.document("users/" + uid!)
        ref?.setData(dataToSave){ [unowned self] (error) in
            if let error = error {
                showAlert(msg: error.localizedDescription)
            }
        }
        // [END add_alan_turing]
    }
    
    @IBAction func setPicture(_ sender: UIButton) {
        let alert = UIAlertController(title: "Set Picture", message: "Choose a method", preferredStyle: .alert)
        let albumAction = UIAlertAction(title: "Album", style: .default, handler: { action -> Void in
            self.judgeAlbumPermissions()
        })
        let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: { action -> Void in
            self.selectCamera()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(albumAction)
        alert.addAction(cameraAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
}

extension SignupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
}

extension SignupViewController: UIImagePickerControllerDelegate {
    func judgeAlbumPermissions() {
        // get auth
        let authStatus = PHPhotoLibrary.authorizationStatus()
        switch authStatus {
        case .notDetermined:
            // first alert
            PHPhotoLibrary.requestAuthorization({ [unowned self] (states) in
                // judge
                if states == .authorized {
                    openPhoto()
                } else if states == .restricted || states == .denied {
                    showAlert(msg: "No access to photo library")// auth fail
                }
            })
        case .authorized:
            openPhoto()
        default:
            showAlert(msg: "Access denied")
        }
    }
    
    private func addPhoto(timestamp:String) {
        // [START add_alan_turing]
        // Add a second document with a generated ID.
        ref = db.collection("photos").addDocument(data: [
            "uid": uid!,
            "storageRef": uid! + "/displayPic.jpg",
            "timestamp": timestamp,
            "icon": true
        ])
        { [unowned self] err in
            if let err = err {
                showAlert(msg: err.localizedDescription)
            } else {
                
            }
        }
    }
    
    func openPhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            DispatchQueue.main.async {
                let picker = UIImagePickerController()
                picker.delegate = self
                picker.sourceType = .photoLibrary
                picker.allowsEditing = true
                self.present(picker, animated: true)
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // get the picture
        guard let pickedImage = info[UIImagePickerController.InfoKey.editedImage]
                as? UIImage else {
            return
        }
        picker.dismiss(animated: true) {
            UIGraphicsBeginImageContextWithOptions(self.icon.bounds.size, true, 0)
            let ctx = UIGraphicsGetCurrentContext()
            UIColor.white.setFill()
            UIRectFill(self.icon.bounds)
            let rect = CGRect.init(x: 0, y: 0, width: self.icon.bounds.size.width, height: self.icon.bounds.size.height)
            self.icon.image = pickedImage
            ctx?.addEllipse(in: rect)
            ctx?.clip()
            self.icon.draw(self.icon.bounds)
            self.icon.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            iconPic = self.icon.image
        }
    }
    
    func selectCamera() {
        // auth
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authStatus {
        case .notDetermined:
            // first alert
            PHPhotoLibrary.requestAuthorization({ [unowned self] (states) in
                // judge
                if states == .authorized {
                    openCamera()
                } else if states == .restricted || states == .denied {
                    // auth fail
                    showAlert(msg: "No access to camera!")
                }
            })
        case .authorized:
            openCamera()
        default:
            showAlert(msg: "Access denied")
        }
    }
    
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            DispatchQueue.main.async {
                let  cameraPicker = UIImagePickerController()
                cameraPicker.delegate = self
                cameraPicker.allowsEditing = true
                cameraPicker.sourceType = .camera
                self.present(cameraPicker, animated: true, completion: nil)
            }
        }
    }
}
