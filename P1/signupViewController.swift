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




class signupViewController: UIViewController, UITextFieldDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var inputemail: UITextField!
    @IBOutlet var inputpw: UITextField!
    @IBOutlet var inputcpw: UITextField!
    @IBOutlet var inputname: UITextField!
    @IBOutlet var inputbio: UITextField!
    
    @IBOutlet var icon: UIImageView!
    
    // [START configurestorage]
    
    
    // [END configurestorage]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        Auth.auth().addStateDidChangeListener { (auth, user) in
            
            if user == nil {
                
                
            } else {
                uid = user?.uid

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
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        
        self.view.endEditing(true)
        
        return false;
    }
    
    @objc func dismissKeyboard() { view.endEditing(true)}
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 { self.view.frame.origin.y -= keyboardSize.height/2
            } }
    }
    @objc func keyboardWillHide(notification: NSNotification) { if ((notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) != nil {
        if self.view.frame.origin.y != 0 { self.view.frame.origin.y = 0
        } }
    }
    func alerts(msg: String){
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { action -> Void in
            //Just dismiss the action sheet
        })
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func createAccount(_ sender: UIButton) {
        
        let email = inputemail.text
        if (email == "") {
            alerts(msg:"Email can't be empty")
            return
        }
        let password = inputpw.text
        if (password == "") {
            alerts(msg:"Password can't be empty")
            return
        }
        
        let cpw = inputcpw.text
        
        let name = inputname.text
        if (name == "") {
            alerts(msg:"Username can't be empty")
            return
        }
        if (cpw != password){
            alerts(msg:"The two passwords are inconsistent")
            return
        }
        
        // [START create_user]
        //let k = self
        Auth.auth().createUser(withEmail: email!, password: password!) { [weak self] authResult, error in
            guard let strongSelf = self else { return }
            // [START_EXCLUDE]
            
            if let error = error {
                strongSelf.alerts(msg: error.localizedDescription)
                return}
            if let user = authResult?.user, error == nil{
                sender.isUserInteractionEnabled = false
                uid = user.uid
            } else{
                //strongSelf.showMessagePrompt(error!.localizedDescription)
                strongSelf.alerts(msg:error!.localizedDescription)
                
                return
            }
            self!.addUser(name:name!)
            let storageRef = storage.reference(withPath: uid! + "/displayPic.jpg")
            self!.addPhoto(timestamp:"\(Int(Date.timeIntervalSinceReferenceDate * 1000))")
            guard let iconData = self!.icon.image!.jpegData(compressionQuality: 0.5) else { return }
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            _ = storageRef.putData(iconData, metadata: metadata) { (metadata, error) in
                if let error = error {
                    self!.alerts(msg:"Error uploading: \(error)")
                    return
                }
          
            self!.performSegue(withIdentifier: "registeredIn", sender: self)
                
                
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
        ref?.setData(dataToSave){(error) in
            if let error = error {
                self.alerts(msg:error.localizedDescription)
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
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { action -> Void in
        })
        alert.addAction(albumAction)
        alert.addAction(cameraAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    func judgeAlbumPermissions() {
        
        // get auth
        let authStatus = PHPhotoLibrary.authorizationStatus()
        
        //not determined
        if authStatus == .notDetermined {
            // first alert
            PHPhotoLibrary.requestAuthorization({ [weak self] (states) in
                // judge
                
                guard let strongSelf = self else { return }
                
                if states == .authorized {
                    strongSelf.openPhoto()
                    
                } else if states == .restricted || states == .denied {
                    strongSelf.alerts(msg:"No access to photo library")// auth fail
                    
                }
                
            })
            
        } else if authStatus == .authorized {
            // auth success
            self.openPhoto()
            
        } else if authStatus == .restricted || authStatus == .denied {
            // auth fail
            alerts(msg:"Access denied")
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
                //print("fail")
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
            
            
            //self.dealwith(image: pickedImage)
        }
        
    }
    
    private func addPhoto(timestamp:String) {
        
        
        // [START add_alan_turing]
        // Add a second document with a generated ID.
        ref = db.collection("photos").addDocument(data: [
            "uid": uid!,
            "storageRef": uid! + "/displayPic.jpg",
            "timestamp": timestamp
            ])
        { err in
            if let err = err {
                self.alerts(msg:err.localizedDescription)
            } else {
                
            }
        }
    }
    
    func selectCamera() {
        // auth
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        //not determined
        if authStatus == .notDetermined {
            // first alert
            PHPhotoLibrary.requestAuthorization({ [weak self] (states) in
                // judge
                guard let strongSelf = self else { return }
                
                if states == .authorized {
                    strongSelf.openCamera()
                    
                } else if states == .restricted || states == .denied {
                    // auth fail
                    self!.alerts(msg:"No access to camera!")
                }
            })
        } else if authStatus == .authorized {
            // auth success
            self.openCamera()
            
        } else if authStatus == .restricted || authStatus == .denied {
            // auth fail
            alerts(msg:"Access denied")
        }
    }
    func openCamera() {
        
        //self.clearAllNotice()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            DispatchQueue.main.async {
                let  cameraPicker = UIImagePickerController()
                cameraPicker.delegate = self
                cameraPicker.allowsEditing = true
                cameraPicker.sourceType = .camera
                //present
                self.present(cameraPicker, animated: true, completion: nil)
            }
            
        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.navigationController != nil{
            // 在后台
        }else{
            // 已关闭
            // 触发 deinit
            self.view = nil
        }
    }
    
}
