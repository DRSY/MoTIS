# A Mobile Text-to-Image Search Powered by AI

# Features
1. text-to-image retrieval using semantic similarity search.
2. support different vector indexing strategies(linear scan and KMeans are now implemented).

# Screenshot
+ All images in the gallery ![all](./all.png) 
+ Search with query **Three cats** ![search](./cats.png)

# Install
1. Download the two TorchScript model files([text encoder](https://drive.google.com/file/d/1583IT_K9cCkeHfrmuTpMbImbS5qB8SA1/view?usp=sharing), [image encoder](https://drive.google.com/file/d/1K2wIyTuSWLTKBXzUlyTEsa4xXLNDuI7P/view?usp=sharing)) into models folder and add them into the Xcode project.
2. Simply do 'pod install' and then open the generated .xcworkspace project file in XCode.
```bash
pod install
```

# Todo
- [x] Accessing to specified album or the whole photos
- [x] OpenAI's CLIP model
- [x] Linear indexing
- [x] KMeans indexing
- [ ] Ball-Tree indexing
- [ ] Locality sensitive hashing indexing
- [ ] Integration of other multimodal retrieval models
- [ ] Reducing memory consumption of models
