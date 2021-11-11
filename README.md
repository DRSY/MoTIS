# Mobile Text-to-Image Search(MoTIS)
MoTIS is a minimal demo demonstrating semantic multimodal text-to-image search using pretrained vision-language models. Semantic search represents each sample(text and image) as a vector in a shared semantic embedding space. The relevance score can then be measured as similarity(cosine similarity or distance) between vectors.

# Recent Updates:
+ Android version is coming soon.
+ 4-layer text encoder is released.
+ We distilled the text encoder into a 6-layer counterpart of the original 12-layer Transformer, the resulting combined dual-encoder achieves even better performance than the one combined using 12-layer Transformer!
+ We use pretrained ViT-Small(85MB) as initialization for the student model. Using the same distillation pipeline, it achieves even better results(2 points higher Hit@1) than the previous Deit-small-distilled model. Link of the jit scirpt checkpoint is [here](https://drive.google.com/file/d/1s_oX0-HIELpjjrBXsjlofIbTGZ_Wllo0/view?usp=sharing).
+ A more effective distilled image encoder(84MB compared to the original 350MB ViT-B/32 in CLIP) is available [here](https://drive.google.com/file/d/1Fg3ckUUqBs5n4jvNWZUcwwk7db0QBRri/view?usp=sharing). This image encoder is initialized with [DeiT-base-distilled](https://github.com/facebookresearch/deit)'s pre-trained weights, which leads to more robust image representation hence better retrieval performance(obtain higher Hit@1/5/10 than original CLIP on MSCOCO validation set). It is further learned through supervised learning and knowledge distillation.
+ Transplanted Spotify's [Annoy](https://github.com/spotify/annoy) Approximate Nearest Neighbor search in this project(annoylib.h).
+ Before searching, all images in the gallery are displayed at relatively lower resolution to save memory. Meanwhile in the background, we take as input the high-resolution version of all images for encoding and indexing. When users actually start to search, the retrieved images are displayed at high resolution since we only display top-K search results.

# Current Best Dual-Encoder TorchScript Files
+ Image Encoder, 85MB disk space, 12 layer, 384 dim 6 heads: https://drive.google.com/file/d/194tnzP0_6pB5XAFrL6QO2dQ5mWvhSF0r/view?usp=sharing
+ Text Encoder, 146MB disk space, 4 layer, 512 dim, 8 heads: https://drive.google.com/file/d/1JKO7H3m-agQ10bXDkDiMgHHdlK3K8w9e/view?usp=sharing
 
**Performance:** These two combined achieves 40.4/68.5/78.4 R@1/R@5/R@10 on MS COCO 2014 5K test set, matching CLIP model(40.9/67.6/77.9) finetuned with contrastive loss. On the 1K test split, our current best compressed dual-encoder achieves 61.2/87.6/94.2 R@1/R@5/R@10, while CLIP obtains 61.0/87.9/94.7.

**Inference Speed:** The image encoder is approximately 1.6 times faster than CLIP's ViT/B-32, and the text encoder is about 2.9 times faster than CLIP's text encoder. 

# Distilled Text Encoder Checkpoints
|  Model   |  Disk Space  |  Google Drive  | R@10 on MS COCO2014 5K testset  |
|  ----  | ----  | ----  | ----  |
| original CLIP |  224MB   | https://drive.google.com/file/d/1583IT_K9cCkeHfrmuTpMbImbS5qB8SA1/view?usp=sharing | 64.5 | 
| fine-tuned CLIP |  224MB   | - | 77.9 | 
| 6-Layer Transformer |  170MB   | https://drive.google.com/file/d/1V4_oJGZiW-J6fqkvRKsmtPae-S32-hfJ/view?usp=sharing | 74.2 | 
| 6-Layer Transformer with hard negatives |  170MB   | https://drive.google.com/file/d/1isMy64zuWnggd9K63RMHG4fx6U4O-izE/view?usp=sharing | 79.1 | 
| 4-Layer Transformer |  146MB   | https://drive.google.com/file/d/1S125Z49P-1ROiRPOa9NkbDmObrVelXOW/view?usp=sharing | 73.8 | 
| 4-Layer Transformer with hard negatives |  146MB   | https://drive.google.com/file/d/1c83gD8NGT8v8RcE_E_rCrkqWN2RIzHEg/view?usp=sharing | 78.4 | 

# Distilled Image Encoder Checkpoints
|  Model   |  Disk Space  |  Google Drive  | R@10 on MS COCO2014 5K testset  |
|  ----  | ----  | ----  | ----  |
| original CLIP |  336MB   | https://drive.google.com/file/d/1K2wIyTuSWLTKBXzUlyTEsa4xXLNDuI7P/view?usp=sharing | 64.5 | 
| fine-tuned CLIP |  336MB   | - | 77.9 | 
| ViT-small-patch16-224  |   85MB    |   https://drive.google.com/file/d/1s_oX0-HIELpjjrBXsjlofIbTGZ_Wllo0/view?usp=sharing | 68.9 |
| ViT-small-patch16-224(larger batch size)  |  85MB   |   https://drive.google.com/file/d/1h_w9msJMB4F-dR6uNwp-BHeguS5QIrnE/view?usp=sharing | 68.3 |
| ViT-small-patch16-224(arger batch size and hard negatives sampled from training set)  |  85MB  |       https://drive.google.com/file/d/14AqCaORjxePrscdwUTGprII8siJ7ik8X/view?usp=sharing | 69.4 |
| ViT-small-patch16-224(larger batch size, bigger image corpus, and hard negatives sampled from training set)  |  85MB  |  https://drive.google.com/file/d/1q3dllreyVTofWh5JZywzWYHQlNgcRacq/view?usp=sharing  | 69.9 |
| ViT-small-patch16-224-ImageNet21K(larger batch size, bigger image corpus, and hard negatives sampled from training set) |  85MB  |  https://drive.google.com/file/d/1Whacd4qeFuP_sair3yNGUeQTm4bshDYh/view?usp=sharing | 75.3 |

Note that these checkpoints are not taken from state_dict(), but rather after torch.jit.script operation. The same original CLIP text encoder is used for all above image encoders.

# Features
1. text-to-image retrieval using semantic similarity search.
2. support different vector indexing strategies(linear scan, KMeans, and random projection).

# Screenshot
+ Before search, all images in the gallery(left)&ensp;&ensp;=>&ensp;&ensp;&ensp;&ensp;After searching with query **Three cats**(right): 

<img src="all.png" width=300px height=600px> &ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;  <img src="cats.png" width=300px height=600px>

# Installation
1. Download the two TorchScript model files([text encoder](https://drive.google.com/file/d/1c83gD8NGT8v8RcE_E_rCrkqWN2RIzHEg/view?usp=sharing), [image encoder](https://drive.google.com/file/d/194tnzP0_6pB5XAFrL6QO2dQ5mWvhSF0r/view?usp=sharing)) into models folder and add them into the Xcode project.
2. Required dependencies are defined in the Podfile. We use Cocapods to manage these dependencies. Simply do 'pod install' and then open the generated .xcworkspace project file in XCode.
```bash
pod install
```
3. This demo by default load all images in the local photo gallery on your realphone or simulator. One can change it to a specified album by setting the **albumName** variable in **getPhotos** method and replacing **assetResults** in line 117 of GalleryInteractor.swift with **photoAssets**.

# Usage
Just type any keyword in order to search the relecant images. Type "reset" to return to the default one.

# Todos
+ Basic features
- [x] Access to specified album or all photos
- [x] Asynchronous model loading and vectors computation
- [x] Export pretrinaed CLIP into TorchScript format using **torch.jit.script** and **optimize_for_mobile** provided by Pytorch
- [x] Transplant the original PIL based image preprocessing procedure into OpenCV based procedure, observed about 1% retrieval performance degradation
- [x] Transplant the CLIP tokenizer from Python into Swift(Tokenizer.swift) 
+ Indexing strategies
- [x] Linear indexing(persisted to file via built-in Data type)
- [x] KMeans indexing(persisted to file via NSMutableDictionary, hard-coded num of clusters, u can change to whatever u want)
- [x] Spotify's [Annoy](https://github.com/spotify/annoy) libraby with random projection indexing, the size of index file is 41MB for 2200 images.
+ Choices of semantic representation models
- [x] OpenAI's CLIP model
- [ ] Integration of other multimodal retrieval models
+ Effiency
- [x] Reducing memory consumption of models: runtime memory 1GB -> 490MB via a smaller yet effective distilled ViT model.

