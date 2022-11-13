import SwiftUI

struct LoginView: View {
    @StateObject var user = User()
    @State private var email = ""
    @State private var password = ""
    @State private var success = false
    @State private var fail = false
    @State private var remember = false
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
                        Text("Incorrect email or password").foregroundColor(.red)
                    }
                    Toggle("Remember me", isOn: $remember).onChange(of:remember) { newValue in
                        // backend
                    }.frame(minWidth: 0, idealWidth: 200, maxWidth: 200, minHeight: 0, idealHeight: 30, maxHeight:30).padding([.bottom], 20)
                    Button("Sign In") {
                        signIn(email: email, password: password)
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
                NavigationLink("", destination: HomeView(), isActive: $success)
                NavigationLink("", destination: RegisterView(), isActive: $signUp)
            }
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .padding()
        .environmentObject(user)
        .textFieldStyle(.roundedBorder)
    }
    
    func signIn(email: String, password: String) {
        let result: Bool = user.authenticate(email: email, password: password)
        success = result
        fail = !result
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
