import SwiftUI

class FeedbackModel: ObservableObject {
    private var user: User
    private var feedback: String
    init(user: User, feedback: String) {
        self.user = user
        self.feedback = feedback
    }
}

extension FeedbackModel {
    func sendFeedback() {
        // backend
        print("\(self.user.getEmail())")
        print("\(self.feedback)")
    }
}
