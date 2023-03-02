import SwiftUI
import Vision
import CoreML
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase
import UIKit
import Accelerate

class GradeClassifier: ObservableObject {
    private var user = Auth.auth().currentUser
    private var boundingBoxes: [UploadView.Box] = []
    private var heightWidth: CGSize = CGSize(width:0, height:0)
    private var coordinates: [[Int]] = [[]]
    private var data: [Int] = []
    private var numLargeHolds = 0
    private var grade: Int = -1
    let dbRef = Database.database().reference()
    let grades: [String] = ["V2","V3","V4","V5","V6"]
    let conversion_x: [String] = ["18","17","16","15","14","13","12","11","10","9","8","7","6","5","4","3","2","1"]
    let conversion_y: [String] = ["A","B","C","D","E","F","G","H","I","J","K"]
    
    private struct Model: Decodable {
        let weights: Weights
        let biases: Biases
    }
    
    private struct Weights: Decodable {
        let layer_1: [[Double]]
        let layer_2: [[Double]]
        let layer_3: [[Double]]
        let layer_4: [[Double]]
    }
    
    private struct Biases: Decodable {
        let layer_1: [Double]
        let layer_2: [Double]
        let layer_3: [Double]
        let layer_4: [Double]
    }
}

extension GradeClassifier {
    
    func initialiseClassifier(activeBoxes: [Bool], boundingBoxes: [UploadView.Box], heightWidth: CGSize) -> Int {
        self.boundingBoxes = []
        for i in 0..<activeBoxes.count {
            if activeBoxes[i] {
                self.boundingBoxes.append(boundingBoxes[i])
            }
        }
        self.heightWidth = heightWidth
        return self.boundingBoxes.count
    }
    
    func mapBoxes() -> Int {
        var numLargeHolds = 0
        var coordinates = [[Int]]()
        for _ in 0..<18 {
            var row = [Int]()
            for _ in 0..<11 {
                row.append(0)
            }
            coordinates.append(row)
        }
        let mapX = { (x: Double) -> Double in
            return (10 / self.heightWidth.width) * x
        }
        let mapY = { (y: Double) -> Double in
            return (17 / self.heightWidth.height) * y
        }
        for box in boundingBoxes {
            let mappedX = Int(round(mapX(box.x)))
            let mappedY = Int(round(mapY(box.y)))
            let mappedWidth = mapX(box.width)
            let mappedHeight = mapY(box.height)
            let area = mappedWidth * mappedHeight
            if area > 1.0 {
                numLargeHolds += 1
            }
            coordinates[mappedY][mappedX] = 1
        }
        self.coordinates = coordinates
        self.numLargeHolds = numLargeHolds
        return numLargeHolds
    }
    
    func getNumLargeHolds() -> Int {
        return self.numLargeHolds
    }
    
    func predict() -> String {
        let url = Bundle.main.url(forResource: "model", withExtension: "json")
        let data = try! Data(contentsOf: url!)
        let model: Model = try! JSONDecoder().decode(Model.self, from: data)
        let input: [[Double]] = self.coordinates.map{$0.compactMap(Double.init)}
        let M = input.count
        let N = input[0].count
        var x: [Double] = []
        if self.data == [] {
            for j in 0..<N {
                for i in stride(from: M-1, to: -1, by: -1) {
                    x.append(input[i][j])
                    self.data.append(self.coordinates[i][j])
                }
            }
        }
        let weights_1: [[Double]] =  model.weights.layer_1
        let bias_1: [Double] = model.biases.layer_1
        let layer_1 = relu(x: vecadd(A: vecmul(A: x, B: weights_1), B: bias_1))
        
        let weights_2: [[Double]] =  model.weights.layer_2
        let bias_2: [Double] = model.biases.layer_2
        let layer_2 = relu(x: vecadd(A: vecmul(A: layer_1, B: weights_2), B: bias_2))
        
        let weights_3: [[Double]] =  model.weights.layer_3
        let bias_3: [Double] = model.biases.layer_3
        let layer_3 = relu(x: vecadd(A: vecmul(A: layer_2, B: weights_3), B: bias_3))
        
        let weights_4: [[Double]] =  model.weights.layer_4
        let bias_4: [Double] = model.biases.layer_4
        let layer_4 = softmax(x: vecadd(A: vecmul(A: layer_3, B: weights_4), B: bias_4))
        var maximum = 0.0
        var index = 0
        for i in 0..<layer_4.count {
            if layer_4[i] > maximum {
                maximum = layer_4[i]
                index = i
            }
        }
        self.grade = index
        return self.grades[index]
    }
    
    func vecmul(A: [Double], B: [[Double]]) -> [Double] {
        if A.count != B.count {
            return []
        }
        let M = A.count
        let P = B[0].count
        var C = Array(repeating: 0.0, count: P)
        for j in 0..<P {
            var sum = 0.0
            for k in 0..<M {
                sum += A[k] * B[k][j]
            }
            C[j] = sum
        }
        return C
    }
    
    func vecadd(A: [Double], B: [Double]) -> [Double] {
        if A.count != B.count {
            return []
        }
        let N = A.count
        var C = A
        for i in 0..<N {
            C[i] = A[i] + B[i]
        }
        return C
    }
    
    func relu(x: [Double]) -> [Double] {
        var f_x = x
        let N = x.count
        for i in 0..<N {
            f_x[i] = max(0.0, x[i])
        }
        return f_x
    }
    
    func softmax(x: [Double]) -> [Double] {
        let max_x = x.max()
        var exps = x
        for i in 0..<x.count {
            exps[i] = exp(x[i] - max_x!)
        }
        let sum = exps.reduce(0, +)
        for i in 0..<exps.count {
            exps[i] = exps[i] / sum
        }
        return exps
    }
    
    func uploadData(correct: Bool, realGrade: Int) -> Void {
        if correct {
            self.dbRef.child("data").childByAutoId().setValue(["Grade": self.grade, "Coordinates": self.data, "Correct": true]) { error,_  in
                if let error = error {
                    let _ = print(error)
                } else {
                    return
                }
            }
        } else {
            if realGrade > 6 || realGrade < 2 {
                return
            }
            self.dbRef.child("data").childByAutoId().setValue(["Grade": realGrade-2, "Coordinates": self.data, "Correct": false]) { error,_  in
                if let error = error {
                    let _ = print(error)
                } else {
                    return
                }
            }
        }
    }
    
    func getBoxes() -> [UploadView.Box] {
        return self.boundingBoxes
    }
    
    func testMapping() -> [String] {
        let N = self.coordinates.count
        let M = self.coordinates[0].count
        var result: [String] = []
        for i in 0..<N {
            for j in 0..<M {
                if self.coordinates[i][j] == 1 {
                    result.append(self.conversion_y[j] + self.conversion_x[i])
                }
            }
        }
        return result
    }
}
