//
//  CalleryCell.swift
//  Gallery
//
//  Created by Alex on 16.02.2021.
//

import UIKit
import SDWebImage

class GalleryCell: UICollectionViewCell {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoImage: UIImage!
    @IBOutlet weak var nameLabel: UILabel!
    
    func set(photoModel: UIImage) {
        //nameLabel.text = photoModel.photographer
        photoImage = photoModel
        photoImageView.image = self.photoImage
//        photoImageView.sd_setImage(with: URL(string: photoModel.link))
    }
}
