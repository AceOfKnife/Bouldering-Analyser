import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct SettingsView: View {
    @State private var email = ""
    @State private var confirmEmail = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var height = 0
    @State private var weight = 0
    @State private var biometrics = false
    @State private var errorMessage = ""
    @State private var success = ""
    @EnvironmentObject var user: User
    let ref = Database.database().reference()
        
    func validateEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func emailError() -> Int {
        if email == "" || confirmEmail == "" {
            return 1
        }
        if email != confirmEmail {
            return 2
        }
        if !validateEmail(email) {
            return 3
        }
        return 0
    }
    
    func passwordError() -> Int {
        if password == "" || confirmPassword == "" {
            return 1
        }
        if password != confirmPassword {
            return 4
        }
        return 0
    }
    
    func biometricsError() -> Int {
        if biometrics {
            if height < 100 || height > 250 {
                return 5
            }
            if weight < 30 || weight > 300 {
                return 6
            }
        }
        return 0
    }
    
    func errorMessage(errorCode: Int) -> String {
        switch errorCode {
        case 1:
            return "Please fill in the required fields"
        case 2:
            return "Please ensure that the emails match"
        case 3:
            return "Please ensure that your email is of the form example@example.com"
        case 4:
            return "Please ensure that the passwords match"
        case 5:
            return "Heights can only be between 100 - 250 cm"
        default:
            return "Weights can only be between 30 - 300 kg"
        }
    }
    
    let formatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .none
            return formatter
    }()
    
    var body: some View {
        Text(errorMessage).foregroundColor(.red)
        Text(success).foregroundColor(.green)
        ScrollView {
            VStack {
                Group {
                    Text("Settings").font(.largeTitle).bold()
                    TextField("Email", text: $email)
                        .frame(minWidth: 0, idealWidth:300, maxWidth: 300, minHeight: 0, idealHeight: 50, maxHeight:50)   .disableAutocorrection(true)        .autocapitalization(.none)
                    TextField("Confirm Email", text: $confirmEmail)
                        .frame(minWidth: 0, idealWidth:300, maxWidth: 300, minHeight: 0, idealHeight: 50, maxHeight:50)   .disableAutocorrection(true)        .autocapitalization(.none)
                    Button("Update email") {
                        if emailError() != 0 {
                            success = ""
                            let errorCode = emailError()
                            errorMessage = errorMessage(errorCode: errorCode)
                        } else {
                            success = ""
                            user.user?.updateEmail(to: email) { error in
                                if error != nil {
                                    errorMessage = error!.localizedDescription
                                } else {
                                    ref.child("users/\(user.user!.uid)/email").setValue(email)
                                    success = "Successfully updated!"
                                }
                            }
                        }
                    }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.blue.opacity(0.3)).cornerRadius(10).padding()
                }
                SecureField("Password", text: $password)
                    .frame(minWidth: 0, idealWidth:300, maxWidth: 300, minHeight: 0, idealHeight: 50, maxHeight:50)
                    .disableAutocorrection(true)        .autocapitalization(.none)
                SecureField("Confirm Password", text: $confirmPassword)
                    .frame(minWidth: 0, idealWidth:300, maxWidth: 300, minHeight: 0, idealHeight: 50, maxHeight:50)
                    .disableAutocorrection(true)        .autocapitalization(.none)
                Button("Update password") {
                    if passwordError() != 0 {
                        success = ""
                        let errorCode = passwordError()
                        errorMessage = errorMessage(errorCode: errorCode)
                    } else {
                        success = ""
                        user.user?.updatePassword(to: password) { error in
                            if error != nil {
                                errorMessage = error!.localizedDescription
                            } else {
                                success = "Successfully updated!"
                            }
                        }
                    }
                }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.blue.opacity(0.3)).cornerRadius(10).padding()
                Text("Would you like to provide your height and weight for more personalised advice?").multilineTextAlignment(.center).padding()
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
                Button("Update biometrics") {
                    if biometricsError() != 0 {
                        success = ""
                        let errorCode = biometricsError()
                        errorMessage = errorMessage(errorCode: errorCode)
                    } else {
                        if biometrics {
                            user.changeBiometrics(height: height, weight: weight)
                        } else {
                            user.changeBiometrics()
                        }
                        errorMessage = ""
                        success = "Successfully updated!"
                    }
                }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.blue.opacity(0.3)).cornerRadius(10).padding()
            }
        }.padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
