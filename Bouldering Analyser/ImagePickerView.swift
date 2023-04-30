import UIKit
import SwiftUI

/**
 # Image Picker View
 This *View* allows users to upload their own images on their device by either taking a photo or uploading one from their library.
 Credit: https://www.hackingwithswift.com/books/ios-swiftui/importing-an-image-into-swiftui-using-phpickerviewcontroller
 */
struct ImagePickerView: UIViewControllerRepresentable {

    // The variable storing the selected image
    @Binding var selectedImage: UIImage?
    
    // Using a presentation mode to overlay the other pages
    @Environment(\.presentationMode) var isPresented
    
    // Variable storing whether its a camera or photo upload
    var sourceType: UIImagePickerController.SourceType
        
    // Functions that are required for the UIViewController protocol
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = self.sourceType
        imagePicker.delegate = context.coordinator
        return imagePicker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(picker: self)
    }
}

// Class that initialises the image picking system
class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var picker: ImagePickerView
    
    init(picker: ImagePickerView) {
        self.picker = picker
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        self.picker.selectedImage = selectedImage
        self.picker.isPresented.wrappedValue.dismiss()
    }
    
}
