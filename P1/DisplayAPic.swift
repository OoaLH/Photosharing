//
//  DisplayAPic.swift
//  P1
//
//  Created by 张翌璠 on 2020-01-19.
//  Copyright © 2020 张翌璠. All rights reserved.
//

import UIKit

class DisplayAPic: UIViewController {
    var index: Int? = nil
    @IBOutlet var downloadProgress: UIProgressView!
    @IBOutlet var showedPic: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        let picRef = storage.reference().child(picList[index!])
        downloadProgress.isHidden = false
        let downloadTask = picRef.getData(maxSize: 4 * 1024 * 1024) {[weak self] data, error in
                if error != nil {
                return// Uh-oh, an error occurred!
            }
            if let data = data {
                // Data for "images/island.jpg" is returned
                self!.showedPic.image = UIImage(data: data)!
            }
            }
        downloadTask.observe(.progress){[weak self](snapshot) in
            guard let tcp = snapshot.progress?.fractionCompleted else{ return }
            self?.downloadProgress.progress = Float(tcp)
            if Float(tcp) == 1{
                self?.downloadProgress.isHidden = true
            }
        }
        //print("path1=" + String(index!))
        // Do any additional setup after loading the view.
        initial = false
    }
    
    @IBAction func back(_ sender: UIButton) {
        self.dismiss(animated: true){
            //self.performSegue(withIdentifier: "back", sender: self)
        }
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
