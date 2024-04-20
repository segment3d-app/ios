//
//  ExploreItemViewModel.swift
//  Segment3D
//
//  Created by I Made Indra Mahaarta on 09/04/24.
//

import Foundation


struct AssetResponse: Codable {
    let asset: Asset
    let message: String
}

class ExploreItemViewModel: ObservableObject {
    @Published var asset: Asset
    
    init(asset: Asset) {
        self.asset = asset
    }
    
    func likeAsset(isLikeAction : Bool = true) {
        var action: String = "like"
        
        if !isLikeAction {
            action = "unlike"
        }
        
        
        guard let url = URL(string: "\(Config.apiUrl)/assets/\(action)/\(asset.id)") else {
            print("Invalid URL")
            return
        }
        
        let token = getToken()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async { [self] in
                if let error = error {
                    print("Error to like asset: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data returned from server")
                    return
                }
                
                guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                    print("Error with the response, unexpected status code \(String(describing: response?.description))")
                    return
                }

                if let decodedResponse = try? JSONDecoder().decode(AssetResponse.self, from: data) {
                    print(decodedResponse.asset)
                    self?.asset = decodedResponse.asset
                } else {
                    print("Failed to decode JSON or index not found")
                }

            }
        }.resume()
    }
    
    private func getToken() -> String {
        return UserDefaults.standard.string(forKey: "jwt") ?? ""
    }
}
