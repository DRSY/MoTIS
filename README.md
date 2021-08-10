# A Mobile Text-to-Image Search Powered by AI
A minimal demo demonstrating semantic multimodal text-to-image search using pretrained vision-language models.

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
+ Basic features
- [x] Accessing to specified album or the whole photos
- [x] Asynchronous model loading and vectors computation
+ Indexing strategies
- [x] Linear indexing(persisted to file via built-in Data type)
- [x] KMeans indexing(persisted to file via NSMutableDictionary)
- [ ] Ball-Tree indexing
- [ ] Locality sensitive hashing indexing
+ Choices of semantic representation models
- [x] OpenAI's CLIP model
- [ ] Integration of other multimodal retrieval models
+ Effiency
- [ ] Reducing memory consumption of models
