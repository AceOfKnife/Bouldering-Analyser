import SwiftUI

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
                    if feedback == "" {
                        invalidFeedback = true
                    } else {
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
