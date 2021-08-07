//
//  DetailViewController.swift
//  Gallery
//
//  Created by Alex on 16.02.2021.
//

import UIKit
import SDWebImage

final class DetailViewController: UIViewController {

    //MARK: - IBOutlets
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var navItem: UINavigationItem!
    
    //MARK: - Variables
    
    var photoViewModel: PhotoViewModel?
    var image: UIImage?

    
    //MARK: - LiveCycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        if let photoViewModel = photoViewModel {
//            navItem.title = ""
//            photoImageView.sd_setImage(with: URL(string: photoViewModel.link))
//            //dateLabel.text = photoViewModel.date
//        }
        if let image = image {
            navItem.title = ""
            photoImageView.image = image
            //dateLabel.text = photoViewModel.date
        }
    }
   
    //MARK: - IBActions
    
    @IBAction func actionButtonPress(_ sender: UIBarButtonItem) {
        guard let image = photoImageView.image else { return }
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityController.popoverPresentationController?.barButtonItem = sender
        activityController.popoverPresentationController?.permittedArrowDirections = .any
        present(activityController, animated: true, completion: nil)
    }
    
    @IBAction func closeButtonPress(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

}
