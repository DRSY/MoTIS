//
//  GalleryBilder.swift
//  Gallery
//
//  Created by Alex on 18.03.2021.
//

import UIKit

final class GalleryBilder {
    
    static func getGalleryVC() -> UIViewController {
        let networkManager = NetworkService()
        let storeManager = StoreService()
        let view = GalleryViewController()
        let presenter = GalleryPresenter(view: view)
        let interactor = GalleryInteractor(presenter: presenter)
        let router = GalleryRouter(view: view)
        interactor.networkService = networkManager
        interactor.storeService = storeManager
        presenter.interactor = interactor
        presenter.router = router
        view.presenter = presenter
        return view
    }
}
