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
class DisplayAPic: UIViewController,UITextFieldDelegate {
    var index: Int? = nil
    var indexG: Int? = nil
    var url: String? = nil
    var width:CGFloat = 0
    var commentNum = 0
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var typedComment: UITextField!
    @IBOutlet var caption: UILabel!
    @IBOutlet var showedPic: UIImageView!
    
    @IBOutlet var hashTag: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        db.settings = FirestoreSettings()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        self.typedComment.delegate = self
        width = self.view.frame.width
        scrollView.frame = CGRect(x: 20, y: 350, width: width-40, height: self.view.frame.height-420)
        scrollView.contentSize.width = width-40
        scrollView.contentSize.height = 0
        deleteButton.isHidden = true
        if index != nil{
            deleteButton.isHidden = false
            //showedPic.image = picSet[index!]
            url = picList[index!]
        }
        else if indexG != nil{
            //showedPic.image = picSetG[indexG!]
            url = picListG[indexG!]
           
        }
        let picRef = storage.reference().child(url!)
        
        _ = picRef.getData(maxSize: 4 * 1024 * 1024) {[weak self] data, error in
            if error != nil {
                return// Uh-oh, an error occurred!
            }
            if let data = data {
                // Data for "images/island.jpg" is returned
                
                self?.showedPic.image = UIImage(data: data)!
                //picSet[staticCount] = UIImage(data: data)!//.crop()
                if self!.index != nil{
                    picSet[self!.index!] = UIImage(data: data)!
                }
                else if self!.indexG != nil{
                    picSetG[self!.indexG!] = UIImage(data: data)!
                   
                }
            }
            
        }
        db.collection("comments")
            .whereField("storageRef", isEqualTo: url!)
            .order(by: "timestamp", descending: false)
            .getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    
                    for document in querySnapshot!.documents {
                        self.addComment(username: document.data()["username"] as! String, comment:document.data()["comment"] as! String,num:self.commentNum)
                        self.commentNum += 1
                    }
                    
                }
        }
        db.collection("photos")
            .whereField("storageRef", isEqualTo: url!)
            .getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    
                    for document in querySnapshot!.documents {
                        self.caption.text = document.data()["caption"] as? String
                        self.hashTag.text = document.data()["hashTag"] as? String
                        if document.data()["uid"] as? String == uid{
                            self.deleteButton.isHidden = false
                        }
                    }
                    
                }
        }
       
        
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        
        self.view.endEditing(true)
        
        return false
    }
    
    @objc func dismissKeyboard() { view.endEditing(true)}
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 { self.view.frame.origin.y -= keyboardSize.height-400
            } }
    }
    @objc func keyboardWillHide(notification: NSNotification) { if ((notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) != nil {
        if self.view.frame.origin.y != 0 { self.view.frame.origin.y = 0
        } }
    }
    func addComment(username:String,comment:String,num:Int){
        let label = UILabel(frame: CGRect(x: 0, y: num*30, width: Int(width-40), height: 30))
        //设置label的文本
        label.text = username + ": " + comment
        //设置文字的颜色
        label.textColor = UIColor.darkGray
        scrollView.contentSize.height += 30
        //将label添加到view的子视图中
        scrollView.addSubview(label)
    }
    @IBAction func deletePhoto(_ sender: UIButton) {
        sender.isUserInteractionEnabled = false
        let storageRef = storage.reference()
        db.collection("comments")
            .whereField("storageRef", isEqualTo: url!)
            .getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    
                    for document in querySnapshot!.documents {
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
                    
                    for document in querySnapshot!.documents {
                        document.reference.delete()
                    }
                    
                }
        }
        let desertRef = storageRef.child(url!)

        // Delete the file
        desertRef.delete { error in
            if error != nil {
            // Uh-oh, an error occurred!
          } else {
            self.dismiss(animated: true)
            // File deleted successfully
          }
        }
        initial = true
        initialG = true
        
    }
    
    @IBAction func postComment(_ sender: UIButton) {
        if typedComment.text != ""{
            ref = db.collection("comments").addDocument(data: [
                "username":  uname ?? "",
                "storageRef": url ?? "",
                "comment": typedComment.text!,
                "timestamp": "\(Int(Date.timeIntervalSinceReferenceDate * 1000))"
                ])
            { err in
                if let err = err {
                    self.alerts(msg:err.localizedDescription)
                } else {
                    
                }
            }
            addComment(username: uname!, comment: typedComment.text!, num: commentNum)
            commentNum += 1
            typedComment.text = ""
        }
        
    }
    @IBAction func back(_ sender: UIButton) {
        
        self.dismiss(animated: true)
    }
    func alerts(msg: String){
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { action -> Void in
            //Just dismiss the action sheet
        })
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.navigationController != nil{
            // 在后台
            //print("在后台")
        }else{
            // 已关闭
            //print("已关闭")
            // 触发 deinit
            showedPic.image = nil
            self.view = nil
        }
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
