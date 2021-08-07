//
//  NetworkManager.swift
//  Gallery
//
//  Created by Alex on 16.02.2021.
//

import Foundation

protocol NetworkServiceProtocol {
    func loadPhotosBy(text: String, complete: @escaping (Result<Response, Error>) -> Void)
    func loadPhotosFrom(url: String, complete: @escaping (Result<Response, Error>) -> Void)
}

class NetworkService {
    
    //MARK: - Metods
    
    private func onMain(_ blok: @escaping () -> Void) {
        DispatchQueue.main.async {
            blok()
        }
    }
    
    private func resumeTask(request: URLRequest, complete: @escaping (Result<Response, Error>) -> Void) {
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let error = error {
                self.onMain { complete(.failure(error)) }
            } else if let data = data,
                      let response = Response(data: data) {
                self.onMain { complete(.success(response)) }
            }
        }.resume()
    }
    
    private func getUrlForSearch(_ text: String) -> URL? {
        let findText = text.replacingOccurrences(of: " ", with: "+")
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.pexels.com"
        components.path = "/v1/search"
        components.queryItems = [URLQueryItem(name: "query", value: findText)]
        return components.url
    }
    
    private func getRequest(from url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 90)
        request.httpMethod = "GET"
        request.addValue(Constans.apiKey, forHTTPHeaderField: "Authorization")
        return request
    }
}

//MARK: - NetworkServiceProtocol

extension NetworkService: NetworkServiceProtocol {
    
    func loadPhotosBy(text: String, complete: @escaping (Result<Response, Error>) -> Void) {
        guard let url = getUrlForSearch(text) else { return }
        print("url: \(url)")
        resumeTask(request: getRequest(from: url), complete: complete)
    }
    
    func loadPhotosFrom(url: String, complete: @escaping (Result<Response, Error>) -> Void) {
        guard let url = URL(string: url) else { return }
        resumeTask(request: getRequest(from: url), complete: complete)
    }
}
