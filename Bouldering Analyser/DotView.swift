import SwiftUI

/**
 # Dot View
 A very simple loading animation that has a circle continuously easing in and out.
 */
struct DotView: View {
    @State var delay: Double = 0
    @State var scale: CGFloat = 0.5
    var body: some View {
        Circle()
            .frame(maxWidth: 35, maxHeight: 35)
            .scaleEffect(scale)
            .animation(Animation.easeInOut(duration: 0.6).repeatForever().delay(delay))
            .onAppear {
                withAnimation {
                    self.scale = 1
                }
            }
    }
}
