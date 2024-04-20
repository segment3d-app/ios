//
//  ProfileViewModel.swift
//  Segment3D
//
//  Created by I Made Indra Mahaarta on 24/03/24.
//

import Foundation

class ProfileViewModel: ObservableObject {
    @Published var user: User? = nil
    let defaults = UserDefaults.standard

    init() {
       fetchUser()
    }

    func fetchUser() {
            guard let token = defaults.string(forKey: "jwt") else {
                print("JWT not found")
                return
            }
            
            guard let url = URL(string: "\(Config.apiUrl)/users") else {
                print("Invalid URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                if let error = error {
                    print("Network request error: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("Error with the response, unexpected status code: \(String(describing: response))")
                    return
                }
                
                guard let data = data else {
                    print("No data")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.user = try? JSONDecoder().decode(User.self, from: data)
                }
            }.resume()
        }
}
