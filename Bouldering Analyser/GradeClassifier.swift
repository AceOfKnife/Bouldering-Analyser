import SwiftUI
import Vision
import CoreML
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase
import UIKit
import Accelerate

/**
 # GradeClassifier Class
 This class is used to parse the `model.json` file and prepare a given input to feed into the model.
 */
class GradeClassifier: ObservableObject {
    private var user = Auth.auth().currentUser
    private var boundingBoxes: [AnalysisView.Box] = []
    
    // Variable storing the height and the width of the image
    private var heightWidth: CGSize = CGSize(width:0, height:0)
    
    // Variable storing the coordinates of the selected boxes mapped onto the Moonboard
    private var coordinates: [[Int]] = [[]]
    
    // The input mapped to the Moonboard and flattened to be put into the Database later
    private var data: [Int] = []
    
    // The number of large holds detected by the algorithm
    private var numLargeHolds = 0
    
    // Grade initially set to -1
    private var grade: Int = -1
    
    let dbRef = Database.database().reference()
    
    // Arrays to convert the coordinates and integer-encoded grades
    let grades: [String] = ["V2","V3","V4","V5","V6"]
    let conversion_y: [String] = ["18","17","16","15","14","13","12","11","10","9","8","7","6","5","4","3","2","1"]
    let conversion_x: [String] = ["A","B","C","D","E","F","G","H","I","J","K"]
    
    /**
     The Model struct used to store the `model.json` after parsing. Contains the variables:
        - weights: The weights of the network
        - biases: The biases of the network
     */
    private struct Model: Decodable {
        let weights: Weights
        let biases: Biases
    }
    
    /**
     The Weights struct that stores each layer's weights:
        - layer_n: Weights for the *n*th layer of the network
    */
    private struct Weights: Decodable {
        let layer_1: [[Double]]
        let layer_2: [[Double]]
        let layer_3: [[Double]]
        let layer_4: [[Double]]
    }
    
    /**
     The Biases struct that stores each layer's biases:
        - layer_n: Biases for the *n*th layer of the network
     */
    private struct Biases: Decodable {
        let layer_1: [Double]
        let layer_2: [Double]
        let layer_3: [Double]
        let layer_4: [Double]
    }
}

extension GradeClassifier {
    
    /**
     Function initialising the classifier by setting the class' variables.
     - Parameters:
        - activeBoxes: Stores if the user has selected a particular box
        - boundingBoxes: An array of all the boxes around the holds of an image
        - heightWidth: The height and width of the image
     - Returns: The number of boxes selected by the user
     */
    func initialiseClassifier(activeBoxes: [Bool], boundingBoxes: [AnalysisView.Box], heightWidth: CGSize) -> Int {
        // Appends the box into `self.boundingBoxes` if they are active
        self.boundingBoxes = []
        for i in 0..<activeBoxes.count {
            if activeBoxes[i] {
                self.boundingBoxes.append(boundingBoxes[i])
            }
        }
        self.heightWidth = heightWidth
        // Returns the number of bounding boxes selected to check if the user has selected any
        return self.boundingBoxes.count
    }
    
    /**
     Function that maps the bounding boxes selected by the user onto the Moonboard coordinate system.
     Reference: https://www.moonboard.com/content/images/2020/holds/mbsetup-mbm2017-min.jpg
     - Returns: The number of large holds detected
     */
    func mapBoxes() -> Int {
        var numLargeHolds = 0
        
        // Initialising coordinate grid similar to the Moonboard
        var coordinates = [[Int]]()
        for _ in 0..<18 {
            var row = [Int]()
            for _ in 0..<11 {
                row.append(0)
            }
            coordinates.append(row)
        }
        
        // Mapping the x and y coordinates by scaling relative to the Moonboard array
        let mapX = { (x: Double) -> Double in
            return (10 / self.heightWidth.width) * x
        }
        let mapY = { (y: Double) -> Double in
            return (17 / self.heightWidth.height) * y
        }
        
        // For every box, apply the functions and check if the area is greater than 1.0
        for box in boundingBoxes {
            let mappedX = Int(round(mapX(box.x)))
            let mappedY = Int(round(mapY(box.y)))
            let mappedWidth = mapX(box.width)
            let mappedHeight = mapY(box.height)
            let area = mappedWidth * mappedHeight
            if area > 1.0 {
                numLargeHolds += 1
            }
            // mappedY is used first because it travels down the rows
            // and mappedX travels across the columns
            coordinates[mappedY][mappedX] = 1
        }
        self.coordinates = coordinates
        self.numLargeHolds = numLargeHolds
        return numLargeHolds
    }
    
    /**
     Simple function that returns the number of large holds detected by the mapping procedure
     - Returns: The number of large holds
     */
    func getNumLargeHolds() -> Int {
        return self.numLargeHolds
    }
    
    /**
     Function used to predict a given input using the model. Parses the `model.json` file into a `Model` object.
     - Returns: The predicted grade
     */
    func predict() -> String {
        // Reading the `model.json` file
        let url = Bundle.main.url(forResource: "model", withExtension: "json")
        let modelData = try! Data(contentsOf: url!)
        let model: Model = try! JSONDecoder().decode(Model.self, from: modelData)
        
        // The coordinates are converted to Double
        let input: [[Double]] = self.coordinates.map{$0.compactMap(Double.init)}
        let M = input.count
        let N = input[0].count
        
        // `x` is a flattened version of `self.coordinates` and a Double type
        var x: [Double] = []
        
        // `self.data` is a flattened version of `self.coordinates` but of the same type Int
        if self.data == [] {
            for j in 0..<N {
                for i in stride(from: M-1, to: -1, by: -1) {
                    x.append(input[i][j])
                    self.data.append(self.coordinates[i][j])
                }
            }
        }
        
        // Forward-propagation through the network using ReLU between layers and Softmax at the end
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
        
        // Retrieving the argmax of the result from the final layer to get the prediction
        var maximum = 0.0
        var index = 0
        for i in 0..<layer_4.count {
            if layer_4[i] > maximum {
                maximum = layer_4[i]
                index = i
            }
        }
        
        // Converting the encoded index grades into their actual grade
        self.grade = index
        return self.grades[index]
    }
    
    /**
     The function for computing the  multiplication between a vector A and a matrix B using a simple algorithm.
     - Parameters:
        - A: The vector being multiplied
        - B: The matrix being multiplied
     - Returns: The vector product of A and B
     */
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
    
    /**
     Function that performs the vector addition between two vectors A and B by iterating through.
     - Parameters:
        - A: The first vector to be added
        - B: The second vector to be added
     - Returns: The vector sum of A and B
     */
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
    
    /**
     Function applying the ReLU function to an array
     - Parameter x: An array to apply the ReLU function
     - Returns: An array of the same shape but with ReLU applied
     */
    func relu(x: [Double]) -> [Double] {
        var f_x = x
        let N = x.count
        for i in 0..<N {
            f_x[i] = max(0.0, x[i])
        }
        return f_x
    }
    
    /**
     Function that applies the Softmax function to an array
     - Parameter x: An array to apply the Softmax function
     - Returns: An array of the same shape but with the Softmax function applied
     */
    func softmax(x: [Double]) -> [Double] {
        // Uses the 'safe' softmax function to prevent overflow errors
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
    
    /**
     Function that uploads graded routes onto the Firebase database with their correct grade and input data in the same format as the input for the model
     - Parameters:
        - correct: Indicates if the grade was predicted correctly, decided by the user
        - realGrade: The actual grade of the route if given
     */
    func uploadData(correct: Bool, realGrade: Int) -> Void {
        if correct {
            self.dbRef.child("data").childByAutoId().setValue(["Grade": self.grade, "Coordinates": self.data, "correctGrade": true, "userID": self.user!.uid]) { error,_  in
                if let error = error {
                    let _ = print(error)
                } else {
                    return
                }
            }
        } else {
            // Invalid grades will just return
            if realGrade > 6 || realGrade < 2 {
                return
            }
            self.dbRef.child("data").childByAutoId().setValue(["Grade": realGrade-2, "Coordinates": self.data, "correctGrade": false, "userID": self.user!.uid]) { error,_  in
                if let error = error {
                    let _ = print(error)
                } else {
                    return
                }
            }
        }
    }
    
    /**
     Simple function that returns only the selected boxes by the user
     - Returns: The selected boxes by the user
     */
    func getBoxes() -> [AnalysisView.Box] {
        return self.boundingBoxes
    }
    
    /**
     A function that allows the testing of the mapping function
     - Returns: The mapped coordinates of the holds in Moonboard coordinate form
     */
    func testMapping() -> [String] {
        let N = self.coordinates.count
        let M = self.coordinates[0].count
        var result: [String] = []
        for i in 0..<N {
            for j in 0..<M {
                if self.coordinates[i][j] == 1 {
                    // Using the conversion arrays to display their corresponding Moonboard coordinates
                    result.append(self.conversion_x[j] + self.conversion_y[i])
                }
            }
        }
        return result
    }
}
