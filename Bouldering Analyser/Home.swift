import SwiftUI

struct Home: View {
    @EnvironmentObject var user: User
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    List {
                        NavigationLink("Feedback") {
                            Feedback()
                        }
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                            user.logOut()
                        }) {
                            Text("Logout").foregroundColor(.black).frame(minWidth: 0, idealWidth: 100, maxWidth:100, minHeight: 0, idealHeight: 30, maxHeight:30).background(Color.blue.opacity(0.3)).cornerRadius(10)
                        }
                    }
                }
            }
        }
        .navigationBarTitle("")
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
    }
}
