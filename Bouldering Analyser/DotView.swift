import SwiftUI

struct DotView: View {
    @State var delay: Double = 0 // 1.
    @State var scale: CGFloat = 0.5
    var body: some View {
        Circle()
            .frame(maxWidth: 35, maxHeight: 35)
            .scaleEffect(scale)
            .animation(Animation.easeInOut(duration: 0.6).repeatForever().delay(delay)) // 2.
            .onAppear {
                withAnimation {
                    self.scale = 1
                }
            }
    }
}
