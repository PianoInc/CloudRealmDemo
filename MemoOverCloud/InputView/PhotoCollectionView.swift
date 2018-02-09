//
//  PhotoCollectionView.swift
//  Paper
//
//  Created by changi kim on 2017. 10. 12..
//  Copyright © 2017년 Piano. All rights reserved.
//

import UIKit

class PhotoCollectionView: UICollectionView {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let nib = UINib(nibName: "ImageCell", bundle: nil)
        register(nib, forCellWithReuseIdentifier: ImageCell.reuseIdentifier)
    }

}
