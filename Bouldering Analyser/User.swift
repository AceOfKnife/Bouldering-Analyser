import SwiftUI
import FirebaseDatabase
import FirebaseDatabaseSwift
import FirebaseAuth
import FirebaseAuthCombineSwift

/**
 # User Class
 This class is used to store the user of the current session. It contains the user authenticatiom
 reference and some functions that allow communication with the Firebase Database.
 */
class User: ObservableObject {
    // Reference to the User in the Firebase Authentication service
    public var user = Auth.auth().currentUser
    private var ref = Database.database().reference()
    // Listening event that updates the current user whenever there is
    // a change in state during initialisation e.g when a user logs out
    init() {
        Auth.auth().addStateDidChangeListener { auth, newUser in
            self.user = newUser
        }
    }
}

extension User {
    
    /**
     Function that allows the user to log out by calling the Firebase Authentication methods
     */
    func logOut() -> Void {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
    }

    /**
     Function that removes the biometrics of the user
     */
    func changeBiometrics() -> Void {
        self.ref.child("users/\(user!.uid)/biometrics").setValue(false)
        self.ref.child("users/\(user!.uid)/height").setValue(nil)
        self.ref.child("users/\(user!.uid)/weight").setValue(nil)
    }

    /**
     Overloaded function that updates the biometrics of the user with the given arguments
     - Parameters:
        - height: The height specified by the user
        - weight: The weight specified by the user
     */
    func changeBiometrics(height: Int, weight: Int) -> Void {
        self.ref.child("users/\(user!.uid)/biometrics").setValue(true)
        self.ref.child("users/\(user!.uid)/height").setValue(height)
        self.ref.child("users/\(user!.uid)/weight").setValue(weight)
    }
    
    /**
     Function that uploads the feedback from the user to the database
     - Parameter feedback: The feedback given by the user
     */
    func sendFeedback(feedback: String) {
        ref.child("feedback/\(user!.uid)").childByAutoId().setValue(feedback)
    }
}
