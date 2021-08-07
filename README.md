# A Mobile Text-to-Image Search Powered by AI

# Features
1. text-to-image retrieval using semantic similarity search.
2. support different vector indexing strategies(linear scan and KMeans are now implemented).

# Install
1. Download the two TorchScript model files into models folder.
2. Simply do 'pod install' and then open the generated .xcworkspace project file in XCode.
```bash
pod install
```

# Todo
- [x] Accessing to specified album or the whole photos
- [x] OpenAI's CLIP model
- [x] Linear indexing
- [x] KMeans indexing
- [ ] Locality sensitive hashing indexing
- [ ] Integration of other multimodal retrieval models
- [ ] Reducing memory consumption of models
