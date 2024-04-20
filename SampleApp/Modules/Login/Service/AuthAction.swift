//
//  AuthAction.swift
//  Segment3D
//
//  Created by I Made Indra Mahaarta on 24/03/24.
//

import Foundation

enum AuthenticationError: Error {
    case invalidCredentials
    case custom(errorMessage: String)
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
}

struct LoginRequestBody: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    var accessToken: String
    var message: String
    var user: User
}

struct RegisterRequestBody: Codable {
    let name: String
    let email: String
    let password: String
}

struct RegisterResponse: Codable {
    var accessToken: String
    var message: String
    var user: User
}

class AuthAction {

    func login(email: String, password: String, completion: @escaping (Result<LoginResponse, AuthenticationError>) -> ()) {
        guard let url = URL(string: "\(Config.apiUrl)/auth/signin") else {
            completion(.failure(.custom(errorMessage: "Invalid URL")))
            return
        }
        
        let body = LoginRequestBody(email: email, password: password)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                completion(.failure(.custom(errorMessage: "Network request error: \(error!.localizedDescription)")))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                if let data = data,
                   let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorResponse["error"] {
                    completion(.failure(.custom(errorMessage: errorMessage)))
                } else {
                    completion(.failure(.custom(errorMessage: "Unknown error occurred")))
                }
                return
            }
            
            guard let data = data else {
                completion(.failure(.custom(errorMessage: "No data")))
                return
            }
            
            guard let loginResponse = try? JSONDecoder().decode(LoginResponse.self, from: data) else {
                completion(.failure(.invalidCredentials))
                return
            }
            
            completion(.success(loginResponse))
        }.resume()
    }
    
    func register(name: String, email: String, password: String, completion: @escaping (Result<RegisterResponse, AuthenticationError>) -> ()) {
        guard let url = URL(string: "\(Config.apiUrl)/auth/signup") else {
            completion(.failure(.custom(errorMessage: "Invalid URL")))
            return
        }
        
        let body = RegisterRequestBody(name: name, email: email, password: password)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                completion(.failure(.custom(errorMessage: "Network request error: \(error!.localizedDescription)")))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                if let data = data,
                   let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorResponse["error"] {
                    completion(.failure(.custom(errorMessage: errorMessage)))
                } else {
                    completion(.failure(.custom(errorMessage: "Unknown error occurred")))
                }
                return
            }
            
            guard let data = data else {
                completion(.failure(.custom(errorMessage: "No data")))
                return
            }
            
            guard let registerResponse = try? JSONDecoder().decode(RegisterResponse.self, from: data) else {
                completion(.failure(.invalidCredentials))
                return
            }
            
            completion(.success(registerResponse))
        }.resume()
    }
}
