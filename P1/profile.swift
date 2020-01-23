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

class profile: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var uploadProgress: UIProgressView!
    @IBOutlet var bio: UILabel!
    @IBOutlet var username: UILabel!
    
    @IBOutlet var icon: UIImageView!
    
    
    @IBOutlet var uploadButton: UIButton!
    
    //var pickedImage: UIImage? = nil
    override func viewDidLoad(){
        super.viewDidLoad()
        uploadProgress.isHidden = true
        var inputbio : String?
        var name : String?
        let storageRef = storage.reference()
        db.settings = FirestoreSettings()
        // [END setup]
        
        
        let iconRef = storageRef.child(uid! + "/displayPic.jpg")
        
        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        if iconPic == nil{
        iconRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if error != nil {
                // Uh-oh, an error occurred!
                return
            } else {
                // Data for "images/island.jpg" is returned
                iconPic = UIImage(data: data!)
                self.icon.image = iconPic
            }
            }}
        else{
            self.icon.image = iconPic
        }
        db.document("users/" + uid!).getDocument{(docSnapshot, error) in
            if let docSnapshot = docSnapshot, docSnapshot.exists{
                inputbio = docSnapshot.data()!["Bio"] as? String ?? ""
                name = docSnapshot.data()!["Username"] as? String ?? ""
            }
            self.bio.text = inputbio
            self.username.text = name
        }
        
        if initial{
        loading()
        }
        else{
            self.view.viewWithTag(1)?.removeFromSuperview()
            createPicsView()
        }
    }
    func loading(){

        db.collection("photos")
                  .whereField("uid", isEqualTo: uid!)
                  .whereField("storageRef", isLessThan: uid! + "/displayPic.jpg")
                  .order(by: "storageRef", descending: true)
                  .getDocuments { (querySnapshot, err) in
                      if let err = err {
                          print("Error getting documents: \(err)")
                      } else {
                        downloadedNumber = 0
                        count = 0
                        picList.removeAll()
                        picSet.removeAll()
                        //initial = true
                          for document in querySnapshot!.documents {
                              picList.append(document.data()["storageRef"] as! String)
                              //"\(document.documentID) => \(document.data())")
                              picSet.append(UIImage(systemName: "photo")!)
                              //print(picList)
                              downloadedNumber += 1
                          }
                          self.createPicsView()
                      }
              }
        
    }
    func createPicsView(){
        
        let layout = UICollectionViewFlowLayout.init()
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        layout.itemSize = CGSize.init(width: 115, height:115)
        
        let collectionView = UICollectionView.init(frame: CGRect.init(x: 12, y: 178, width: 350, height: 469), collectionViewLayout: layout)
        
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.white
        collectionView.tag = 1
        self.view.addSubview(collectionView)
        self.view.sendSubviewToBack(collectionView)
        collectionView.register(UploadedPics.classForCoder() ,forCellWithReuseIdentifier: "cellID")
        //print("count = "+String(picList.count))
        
    }
    func numberOfSections(in collectionView:UICollectionView) ->Int {
        
        return 1
        
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return picList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellID", for: indexPath) as! UploadedPics
        if initial == false{
            //let size = min(picSet[indexPath.row].cgImage!.width,picSet[indexPath.row].cgImage!.height)
            //let cropZone = CGRect(x: 0, y: 0, width: size, height: size)
            //cell.pic!.image = UIImage(cgImage: (picSet[indexPath.row].cgImage?.cropping(to:cropZone))!,scale: 4,orientation: UIImage.Orientation.up)
            cell.pic!.image = picSet[indexPath.row]
            //print("count="+String(indexPath.row))
        }
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        self.performSegue(withIdentifier: "showInfo", sender: indexPath.row)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showInfo", let c = segue.destination as? DisplayAPic {
            c.index = sender as? Int
        }
       
    }
    @IBAction func uploadPhoto(_ sender: UIButton) {
        sender.isUserInteractionEnabled = false
        sender.tintColor = UIColor.systemGray
        self.selectCamera()
    }
    
    

    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // get the picture
        
        guard let pickedImage = info[UIImagePickerController.InfoKey.originalImage]
                as? UIImage else{
                    return
        }
        picker.dismiss(animated: true){
            self.uploadProgress.isHidden = false
            let timestamp = "\(Int(Date.timeIntervalSinceReferenceDate * 1000))"
            let path = [uid! + "/" + timestamp + ".jpg"]
            
            let storageRef = storage.reference(withPath: uid! + "/" + timestamp + ".jpg")
            guard let picData = pickedImage.jpegData(compressionQuality: 0.6) else { return }
            let size = min(UIImage(data: picData,scale:10)!.cgImage!.width,UIImage(data: picData,scale:10)!.cgImage!.height)
            var newImage = [UIImage(cgImage: (UIImage(data: picData,scale:10)!.cgImage?.cropping(to:CGRect(x: 0, y: 0, width: size, height: size)))!,scale: 10,orientation: UIImage.Orientation.up)]
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            newImage.append(contentsOf: picSet)
            picSet = newImage
            picList = path + picList
            initial = false
            self.addPhoto(timestamp:timestamp)
            let uploadTask = storageRef.putData(picData, metadata: metadata) { (metadata, error) in
                if let error = error {
                    self.alerts(msg:"Error uploading: \(error)")
                    return
                }
            }
            uploadTask.observe(.progress){[weak self](snapshot) in
                guard let tcp = snapshot.progress?.fractionCompleted else{return}
                self?.uploadProgress.progress = Float(tcp)
                if Float(tcp) == 1{
                    self?.uploadProgress.isHidden = true
                    self?.uploadButton.isUserInteractionEnabled = true
                    self?.uploadButton.tintColor = UIColor.systemBlue
                }
                
            }
            self.view.viewWithTag(1)?.removeFromSuperview()
            
            self.createPicsView()
        
        }
        //picker.viewDidDisappear(animated: true)
        
            
        //}
        
    }
    private func addPhoto(timestamp:String) {
        // [START add_alan_turing]
        // Add a second document with a generated ID.
        ref = db.collection("photos").addDocument(data: [
            "uid": uid ?? "",
            "storageRef": uid! + "/" + timestamp + ".jpg",
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
                cameraPicker.allowsEditing = false//true
                cameraPicker.sourceType = .camera
                //present
                self.present(cameraPicker, animated: true, completion: nil)
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
    
    @IBAction func logout(_ sender: UIButton) {
        downloadedNumber = 0
        initial = true
        count = 0
        picList.removeAll()
        picSet.removeAll()
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
    deinit{print("已关闭")}
}

