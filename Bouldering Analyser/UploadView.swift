import SwiftUI
import FirebaseStorage
import FirebaseAuth
import Vision
import CoreGraphics
import UIKit

struct UploadView: View {
    @EnvironmentObject var user: User
    let storageRef = Storage.storage().reference()
    @State var holds: [Holds] = []
    @State var image: UIImage?
    @State var waiting = false
    @State var completed = false
    @State var boundingBoxes: [Box] = []
    @State var activeBoxes: [Bool] = []
    @State var gradeClassifier: GradeClassifier = GradeClassifier()
    @State var invalidConfirm = false
    @State var failedContouring = false
    @State var confirmed = false
    @State var finishProcessing = false
    @State var scale = 0.5

    struct Box: Identifiable {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
        var id: Int
    }
    
    struct Holds: Decodable {
        let confidence: Double
        let height: Double
        let width: Double
        let x: Double
        let y: Double
    }
    
    func drawBoxes() {
        for (i, hold) in self.holds.enumerated() {
            let properties = Box(x: hold.x, y: hold.y, width: hold.width, height: hold.height, id: i)
            self.boundingBoxes.append(properties)
            self.activeBoxes.append(false)
        }
    }
    
    func processImage() -> Void {
        let imageRef = storageRef.child("images/\(user.user!.uid)/copy.jpg")
        imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                let _ = print(error)
            } else {
                self.sendRequest(image: UIImage(data: data!)!)
            }
        }
    }
    
    func sendRequest(image: UIImage) -> Void {
        
        self.image = image
        let imageData = image.jpegData(compressionQuality: 1)
        let fileContent = imageData?.base64EncodedString()
        let postData = fileContent!.data(using: .utf8)

        // Initialize Inference Server Request with API KEY, Model, and Model Version
        var request = URLRequest(url: URL(string: "https://detect.roboflow.com/june-5-holds/1?api_key=I0p6TiUjusbhf6X0PLva&name=YOUR_IMAGE.jpg")!,timeoutInterval: Double.infinity)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = postData

        // Execute Post Request
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in

            // Parse Response to String
            guard let data = data else {
                let _ = print(String(describing: error))
                return
            }

            // Convert Response String to Dictionary
            do {
                let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                self.getResponse(response: dict!)
            } catch {
                let _ = print(error.localizedDescription)
            }

            // Print String Response
            // let _ = print(String(data: data, encoding: .utf8)!)
        }).resume()
    }
    
    func getResponse(response: [String: Any]) {
        let regex = try! NSRegularExpression(pattern: "  *class = Hold;\n")
        let regQuote = try! NSRegularExpression(pattern: "\"")
        let regConfidence = try! NSRegularExpression(pattern: "  *confidence")
        let regHeight = try! NSRegularExpression(pattern: "  *height")
        let regWidth = try! NSRegularExpression(pattern: "  .*width")
        let regX = try! NSRegularExpression(pattern: "  .*x")
        let regY = try! NSRegularExpression(pattern: "  .*y")
        let regEqls = try! NSRegularExpression(pattern: "=")
        let regSemi = try! NSRegularExpression(pattern: ";")
        var JSON = String(describing: response["predictions"])
        let firstLine = JSON.components(separatedBy: CharacterSet.newlines).first!
        let length = firstLine.count
        JSON = String(JSON.dropFirst(length+1))
        JSON = String(JSON.dropLast(4))
        JSON = "[" + JSON + "]"
        let mJSON = NSMutableString(string: JSON)
        regex.replaceMatches(in: mJSON, options: [], range: NSMakeRange(0, mJSON.length), withTemplate: "")
        regQuote.replaceMatches(in: mJSON, options: [], range: NSMakeRange(0, mJSON.length), withTemplate: "")
        regConfidence.replaceMatches(in: mJSON, options: [], range: NSMakeRange(0, mJSON.length), withTemplate: "\"confidence\"")
        regHeight.replaceMatches(in: mJSON, options: [], range: NSMakeRange(0, mJSON.length), withTemplate: "\"height\"")
        regWidth.replaceMatches(in: mJSON, options: [], range: NSMakeRange(0, mJSON.length), withTemplate: "\"width\"")
        regX.replaceMatches(in: mJSON, options: [], range: NSMakeRange(0, mJSON.length), withTemplate: "\"x\"")
        regY.replaceMatches(in: mJSON, options: [], range: NSMakeRange(0, mJSON.length), withTemplate: "\"y\"")
        regEqls.replaceMatches(in: mJSON, options: [], range: NSMakeRange(0, mJSON.length), withTemplate: ":")
        regSemi.replaceMatches(in: mJSON, options: [], range: NSMakeRange(0, mJSON.length), withTemplate: ",")
        JSON = String(mJSON)
        JSON = JSON.filter{ !$0.isWhitespace}
        var JSONArray = Array(JSON)
        for i in 0..<JSON.count {
            if JSONArray[i] == "}" {
                JSONArray[i-1] = " "
            }
        }
        JSON = String(JSONArray)
        JSON = JSON.filter{ !$0.isWhitespace}
        let jsonData = JSON.data(using: .utf8)!
        self.holds = try! JSONDecoder().decode([Holds].self, from: jsonData)
        if self.holds.count == 0 {
            self.failedContouring = true
        } else {
            drawBoxes()
            self.completed = true
        }
    }
    
    var body: some View {

        NavigationView {
            VStack {
                if !completed {
                    if !waiting {
                        Button("Start Hold Selection") {
                            waiting = true
                            self.processImage()
                        }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.mint.opacity(0.3)).cornerRadius(10)
                    } else {
                        Text("Processing...").font(.largeTitle)
                        HStack {
                            DotView()
                            DotView(delay: 0.2)
                            DotView(delay: 0.4)
                        }
                    }
                } else if failedContouring {
                    Text("Failed to identify any holds. Please try another image.").foregroundColor(.red)
                } else if !confirmed {
                    ScrollView {
                        VStack {
                            Text("Holds Selection").font(.largeTitle).bold().padding().multilineTextAlignment(.center)
                            Image(uiImage: image!)
                                .resizable()
                                .scaledToFit()
                                .overlay(
                                    GeometryReader { geometry in
                                        ForEach(boundingBoxes) { box in
                                            let widthScalar = geometry.size.width / image!.size.width
                                            let heightScalar = geometry.size.height / image!.size.height
                                            let boxWidth = box.width * widthScalar
                                            let boxHeight = box.height * heightScalar
                                            let centre = CGPoint(x: box.x * widthScalar, y: box.y * heightScalar)
                                            let trueX = centre.x - (boxWidth / 2)
                                            let trueY = centre.y - (boxHeight / 2)
                                            Rectangle()
                                                .path(in: CGRect(
                                                    x: trueX,
                                                    y: trueY,
                                                    width: boxWidth,
                                                    height: boxHeight))
                                                .stroke(self.activeBoxes[box.id] ? Color.blue : Color.red, lineWidth: 2.0).contentShape(Rectangle().size(width: boxWidth, height: boxHeight).offset(x: trueX, y: trueY)).onTapGesture {
                                                    self.activeBoxes[box.id].toggle()
                                                }
                                        }
                                    }
                                )
                            Text("Tap on the holds of your route").padding()
                            HStack {
                                Spacer()
                                Text("Red: ")
                                    .frame(alignment: .trailing)
                                    .foregroundColor(Color.red)
                                Text("Unselected holds")
                                    .frame(alignment: .leading)
                                Spacer()
                            }
                            HStack {
                                Spacer()
                                Text("Blue: ")
                                    .frame(alignment: .trailing)
                                    .foregroundColor(Color.blue)
                                Text("Selected holds")
                                    .frame(alignment: .leading)
                                Spacer()
                            }
                            Button("Confirm Selection") {
                                self.gradeClassifier.initialiseClassifier(activeBoxes: self.activeBoxes, boundingBoxes: self.boundingBoxes, heightWidth: self.image!.size)
                                if self.gradeClassifier.getBoxes().count == 0 {
                                    self.invalidConfirm = true
                                } else {
                                    self.invalidConfirm = false
                                    self.confirmed = true
                                }
                                let _ = print(String(describing: self.gradeClassifier.getBoxes()))
                            }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.green.opacity(0.3)).cornerRadius(10)
                            if self.invalidConfirm {
                                Text("Please select at least one hold to proceed").foregroundColor(.red)
                            }
                        }
                    }
                }
                else if !finishProcessing {
                    Text("Grading your route").font(.largeTitle).padding()
                    HStack {
                        DotView()
                        DotView(delay: 0.2)
                        DotView(delay: 0.4)
                    }
                    let test = self.gradeClassifier.mapBoxes()
                }
            }
        }
    }
}

struct UploadView_Previews: PreviewProvider {
    static var previews: some View {
        UploadView()
    }
}
