import SwiftUI
import FirebaseDatabase
import FirebaseDatabaseSwift
import FirebaseAuth
import FirebaseAuthCombineSwift

class User: ObservableObject {
    public var user = Auth.auth().currentUser
    private var ref = Database.database().reference()
    init() {
        let handle = Auth.auth().addStateDidChangeListener { auth, newUser in
            self.user = newUser
        }
    }
}

extension User {
    
    func updateUser(user: FirebaseAuth.User) {
        self.user = user
    }
    
    func logOut() -> Void {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
    }

    func changeBiometrics() -> Void {
        self.ref.child("users/\(user!.uid)/biometrics").setValue(false)
        self.ref.child("users/\(user!.uid)/height").setValue(nil)
        self.ref.child("users/\(user!.uid)/weight").setValue(nil)
    }

    func changeBiometrics(height: Int, weight: Int) -> Void {
        self.ref.child("users/\(user!.uid)/biometrics").setValue(true)
        self.ref.child("users/\(user!.uid)/height").setValue(height)
        self.ref.child("users/\(user!.uid)/weight").setValue(weight)
    }
    
    func sendFeedback(feedback: String) {
        ref.child("feedback/\(user!.uid)").childByAutoId().setValue(feedback)
    }
}
