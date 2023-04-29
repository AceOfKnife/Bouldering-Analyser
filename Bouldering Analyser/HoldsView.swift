import SwiftUI

/**
 # Holds View
 This page shows an interactive list of different types of holds along with a description of their applications and how to utilise them properly.
 */
struct HoldsView: View {
    @EnvironmentObject var user: User
    
    // Variables that allow dynamic changing of the page
    @State private var jug: Bool = false
    @State private var crimp: Bool = false
    @State private var pinch: Bool = false
    @State private var sloper: Bool = false
    @State private var pocket: Bool = false
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Types of Holds").font(.title).padding()
                Text("Here are some holds for your reference").multilineTextAlignment(.center).padding()
                Text("You may refer to this page as a guide for some of the holds you will encounter").multilineTextAlignment(.center)
                Text("Note: This is by no means an exhaustive list of all the holds but serves as an introduction").multilineTextAlignment(.center).font(.caption).padding()
                Group {
                    Button() {
                        jug.toggle()
                    } label: {
                        Text("Jug").bold(jug)
                    }.padding()
                    if jug {
                        Image("jugs").resizable().scaledToFit().frame(maxWidth:200, maxHeight:200)
                        Text("Everyone loves jugs! They offer the easiest form of climbing that allow you wrap your whole hand around the hold. These are the first sorts of holds that you will encounter during your climbing journey.").padding()
                    }
                    Button() {
                        crimp.toggle()
                    } label: {
                        Text("Crimp").bold(crimp)
                    }.padding()
                    if crimp {
                        Image("crimp").resizable().scaledToFit().frame(maxWidth:200, maxHeight:200)
                        Text("A crimp is a hold that has always been a challenge for newer climbers. They are very small holds that only allow the pads of your fingers to grab hold. Assuming positions such as the full hand crimp lets you fully utilise the hold, but proceed with caution! The position may cause injury if held inappropriately.").padding()
                    }
                    Button() {
                        pinch.toggle()
                    } label: {
                        Text("Pinch").bold(pinch)
                    }.padding()
                    if pinch {
                        Image("pinch").resizable().scaledToFit().frame(maxWidth:200, maxHeight:200)
                        Text("A pinch is any hold that requires the use of the thumb to pinch both sides of the hold - creating counterpressure. Newer climbers may find it difficult as the muscles in the thumb have not been developed fully, but there are a large variety of pinches that can even be offered to the easiest climbs.").padding()
                    }
                    Button() {
                        sloper.toggle()
                    } label: {
                        Text("Sloper").bold(sloper)
                    }.padding()
                    if sloper {
                        Image("sloper").resizable().scaledToFit().frame(maxWidth:200, maxHeight:200)
                        Text("Slopers are holds that have forever stumped new climbers! They are typically large, round holds that do not seem to offer any sort of grip. A tip to mastering this hold is to always hold the sloper with as much surface area of your palm as you can, which will increase the friction you have on the hold. Then hang very low whilst keeping your arms straight.").padding()
                    }
                    Button() {
                        pocket.toggle()
                    } label: {
                        Text("Pocket").bold(pocket)
                    }.padding()
                    if pocket {
                        Image("pocket").resizable().scaledToFit().frame(maxWidth:200, maxHeight:200)
                        Text("Pockets are holds that restrict the number of fingers you are able to fit in the hold. While harder pockets will only allow one or two fingers, pockets can still appear in easier climbs. These holds will test your finger strength and they are definitely worth trying out!").padding()
                    }
                }
            }
        }.padding()
    }
}

struct HoldsView_Previews: PreviewProvider {
    static var previews: some View {
        HoldsView()
    }
}
