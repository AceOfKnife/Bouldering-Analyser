import SwiftUI

struct SavedRoutesView: View {
    @EnvironmentObject var user: User
    var body: some View {
        Text("Here are your saved routes").font(.title)
    }
}

struct SavedRoutesView_Previews: PreviewProvider {
    static var previews: some View {
        SavedRoutesView()
    }
}
