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
class CaptionViewController: UIViewController,UITextFieldDelegate {
    var index:Int? = nil
    var indexG:Int? = nil
    @IBOutlet var caption: UITextField!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var photo: UIImageView!
    
    @IBOutlet var hashSwitch: UISwitch!
    @IBOutlet var hashTags: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if index != nil{
            photo.image = picSet[0]
        }
        else if indexG != nil{
            photo.image = picSetG[0]
        }
        if hashSwitch.isOn{
            
            let image = VisionImage(image: photo.image!)
            let options = VisionOnDeviceImageLabelerOptions()
            options.confidenceThreshold = 0.7
            let labeler = Vision.vision().onDeviceImageLabeler(options: options)
            labeler.process(image) { labels, error in
                guard error == nil, let labels = labels else { return }
                var labelText = ""
                for label in labels {
                    //let labelText = label.text
                    //let entityId = label.entityID
                    //let confidence = label.confidence
                    labelText = labelText + label.text + " "
                }
                
                self.hashTags.text = labelText            }
        }
        hashSwitch.addTarget(self, action: #selector(addHash), for:.valueChanged)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        self.caption.delegate = self
        // Do any additional setup after loading the view.
    }
    @objc func addHash(){
        if hashSwitch.isOn{
            
            let image = VisionImage(image: photo.image!)
            let options = VisionOnDeviceImageLabelerOptions()
            options.confidenceThreshold = 0.7
            let labeler = Vision.vision().onDeviceImageLabeler(options: options)
            labeler.process(image) { labels, error in
                guard error == nil, let labels = labels else { return }
                var labelText = ""
                for label in labels {
                    //let labelText = label.text
                    //let entityId = label.entityID
                    //let confidence = label.confidence
                    labelText = labelText + label.text + " "
                }
                
                self.hashTags.text = labelText
            }
        }
        else{
            self.hashTags.text = " "
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        
        self.view.endEditing(true)
        
        return false
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
    @IBAction func cancel(_ sender: UIButton) {
        if index != nil{
            picSet.remove(at: 0)
        }
        else if indexG != nil{
            picSetG.remove(at: 0)
        }
        self.dismiss(animated: true)
    }
    @IBAction func post(_ sender: UIButton) {
        
        sender.isUserInteractionEnabled = false
        cancelButton.isUserInteractionEnabled = false
        let timestamp = "\(Int(Date.timeIntervalSinceReferenceDate * 1000))"
        let path = [uid! + "/" + timestamp + ".jpg"]
        
        let storageRef = storage.reference(withPath: uid! + "/" + timestamp + ".jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        guard let picData = photo.image?.jpegData(compressionQuality: 0.7) else { return }
        if index != nil{
            var newImage = [photo.image]
            newImage.append(contentsOf:picSetG)
            picSetG = newImage as! [UIImage]
            
        }
        else if indexG != nil{
            var newImage = [photo.image]
            newImage.append(contentsOf:picSet)
            picSet = newImage as! [UIImage]
            
        }
        picListG = path + picListG
        picList = path + picList
        self.addPhoto(timestamp:timestamp, caption:caption.text)
        _ = storageRef.putData(picData, metadata: metadata) { (metadata, error) in
            if let error = error {
                self.alerts(msg:"Error uploading: \(error)")
                return
            }
        }
        /*uploadTask.observe(.progress){[weak self](snapshot) in
         guard let tcp = snapshot.progress?.fractionCompleted else{return}
         self?.uploadProgress.progress = Float(tcp)
         if Float(tcp) == 1{
         self?.uploadProgress.isHidden = true
         
         }
         
         }*/
        self.dismiss(animated: true)
    }
    private func addPhoto(timestamp:String, caption:String?) {
        // [START add_alan_turing]
        // Add a second document with a generated ID.
        ref = db.collection("photos").addDocument(data: [
            "uid": uid ?? "",
            "storageRef": uid! + "/" + timestamp + ".jpg",
            "timestamp": timestamp,
            "caption": caption ?? "",
            "icon": false,
            "hashTag": hashTags.text ?? ""
            ])
        { err in
            if let err = err {
                self.alerts(msg:err.localizedDescription)
            } else {
                
            }
        }
    }
    func alerts(msg: String){
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { action -> Void in
            //Just dismiss the action sheet
        })
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
