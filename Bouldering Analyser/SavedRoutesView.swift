import SwiftUI
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import CoreGraphics
import UIKit

struct SavedRoutesView: View {
    @EnvironmentObject var user: User
    @State var metaDatas: [String: [String: String]] = [String: [String: String]]()
    @State var images: [String: UIImage] = [String: UIImage]()
    @State var boxes: [String: [[String: Double]]] = [String: [[String: Double]]]()
    @State var routes: [Route] = [Route]()
    @State var obtainedData = false
    @State var calling = false
    @State var fail = false
    @State var confirm: [Int: String] = [:]
    let storageRef = Storage.storage().reference()
    let dbRef = Database.database().reference()
    
    struct Route: Identifiable {
        var id: Int
        let image: UIImage
        let boxes: [Box]
        let grade: String
        let date: String
    }
    
    struct Box: Identifiable {
        var id: Int
        let x: Double
        let y: Double
        let width: Double
        let height: Double
    }
    
    func getData() -> Void {
        self.dbRef.child("users/\(user.user!.uid)/routes").getData(completion:  { error, snapshot in
          guard error == nil else {
            print(error!.localizedDescription)
            return;
          }
            if let _ = snapshot!.value as? NSNull {
                failed()
            } else {
                addBoxes(boxes: snapshot!.value as! [String: [[String: Double]]])
            }
        });
    }
    
    func failed() -> Void {
        self.fail = true
    }
    
    func addBoxes(boxes: [String: [[String: Double]]]) -> Void {
        self.boxes = boxes
        self.getImages()
    }
    
    func getImages() -> Void {
        for (key, _) in self.boxes {
            let imageRef = storageRef.child("images/\(user.user!.uid)/saved/\(key).jpg")
            imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                if let error = error {
                    let _ = print(error)
                } else {
                    self.addImages(key: key, image: UIImage(data: data!)!)
                }
            }
        }
    }
    
    func addImages(key: String, image: UIImage) -> Void {
        self.images[key] = image
        if self.images.count == self.boxes.count {
            for (key, _) in self.images {
                let imageRef = storageRef.child("images/\(user.user!.uid)/saved/\(key).jpg")
                imageRef.getMetadata { metadata, error in
                  if let error = error {
                    let _ = print(error)
                  } else {
                      self.addMetaData(key: key, metadata: metadata!)
                  }
                }
            }
        }
    }
    
    func addMetaData(key: String, metadata: StorageMetadata) {
        let grade = metadata.customMetadata!["Grade"]!
        let date = metadata.timeCreated!.formatted(date: .abbreviated, time: .standard)
        self.metaDatas[key] = ["Grade": grade, "Date": date]
        if self.metaDatas.count == self.images.count {
            for (key, _) in self.boxes {
                let id = Int(key)
                let image = self.images[key]
                var boxes: [Box] = []
                for (i, box) in self.boxes[key]!.enumerated() {
                    let theBox = Box(id:i,x:box["x"]!,y:box["y"]!,width:box["width"]!,height:box["height"]!)
                    boxes.append(theBox)
                }
                let grade = self.metaDatas[key]!["Grade"]
                let date = self.metaDatas[key]!["Date"]
                let route = Route(id:id!,image:image!,boxes:boxes,grade:grade!,date:date!)
                self.routes.append(route)
                self.confirm[Int(key)!] =  ""
            }
            self.obtainedData = true
        }
    }
    
    func deleteRoute(routeID: Int) -> Void {
        let id = String(routeID)
        let routeRef = storageRef.child("images/\(user.user!.uid)/saved/\(id).jpg")
        routeRef.delete { error in
          if let error = error {
            let _ = print(error)
          } else {
              deleteDBRef(routeID: id)
          }
        }
    }
    
    func deleteDBRef(routeID: String) -> Void {
        self.dbRef.child("users/\(user.user!.uid)/routes/\(routeID)").removeValue { error, _ in
            if let error = error {
                let _ = print(error)
            } else {
                completeDelete(routeID: routeID)
            }
        }
    }
    
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
                } else if self.obtainedData {
                    ForEach(routes) { route in
                        VStack {
                            Text("Grade: \(route.grade)").bold()
                            Text("\(route.date)")
                            Image(uiImage: route.image)
                                .resizable()
                                .scaledToFit()
                                .overlay(
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
