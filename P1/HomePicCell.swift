//
//  UploadedPics.swift
//  P1
//
//  Created by 张翌璠 on 2020-01-18.
//  Copyright © 2020 张翌璠. All rights reserved.
//

import UIKit


class HomePicCell: UICollectionViewCell {
    var pic: UIImage? {
        didSet {
            picView.image = pic
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(picView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var picView: UIImageView = {
        let view = UIImageView()
        view.frame = contentView.frame
        view.image = UIImage(systemName: "photo")
        return view
    }()
}
