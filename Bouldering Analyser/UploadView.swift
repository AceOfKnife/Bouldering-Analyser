import SwiftUI
import FirebaseStorage
import FirebaseAuth
import Vision
import CoreGraphics
import UIKit
import FirebaseDatabase

struct UploadView: View {
    @EnvironmentObject var user: User
    let storageRef = Storage.storage().reference()
    let dbRef = Database.database().reference()
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
    @State var startMapping = false
    @State var startProcessing = false
    @State var scale = 0.5
    @State var completeGrading = true
    @State var realGrade = 0
    @State var yes = false
    @State var no = false
    @State var submit = false
    @State var progressWidth = 0.0
    @State var saving = false
    @State var uploadedRoute = false
    @State var successMessage = ""
    
    func modifyPercentBar(scale: Double) -> Void {
        self.progressWidth = scale * 250
    }
    
    func uploadComplete() -> Void {
        self.uploadedRoute = true
        self.saving = false
        self.progressWidth = 0.0
    }
    
    struct V2: View {
        var body: some View {
            Text("Our algorithms have graded this route a V2 - which is a beginner level climb.").padding().multilineTextAlignment(.center)
            Text("To climb these routes successfully, make sure you review the fundamentals of climbing.").padding().multilineTextAlignment(.center)
            Text("Always try to climb with your arms straight and step onto footholds with the tip of your shoe to allow for maximum ankle rotation.").padding().multilineTextAlignment(.center)
        }
    }
    
    struct V3: View {
        var body: some View {
            Text("Our algorithms have graded this route a V3 - which is an intermediate level climb.").padding().multilineTextAlignment(.center)
            Text("Climbing these routes will test your understanding of the core basics of climbing.").padding().multilineTextAlignment(.center)
            Text("Compared to V2 routes, these will have more dynamic and technical moves that will challenge the way you think about climbing.").padding().multilineTextAlignment(.center)
            Text("Conquering V3 graded routes is generally seen as a benchmark for a solid climber. Keep pushing!").padding().multilineTextAlignment(.center)
        }
    }
    
    struct V4: View {
        var body: some View {
            Text("Our algorithms have graded this route a V4 - which is an intermediate level climb.").padding().multilineTextAlignment(.center)
            Text("A V4 graded route is seen as the first great hurdle for many climbers.").padding().multilineTextAlignment(.center)
            Text("More strength and technique comes into play when attemping these routes.").padding().multilineTextAlignment(.center)
            Text("You may be introduced to new holds that you have never climbed before, like crimps and slopers.").padding().multilineTextAlignment(.center)
            Text("Mastering V4 graded routes will take time and dedication and will make you a much better climber than before.").padding().multilineTextAlignment(.center)
        }
    }
    
    struct V5: View {
        var body: some View {
            Text("Our algorithms have graded this route a V5 - which is an advanced level climb.").padding().multilineTextAlignment(.center)
            Text("A lot more strength will be required to climb these routes.").padding().multilineTextAlignment(.center)
            Text("Being able to climb these routes will solidify you as a great climber.").padding().multilineTextAlignment(.center)
            Text("There will be a variety of holds and techniques that you must incorporate into your climb in order to successfuly send this grade.").padding().multilineTextAlignment(.center)
            Text("Climbing a V5 graded route is a great achievement and will make you well above the average climber.").padding().multilineTextAlignment(.center)
        }
    }
    
    struct V6: View {
        var body: some View {
            Text("Our algorithms have graded this route a V6 - which is an advanced level climb.").padding().multilineTextAlignment(.center)
            Text("These grades will really challenge your body positions and climbing knowledge.").padding().multilineTextAlignment(.center)
            Text("The route will force you into extreme situations that will challenge your climbing abilities.").padding().multilineTextAlignment(.center)
            Text("It is recommended that you first strengthen your body to keep up with the demands of a V6 graded route before attempting one.").padding().multilineTextAlignment(.center)
        }
    }

    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
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
        self.boundingBoxes = []
        self.activeBoxes = []
        for (i, hold) in self.holds.enumerated() {
            let properties = Box(x: hold.x, y: hold.y, width: hold.width, height: hold.height, id: i)
            self.boundingBoxes.append(properties)
            self.activeBoxes.append(false)
        }
    }
    
    func processImage() -> Void {
        let imageRef = storageRef.child("images/\(user.user!.uid)/analysing.jpg")
        imageRef.getData(maxSize: Int64.max) { data, error in
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
            self.completed = true
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
                                let result = self.gradeClassifier.initialiseClassifier(activeBoxes: self.activeBoxes, boundingBoxes: self.boundingBoxes, heightWidth: self.image!.size)
                                if result == 0 {
                                    self.invalidConfirm = true
                                } else {
                                    self.invalidConfirm = false
                                    self.confirmed = true
                                    self.startMapping = true
                                }
                            }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.green.opacity(0.3)).cornerRadius(10)
                            if self.invalidConfirm {
                                Text("Please select at least one hold to proceed").foregroundColor(.red)
                            }
                        }
                    }
                }
                else if startMapping {
                    Text("Mapping your route").font(.largeTitle).padding()
                    HStack {
                        DotView()
                        DotView(delay: 0.2)
                        DotView(delay: 0.4)
                    }
                    let numLargeHolds = self.gradeClassifier.mapBoxes()
                    let _ = print(self.gradeClassifier.testMapping())
                    if numLargeHolds > 0 {
                        Text("Detected \(self.gradeClassifier.getNumLargeHolds()) large hold(s). This may cause an inaccurate grade result. Would you like to continue?").multilineTextAlignment(.center)
                        HStack {
                            Spacer()
                            Button("No") {
                                drawBoxes()
                                self.startMapping = false
                                self.confirmed = false
                                self.completeGrading = false
                            }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.red.opacity(0.3)).cornerRadius(10)
                            Button("Yes") {
                                self.startMapping = false
                                self.completeGrading = true
                            }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.green.opacity(0.3)).cornerRadius(10)
                            Spacer()
                        }
                    } else {
                        Button("Reveal Grade") {
                            self.startMapping = false
                            self.completeGrading = true
                        }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.green.opacity(0.3)).cornerRadius(10)
                    }
                } else if completeGrading {
                    ScrollView {
                        Text("Grade").font(.largeTitle).bold()
                        let grade = self.gradeClassifier.predict()
                        Text(grade).font(.largeTitle).bold().padding()
                        if grade == "V2" {
                            V2()
                        } else if grade == "V3" {
                            V3()
                        } else if grade == "V4" {
                            V4()
                        } else if grade == "V5" {
                            V5()
                        } else {
                            V6()
                        }
                        if !self.yes && !self.no {
                            HStack{
                                Text("Was this grading accurate?").multilineTextAlignment(.center)
                                Spacer()
                                Button {
                                    yes = true
                                    self.gradeClassifier.uploadData(correct: true, realGrade: self.realGrade)
                                } label: {
                                    Image("thumbsup").resizable().scaledToFit().frame(maxWidth:30, maxHeight:30)
                                }.padding()
                                Button {
                                    no = true
                                } label: {
                                    Image("thumbsdown").resizable().scaledToFit().frame(maxWidth:30, maxHeight:30)
                                }.padding()
                            }.padding()
                        } else if yes {
                            Text("Thank you for the feedback!").foregroundColor(Color.green).multilineTextAlignment(.center)
                        } else {
                            if !self.submit {
                                HStack {
                                    Text("What was the real grade?").multilineTextAlignment(.center)
                                    Spacer()
                                    Text("V")
                                    TextField("(2-6)", value: $realGrade, formatter: formatter)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .padding()
                                    Spacer()
                                    Button("Submit") {
                                        self.submit = true
                                        self.gradeClassifier.uploadData(correct: false, realGrade: self.realGrade)
                                    }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.green.opacity(0.3)).cornerRadius(10)
                                }
                            } else if self.submit {
                                if self.realGrade <= 6 && self.realGrade >= 2 {
                                    Text("Your feedback will be used to improve the model!").foregroundColor(Color.green).multilineTextAlignment(.center)
                                } else {
                                    Text("Please enter a grade between V2-V6.").foregroundColor(Color.red).multilineTextAlignment(.center)
                                    Button("Try again") {
                                        self.submit = false
                                    }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.red.opacity(0.3)).cornerRadius(10)
                                }
                            }
                        }
                        if !self.uploadedRoute {
                            Button("Save route") {
                                if !self.saving {
                                    self.saving = true
                                    let boxes = self.gradeClassifier.getBoxes()
                                    var saveBoxes: [[String: Double]] = []
                                    for box in boxes {
                                        saveBoxes.append(["x":box.x,"y":box.y,"width":box.width,"height":box.height])
                                    }
                                    let metadata = StorageMetadata()
                                    let timestamp = Int(NSDate().timeIntervalSince1970)
                                    self.dbRef.child("users/\(user.user!.uid)/routes/\(timestamp)").setValue(saveBoxes)
                                    metadata.customMetadata = ["Grade": grade]
                                    metadata.contentType = "image/jpeg"
                                    let uploadRef = self.storageRef.child("images").child(user.user!.uid).child("saved/\(timestamp).jpg")
                                    let uploadTask = uploadRef.putData(self.image!.jpegData(compressionQuality: 1)!, metadata: metadata)
                                    uploadTask.observe(.progress) { snapshot in
                                        let percentComplete = Double(snapshot.progress!.completedUnitCount)
                                        / Double(snapshot.progress!.totalUnitCount)
                                        modifyPercentBar(scale: percentComplete)
                                    }
                                    uploadTask.observe(.success) { snapshot in
                                        uploadComplete()
                                    }
                                }
                            }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.green.opacity(0.3)).cornerRadius(10)
                        } else {
                            Text("Saving complete!").foregroundColor(Color.green).multilineTextAlignment(.center)
                        }
                        if self.saving {
                            VStack {
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerSize: CGSize(width: 0.1, height: 0.1)).frame(maxWidth:250, maxHeight: 5).foregroundColor(Color.black).cornerRadius(5)
                                    RoundedRectangle(cornerSize: CGSize(width: 0.1, height: 0.1)).frame(maxWidth:self.progressWidth, maxHeight: 5).foregroundColor(Color.green).cornerRadius(5).animation(.linear)
                                }
                                Text(String(Int(self.progressWidth / 250 * 100)) + "%")
                            }.padding()
                        }
                    }
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
