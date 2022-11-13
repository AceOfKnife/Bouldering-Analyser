import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var user: User
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
    
    func validateEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
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
        if !validateEmail(email) {
            return 6
        }
        return 0
    }
    
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
        case 5:
            return "Please read and accept the terms and conditions"
        default:
            return "Please provide an email of the form example@example.com"
        }
    }
    
    let formatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .none
            return formatter
    }()
    
    var body: some View {
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
                        let errorCode = validateRegister()
                        if errorCode != 0 {
                            errorMessage = getError(error: errorCode)
                        } else {
                            if biometrics {
                                user.registerUser(email: email, password: password, height: height, weight: weight)
                            } else {
                                user.registerUser(email: email, password: password)
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
}


struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
