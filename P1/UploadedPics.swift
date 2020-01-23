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

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.createCell(staticCount: count)
        count += 1
        
    }

    public func createCell(staticCount:Int) -> Void {
        
        
        if initial{
            if staticCount >= downloadedNumber{
                //initial = false
                return
            }
            else{
                //print("what"+String(staticCount)+String(picList.count)+String(downloadedNumber))
            let picRef = storage.reference().child(picList[staticCount])
            
                _ = picRef.getData(maxSize: 4 * 1024 * 1024) {[weak self] data, error in
                    if error != nil {
                    return// Uh-oh, an error occurred!
                }
                if let data = data {
                    // Data for "images/island.jpg" is returned
                    self!.pic = UIImageView.init(frame:CGRect.init(x: 0, y: 0, width: self!.bounds.size.width, height: self!.bounds.size.height))
                    picSet[staticCount] = UIImage(data: data,scale:10)!
                    let size = min(picSet[staticCount].cgImage!.width,picSet[staticCount].cgImage!.height)
                    let cropZone = CGRect(x: 0, y: 0, width: size, height: size)
                    self!.pic!.image = UIImage(cgImage: (picSet[staticCount].cgImage?.cropping(to:cropZone))!,scale: 4,orientation: UIImage.Orientation.up)
                    picSet[staticCount] = (self!.pic!.image ?? nil)!
                    self!.addSubview(self!.pic!)
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

}
