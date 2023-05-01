import SwiftUI
import FirebaseStorage
import FirebaseAuth

/**
 # Home View
 The page that every user first interacts with once they log in. It has a menu that allows the user to view other pages
 and hosts the main purpose of the application: the automatic grading system.
 */
struct HomeView: View {
    
    // Using `PresentationMode` to quickly return to the login page
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    // Variables to allow dynamic changes to the page and storing of images
    @State private var menu = false
    @State private var camera = false
    @State private var upload = false
    
    // User object storing the current user of the session
    @State private var user = User()
    
    // Initialising variables to store the image to be uploaded to the system
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    @State private var displayImagePicker = false
    @State private var uploadedImage = false
    @State private var uploading = false
    @State private var progressWidth = 0.0
    
    // Reference to the Firebase Storage for image storage
    let storageRef = Storage.storage().reference()

    var body: some View {
        NavigationView {
            VStack {
                Button {
                    menu.toggle()
                } label: {
                    Image("menu").resizable().scaledToFit().frame(maxWidth:30, maxHeight:30)
                }.padding()
                // Menu button that displays the other pages that a user can access
                if menu {
                    List {
                        // Feedback page for providing feedback
                        Text("Feedback")
                            .background( NavigationLink("", destination: FeedbackView()).opacity(0) )
                        // Saved routes page that displays the routes saved by the user
                        Text("Saved routes")
                            .background( NavigationLink("", destination: SavedRoutesView()).opacity(0) )
                        // Types of holds page showing the user different types of holds
                        Text("Types of holds")
                            .background( NavigationLink("", destination: HoldsView()).opacity(0) )
                        // Settings page that allows the user to change their details
                        Text("Settings")
                            .background( NavigationLink("", destination: SettingsView()).opacity(0) )
                        // Log out button that calls the user object's function logOut()
                        Button(action: {
                            user.logOut()
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Logout").foregroundColor(.black)
                        }
                    }.frame(idealHeight: 300, maxHeight:300)
                }
                ScrollView {
                    Group {
                        // Describing how to use the application properly
                        Text("Route Analysis").font(.largeTitle).bold().padding()
                        
                        Text("How to use the app:").padding().multilineTextAlignment(.center).bold()
                        Text("1. Take a photo or upload an image of the desired route").multilineTextAlignment(.center)
                        Text("2. Select the holds of the route").multilineTextAlignment(.center)
                        Text("3. Receive automatic grading and tips on how to climb the route!").multilineTextAlignment(.center)
                        
                        Text("Tips on receiving an accurate grade:").padding().multilineTextAlignment(.center).bold()
                        Text("\u{2022} Try to fill up the entire image with only your route").multilineTextAlignment(.center)
                        Text("\u{2022} The algorithm can only predict grades between V2-V6").multilineTextAlignment(.center)
                        Text("\u{2022} Use walls that have no incline/decline").multilineTextAlignment(.center)
                        Text("\u{2022} Try to find routes without big holds").multilineTextAlignment(.center)
                    }
                    Button {
                        // Button that allows the user to upload an image by taking a picture
                        self.sourceType = .camera
                        // Displaying the image picker system
                        self.displayImagePicker.toggle()
                        self.uploading = false
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
                        // Button that allows the user to upload an image from their photo library
                        self.sourceType = .photoLibrary
                        self.displayImagePicker.toggle()
                        self.uploading = false
                    } label: {
                        VStack {
                            Image("upload").resizable().scaledToFit().frame(maxWidth:100, maxHeight:100)
                            Text("Upload a photo").foregroundColor(.black).frame(minWidth: 0, idealWidth: 150, maxWidth:150, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.green.opacity(0.3)).cornerRadius(10)
                        }
                    }.padding()
                    Group {
                        if selectedImage != nil {
                            VStack{
                                Image(uiImage: selectedImage!).resizable().scaledToFit()
                                Button("Confirm image") {
                                    // Uploading the image into the Firebase storage
                                    if !self.uploading {
                                        self.uploading = true
                                        let metadata = StorageMetadata()
                                        metadata.contentType = "image/jpeg"
                                        // Names the image `analysing.jpg` for later grade classification
                                        let uploadRef = self.storageRef.child("images").child(user.user!.uid).child("analysing.jpg")
                                        let uploadTask = uploadRef.putData(selectedImage!.jpegData(compressionQuality: 1)!, metadata: metadata)
                                        uploadTask.observe(.progress) { snapshot in
                                            // Attaches an observer onto the progress of the upload and displays
                                            // the percentage complete using a completion bar
                                          let percentComplete = Double(snapshot.progress!.completedUnitCount)
                                            / Double(snapshot.progress!.totalUnitCount)
                                            modifyPercentBar(scale: percentComplete)
                                        }
                                        uploadTask.observe(.success) { snapshot in
                                            uploadComplete()
                                        }
                                    }
                                }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.mint.opacity(0.3)).cornerRadius(10)
                                if uploading {
                                    // Creating the uploading percentage bar
                                    VStack {
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerSize: CGSize(width: 0.1, height: 0.1)).frame(maxWidth:250, maxHeight: 5).foregroundColor(Color.black).cornerRadius(5)
                                            // Second rectangle dynamically changes size based on `self.progressWidth`
                                            RoundedRectangle(cornerSize: CGSize(width: 0.1, height: 0.1)).frame(maxWidth:self.progressWidth, maxHeight: 5).foregroundColor(Color.green).cornerRadius(5).animation(.linear)
                                        }
                                        // Text that displays the uploading percentage complete
                                        Text(String(Int(self.progressWidth / 250 * 100)) + "%")
                                    }.padding()
                                }
                            }.padding()
                        }
                        // Changes to the AnalysisView after uploading a successful image
                        NavigationLink("", destination: AnalysisView(), isActive: $uploadedImage)
                    }
                }.padding()
            }
        }
        .navigationBarTitle("")
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .environmentObject(user)
        
        // Sheet that overlays the current page for the user to pick an image
        .sheet(isPresented: self.$displayImagePicker
        ) {
            ImagePickerView(selectedImage: self.$selectedImage, sourceType: self.sourceType)
        }
    }
    
    /**
     Function that dynamically updates the percentage bar.
     - Parameter scale: The amount of upload complete between 0-1 `* 250` to scale it based on the upload bar's maximum width
     */
    func modifyPercentBar(scale: Double) -> Void {
        self.progressWidth = scale * 250
    }
    
    /**
     Function that updates the variables concerning the upload after it is done.
     */
    func uploadComplete() -> Void {
        self.uploadedImage = true
        self.selectedImage = nil
        self.progressWidth = 0.0
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
