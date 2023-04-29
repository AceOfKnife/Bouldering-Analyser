import SwiftUI

/**
 # Submitted View
 A simple page that displays once a user successfully submits feedback to the system.
 */
struct SubmittedView: View {
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
