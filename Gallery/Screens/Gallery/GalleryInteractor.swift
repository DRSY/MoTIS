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
import Cereal

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
    var double_vectors: [[Double]] = []

    var flat_vectors: [Float] = []
    let n = vDSP_Length(512)
    let stride = vDSP_Stride(1)
    private var nextPageUrl: String?
    private var isLoading = false
    public var isVectorReady = false
    
    var tokenizer = Tokenizer()
    
    private var CLIPTextmodule: CLIPNLPTorchModule? = nil
    private var IndexModule: IndexingModule? = nil;

    
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
        let albumName = "Test2"
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
        /* Retrieve the items in order of modification date, ascending */
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: true)]
        assetResults = PHAsset.fetchAssets(with: .image, options: options) as! PHFetchResult<AnyObject>
        isLoading = true
        let imageManager = PHCachingImageManager()
        var flags: Array<Bool> = []
        var done: Bool = false
        assetResults.enumerateObjects{ [self](object: AnyObject, count: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            if object is PHAsset {
                let asset = object as! PHAsset
//                let imageSize = CGSize(width: asset.pixelWidth,height: asset.pixelHeight)
                let imageSize = CGSize(width: 22,height: 22)

                /* For faster performance, and maybe degraded image */
                let options = PHImageRequestOptions()
                options.deliveryMode = .fastFormat
                flags.append(false)
//                options.isSynchronous = true
                if (count == assetResults.count-1) {
                    done = true
                }
                let idx: Int = flags.count-1
//                imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: PHImageContentMode.aspectFit, options: options, resultHandler: { (image: UIImage?, info:[AnyHashable:Any]?) in
//                    self.showedImages.append(image!)
//                })
                imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .default, options: options, resultHandler: { (image: UIImage?, info:[AnyHashable:Any]?) in
                    self.localImages.append(image!)
                    flags[idx] = true
                })
            }
        }
//        self.localImages = []
//        self.showedImages = self.localImages
//        self.isLoading = false
//        self.presenter.didUpdatePhotos()
        
        DispatchQueue.global(qos: .userInitiated).async {
            while done == false {}
            while true {
                var exit_:Bool = true
                for val in flags {
                    if (val==false) {
                        exit_ = false
                        break
                    }
                }
                if(exit_==true) {
                    break
                }
            }
            DispatchQueue.main.async {

                self.showedImages = self.localImages
                self.isLoading = false
                self.presenter.didUpdatePhotos()
            }
          // Mobile app will remain to be responsive to user actions
            self.CLIPTextmodule = {
                if let filePath = Bundle.main.path(forResource: "text", ofType: "pt"),
                    let module = CLIPNLPTorchModule(fileAtPath: filePath) {
                    NSLog("CLIP Text encoder loaded")
                    return module
                } else {
                    fatalError("Failed to load clip nlp model!")
                }
            }()

            //check if index file exists
            let fileManager = FileManager.default
            let filePath:String = NSHomeDirectory() + "/Documents/kmeans.plist"
            let vec_filePath:String = NSHomeDirectory() + "/Documents/vectors.plist"
            let exist = fileManager.fileExists(atPath: filePath)
            let vec_exist = fileManager.fileExists(atPath: vec_filePath)
            let annoy_index_exist = fileManager.fileExists(atPath: "/tmp/tree")
            if exist == true && vec_exist == true && annoy_index_exist==true{
                self.IndexModule = IndexingModule()
//                var dictionary:NSMutableDictionary = [:]
//                dictionary = NSMutableDictionary(contentsOfFile: filePath)!
//                 de-serialize images' vectors
//                let N = dictionary["N"] as! Int
//                let vectors_data: Data = try! Data(contentsOf: URL(fileURLWithPath: vec_filePath))
//                var decoder = try! CerealDecoder(data: vectors_data)
//                for i in 0..<N {
//                    self.double_vectors.append(try! decoder.decode(key: String(i))!)
//                }
                // restore KMeans index's metadata, including:
//                KMeans.sharedInstance.vectors = self.double_vectors
//                KMeans.sharedInstance.clusteringNumber = dictionary["K"] as! Int
//                KMeans.sharedInstance.finalClusters = dictionary["clusters"] as! [[Int]]
//                KMeans.sharedInstance.finalCentroids = dictionary["centroids"] as! [[Double]]
            }else {
                if(annoy_index_exist) {
                    try! fileManager.removeItem(atPath: "/tmp/tree")
                }
                self.CLIPImagemodule = {
                    if let filePath = Bundle.main.path(forResource: "student_image", ofType: "pt"),
                        let module = CLIPImageTorchModule(fileAtPath: filePath) {
                        NSLog("CLIP Image encoder loaded")
                        return module
                    } else {
                        fatalError("Failed to load clip image model!")
                    }
                }()
                self.IndexModule = IndexingModule()
//                var encoder = CerealEncoder()
                let imageSize = CGSize(width: 224,height: 224)
                let options = PHImageRequestOptions()
                let imageManager_ = PHImageManager.default()
                options.deliveryMode = .highQualityFormat
                options.isSynchronous = true
                var image_vectors: Array<Array<Float>> = []
                self.assetResults.enumerateObjects{ [self](object: AnyObject, count: Int, stop: UnsafeMutablePointer<ObjCBool>) in
                    if object is PHAsset {
                        let asset = object as! PHAsset
                        autoreleasepool {
                            imageManager_.requestImage(for: asset, targetSize: imageSize, contentMode: PHImageContentMode.aspectFit, options: options, resultHandler: { (image: UIImage?, _) in
                                    image_vectors.append(self.CLIPImagemodule!.test_uiimagetomat(image: image!) as! Array<Float>)
    //                                self.IndexModule?.buildIndexOne(data: (self.CLIPImagemodule?.test_uiimagetomat(image: image!))!)
    //                                self.CLIPImagemodule?.test_uiimagetomat(image: image!)
                            })
                        }
                    }
                }
                self.IndexModule?.buildIndex(datas: image_vectors as! [[NSNumber]])
//                self.IndexModule?.save()
//                let vec = self.localImages.map{
//                    (self.CLIPImagemodule!.test_uiimagetomat(image:$0))! }
//                self.IndexModule?.buildIndex(datas: vec)
//                for id in 0..<vec.count {
//                    self.vectors.append(vec[id] as! [Float])
//                    let tmp_vec = vec[id] as! [Double]
//                    KMeans.sharedInstance.addVector(tmp_vec)
//                    try! encoder.encode(tmp_vec, forKey: String(id))
//                }
//                let data = encoder.toData()
//                try! data.write(to: URL(fileURLWithPath: vec_filePath))
                // indexing using KMeans
//                KMeans.sharedInstance.clusteringNumber = 4
//                KMeans.sharedInstance.dimension = 512
//                KMeans.sharedInstance.clustering(5)
//                var dictionary:NSMutableDictionary = [:]
//                dictionary["N"] = self.localImages.count
//                dictionary["centroids"] = KMeans.sharedInstance.finalCentroids
//                dictionary["clusters"] = KMeans.sharedInstance.finalClusters
//                dictionary["K"] = KMeans.sharedInstance.clusteringNumber
//                dictionary.write(toFile: filePath, atomically: true)
//                self.double_vectors = KMeans.sharedInstance.vectors
            }
            self.isVectorReady = true
            print("done")
      }
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
        let results_ids = self.IndexModule?.search(query: res!)
        self.showedImages = []
        let imageManager = PHCachingImageManager()
        let imageSize = CGSize(width: 224,height: 224)
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = true
        for i in 0..<results_ids!.count {
            imageManager.requestImage(for: self.assetResults[Int(results_ids![i])] as! PHAsset, targetSize: imageSize, contentMode: PHImageContentMode.aspectFit, options: options, resultHandler: { (image: UIImage?, info:[AnyHashable:Any]?) in
                self.showedImages.append(image!)
            })
        }
//        let vector: [Double] = res! as! [Double]
//        // Mark: K-Means
//        let f_vector: [Float] = res as! [Float]
//        var max_centroid_id: Int = -1
//        var max_centroids_score: Double = .nan
//        for idx in 0..<KMeans.sharedInstance.finalCentroids.count {
//            let centroid = KMeans.sharedInstance.finalCentroids[idx]
//            var sim_score: Double = .nan
//            vDSP_dotprD(vector, self.stride, centroid, self.stride, &sim_score, self.n)
//            if max_centroids_score.isNaN || sim_score > max_centroids_score {
//                max_centroids_score = sim_score
//                max_centroid_id = idx
//            }
//        }
//        var final_sim_scores: [(score: Double, id: Int)] = []
//        for vec_id in KMeans.sharedInstance.finalClusters[max_centroid_id] {
//            var sim_score: Double = .nan
//            vDSP_dotprD(vector, self.stride, self.double_vectors[vec_id], self.stride, &sim_score, self.n)
////            vDSP_dotpr(f_vector, self.stride, self.vectors[vec_id], self.stride, &sim_score, self.n)
//            final_sim_scores.append((sim_score, vec_id))
//        }
//        final_sim_scores.sort { $0.score > $1.score } // sort in descending order by sim_score

//        for i in 0..<final_sim_scores.count {
//            self.showedImages.append(self.localImages[final_sim_scores[i].id])
//        }
        // Mark: Linear scan
//        var sim_scores: [(score: Float, id: Int)] = []
//        for idx in 0..<self.vectors.count {
//            var sim_score: Float = .nan
//            vDSP_dotpr(vector, self.stride, self.vectors[idx], self.stride, &sim_score, self.n)
//            sim_scores.append((sim_score, idx))
//        }
//        sim_scores.sort { $0.score > $1.score }
//        self.showedImages = []
//        for i in 0...2 {
//            self.showedImages.append(self.localImages[sim_scores[i].id])
//        }
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
