import SwiftUI
import FirebaseAuth
import FirebaseDatabase

/**
 # Register View
 Constructs the page that allows users to register onto the system. Calls the Firebase database and authentication
 to store the user's details for later retrieval.
 */
struct RegisterView: View {
    
    // State variables storing the email and password credentials of the user
    // Has optional parameters for biometrics if the user wishes to disclose
    @State private var email = ""
    @State private var password = ""
    @State private var confirmEmail = ""
    @State private var confirmPassword = ""
    @State private var biometrics = false
    @State private var info = false
    @State private var height = 0
    @State private var weight = 0
    @State private var tc = false
    @State private var errorMessage = ""
    @State private var success = false
    
    // Reference to the Firebase database
    @State private var ref = Database.database().reference()

    /**
     Registers a user onto the system with a given email and password.
     - Parameters:
        - email: The *email* provided by the user
        - password: The *password* provided by the user
     */
    func registerUser(email: String, password: String) -> Void {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                let message = error.localizedDescription
                errorMessage = message
            } else {
                // Storing the user's details securely in the database without biometrics
                self.ref.child("users").child(authResult!.user.uid).setValue(["email": self.email, "biometrics": false]) { error,_  in
                    if let error = error {
                        let message = error.localizedDescription
                        errorMessage = message
                    } else {
                        success = true
                    }
                }
            }
        }
    }
    
    /**
     Overloaded registerUser function that allows for biometrics to be added.
     - Parameters:
        - email: The *email* provided by the user
        - password: The *password* provided by the user
        - height: The *height* specified by the user
        - weight: The *weight* specified by the user
     */
    func registerUser(email: String, password: String, height: Int, weight: Int) -> Void {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                let message = error.localizedDescription
                errorMessage = message
            } else {
                // Storing the details securely in the database with the biometrics
                self.ref.child("users").child(authResult!.user.uid).setValue(["email": self.email, "biometrics": true, "height": height, "weight": weight]) { error,_  in
                    if let error = error {
                        let message = error.localizedDescription
                        errorMessage = message
                    } else {
                        success = true
                    }
                }
            }
        }
    }
    
    /**
     Function that checks if the details provided by the user is sufficient.
     - Returns: An Int encoding the result of the sign up:
                0. All necessary details are provided
                1. One or more required fields are empty
                2. Confirm email/password fields do not match with the email/password fields
                3/4. Biometrics are not sensible
                5. Terms and conditions not checked
     */
    func validateRegister() -> Int {
        if email == "" || password == "" || confirmEmail == "" || confirmPassword == "" {
            return 1
        }
        if email != confirmEmail || password != confirmPassword {
            return 2
        }
        if biometrics {
            if height < 100 || height > 250 {
                return 3
            }
            if weight < 30 || weight > 300 {
                return 4
            }
        }
        if !tc {
            return 5
        }
        return 0
    }
    
    /**
     Function that returns the error message based on the encoded result
     - Parameters error: The integer encoding of the error message
     - Returns: The string for the error message
     */
    func getError(error: Int) -> String {
        switch error {
        case 1:
            return "Please ensure that all fields are filled"
        case 2:
            return "Check to make sure emails and passwords match"
        case 3:
            return "Enter a height between 100 - 200 cm"
        case 4:
            return "Enter a weight between 30 - 300 kg"
        default:
            return "Please read and accept the terms and conditions"
        }
    }
    
    // Formatter that forces input to be numerical for the biometrics
    let formatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .none
            return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                ZStack {
                    VStack{
                        Group {
                            Text("Register").font(.largeTitle).bold().padding([.bottom], 50)
                            TextField("Email", text: $email)
                                .frame(minWidth: 0, idealWidth:300, maxWidth: 300, minHeight: 0, idealHeight: 50, maxHeight:50)   .disableAutocorrection(true)        .autocapitalization(.none)
                            TextField("Confirm Email", text: $confirmEmail)
                                .frame(minWidth: 0, idealWidth:300, maxWidth: 300, minHeight: 0, idealHeight: 50, maxHeight:50)   .disableAutocorrection(true)        .autocapitalization(.none)
                            SecureField("Password", text: $password)
                                .frame(minWidth: 0, idealWidth:300, maxWidth: 300, minHeight: 0, idealHeight: 50, maxHeight:50)
                                .disableAutocorrection(true)        .autocapitalization(.none)
                            SecureField("Confirm Password", text: $confirmPassword)
                                .frame(minWidth: 0, idealWidth:300, maxWidth: 300, minHeight: 0, idealHeight: 50, maxHeight:50)
                                .disableAutocorrection(true)        .autocapitalization(.none)
                        }
                        HStack {
                            Text("Would you like to provide your height and weight for more personalised advice?").padding().multilineTextAlignment(.center).minimumScaleFactor(0.3).frame(minWidth:150, minHeight:100)
                            Button {
                                info.toggle()
                            } label: {
                                Image("info").resizable().scaledToFit().frame(maxWidth:20, maxHeight:20).padding(.trailing, 20)
                            }
                        }
                        HStack {
                            Button {
                                biometrics = false
                            } label: {
                                Text("No").bold(!biometrics).foregroundColor(.black)
                            }
                            Spacer().frame(maxWidth: 200)
                            Button {
                                biometrics = true
                            } label: {
                                Text("Yes").bold(biometrics).foregroundColor(.black)
                            }
                        } .padding(.bottom, 20)
                        if biometrics {
                            HStack {
                                Text("Height").frame(width:55).minimumScaleFactor(0.01)
                                Spacer()
                                TextField("Height in cm", value: $height, formatter: formatter)
                                    .frame(minWidth: 0, idealWidth:150, maxWidth: 150, minHeight: 0, idealHeight: 50, maxHeight:50).disableAutocorrection(true).autocapitalization(.none)
                                Spacer()
                                Text("cm").frame(width:25).minimumScaleFactor(0.01)
                            }
                            HStack {
                                Text("Weight").frame(width:55).minimumScaleFactor(0.01)
                                Spacer()
                                TextField("Weight in kg", value: $weight, formatter: formatter)
                                    .frame(minWidth: 0, idealWidth:150, maxWidth: 150, minHeight: 0, idealHeight: 50, maxHeight:50).disableAutocorrection(true).autocapitalization(.none)
                                Spacer()
                                Text("kg").frame(width:25).minimumScaleFactor(0.01)
                            }
                        }
                        Toggle("I have read the terms and conditions", isOn: $tc).onChange(of:tc) { newValue in
                            // backend
                        }.frame(minWidth: 0, idealWidth: 400, maxWidth: 400, minHeight: 0, idealHeight: 20, maxHeight:20).padding([.bottom], 20).minimumScaleFactor(0.01)
                        Text(errorMessage).foregroundColor(.red)
                        Button("Sign Up") {
                            // Checks the error code and displays an error message if necessary
                            let errorCode = validateRegister()
                            if errorCode != 0 {
                                errorMessage = getError(error: errorCode)
                            } else {
                                if biometrics {
                                    registerUser(email: email, password: password, height: height, weight: weight)
                                } else {
                                    registerUser(email: email, password: password)
                                }
                            }
                        }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.green.opacity(0.3)).cornerRadius(10)
                    } .padding()
                    if info {
                        ZStack {
                            Rectangle().frame(maxWidth: 300, maxHeight: 100).foregroundColor(.white).border(Color.mint.opacity(0.5), width: 5)
                            Text("Your height and weight data will be used to improve the app experience by comparing data of climbers of similar proportions to tailor your advice.").frame(maxWidth: 250, maxHeight: 75).minimumScaleFactor(0.01).foregroundColor(.black)
                        } .offset(y:200)
                    }
                } .padding()
            }
        }
        NavigationLink("", destination: SuccessRegisterView(), isActive: $success)
    }
}


struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
