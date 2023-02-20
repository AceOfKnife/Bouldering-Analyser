import SwiftUI
import Vision
import CoreML
import FirebaseAuth
import FirebaseStorage
import UIKit

class GradeClassifier: ObservableObject {
    private var user = Auth.auth().currentUser
    private var boundingBoxes: [UploadView.Box] = []
    private var heightWidth: CGSize = CGSize(width:0, height:0)
}


extension GradeClassifier {

    func initialiseClassifier(activeBoxes: [Bool], boundingBoxes: [UploadView.Box], heightWidth: CGSize) -> Void {
        for i in 0..<activeBoxes.count {
            if activeBoxes[i] {
                self.boundingBoxes.append(boundingBoxes[i])
            }
        }
        self.heightWidth = heightWidth
    }
    
    func getBoxes() -> [UploadView.Box] {
        return boundingBoxes
    }
    
    func mapBoxes() -> [[Int]] {
        var coordinates = [[Int]]()
        for _ in 0..<18 {
            for _ in 0..<11 {
                coordinates.append([])
            }
        }
        let mapX = { (x: Double) -> Double in
            return (11 / self.heightWidth.width) * x
        }
        let mapY = { (y: Double) -> Double in
            return (18 / self.heightWidth.height) * y
        }
        for box in boundingBoxes {
            let x = box.x
            let y = box.y
            let width = box.width
            let height = box.height
            let mappedX = mapX(x)
            let mappedY = mapY(y)
            let mappedWidth = mapX(width)
            let mappedHeight = mapY(height)
            let _ = print(mappedX)
            let _ = print(mappedY) 
            
        }
        return coordinates
    }
}
