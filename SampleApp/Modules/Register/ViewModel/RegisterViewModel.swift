//
//  RegisterViewModel.swift
//  Segment3D
//
//  Created by I Made Indra Mahaarta on 31/03/24.
//

import Foundation

class RegisterViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var name: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    
    func register() -> Void {
        guard validate() else {
            errorMessage = "Please fill all field"
            return
        }
        
        
    }
    
    func validate() -> Bool {
        if email.trimmingCharacters(in: .whitespaces).isEmpty || password.trimmingCharacters(in: .whitespaces).isEmpty {
            DispatchQueue.main.async {
                self.errorMessage = "Please fill all fields."
            }
            return false
        }
        
        if !(email.contains("@") && email.contains(".")) {
            DispatchQueue.main.async {
                self.errorMessage = "Email is not valid."
            }
            return false
        }
        
        return true
    }
}
