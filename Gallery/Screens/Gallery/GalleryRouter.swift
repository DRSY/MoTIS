//
//  GalleryRouter.swift
//  Gallery
//
//  Created by Alex on 17.02.2021.
//

import UIKit

protocol GalleryRouterProtocol {
    func showDetail(by image: UIImage)
}

final class GalleryRouter {
    
    unowned let view: UIViewController
    
    init(view: UIViewController) {
        self.view = view
    }
}

//MARK: - GalleryRouterProtocol

extension GalleryRouter: GalleryRouterProtocol {
    
    func showDetail(by image: UIImage) {
        let detailVC = DetailBilder.getDetailVC(by: image)
        view.present(detailVC, animated: true)
    }
}
