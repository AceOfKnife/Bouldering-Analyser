import SwiftUI

/**
 # Success Register View
 A simple page that displays a success message once a user successfully registers onto the system.
 */
struct SuccessRegisterView: View {
    @State private var back = false
    var body: some View {
        NavigationView {
            VStack{
                Text("Successfully registered!").font(.largeTitle)
                // Button that allows the user to return to the log in page
                Button("Return to Login") {
                    back = true
                } .foregroundColor(.black).frame(minWidth: 0, idealWidth: 150, maxWidth:150, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.green.opacity(0.3)).cornerRadius(10)
            }
        }   .navigationBarTitle("")
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
            .padding()
        NavigationLink("", destination: LoginView(), isActive: $back)
    }
}

struct SuccessRegisterView_Previews: PreviewProvider {
    static var previews: some View {
        SuccessRegisterView()
    }
}
