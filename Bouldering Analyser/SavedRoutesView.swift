import SwiftUI
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import CoreGraphics
import UIKit

/**
 # Saved Routes View
 The page that displays all of the routes that a user has saved in chronologically descending order.
 Calls upon the Firebase Storage and Database to re-draw selected the boxes  onto the image and retrieve the predicted grade.
 */
struct SavedRoutesView: View {
    @EnvironmentObject var user: User
    
    // Variable storing the metadata in a dictionary
    @State var metaDatas: [Date: [String: String]] = [Date: [String: String]]()
    
    // Stores all the images of the user in a dictionary
    @State var images: [String: UIImage] = [String: UIImage]()
    
    // Stores the boxes for each corresponding route saved in a dictionary
    @State var boxes: [String: [[String: Double]]] = [String: [[String: Double]]]()
    
    // Array storing the `Route` objects
    @State var routes: [Route] = [Route]()
    
    // Variables for dynamic changes to the page
    @State var obtainedData = false
    @State var calling = false
    @State var fail = false
    
    // Confirm dictionary used to identify which route is being deleted
    @State var confirm: [Int: String] = [:]
    
    // Array storing the Dates of the routes
    @State var dates: [Date] = [Date]()
    
    let storageRef = Storage.storage().reference()
    let dbRef = Database.database().reference()
    
    /**
     `Route` object that stores elements found from the database and storage:
        - id: A given ID for the route
        - image: The image of the route
        - boxes: An array storing all the boxes
        - grade: The grade of the route
        - date: The date of the route saved
     */
    struct Route: Identifiable {
        var id: Int
        let image: UIImage
        let boxes: [Box]
        let grade: String
        let date: String
    }
    
    /**
     Same `Box` object as in `UploadView`. Contains variables:
        - id: A given ID for the box
        - x: The x coordinate of the box
        - y: The y coordinate of the box
        - width: The width of the box
        - height: The height of the box
     */
    struct Box: Identifiable {
        var id: Int
        let x: Double
        let y: Double
        let width: Double
        let height: Double
    }
    
    /**
     Function retrieves the boxes from the database for every single route saved by the user
     */
    func getData() -> Void {
        self.dbRef.child("users/\(user.user!.uid)/routesID").getData(completion:  { error, snapshot in
          guard error == nil else {
            return;
          }
            if let _ = snapshot!.value as? NSNull {
                // If the object is empty, then there are no saved routes
                failed()
            } else {
                // Calls a function to set the variables as the boxes
                addBoxes(boxes: snapshot!.value as! [String: [[String: Double]]])
            }
        });
    }
    
    /**
     Simple function that sets the global variable fail to true to dynamically change the page
     */
    func failed() -> Void {
        self.fail = true
    }
    
    /**
     Function that sets the boxes found in the Firebase database
     - Parameter boxes: Dictionary array containing the ID of the routes as the key and an array storing the properties of each box for that route as the value
     */
    func addBoxes(boxes: [String: [[String: Double]]]) -> Void {
        self.boxes = boxes
        // Calls the `getImages` function to retrieve the images for each of the routes in the Firebase Storage
        self.getImages()
    }
    
    /**
     Function that retrieves the images for every route saved by the user
     */
    func getImages() -> Void {
        // The key is the integer timestamp and is the ID for that route
        for (key, _) in self.boxes {
            let imageRef = storageRef.child("images/\(user.user!.uid)/saved/\(key).jpg")
            imageRef.getData(maxSize: Int64.max) { data, error in
                if let error = error {
                    return
                } else {
                    // Calls the `addImages` to add each image found into the dictionary
                    self.addImages(key: key, image: UIImage(data: data!)!)
                }
            }
        }
    }
    
    /**
     Function that adds the images to the dictionary `images` with the key being the integer timestamp and the value as the image
     - Parameters:
        - key: The integer timestamp of the route
        - image: The image of the route
     */
    func addImages(key: String, image: UIImage) -> Void {
        self.images[key] = image
        // Function stops here until the number of images matches the number of routes retrieved
        if self.images.count == self.boxes.count {
            // Retrieves the metadata tags for each of the images
            for (key, _) in self.images {
                let imageRef = storageRef.child("images/\(user.user!.uid)/saved/\(key).jpg")
                imageRef.getMetadata { metadata, error in
                  if let error = error {
                    return
                  } else {
                      self.addMetaData(key: key, metadata: metadata!)
                  }
                }
            }
        }
    }
    
    /**
     Function that stores the metadata tags into the corresponding variables
     - Parameters:
        - key: The integer timestamp of the route
        - metadata: The metadata of the image
     */
    func addMetaData(key: String, metadata: StorageMetadata) {
        let grade = metadata.customMetadata!["Grade"]!
        let date = metadata.timeCreated!
        let dateString = date.formatted(date: .abbreviated, time: .standard)
        
        // The `metaDatas` dictionary uses the date as the key and references the integer timestamp key
        self.metaDatas[date] = ["Grade": grade, "Date": dateString, "Key": key]
        
        self.dates.append(date)
        
        // Waits until the number of metadatas is the same as the number of routes retrieved
        if self.metaDatas.count == self.images.count {
            // Sorts the dates by descending order
            self.dates.sort(by: >)
            for time in self.dates {
                
                // Uses the `metaDatas` dictionary to retrieve the routes in the same order
                let boxKey = self.metaDatas[time]!["Key"]!
                let id = Int(boxKey)
                let image = self.images[boxKey]
                var boxes: [Box] = []
                
                // Initialises each of the boxes as a `Box` object
                for (i, box) in self.boxes[boxKey]!.enumerated() {
                    let theBox = Box(id:i,x:box["x"]!,y:box["y"]!,width:box["width"]!,height:box["height"]!)
                    boxes.append(theBox)
                }
                
                let grade = self.metaDatas[time]!["Grade"]
                let date = self.metaDatas[time]!["Date"]
                
                // Appends a new `Route` object and stores it in the `route` array
                let route = Route(id:id!,image:image!,boxes:boxes,grade:grade!,date:date!)
                self.routes.append(route)
                
                // Initialises the ID in the `confirm` dictionary as "" to later be used as a display method
                self.confirm[id!] =  ""
            }
            
            // Flag that describes the data being fully retrieved
            self.obtainedData = true
        }
    }
    
    /**
     Function that deletes a route
     - Parameter routeID: The integer timestamp of the given route to be deleted
     */
    func deleteRoute(routeID: Int) -> Void {
        let id = String(routeID)
        
        // First deletes it in the Firebase Storage
        let routeRef = storageRef.child("images/\(user.user!.uid)/saved/\(id).jpg")
        routeRef.delete { error in
          if let error = error {
            return
          } else {
              // Then, deletes it in the Firebase Database
              deleteDBRef(routeID: id)
          }
        }
    }
    
    /**
     Function that deletes a given route in the Firebase Database
     - Parameter routeID: The integer timestamp of the given route to be deleted
     */
    func deleteDBRef(routeID: String) -> Void {
        // Calls the database reference to remove the given route
        self.dbRef.child("users/\(user.user!.uid)/routesID/\(routeID)").removeValue { error, _ in
            if let error = error {
                return
            } else {
                // Calls the function to indicate success
                completeDelete(routeID: routeID)
            }
        }
    }
    
    /**
     Function that updates the confirm dictionary to display a message
     - Parameter routeID: The integer timestamp of the given route to be deleted
     */
    func completeDelete(routeID: String) -> Void {
        let id = Int(routeID)
        self.confirm[id!] = "Successfully deleted!"
    }
    
    var body: some View {
        Text("Saved Routes").font(.title)
        ScrollView {
            VStack {
                if !self.calling {
                    Button("Get routes") {
                        self.calling = true
                        self.getData()
                    }.foregroundColor(.black).frame(minWidth: 0, idealWidth: 180, maxWidth:180, minHeight: 0, idealHeight: 40, maxHeight:40).background(Color.green.opacity(0.3)).cornerRadius(10)
                }
                // Waits until the data is fully obtained
                else if self.obtainedData {
                    ForEach(routes) { route in
                        VStack {
                            Text("Grade: \(route.grade)").bold()
                            Text("\(route.date)")
                            Image(uiImage: route.image)
                                .resizable()
                                .scaledToFit()
                                .overlay(
                                    // Re-drawing the selected boxes in the image
                                    GeometryReader { geometry in
                                        ForEach(route.boxes) { box in
                                            let widthScalar = geometry.size.width / route.image.size.width
                                            let heightScalar = geometry.size.height / route.image.size.height
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
                                                .stroke(Color.red, lineWidth: 2.0)
                                        }
                                    }
                                )
                            HStack {
                                Text(self.confirm[route.id]!)
                                if self.confirm[route.id] != "Successfully deleted!" {
                                    // Button to confirm deleting a saved route
                                    Button {
                                        if self.confirm[route.id] == "" {
                                            self.confirm[route.id] = "Are you sure?"
                                        } else {
                                            deleteRoute(routeID: route.id)
                                        }
                                    } label: {
                                        Image("bin").resizable().scaledToFit().frame(maxWidth:30, maxHeight:30)
                                    }
                                }
                            }.padding()
                        }.padding().border(.black, width:0.5)
                    }
                }
                if self.fail {
                    // Displays if the user has no saved routes
                    Text("You have no saved routes.").foregroundColor(Color.red).multilineTextAlignment(.center)
                }
            }
        }
    }
}

struct SavedRoutesView_Previews: PreviewProvider {
    static var previews: some View {
        SavedRoutesView()
    }
}
