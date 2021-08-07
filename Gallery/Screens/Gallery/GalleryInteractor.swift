//
//  GalleryInteractor.swift
//  Gallery
//
//  Created by Alex on 18.03.2021.
//

import Foundation
import Photos
import AVFoundation
import UIKit
import Accelerate


protocol GalleryInteractorInput {
    var photos: [Photo] { get }
    var localImages: [UIImage] { get }
    var showedImages: [UIImage] { get }
    var vectors: [[Float]] { get }
    var flat_vectors: [Float] { get }
    var isVectorReady: Bool { get }
    func getPhotos()
    func getSearchPhotos(by text: String)
    func willShowPhoto(by index: Int)
}

final class GalleryInteractor {
    
    unowned let presenter: GalleryInteractorOutput
    var networkService: NetworkServiceProtocol!
    var storeService: StoreServiceProtocol!
    var assetResults : PHFetchResult<AnyObject>!

    var photos: [Photo] = []
    var localImages: [UIImage] = []
    var showedImages: [UIImage] = []
    var vectors: [[Float]] = []
    var flat_vectors: [Float] = []
    let n = vDSP_Length(512)
    let stride = vDSP_Stride(1)
    private var nextPageUrl: String?
    private var isLoading = false
    public var isVectorReady = false
    
    var tokenizer = Tokenizer()
    
    private var CLIPTextmodule: CLIPNLPTorchModule? = nil
    
    private var CLIPImagemodule: CLIPImageTorchModule? = nil
    
    init(presenter: GalleryInteractorOutput) {
        self.presenter = presenter
        self.tokenizer.loadJsons()
        print("GalleryInteractor init")
    }
    
    deinit {
        print("GalleryInteractor deinit")
    }
    
    //MARK: - Metods
    private func appendPhotos(_ response: Response) {
        storeService.addPhotos(response.photos)
        nextPageUrl = response.nextPageUrl
        let startIndex = self.photos.count
        photos.append(contentsOf: response.photos)
        let endIndex = self.photos.count
        let indexArr = (startIndex..<endIndex).map { Int($0) }
        presenter.didAppendPhotos(at: indexArr)
    }
    
    private func updatePhotos(_ response: Response) {
        storeService.deleteAllPhotos()
        storeService.addPhotos(response.photos)
        photos = []
        photos.append(contentsOf: response.photos)
        nextPageUrl = response.nextPageUrl
        presenter.didUpdatePhotos()
    }
}

//MARK: - GalleryInteractorInput

extension GalleryInteractor: GalleryInteractorInput {
    
    func getPhotos() {
        let albumName = "test"
        var assetCollection = PHAssetCollection()
        var albumFound = Bool()
        var photoAssets = PHFetchResult<AnyObject>()
        let fetchOptions = PHFetchOptions()

        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        if let firstObject = collection.firstObject{
            //found the album
            assetCollection = firstObject
            albumFound = true
        }
        else { albumFound = false }
        _ = collection.count
        photoAssets = PHAsset.fetchAssets(in: assetCollection, options: nil) as! PHFetchResult<AnyObject>
        print(photoAssets.count)
        /* Retrieve the items in order of modification date, ascending */
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: true)]
        
        /* Then get an object of type PHFetchResult that will contain
         all our image assets */
        assetResults = PHAsset.fetchAssets(with: .image, options: options) as! PHFetchResult<AnyObject>
        isLoading = true
        // print("Found \(assetResults.count) results")
        let imageManager = PHCachingImageManager()
        assetResults.enumerateObjects{(object: AnyObject, count: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            if object is PHAsset {
                let asset = object as! PHAsset
                let imageSize = CGSize(width: asset.pixelWidth,height: asset.pixelHeight)
                /* For faster performance, and maybe degraded image */
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isSynchronous = true
                imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: PHImageContentMode.aspectFit, options: options, resultHandler: { (image: UIImage?, info:[AnyHashable:Any]?) in
                    self.localImages.append(image!)
                })
            }
        }
        self.showedImages = self.localImages
        isLoading = false
        self.presenter.didUpdatePhotos()
        DispatchQueue.global(qos: .userInitiated).async {
          // Do some time consuming task in this background thread
          // Mobile app will remain to be responsive to user actions
          print("Performing time consuming task in this background thread")
            self.CLIPTextmodule = {
                if let filePath = Bundle.main.path(forResource: "text", ofType: "pt"),
                    let module = CLIPNLPTorchModule(fileAtPath: filePath) {
                    NSLog("CLIP Text encoder loaded")
                    return module
                } else {
                    fatalError("Failed to load clip nlp model!")
                }
            }()
            self.CLIPImagemodule = {
                if let filePath = Bundle.main.path(forResource: "image", ofType: "pt"),
                    let module = CLIPImageTorchModule(fileAtPath: filePath) {
                    NSLog("CLIP Image encoder loaded")
                    return module
                } else {
                    fatalError("Failed to load clip image model!")
                }
            }()
            let vec = self.localImages.map{
                (self.CLIPImagemodule!.test_uiimagetomat(image:$0)) }
            for nsarray in vec {
                self.vectors.append(nsarray! as! [Float])
//                let tmp_vec = nsarray! as! [Double]
    //            KMeans.sharedInstance.addVector(tmp_vec)
            }
            self.isVectorReady = true
         DispatchQueue.main.async {
              print("Time consuming task has completed. From here we are allowed to update user interface.")
          }
      }
        // indexing using KMeans
//        KMeans.sharedInstance.reset()
//        KMeans.sharedInstance.clusteringNumber = 5
//        KMeans.sharedInstance.dimension = 512
//        KMeans.sharedInstance.clustering(6)
    }
    
    func getSearchPhotos(by text: String) {
        isLoading = true
        if text == "reset" || text == "Reset" {
            self.showedImages = self.localImages
            presenter.didUpdatePhotos()
            isLoading = false
            return
        }
        let token_ids = self.tokenizer.tokenize(text: text)
        let res = self.CLIPTextmodule!.encode(text: token_ids)
        let vector: [Float] = res! as! [Float]
        // Mark: K-Means
//        let f_vector: [Float] = res as! [Float]
//        var centroid_scores: [Double] = []
//        var max_centroid_id: Int = -1
//        var max_centroids_score: Double = .nan
//        for idx in 0..<KMeans.sharedInstance.finalCentroids.count {
//            let centroid = KMeans.sharedInstance.finalCentroids[idx]
//            var sim_score: Double = .nan
//            vDSP_dotprD(vector, self.stride, centroid, self.stride, &sim_score, self.n)
//            centroid_scores.append(sim_score)
//            if max_centroids_score.isNaN || sim_score > max_centroids_score {
//                max_centroids_score = sim_score
//                max_centroid_id = idx
//            }
//        }
//        var final_sim_scores: [(score: Float, id: Int)] = []
//        for vec_id in KMeans.sharedInstance.finalClusters[max_centroid_id] {
//            var sim_score: Float = .nan
//            vDSP_dotpr(f_vector, self.stride, self.vectors[vec_id], self.stride, &sim_score, self.n)
//            final_sim_scores.append((sim_score, vec_id))
//        }
//        final_sim_scores.sort { $0.score > $1.score } // sort in descending order by sim_score
//        self.showedImages = []
//        var prev_diff: Float = 0.0
//        self.showedImages.append(self.localImages[final_sim_scores[0].id])
//        for idx in 1..<final_sim_scores.count {
//            var score_diff = final_sim_scores[idx-1].score - final_sim_scores[idx].score
//            if score_diff >= prev_diff / 3 {
//                self.showedImages.append(self.localImages[final_sim_scores[idx].id])
//                prev_diff = score_diff
//            }else {
//                break
//            }
//        }
        // Mark: Linear scan
        var sim_scores: [(score: Float, id: Int)] = []
        for idx in 0..<self.vectors.count {
            var sim_score: Float = .nan
            vDSP_dotpr(vector, self.stride, self.vectors[idx], self.stride, &sim_score, self.n)
            sim_scores.append((sim_score, idx))
        }
        sim_scores.sort { $0.score > $1.score }
        self.showedImages = []
        for i in 0...2 {
            self.showedImages.append(self.localImages[sim_scores[i].id])
        }
        presenter.didUpdatePhotos()
        self.isLoading = false
    }
    
    func willShowPhoto(by index: Int) {
        if !isLoading,
           index >= photos.count - Constans.preLoadPhotoCount,
           let nextPageUrl = nextPageUrl {
            isLoading = true
            networkService.loadPhotosFrom(url: nextPageUrl) { (result) in
                switch result {
                case .failure(let error):
                    self.presenter.didCameError(error)
                case .success(let response):
                    self.appendPhotos(response)
                }
                self.isLoading = false
            }
        }
    }
}
