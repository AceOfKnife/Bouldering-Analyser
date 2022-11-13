import SwiftUI

class User: ObservableObject {
    private var email = ""
    private var password = ""
    private var biometrics = false
    private var height = 0
    private var weight = 0
}

extension User {
    
    func authenticate(email: String, password: String) -> Bool {
        // authentication testing
        let valid: Bool = (email == "test@test.com" && password == "test")
        if valid {
            self.email = email
            self.password = password
            self.biometrics = true
            self.height = 160
            self.weight = 60
        }
        return valid
    }
    
    func getEmail() -> String {
        return self.email
    }
    
    func changeEmail(email: String) -> Void {
        // backend
        self.email = email
        print("\(self.email)")
    }
    
    func changePassword(password: String) -> Void {
        // backend
        self.password = password
        print("\(self.password)")
    }
    
    func logOut() -> Void {
        self.email = ""
        self.password = ""
        self.biometrics = false
        self.height = 0
        self.weight = 0
    }
    
    func getHeight() -> Int {
        return self.height
    }
    
    func getWeight() -> Int {
        return self.weight
    }
    
    func resetBiometrics() -> Void {
        // backend
        self.biometrics = false
        self.height = 0
        self.weight = 0
        print("\(self.height)")
        print("\(self.weight)")
    }
    
    func changeBiometrics(height: Int, weight: Int) -> Void {
        // backend
        self.height = height
        self.weight = weight
        print("\(self.height)")
        print("\(self.weight)")
    }
    
    func registerUser(email: String, password: String) -> Void {
        // backend
        print("\(email)")
        print("\(password)")
    }
    
    func registerUser(email: String, password: String, height: Int, weight: Int) {
        // backend
        print("\(email)")
        print("\(password)")
        print("\(height)")
        print("\(weight)")
    }
    
    func usingBiometrics() -> Bool {
        return self.biometrics
    }
}
