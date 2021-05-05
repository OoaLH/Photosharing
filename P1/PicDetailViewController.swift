//
//  DisplayAPic.swift
//  P1
//
//  Created by 张翌璠 on 2020-01-19.
//  Copyright © 2020 张翌璠. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

class PicDetailViewController: UIViewController {
    
    var index: Int? = nil
    var indexG: Int? = nil
    var url: String? = nil
    var width:CGFloat = 0
    var commentNum = 0
    
    var deleteAndRefreshBlock: (() -> Void)?
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var commentTextField: UITextField!
    @IBOutlet var captionLabel: UILabel!
    @IBOutlet var picImageView: UIImageView!
    @IBOutlet var hashTagLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        db.settings = FirestoreSettings()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        width = view.frame.width
        scrollView.frame = CGRect(x: 20, y: 380, width: width - 40, height: view.frame.height - 450)
        scrollView.contentSize.width = width - 40
        scrollView.contentSize.height = 0
        
        deleteButton.isHidden = true
        
        if index != nil {
            deleteButton.isHidden = false
            url = picRefs[index!]
        }
        else if indexG != nil {
            url = picRefsGlobal[indexG!]
            
        }
        let picRef = storage.reference().child(url!)
        _ = picRef.getData(maxSize: 4 * 1024 * 1024) { [unowned self] data, error in
            if error != nil {
                return
            }
            if let data = data {
                // Data for "images/island.jpg" is returned
                picImageView.image = UIImage(data: data)!
                //picSet[staticCount] = UIImage(data: data)!//.crop()
                if index != nil {
                    picImages[index!] = UIImage(data: data)!
                }
                else if indexG != nil {
                    picImagesGlobal[indexG!] = UIImage(data: data)!
                }
            }
            
        }
        
        db.collection("comments")
            .whereField("storageRef", isEqualTo: url!)
            .order(by: "timestamp", descending: false)
            .getDocuments { [unowned self] (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    for document in querySnapshot.documents {
                        addComment(username: document.data()["username"] as! String, comment: document.data()["comment"] as! String, num: self.commentNum)
                        commentNum += 1
                    }
                }
            }
        
        db.collection("photos")
            .whereField("storageRef", isEqualTo: url!)
            .getDocuments { [unowned self] (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    for document in querySnapshot.documents {
                        captionLabel.text = document.data()["caption"] as? String
                        hashTagLabel.text = document.data()["hashTag"] as? String
                        if document.data()["uid"] as? String == uid {
                            deleteButton.isHidden = false
                        }
                    }
                }
            }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.origin.y == 0 {
                view.frame.origin.y -= keyboardSize.height-400
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if ((notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y = 0
            }
        }
    }
    
    func addComment(username: String, comment: String, num: Int) {
        let label = UILabel(frame: CGRect(x: 0, y: num * 30, width: Int(width - 40), height: 30))
        //设置label的文本
        label.text = username + ": " + comment
        //设置文字的颜色
        label.textColor = UIColor.darkGray
        scrollView.contentSize.height += 30
        //将label添加到view的子视图中
        scrollView.addSubview(label)
    }
    
    @IBAction func deletePhoto(_ sender: UIButton) {
        let storageRef = storage.reference()
        db.collection("comments")
            .whereField("storageRef", isEqualTo: url!)
            .getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    for document in querySnapshot.documents {
                        document.reference.delete()
                    }
                }
            }
        
        db.collection("photos")
            .whereField("storageRef", isEqualTo: url!)
            .getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    guard let querySnapshot = querySnapshot else {
                        return
                    }
                    for document in querySnapshot.documents {
                        document.reference.delete()
                    }
                    
                }
            }
        
        let desertRef = storageRef.child(url!)
        // Delete the file
        desertRef.delete { [unowned self] error in
            if error != nil {
                // Uh-oh, an error occurred!
            } else {
                dismiss(animated: true)
                deleteAndRefreshBlock?()
                // File deleted successfully
            }
        }
    }
    
    @IBAction func postComment(_ sender: UIButton) {
        if commentTextField.text != "" {
            ref = db.collection("comments").addDocument(data: [
                "username":  username ?? "",
                "storageRef": url ?? "",
                "comment": commentTextField.text!,
                "timestamp": "\(Int(Date.timeIntervalSinceReferenceDate * 1000))"
            ])
            { [unowned self] err in
                if let err = err {
                    showAlert(msg: err.localizedDescription)
                } else {
                    
                }
            }
            addComment(username: username!, comment: commentTextField.text!, num: commentNum)
            commentNum += 1
            commentTextField.text = ""
        }
        
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
}

extension PicDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
