//
//  ExploreFileUploaderViewModel.swift
//  Segment3D
//
//  Created by I Made Indra Mahaarta on 09/04/24.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI

struct UploadFileResponse: Codable {
    let message: String
    let url: [String]
}


struct UploadAssetResponse: Codable {
    let asset: Asset
    let message: String
}


class ExploreFileUploaderViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var privacy: String = ""
    @Published var tags: [String] = []
    @Published var recomendation: [String] = []
    @Published var enteredTag: String = ""
    @Published var availablePrivacy: [String] = ["Public", "Private"]
    @Published var isLoading: Bool = false
    @Published var uploadError: String?
    @Published var uploadedUrl: String?
    @Published var asset: Asset?
    
    
    func addTag(tag: String) {
        if !tags.contains(where: { str in
            str == tag
        }) {
            tags.append(tag)
            enteredTag = ""
            recomendation.removeAll()
        }
        
    }
    
    func removeTag(tag: String) {
        tags.removeAll { str in
            str == tag
        }
        enteredTag = ""
        recomendation.removeAll()
    }
    
    func fetchTags(search: String, limit: Int) {
        guard !search.isEmpty else {
            return
        }
        
        guard let url = URL(string: "\(Config.apiUrl)/tags/search?keyword=\(search)&limit=\(limit)") else {
            print("Invalid URL")
            return
        }
        
        let token = getToken()
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
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
                
                if let decodedResponse = try? JSONDecoder().decode(TagListResponse.self, from: data) {
                    self?.recomendation = decodedResponse.tags.map({ tag in
                        tag.name
                    })
                } else {
                    print("Failed to decode JSON")
                }
            }
        }.resume()
    }
    
    private func getToken() -> String {
        return UserDefaults.standard.string(forKey: "jwt") ?? ""
    }
    
    func convertImagesToURL(images: [UIImage]) -> [URL] {
        var fileURLs: [URL] = []
        
        for image in images {
            if let data = image.jpegData(compressionQuality: 1.0) {
                let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                let fileURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")

                do {
                    try data.write(to: fileURL)
                    fileURLs.append(fileURL)
                } catch {
                    print("Error saving image to file: \(error)")
                }
            }
        }

        return fileURLs
    }

    func uploadFiles(folder: String, files: [URL], completion: @escaping () -> Void) {
        isLoading = true
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: URL(string: "\(Config.storageUrl)/upload")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var data = Data()
        data.append("--\(boundary)\r\n")
        data.append("Content-Disposition: form-data; name=\"folder\"\r\n\r\n")
        data.append("\(folder)\r\n")

        for fileUrl in files {
            data.append("--\(boundary)\r\n")
            let fileName = fileUrl.lastPathComponent
            let mimeType = fileUrl.mimeType
            data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
            data.append("Content-Type: \(mimeType)\r\n\r\n")
            if let fileData = try? Data(contentsOf: fileUrl) {
                data.append(fileData)
                data.append("\r\n")
            }
        }

        data.append("--\(boundary)--\r\n")
        request.httpBody = data

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error upload file: \(error.localizedDescription)")
                    self?.uploadError = "Error upload file: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    print("No data returned from server")
                    self?.uploadError = "No data returned from server"
                    return
                }
                
                guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                    print("Error with the response, unexpected status code")
                    self?.uploadError = "Error with the response, unexpected status code"
                    return
                }
                
                if let decodedResponse = try? JSONDecoder().decode(UploadFileResponse.self, from: data) {
                    guard !decodedResponse.url.isEmpty else {
                        self?.uploadError = "Url response is empty"
                        return
                    }
                    var fileType = "video"
                    if decodedResponse.url.count > 0 {
                        fileType = "images"
                    }
                    let url = self?.processAssetUrl(decodedResponse.url, fileType: fileType)
                    self?.uploadedUrl = url
                    self?.postAssetDetails(assetType: fileType, completion: completion)
                } else {
                    self?.uploadError = "Failed to decode JSON"
                    print("Failed to decode JSON")
                }
            }
        }.resume()
    }
    
    private func postAssetDetails(assetType: String, completion: @escaping () -> Void) {
        let payload: [String: Any] = [
            "assetType": assetType,
            "assetUrl": uploadedUrl!,
            "isPrivate": privacy == "Private" ? true : false,
            "title": title,
            "tags": tags
        ]

        guard let url = URL(string: "\(Config.apiUrl)/assets") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
        request.addValue("Bearer \(getToken())", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Error upload asset: \(error.localizedDescription)")
                    self?.uploadError = "Error upload asset: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    print("No data returned from server")
                    self?.uploadError = "No data returned from server"
                    return
                }
                
                guard let response = response as? HTTPURLResponse, response.statusCode == 202 else {
                    print("Error with the response, unexpected status code")
                    self?.uploadError = "Error with the response, unexpected status code"
                    return
                }
                
                if let decodedResponse = try? JSONDecoder().decode(UploadAssetResponse.self, from: data) {
                    self?.asset = decodedResponse.asset
                    completion()
                } else {
                    self?.uploadError = "Failed to decode JSON"
                    print("Failed to decode JSON")
                }
            }
        }.resume()
    }

    private func processAssetUrl(_ url: [String], fileType: String) -> String {
        var assetUrl = url.count >= 1 ? url[0] : ""
        if fileType == "images" {
           var urlComponents = assetUrl.components(separatedBy: "/")
           urlComponents.removeLast()
           assetUrl = urlComponents.joined(separator: "/")
        }
        return assetUrl
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

private extension URL {
    var mimeType: String {
        guard let utType = UTType(filenameExtension: self.pathExtension) else {
            return "application/octet-stream"
        }
        return utType.preferredMIMEType ?? "application/octet-stream"
    }
}
