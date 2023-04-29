import SwiftUI

/**
 # Feedback View
 A simple page that allows users to send feedback to the system where it is stored in the Firebase database.
 */
struct FeedbackView: View {
    @EnvironmentObject var user: User
    @State private var feedback: String = ""
    @State private var invalidFeedback: Bool = false
    @State private var submitted: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Submit Feedback").font(.largeTitle).bold().padding()
                Text("Any feedback will be greatly appreciated and will help the development of the app!").multilineTextAlignment(.center)
                ZStack {
                    TextEditor(text: $feedback).padding().border(Color.black)
                    if feedback == "" {
                        Text("Type your feedback here...").opacity(0.5)
                    }
                }
                if invalidFeedback {
                    Text("Please enter valid feedback").foregroundColor(.red)
                }
                Button("Submit") {
                    // Invalid feedback if the textbox is empty
                    if feedback == "" {
                        invalidFeedback = true
                    } else {
                        // Calls the user object function *sendFeedback* to store it in the database
                        user.sendFeedback(feedback: feedback)
                        submitted = true
                    }
                }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 150, maxWidth:150, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.green.opacity(0.3)).cornerRadius(10)
                NavigationLink("", destination: SubmittedView(), isActive: $submitted)
            }.padding()
        }
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackView()
    }
}
