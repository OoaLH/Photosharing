//
//  ViewController.swift
//  P1
//
//  Created by 张翌璠 on 2020-01-11.
//  Copyright © 2020 张翌璠. All rights reserved.
//

import UIKit
import Firebase



class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var inputemail: UITextField!
    @IBOutlet var inputpw: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //self.view.endEditing(true)
        Auth.auth().addStateDidChangeListener { (auth, user) in
            
            if user == nil {
                
                
            } else {
                uid = user?.uid
                
                self.performSegue(withIdentifier: "logged", sender: self)
                
            }
            
        }
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        self.inputemail.delegate = self
        self.inputpw.delegate = self
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
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
    func alerts(msg: String){
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { action -> Void in
            //Just dismiss the action sheet
        })
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func logIn(_ sender: UIButton) {
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
        
        // [START headless_email_auth]
        Auth.auth().signIn(withEmail: email!, password: password!) {[weak self] authResult, error in
            guard let strongSelf = self else { return }
            // [START_EXCLUDE]
            if let error = error {
                strongSelf.alerts(msg: error.localizedDescription)
                return
            }
            uid = authResult?.user.uid
            print("uid" + uid!)
            //self?.dismiss(animated: true)
            //self!.performSegue(withIdentifier: "logged", sender: self)
            // [END_EXCLUDE]
            self!.performSegue(withIdentifier: "logged", sender: self)
        }
        // [END headless_email_auth]
        
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





