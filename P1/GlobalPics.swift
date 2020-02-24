//
//  GlobalPics.swift
//  P1
//
//  Created by 张翌璠 on 2020-02-06.
//  Copyright © 2020 张翌璠. All rights reserved.
//

import UIKit

class GlobalPics: UICollectionViewCell {
    var pic:UIImageView?
    
   /* override init(frame: CGRect) {
        super.init(frame: frame)
        self.createCell(staticCount: countG)
        countG += 1
        
    }
    
    func createCell(staticCount:Int) -> Void {
        
        
        if initialG{
            if staticCount >= downloadedNumberG{
                
                return
            }
            else{
                let picRef = storage.reference().child(picListG[staticCount])
                
                _ = picRef.getData(maxSize: 4 * 1024 * 1024) {[weak self] data, error in
                    if error != nil {
                        print("error occurred")
                        return// Uh-oh, an error occurred!
                    }
                    if let data = data {
                        self?.pic = UIImageView.init(frame:CGRect.init(x: 0, y: 0, width: self!.bounds.size.width, height: self!.bounds.size.height))
                        picSetG[staticCount] = UIImage(data: data)!
                        self?.pic!.image = picSetG[staticCount]
                        //print(" 66666"+String(staticCount))
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
