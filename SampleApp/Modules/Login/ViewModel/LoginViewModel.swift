import Foundation

class LoginViewModel: ObservableObject {
    
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    @Published var isAuthenticated: Bool = false
    
    func clearData() -> Void {
        name = ""
        email = ""
        password = ""
        errorMessage = ""
    }
    
    func register() -> Void {
        errorMessage = ""
        
        guard validateLogin() else {
            return
        }

        let defaults = UserDefaults.standard
        
        AuthAction().register(name:name, email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let registerResponse):
                    defaults.setValue(registerResponse.accessToken, forKey: "jwt")
                    if let userData = try? JSONEncoder().encode(registerResponse.user) {
                        defaults.set(userData, forKey: "user")
                    }
                    self?.isAuthenticated = true
                    self?.email = ""
                    self?.password = ""
                case .failure(let error):
                    switch error {
                        case .custom(let errorMessage):
                            self?.errorMessage = errorMessage
                        default:
                            self?.errorMessage = error.localizedDescription
                        }
                }
            }
        }
    }
    
    func validateRegister() -> Bool {
        if email.trimmingCharacters(in: .whitespaces).isEmpty || password.trimmingCharacters(in: .whitespaces).isEmpty || name.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please fill all fields."
            return false
        }
        
        
        if !(email.contains("@") && email.contains(".")) {
            errorMessage = "Email is not valid."
            return false
        }
        
        return true
    }
    
    func login() -> Void {
        errorMessage = ""
        
        guard validateLogin() else {
            return
        }

        let defaults = UserDefaults.standard
        
        AuthAction().login(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let loginResponse):
                    defaults.setValue(loginResponse.accessToken, forKey: "jwt")
                    if let userData = try? JSONEncoder().encode(loginResponse.user) {
                        defaults.set(userData, forKey: "user")
                    }
                    self?.isAuthenticated = true
                    self?.email = ""
                    self?.password = ""
                case .failure(let error):
                    switch error {
                        case .custom(let errorMessage):
                            self?.errorMessage = errorMessage
                        default:
                            self?.errorMessage = error.localizedDescription
                        }
                }
            }
        }
    }
    
    func loginUsingGoogle(accessToken: String) -> Void {
        errorMessage = ""

        let defaults = UserDefaults.standard
        
            let payload: [String: Any] = [
                "token": accessToken
            ]

            guard let url = URL(string: "\(Config.apiUrl)/auth/google") else {
                print("Invalid URL")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])

            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    
                    if let error = error {
                        print("Error upload asset: \(error.localizedDescription)")
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
                    
                    if let decodedResponse = try? JSONDecoder().decode(LoginResponse.self, from: data) {
                        defaults.setValue(decodedResponse.accessToken, forKey: "jwt")
                        if let userData = try? JSONEncoder().encode(decodedResponse.user) {
                            defaults.set(userData, forKey: "user")
                        }
                        self?.isAuthenticated = true
                    } else {
                        print("Failed to decode JSON")
                    }
                }
            }.resume()
        
    }
    
    func validateLogin() -> Bool {
        if email.trimmingCharacters(in: .whitespaces).isEmpty || password.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please fill all fields."
            return false
        }
        
        if !(email.contains("@") && email.contains(".")) {
            errorMessage = "Email is not valid."
            return false
        }
        
        return true
    }
    
    func logout() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "jwt")
        defaults.removeObject(forKey: "user")
        DispatchQueue.main.async {
            self.isAuthenticated = false
        }
    }
}
