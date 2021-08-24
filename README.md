# A Mobile Text-to-Image Search Powered by AI
A minimal demo demonstrating semantic multimodal text-to-image search using pretrained vision-language models. Semantic search represents each sample(text and image) as a vector in a shared semantic embedding space. The relevance score can then be measured as similarity(cosine similarity or distance) between vectors.

# Recent Updates:
+ Transplanted Spotify's [Annoy](https://github.com/spotify/annoy) Approximate Nearest Neighbor search in this project(annoylib.h).
+ A distilled ViT image encoder is provided [here](https://drive.google.com/file/d/1Miocgk0gxAf79pu51IX8kfR04iJM_TCm/view?usp=sharing), with a much smaller size of 48MB compared to the original 351MB one while retaining decent retrieval performance.
+ Relatively low quality images are displayed by default. Retrieved images are displayed with high quality. This is designed to reduce the runtime memory.

# Features
1. text-to-image retrieval using semantic similarity search.
2. support different vector indexing strategies(linear scan, KMeans, and random projection).

# Screenshot
+ All images in the gallery ![all](./all.png) 
+ Search with query **Three cats** ![search](./cats.png)

# Install
1. Download the two TorchScript model files([text encoder](https://drive.google.com/file/d/1583IT_K9cCkeHfrmuTpMbImbS5qB8SA1/view?usp=sharing), [image encoder](https://drive.google.com/file/d/1Miocgk0gxAf79pu51IX8kfR04iJM_TCm/view?usp=sharing)) into models folder and add them into the Xcode project.
2. Required dependencies are defined in the Podfile. We use Cocapods to manage these dependencies. Simply do 'pod install' and then open the generated .xcworkspace project file in XCode.
```bash
pod install
```
3. This demo by default load all images in the local photo gallery on your realphone or simulator. One can change it to a specified album by setting the **albumName** variable in **getPhotos** method and replacing **assetResults** in line 117 of GalleryInteractor.swift with **photoAssets**.

# Usage
Just type any keyword in order to search the relecant images. Type "reset" to return to the default one.

# Todos
+ Basic features
- [x] Accessing to specified album or the whole photos
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

# About Us
This project is actively maintained by [ADAPT](http://adapt.seiee.sjtu.edu.cn/) lab from Shanghai Jiao Tong University. We expect it to continually integrate more advanced features and better cross-modal search experience. If you have any problems, welcome to file an issue.
