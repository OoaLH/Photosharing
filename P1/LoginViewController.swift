//
//  ViewController.swift
//  P1
//
//  Created by 张翌璠 on 2020-01-11.
//  Copyright © 2020 张翌璠. All rights reserved.
//

import UIKit
import Firebase



class LoginViewController: UIViewController {
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                uid = user.uid
                self.performSegue(withIdentifier: "logged", sender: self)
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
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
        if (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue != nil {
            if view.frame.origin.y != 0 {
                view.frame.origin.y = 0
            }
        }
    }
    
    @IBAction func logIn(_ sender: UIButton) {
        guard let email = emailTextField.text, email != "" else {
            showAlert(msg: "Email can't be empty")
            return
        }
        guard let password = passwordTextField.text, password != "" else {
            showAlert(msg: "Password can't be empty")
            return
        }
        
        // [START headless_email_auth]
        Auth.auth().signIn(withEmail: email, password: password) {[unowned self] authResult, error in
            // [START_EXCLUDE]
            if let error = error {
                self.showAlert(msg: error.localizedDescription)
                return
            }
            uid = authResult?.user.uid
            print("uid" + uid!)
            // [END_EXCLUDE]
            self.performSegue(withIdentifier: "logged", sender: self)
        }
        // [END headless_email_auth]
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
}

extension UIViewController {
    func showAlert(msg: String) {
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}


