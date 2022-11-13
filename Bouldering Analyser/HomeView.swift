import SwiftUI

struct HomeView: View {
    @EnvironmentObject var user: User
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var menu = false
    @State private var camera = false
    @State private var upload = false
    
    var body: some View {
            NavigationView {
                VStack {
                    Button {
                        menu.toggle()
                    } label: {
                        Image("menu").resizable().scaledToFit().frame(maxWidth:30, maxHeight:30)
                    }.padding()
                    if menu {
                        List {
                            Text("Feedback")
                                .background( NavigationLink("", destination: FeedbackView()).opacity(0) )
                            Text("Saved routes")
                                .background( NavigationLink("", destination: SavedRoutesView()).opacity(0) )
                            Text("Types of holds")
                                .background( NavigationLink("", destination: HoldsView()).opacity(0) )
                            Text("Settings")
                                .background( NavigationLink("", destination: SettingsView()).opacity(0) )
                            Button(action: {
                                self.presentationMode.wrappedValue.dismiss()
                                user.logOut()
                            }) {
                                Text("Logout").foregroundColor(.black)
                            }
                        }.frame(idealHeight: 300, maxHeight:300)
                    }
                    ScrollView {
                        Text("Route Analysis").font(.largeTitle).bold().padding()
                        Text("How to use the app:").padding()
                        Text("1. Take a photo or upload an image of the desired route").multilineTextAlignment(.center)
                        Text("2. Select the starting and ending holds of the route").multilineTextAlignment(.center)
                        Text("3. Select the rest of the holds on the route").multilineTextAlignment(.center)
                        Text("4. Receive automatic grading and tips on how to climb the route!").multilineTextAlignment(.center)
                        Button {
                            camera = true
                        } label: {
                            VStack {
                                Image("camera").resizable().scaledToFit().frame(maxWidth:100, maxHeight:100)
                                Text("Take a photo").foregroundColor(.black).frame(minWidth: 0, idealWidth: 150, maxWidth:150, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.blue.opacity(0.3)).cornerRadius(10)
                            }
                        }.padding()
                        HStack {
                            Rectangle().frame(minWidth: 0, idealWidth: 150, maxWidth: 150, minHeight: 1, maxHeight: 1).ignoresSafeArea()
                            Spacer()
                            Text("OR")
                            Spacer()
                            Rectangle().frame(minWidth: 0, idealWidth: 150, maxWidth: 150, minHeight: 1, maxHeight: 1).ignoresSafeArea()
                        } .padding([.bottom], 10)
                        Button {
                            upload = true
                        } label: {
                            VStack {
                                Image("upload").resizable().scaledToFit().frame(maxWidth:100, maxHeight:100)
                                Text("Upload a photo").foregroundColor(.black).frame(minWidth: 0, idealWidth: 150, maxWidth:150, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.green.opacity(0.3)).cornerRadius(10)
                            }
                        }.padding()
                    }.padding()
                }
            }
            .navigationBarTitle("")
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
        }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
