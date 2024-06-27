//
//  ExploreViewModel.swift
//  Segment3D
//
//  Created by I Made Indra Mahaarta on 24/03/24.
//

import Foundation
import SwiftUI

struct AssetListResponse: Codable {
    let assets: [Asset]
    let message: String
}

struct SagaImagesResponse: Codable {
    let files: [String]
}

struct Asset: Codable, Identifiable {
    let id: String
    let title, slug, type, thumbnailUrl, photoDirUrl, splatUrl, pclUrl, pclColmapUrl, segmentedPclDirUrl, segmentedSplatDirUrl, status, createdAt, updatedAt: String
    var isPrivate, isLikedByMe: Bool
    var likes: Int
    let user: User
}

struct TagListResponse: Codable {
    let tags: [Tag]
    let message: String
}

struct Tag: Codable, Identifiable {
    let id: String
    let name: String
    let slug: String
    let createdAt: String
    let updatedAt: String
}

class ExploreViewModel: ObservableObject {
    @Published var assets: [Asset] = []
    @Published var tags: [Tag] = []
    @Published var message: String = ""
    @Published var isLoading = false
    @Published var isMyAssetOnly: Bool
    @Published var searchTerm: String = ""
    @Published var images: [UIImage] = []
    @Published var mediaItems: [MediaItem] = []
    @Published var alertMessage: String?
    @Published var sagaImage: [String] = []
    
    init(isMyAssetOnly: Bool) {
        self.isMyAssetOnly = isMyAssetOnly
        fetchAssets()
    }
    
    func fetchAssets(withLoading: Bool = true) {
        if withLoading {
            isLoading = true
        }
        
        var urlString = "\(Config.apiUrl)/assets"
        
        if self.isMyAssetOnly {
            urlString += "/me"
        }
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        let token = getToken()
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("Error fetching assets: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data returned from server")
                    return
                }
                
                guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                    print("Error with the response, unexpected status code")
                    return
                }
                
                if let decodedResponse = try? JSONDecoder().decode(AssetListResponse.self, from: data) {
                    self?.assets = decodedResponse.assets
                    self?.message = decodedResponse.message
                } else {
                    print(data, response)
                    print("Failed to decode JSON")
                }
            }
        }.resume()
    }
    
    func fetchSagaImage(assetDir: String, withLoading: Bool = true) {
        if withLoading {
            isLoading = true
        }
        
        var urlString = "\(Config.storageUrl)\(assetDir)"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        let token = getToken()
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("Error fetching assets: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data returned from server")
                    return
                }
                
                guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                    print("Error with the response, unexpected status code")
                    return
                }
                
                if let decodedResponse = try? JSONDecoder().decode(SagaImagesResponse.self, from: data) {
                    self?.sagaImage = decodedResponse.files
                    let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff"]

                    let imageFiles = decodedResponse.files.filter { file in
                        if let fileExtension = file.split(separator: ".").last?.lowercased() {
                            return imageExtensions.contains(fileExtension)
                        }
                        return false
                    }
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.sagaImage = imageFiles
                    }
                } else {
                    print("Failed to decode JSON")
                }

            }
        }.resume()
    }
    
    func onMediaPick(pickedMedia : [MediaItem]) -> ActiveSheet? {
        images = []
        
        let imageCollection = pickedMedia.compactMap { item -> UIImage? in
            if case .image(let image) = item {
                return image
            }
            return nil
        }
        
        guard imageCollection.count >= 5 else {
            alertMessage = "You must select at least five images."
            return nil
        }
        
        images = imageCollection
        
        return .uploadForm
    }
    
    private func getToken() -> String {
        return UserDefaults.standard.string(forKey: "jwt") ?? ""
    }
}
