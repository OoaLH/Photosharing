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

class GlobalViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    var screenWidth:CGFloat = 0
    var screenHeight:CGFloat = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        db.settings = FirestoreSettings()
        screenWidth = self.view.frame.width
        screenHeight = self.view.frame.height
        // Do any additional setup after loading the view.
        if initialG == true{
            loading()
        }
        else{
            self.view.viewWithTag(2)?.removeFromSuperview()
            createPicsView()
        }
    }
    func numberOfSections(in collectionView:UICollectionView) ->Int {
        
        return 1
        
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return picListG.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellIDG", for: indexPath) as! GlobalPics
        if initialG == true && picSetG[indexPath.row] == UIImage(systemName: "photo")!{
            let picRef = storage.reference().child(picListG[indexPath.row])
            
            _ = picRef.getData(maxSize: 4 * 1024 * 1024) {[weak self] data, error in
                if error != nil {
                    print("error occurred")
                    return// Uh-oh, an error occurred!
                }
                if let data = data {
                    cell.pic = UIImageView.init(frame:CGRect.init(x: 0, y: 0, width: cell.bounds.size.width, height: cell.bounds.size.height))
                    picSetG[indexPath.row] = UIImage(data: data)!
                    cell.pic!.image = picSetG[indexPath.row]
                    //print(" 66666"+String(staticCount))
                    cell.addSubview(cell.pic!)
                }
            
            }
        }
        else {//if initialG == false{
            cell.pic = UIImageView.init(frame:CGRect.init(x: 0, y: 0, width: cell.bounds.size.width, height: cell.bounds.size.height))
            cell.pic!.image = picSetG[indexPath.row]
            cell.addSubview(cell.pic!)
        }
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //initialG = false
        self.performSegue(withIdentifier: "showInfoG", sender: indexPath.row)
    }
    func loading(){
        
        db.collection("photos")
            .whereField("icon", isEqualTo: false)
            .order(by: "timestamp", descending: true)
            .getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    //downloadedNumberG = 0
                    //countG = 0
                    picListG.removeAll()
                    picSetG.removeAll()
                    
                    for document in querySnapshot!.documents {
                        
                        picListG.append(document.data()["storageRef"] as! String)
                        
                        //downloadedNumberG += 1
                        picSetG.append(UIImage(systemName: "photo")!)
                        
                        
                    }
                    //initial = false
                    self.createPicsView()
                }
        }
        
    }
    func createPicsView(){
        
        let layout = UICollectionViewFlowLayout.init()
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        layout.itemSize = CGSize.init(width: screenWidth-30, height:screenWidth-30)
        
        let collectionView = UICollectionView.init(frame: CGRect.init(x: 15, y: 100, width: screenWidth-30, height: screenHeight-100), collectionViewLayout: layout)
        
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.white
        collectionView.tag = 2
        self.view.addSubview(collectionView)
        self.view.sendSubviewToBack(collectionView)
        collectionView.register(GlobalPics.classForCoder() ,forCellWithReuseIdentifier: "cellIDG")
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "captionG", let c = segue.destination as? CaptionViewController{
            c.indexG = sender as? Int
            c.index = nil
        }
        if segue.identifier == "showInfoG", let c = segue.destination as? DisplayAPic {
            c.indexG = sender as? Int
            c.index = nil
        }
    }
    @IBAction func uploadPic(_ sender: UIButton) {
        initialG = false
        sender.isUserInteractionEnabled = false
        sender.tintColor = UIColor.systemGray
        self.selectCamera()
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // get the picture
        
        guard let pickedImage = info[UIImagePickerController.InfoKey.editedImage]
            as? UIImage else{
                return
        }
        picker.dismiss(animated: true){
            guard let picData = pickedImage.jpegData(compressionQuality: 0.7) else { return }
            var newImage = [UIImage(data: picData)!]
            newImage.append(contentsOf: picSetG)
            picSetG = newImage
            
            self.performSegue(withIdentifier: "captionG", sender: picSetG.count)
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
    
    func alerts(msg: String){
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { action -> Void in
            //Just dismiss the action sheet
        })
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    @IBAction func back(_ sender: UIButton) {
        //initialG = false
        self.dismiss(animated: true)
    }
    @IBAction func logout(_ sender: UIButton) {
        //downloadedNumber = 0
        initial = true
        //count = 0
        picList.removeAll()
        picSet.removeAll()
        //downloadedNumberG = 0
        initialG = true
        //countG = 0
        picListG.removeAll()
        picSetG.removeAll()
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
        }else{
            
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
