import SwiftUI
import FirebaseStorage
import FirebaseAuth
import Vision
import CoreGraphics
import UIKit
import FirebaseDatabase

/**
 # Analysis View
 The page that the user sees after uploading an image onto the system to be analysed.
 It prepares the image to be analysed and sets up the inputs for the model to classify the image.
 It also displays the results of the classification.
 */
struct AnalysisView: View {
    @State var start = 0.0

    // User object storing the user of the current session and references to the database and storage
    @EnvironmentObject var user: User
    let storageRef = Storage.storage().reference()
    let dbRef = Database.database().reference()
    
    // Variable intially storing the holds identified by the object detection API from reading a JSON format
    @State var holds: [Holds] = []
    
    // Stores the image being analysed
    @State var image: UIImage?
    
    // `boundingBoxes` translates the `Holds` in `holds` into a `Box` object and stores it
    @State var boundingBoxes: [Box] = []
    
    // Variable storing boolean values indicating if a hold is selected by a user
    @State var activeBoxes: [Bool] = []
    
    // The variable storing the object that predicts a grade given an input
    @State var gradeClassifier: GradeClassifier = GradeClassifier()
    
    // The image to be analysed. Tested on `copy.jpg` from test@test.com's account
    // but can be changed to `analysing.jpg` to perform analysis on uploaded images
    @State var testingImage = "copy.jpg"
    
    // Variables for dynamic changing of the page
    @State var waiting = false
    @State var completed = false
    @State var invalidConfirm = false
    @State var failedContouring = false
    @State var confirmed = false
    @State var startMapping = false
    @State var startProcessing = false
    @State var scale = 0.5
    @State var completeGrading = true
    @State var grade = ""
    @State var realGrade = 0
    @State var yes = false
    @State var no = false
    @State var submit = false
    @State var progressWidth = 0.0
    @State var saving = false
    @State var uploadedRoute = false
    @State var successMessage = ""
    
    /**
     Function that dynamically changes the percentage bar.
     - Parameter scale: The amount complete `* 250` to scale it relative to the width of the progress bar
     */
    func modifyPercentBar(scale: Double) -> Void {
        self.progressWidth = scale * 250
    }
    
    /**
     Function that updates dynamic variables once the upload is complete
     */
    func uploadComplete() -> Void {
        self.uploadedRoute = true
        self.saving = false
        self.progressWidth = 0.0
    }
    
    func clearHolds() -> Void {
        for i in 0..<self.activeBoxes.count {
            self.activeBoxes[i] = false
        }
    }
    
    /**
     # Grade Structs
     These structs are of `View` type and are displayed once the result is computed
     */
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

    // Formatter to force inputs to be numbers only
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    /**
     # Box struct
     This object stores:
        - x: The x coordinate of the hold
        - y: The y coordinate of the hold
        - width: The width of the hold
        - height: The height of the hold
        - id: The ID of the object
     The object will be initialised for each hold identified by the object detection API.
     */
    struct Box: Identifiable {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
        var id: Int
    }
    
    /**
     # Holds struct
     The JSON response from the object detection API is parsed into this object with the variables:
        - confidence: The confidence scale on the object being a hold
        - height: The height of the hold
        - width: The width of the hold
        - x: The x coordinate of the hold
        - y: The y coordinate of the hold
     */
    struct Holds: Decodable {
        let confidence: Double
        let height: Double
        let width: Double
        let x: Double
        let y: Double
    }
    
    /**
     Function that initialises the variables storing the boxes for each hold identified by the API.
     */
    func initBoxes() -> Void {
        // Initially empties the variables
        self.boundingBoxes = []
        self.activeBoxes = []
        for (i, hold) in self.holds.enumerated() {
            // Initialises a `Box` object with the given parameters
            let properties = Box(x: hold.x, y: hold.y, width: hold.width, height: hold.height, id: i)
            self.boundingBoxes.append(properties)
            self.activeBoxes.append(false)
        }
    }
    
    /**
     Function that processes an image by retrieving the image from the Firebase storage and sending the API request
     */
    func processImage() -> Void {
        // Calling the storage reference to download the image and call the `sendRequest` function
        let imageRef = storageRef.child("images/\(user.user!.uid)/\(self.testingImage)")
        imageRef.getData(maxSize: Int64.max) { data, error in
            if let error = error {
                let _ = print(error)
            } else {
                self.sendRequest(image: UIImage(data: data!)!)
            }
        }
    }
    
    /**
     Asynchronous function that calls the API to use the object detection model and retrieves a response
     - Parameter image: The image that the user wants to be analysed
     Source: https://universe.roboflow.com/rock-climbing-coach/june-5-holdsi
     */
    func sendRequest(image: UIImage) -> Void {
        self.image = image
        
        // Processing the image to allow it to be sent via HTTP
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
                // Calling the `getResponse` function to parse the response
                self.getResponse(response: dict!)
            } catch {
                let _ = print(error.localizedDescription)
            }
        }).resume()
    }
    
    /**
     # Parsing Response
     This function parses the response using regular expressions converting it into a JSON object and initialises the boxes needed for highlighting the holds in the image
     - Parameter response: The dictionary storing the JSON response
     */
    func getResponse(response: [String: Any]) {
        // Intialising the regular expressions matching with patterns of the response
        let regex = try! NSRegularExpression(pattern: "  *class = Hold;\n")
        let regQuote = try! NSRegularExpression(pattern: "\"")
        let regConfidence = try! NSRegularExpression(pattern: "  *confidence")
        let regHeight = try! NSRegularExpression(pattern: "  *height")
        let regWidth = try! NSRegularExpression(pattern: "  .*width")
        let regX = try! NSRegularExpression(pattern: "  .*x")
        let regY = try! NSRegularExpression(pattern: "  .*y")
        let regEqls = try! NSRegularExpression(pattern: "=")
        let regSemi = try! NSRegularExpression(pattern: ";")
        
        // Converting the dictionary into a string
        var JSON = String(describing: response["predictions"])
        
        // Removing the first line, which is the header of the response and unnecessary strings at the end
        let firstLine = JSON.components(separatedBy: CharacterSet.newlines).first!
        let length = firstLine.count
        JSON = String(JSON.dropFirst(length+1))
        JSON = String(JSON.dropLast(4))
        
        // Adding square brackets at the start and end to fit the JSON format
        JSON = "[" + JSON + "]"
        // Initialising a `NSMutableString` to update the string acoordingly
        let mJSON = NSMutableString(string: JSON)
        
        // Replacing the matches with strings that follow the JSON format
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
        
        // Casting the `String` into an `Array`
        var JSONArray = Array(JSON)
        for i in 0..<JSON.count {
            // A comma is present before every closing brace `}`
            // They are removed systematically to follow the JSON format
            if JSONArray[i] == "}" {
                JSONArray[i-1] = " "
            }
        }
        // Casts it back into a `String` and filters out the whitespace
        JSON = String(JSONArray)
        JSON = JSON.filter{ !$0.isWhitespace}
                
        // Casts the `String` insto a Swift JSON object
        let jsonData = JSON.data(using: .utf8)!
        
        // Decodes the JSON string using the `Holds` struct that follows the same structure as the JSON string
        self.holds = try! JSONDecoder().decode([Holds].self, from: jsonData)
        
        // Sometimes the API does not detect any holds, which will be indicated on the app
        if self.holds.count == 0 {
            self.failedContouring = true
            self.completed = true
        } else {
            // Initialises the boxes needed for highlighting the holds in the image
            initBoxes()
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
                                    // Draws boxes around the holds detected by the API using `GeometryReader`
                                    GeometryReader { geometry in
                                        // Fetches each `Box` from the `boundingBoxes` array
                                        ForEach(boundingBoxes) { box in
                                            // Scales the width/height proportionally to the image width/height
                                            let widthScalar = geometry.size.width / image!.size.width
                                            let heightScalar = geometry.size.height / image!.size.height
                                            let boxWidth = box.width * widthScalar
                                            let boxHeight = box.height * heightScalar
                                            
                                            // Computes the coordinates of the centre of the bounding box
                                            // by scaling the x and y coordinates by the same height/weight factor
                                            let centre = CGPoint(x: box.x * widthScalar, y: box.y * heightScalar)
                                            
                                            // Calculates the x and y coordinates for the top left corner
                                            // of the bounding box by using a simple formula
                                            let trueX = centre.x - (boxWidth / 2)
                                            let trueY = centre.y - (boxHeight / 2)
                                            
                                            // Draws the rectangles using the computed coordinates and sizes
                                            Rectangle()
                                                .path(in: CGRect(
                                                    x: trueX,
                                                    y: trueY,
                                                    width: boxWidth,
                                                    height: boxHeight))
                                            
                                                // The outline of the box dynamically changes colour
                                                // based on if it is selected or not using variable `activeBoxes`
                                                .stroke(self.activeBoxes[box.id] ? Color.blue : Color.red, lineWidth: 2.0).contentShape(Rectangle().size(width: boxWidth, height: boxHeight).offset(x: trueX, y: trueY)).onTapGesture {
                                                    
                                                    // Binds the tap gesture of the box to updating the corresponding boolean value in `activeBoxes`
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
                            Button("Clear Selection") {
                                clearHolds()
                            }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.red.opacity(0.3)).cornerRadius(10)
                            Button("Confirm Selection") {
                                // Initialises the grade classifier object with given parameters
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
                    // Maps the boxes onto the Moonboard and finds large holds
                    let numLargeHolds = self.gradeClassifier.mapBoxes()
                    if numLargeHolds > 0 {
                        Text("Detected \(self.gradeClassifier.getNumLargeHolds()) large hold(s). This may cause an inaccurate grade result. Would you like to continue?").multilineTextAlignment(.center)
                        HStack {
                            Spacer()
                            Button("No") {
                                initBoxes()
                                self.startMapping = false
                                self.confirmed = false
                                self.completeGrading = false
                            }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.red.opacity(0.3)).cornerRadius(10)
                            Button("Yes") {
                                self.startMapping = false
                                self.completeGrading = true
                                
                                // Finally predicting the grade of the route
                                self.grade = self.gradeClassifier.predict()
                                
                                // To test the mapping function of the grade classifier
                                // let _ = print(self.gradeClassifier.testMapping())
                            }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.green.opacity(0.3)).cornerRadius(10)
                            Spacer()
                        }
                    } else {
                        Button("Reveal Grade") {
                            self.startMapping = false
                            self.completeGrading = true
                            self.grade = self.gradeClassifier.predict()
                        }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.green.opacity(0.3)).cornerRadius(10)
                    }
                } else if completeGrading {
                    ScrollView {
                        // Uses the structs declared earlier to display the results
                        Text("Grade").font(.largeTitle).bold()
                        Text(self.grade).font(.largeTitle).bold().padding()
                        if self.grade == "V2" {
                            V2()
                        } else if self.grade == "V3" {
                            V3()
                        } else if self.grade == "V4" {
                            V4()
                        } else if self.grade == "V5" {
                            V5()
                        } else if self.grade == "V6" {
                            V6()
                        }
                        if !self.yes && !self.no {
                            
                            // Gives the user the option to send in a request for the correct grade
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
                            
                            // Button that allows saving the route and its grade
                            Button("Save route") {
                                if !self.saving {
                                    self.saving = true
                                    
                                    // Retrieves the selected boxes from the gradeClassifier object
                                    let boxes = self.gradeClassifier.getBoxes()
                                    
                                    // Converting the `Box` type into a dictionary storing its properties
                                    var saveBoxes: [[String: Double]] = []
                                    for box in boxes {
                                        saveBoxes.append(["x":box.x,"y":box.y,"width":box.width,"height":box.height])
                                    }
                                    
                                    // Using the integer casted timestamp as a unique ID for the route being saved in the database
                                    let timestamp = Int(NSDate().timeIntervalSince1970)
                                    self.dbRef.child("users/\(user.user!.uid)/routesID/\(timestamp)").setValue(saveBoxes)
                                    
                                    // Also stores the image of the route by attaching a metadata tag that stores
                                    // a custom metadata for the grade of the given route. Also uses timestamp as a unique ID
                                    let metadata = StorageMetadata()
                                    metadata.customMetadata = ["Grade": grade]
                                    metadata.contentType = "image/jpeg"
                                    let uploadRef = self.storageRef.child("images").child(user.user!.uid).child("saved/\(timestamp).jpg")
                                    let uploadTask = uploadRef.putData(self.image!.jpegData(compressionQuality: 1)!, metadata: metadata)
                                    uploadTask.observe(.progress) { snapshot in
                                        
                                        // Displays the progress of the upload
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

struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisView()
    }
}
