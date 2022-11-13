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
            changeEmail(email: email)
            changePassword(password: password)
        }
        return valid
    }
    
    func getEmail() -> String {
        return self.email
    }
    
    func changeEmail(email: String) -> Void {
        self.email = email
    }
    
    func changePassword(password: String) -> Void {
        self.password = password
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
}
