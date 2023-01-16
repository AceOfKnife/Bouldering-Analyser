import SwiftUI
import FirebaseStorage
import FirebaseAuth

struct HomeView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var menu = false
    @State private var camera = false
    @State private var upload = false
    @State private var user = User()
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    @State private var displayImagePicker = false
    @State private var uploadedImage = false
    @State private var uploading = false
    @State private var progressWidth = 0.0
    let storageRef = Storage.storage().reference()

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
                            user.logOut()
                            self.presentationMode.wrappedValue.dismiss()
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
                        self.sourceType = .camera
                        self.displayImagePicker.toggle()
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
                        self.sourceType = .photoLibrary
                        self.displayImagePicker.toggle()
                    } label: {
                        VStack {
                            Image("upload").resizable().scaledToFit().frame(maxWidth:100, maxHeight:100)
                            Text("Upload a photo").foregroundColor(.black).frame(minWidth: 0, idealWidth: 150, maxWidth:150, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.green.opacity(0.3)).cornerRadius(10)
                        }
                    }.padding()
                    Group {
                        if selectedImage != nil {
                            VStack{
                                Image(uiImage: selectedImage!).resizable().scaledToFit().frame(maxWidth:200, maxHeight:200)
                                Button("Confirm image") {
                                    self.uploading = true
                                    let uploadRef = self.storageRef.child("images").child(user.user!.uid).child("analysing.png")
                                    let uploadTask = uploadRef.putData(selectedImage!.pngData()!, metadata: nil)
                                    uploadTask.observe(.progress) { snapshot in
                                      let percentComplete = Double(snapshot.progress!.completedUnitCount)
                                        / Double(snapshot.progress!.totalUnitCount)
                                        modifyPercentBar(scale: percentComplete)
                                    }
                                    uploadTask.observe(.success) { snapshot in
                                        uploadComplete()
                                    }
                                }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.mint.opacity(0.3)).cornerRadius(10)
                                if uploading {
                                    VStack {
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerSize: CGSize(width: 0.1, height: 0.1)).frame(maxWidth:250, maxHeight: 5).foregroundColor(Color.black).cornerRadius(5)
                                            RoundedRectangle(cornerSize: CGSize(width: 0.1, height: 0.1)).frame(maxWidth:self.progressWidth, maxHeight: 5).foregroundColor(Color.green).cornerRadius(5).animation(.linear)
                                        }
                                        Text(String(Int(self.progressWidth / 250 * 100)) + "%")
                                    }.padding()
                                }
                            }.padding()
                        }
                        NavigationLink("", destination: UploadView(), isActive: $uploadedImage)
                    }
                }.padding()
            }
        }
        .navigationBarTitle("")
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .environmentObject(user)
        .sheet(isPresented: self.$displayImagePicker
        ) {
            ImagePickerView(selectedImage: self.$selectedImage, sourceType: self.sourceType)
        }
    }
    
    func modifyPercentBar(scale: Double) -> Void {
        self.progressWidth = scale * 250
    }
    
    func uploadComplete() -> Void {
        self.uploadedImage = true
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
