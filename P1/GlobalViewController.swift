//
//  GlobalViewController.swift
//  P1
//
//  Created by 张翌璠 on 2020-02-05.
//  Copyright © 2020 张翌璠. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import Photos

class GlobalViewController: UIViewController, UINavigationControllerDelegate {
    
    var screenWidth: CGFloat = 0
    var screenHeight: CGFloat = 0
    var refreshBlock: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        db.settings = FirestoreSettings()
        
        screenWidth = view.frame.width
        screenHeight = view.frame.height
        
        loadPics()
        
        view.addSubview(picCollectionView)
        view.sendSubviewToBack(picCollectionView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        picCollectionView.reloadData()
    }
    
    func loadPics() {
        db.collection("photos")
            .whereField("icon", isEqualTo: false)
            .order(by: "timestamp", descending: true)
            .getDocuments { [unowned self] (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    guard let querySnapshot = querySnapshot else { return }
                    
                    picRefsGlobal.removeAll()
                    picImagesGlobal.removeAll()
                    
                    for document in querySnapshot.documents {
                        picRefsGlobal.append(document.data()["storageRef"] as! String)
                        picImagesGlobal.append(UIImage(systemName: "photo")!)
                        
                        let index = picRefsGlobal.count - 1
                        let picRef = storage.reference().child(picRefsGlobal[index])
                        _ = picRef.getData(maxSize: 4 * 1024 * 1024) { [unowned self] data, error in
                            if error != nil {
                                print("error occurred")
                                return
                            }
                            if let data = data {
                                print("123123")
                                picImagesGlobal[index] = UIImage(data: data)!
                                picCollectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
                            }
                        }
                    }
                    
                    picCollectionView.reloadData()
                }
            }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "captionG", let c = segue.destination as? CaptionViewController {
            c.indexG = sender as? Int
            c.index = nil
        }
        if segue.identifier == "showInfoG", let c = segue.destination as? PicDetailViewController {
            c.indexG = sender as? Int
            c.index = nil
            c.deleteAndRefreshBlock = {[unowned self] () -> Void in
                loadPics()
                refreshBlock?()
            }
        }
    }
    
    @IBAction func uploadPic(_ sender: UIButton) {
        selectCamera()
    }
    
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
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
            //Just dismiss the action sheet
        })
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    lazy var picCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout.init()
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        layout.itemSize = CGSize.init(width: screenWidth - 30, height: screenWidth - 30)
        let view = UICollectionView.init(frame: CGRect.init(x: 15, y: 130, width: screenWidth - 30, height: screenHeight - 130), collectionViewLayout: layout)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.backgroundColor = UIColor.white
        view.register(HomePicCell.self, forCellWithReuseIdentifier: "cellIDGlobal")
        return view
    }()
}

extension GlobalViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return picRefsGlobal.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellIDGlobal", for: indexPath) as! HomePicCell
        cell.pic = picImagesGlobal[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showInfoG", sender: indexPath.row)
    }
}

extension GlobalViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // get the picture
        guard let pickedImage = info[UIImagePickerController.InfoKey.editedImage]
                as? UIImage else {
            return
        }
        picker.dismiss(animated: true) {
            guard let picData = pickedImage.jpegData(compressionQuality: 0.7) else { return }
            var newImage = [UIImage(data: picData)!]
            newImage.append(contentsOf: picImagesGlobal)
            picImagesGlobal = newImage
            self.performSegue(withIdentifier: "captionG", sender: picImagesGlobal.count)
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
