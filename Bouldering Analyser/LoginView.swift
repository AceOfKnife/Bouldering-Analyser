import SwiftUI
import FirebaseAuth

/**
 # Login View
 Constructs the page that allows a user to log into their account. Requires the user to have a registered account in the system.
 Uses the Firebase Authentication system for authentication.
 */
struct LoginView: View {
    // State variables storing the email, password of user
    // success and fail variables to display error messages correctly and switch to different pages
    // signUp variable to switch to the page for registering
    @State private var email = ""
    @State private var password = ""
    @State private var success = false
    @State private var fail = false
    @State private var signUp = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Text("Bouldering").font(.largeTitle).bold()
                    Text("Analyser").font(.largeTitle).bold()
                    Text("Login").font(.title).padding()
                    TextField("Email", text: $email)
                        .frame(minWidth: 0, idealWidth:300, maxWidth: 300, minHeight: 0, idealHeight: 50, maxHeight:50)   .disableAutocorrection(true)        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                        .frame(minWidth: 0, idealWidth:300, maxWidth: 300, minHeight: 0, idealHeight: 50, maxHeight:50)
                        .disableAutocorrection(true)        .autocapitalization(.none)
                    if fail {
                        // Error message for the user if the credentials are incorrect
                        Text("Incorrect email or password").foregroundColor(.red)
                    }
                    Button("Sign In") {
                        // Calling the authentication service in Firebase
                        Auth.auth().signIn(withEmail: email, password: password) { auth, error in
                            if error == nil {
                                fail = false
                                success = true
                            } else {
                                success = false
                                fail = true
                            }
                        }
                    } .foregroundColor(.black).frame(minWidth: 0, idealWidth: 150, maxWidth:150, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.blue.opacity(0.3)).cornerRadius(10)
                    HStack {
                        Rectangle().frame(minWidth: 0, idealWidth: 150, maxWidth: 150, minHeight: 1, maxHeight: 1).ignoresSafeArea().padding([.top], 50)
                        Spacer()
                        Text("OR").padding([.top], 50)
                        Spacer()
                        Rectangle().frame(minWidth: 0, idealWidth: 150, maxWidth: 150, minHeight: 1, maxHeight: 1).ignoresSafeArea().padding([.top], 50)
                    } .padding([.bottom], 50)
                    Button("Create an account") {
                        signUp = true
                    }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.green.opacity(0.3)).cornerRadius(10)
                }
                // Page changes based on if the log in was a success or the user wants to sign up
                NavigationLink("", destination: HomeView(), isActive: $success)
                NavigationLink("", destination: RegisterView(), isActive: $signUp)
            }
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .padding()
        .textFieldStyle(.roundedBorder)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
