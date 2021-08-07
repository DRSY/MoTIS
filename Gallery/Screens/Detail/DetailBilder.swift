//
//  DetailBilder.swift
//  Gallery
//
//  Created by Alex on 18.03.2021.
//

import UIKit

class DetailBilder {
    
//    static func getDetailVC(by photoViewModel: PhotoViewModel) -> UIViewController {
//        let view = DetailViewController()
//        view.modalPresentationStyle = .fullScreen
//        view.photoViewModel = photoViewModel
//        return view
//    }
    
    static func getDetailVC(by image: UIImage) -> UIViewController {
        let view = DetailViewController()
        view.modalPresentationStyle = .fullScreen
        view.image = image
        return view
    }
}
