import SwiftUI

struct UploadView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var user: User
    
    var body: some View {
        NavigationView {
            VStack {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerSize: CGSize(width: 0.1, height: 0.1)).frame(maxWidth:250, maxHeight: 5).foregroundColor(Color.black).cornerRadius(5)
                    RoundedRectangle(cornerSize: CGSize(width: 0.1, height: 0.1)).frame(maxWidth:250, maxHeight: 5).foregroundColor(Color.green).cornerRadius(5)
                }
                Text("100%")
                Text("Uploaded")
            }.padding()
        }   .navigationBarTitle("")
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
    }
}

struct UploadView_Previews: PreviewProvider {
    static var previews: some View {
        UploadView()
    }
}
