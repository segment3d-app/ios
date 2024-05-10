import SwiftUI
import UIKit

struct ScannerWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = ViewController // Replace MyUIKitViewController with the name of your UIKit View Controller class

    func makeUIViewController(context: Context) -> ViewController {
        // Instantiate and return your UIKit View Controller
        return ViewController()
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        // Update the UIKit View Controller if needed
    }
}
