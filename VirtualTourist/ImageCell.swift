//
//  ImageCell.swift
//  VirtualTourist
//
//  Created by Gerry Low on 2020-06-10.
//  Copyright © 2020 Gerry Low. All rights reserved.
//

import UIKit

class ImageCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    public func setImage(_ image: UIImage) {
        imageView.image = image
    }

}
