import SwiftUI

struct SubmittedView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var back = false
    var body: some View {
        NavigationView {
            VStack{
                Text("Feedback submitted!").font(.largeTitle)
            }
        }   .navigationBarTitle("")
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
            .padding()
    }
}

struct SubmittedView_Previews: PreviewProvider {
    static var previews: some View {
        SubmittedView()
    }
}
