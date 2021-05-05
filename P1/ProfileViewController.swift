//
//  profile.swift
//  P1
//
//  Created by 张翌璠 on 2020-01-12.
//  Copyright © 2020 张翌璠. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import Photos

class ProfileViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet var bioLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var iconImageView: UIImageView!
    
    var screenWidth: CGFloat = 0
    var screenHeight: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let storageRef = storage.reference()
        db.settings = FirestoreSettings()
        
        screenWidth = view.frame.width
        screenHeight = view.frame.height
        
        guard let uid = uid else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        let iconRef = storageRef.child(uid + "/displayPic.jpg")
        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        if iconPic == nil {
            iconRef.getData(maxSize: 1 * 1024 * 1024) { [unowned self] data, error in
                if error != nil {
                    // Uh-oh, an error occurred!
                    return
                } else {
                    // Data for "images/island.jpg" is returned
                    iconPic = UIImage(data: data!)
                    iconImageView.image = iconPic
                }
            }
        }
        else {
            iconImageView.image = iconPic
        }
        
        var inputBio = ""
        db.document("users/" + uid).getDocument { [unowned self] docSnapshot, error in
            if let docSnapshot = docSnapshot, docSnapshot.exists {
                inputBio = docSnapshot.data()?["Bio"] as? String ?? ""
                username = docSnapshot.data()?["Username"] as? String ?? ""
            }
            bioLabel.text = inputBio
            usernameLabel.text = username
        }
        
        loadPics()
        
        view.addSubview(picCollectionView)
        view.sendSubviewToBack(picCollectionView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        picCollectionView.reloadData()
    }
    
    func loadPics() {
        guard let uid = uid else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        db.collection("photos")
            .whereField("uid", isEqualTo: uid)
            .whereField("storageRef", isLessThan: uid + "/displayPic.jpg")
            .order(by: "storageRef", descending: true)
            .getDocuments { [unowned self] querySnapshot, err in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    guard let querySnapshot = querySnapshot else { return }
                    
                    picRefs.removeAll()
                    picImages.removeAll()
                    
                    for document in querySnapshot.documents {
                        picRefs.append(document.data()["storageRef"] as! String)
                        picImages.append(UIImage(systemName: "photo")!)
                        
                        let index = picRefs.count - 1
                        let picRef = storage.reference().child(picRefs[index])
                        _ = picRef.getData(maxSize: 4 * 1024 * 1024) { [unowned self] data, error in
                            if error != nil {
                                print("error occurred")
                                return
                            }
                            if let data = data {
                                picImages[index] = UIImage(data: data)!
                                picCollectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
                            }
                        }
                    }
                    
                    picCollectionView.reloadData()
                }
            }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showInfo", let c = segue.destination as? PicDetailViewController {
            c.index = sender as? Int
            c.indexG = nil
            c.deleteAndRefreshBlock = {[unowned self] () -> Void in
                loadPics()
            }
        }
        if segue.identifier == "caption", let c = segue.destination as? CaptionViewController {
            c.index = sender as? Int
            c.indexG = nil
        }
        if segue.identifier == "goGlobal", let c = segue.destination as? GlobalViewController {
            c.refreshBlock = {[unowned self] () -> Void in
                loadPics()
            }
        }
    }
    
    @IBAction func uploadPhoto(_ sender: UIButton) {
        selectCamera()
    }
    
    @IBAction func enterGlobalMode(_ sender: UIButton) {
        performSegue(withIdentifier: "goGlobal", sender: nil)
    }
    
    @IBAction func logout(_ sender: UIButton) {
        picRefs.removeAll()
        picImages.removeAll()
        picRefsGlobal.removeAll()
        picImagesGlobal.removeAll()
        iconPic = nil
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
            return
        }
        let alert = UIAlertController(title: "Successful", message: "You have been logged out", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { action -> Void in
            var rootVC = self.presentingViewController
            while let parent = rootVC?.presentingViewController {
                rootVC = parent
            }
            //释放所有下级视图
            rootVC?.dismiss(animated: true, completion: nil)
        })
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    lazy var picCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout.init()
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        layout.itemSize = CGSize.init(width: (screenWidth - 40) / 3, height: (screenWidth - 40) / 3)
        let view = UICollectionView.init(frame: CGRect.init(x: 15, y: 230, width: screenWidth - 30, height: screenHeight - 230), collectionViewLayout: layout)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.backgroundColor = UIColor.white
        view.register(HomePicCell.self, forCellWithReuseIdentifier: "cellID")
        return view
    }()
}

extension ProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return picRefs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellID", for: indexPath) as! HomePicCell
        cell.pic = picImages[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showInfo", sender: indexPath.row)
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // get the picture
        guard let pickedImage = info[UIImagePickerController.InfoKey.editedImage]
                as? UIImage else {
            return
        }
        picker.dismiss(animated: true) {
            guard let picData = pickedImage.jpegData(compressionQuality: 0.7) else { return }
            var newImages = [UIImage(data: picData)!]
            newImages.append(contentsOf: picImages)
            picImages = newImages
            self.performSegue(withIdentifier: "caption", sender: picImages.count)
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
                }
                else if states == .restricted || states == .denied {
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

