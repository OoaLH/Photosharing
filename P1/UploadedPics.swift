//
//  UploadedPics.swift
//  P1
//
//  Created by 张翌璠 on 2020-01-18.
//  Copyright © 2020 张翌璠. All rights reserved.
//

import UIKit


class UploadedPics: UICollectionViewCell {
    var pic:UIImageView?
    
   /* override init(frame: CGRect) {
        super.init(frame: frame)
        self.createCell(staticCount: count)
        count += 1
        
    }
    
    func createCell(staticCount:Int) -> Void {
        
        
        if initial{
            if staticCount >= downloadedNumber{
                //initial = false
                return
            }
            else{
                let picRef = storage.reference().child(picList[staticCount])
                
                _ = picRef.getData(maxSize: 4 * 1024 * 1024) {[weak self] data, error in
                    if error != nil {
                        return// Uh-oh, an error occurred!
                    }
                    if let data = data {
                        // Data for "images/island.jpg" is returned
                        self?.pic = UIImageView.init(frame:CGRect.init(x: 0, y: 0, width: self!.bounds.size.width, height: self!.bounds.size.height))
                        //picSet.append(UIImage(data: data)!)
                        picSet[staticCount] = UIImage(data: data)!//.crop()
                        //print( "indexpath" + String(staticCount) + String(picSet.count))
                        self?.pic!.image = picSet[staticCount]
                        self?.addSubview(self!.pic!)
                    }
                    
                }
                
            }
        }
        else{
            self.pic = UIImageView.init(frame:CGRect.init(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
            self.addSubview(self.pic!)
        }
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    */
}
