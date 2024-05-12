import SwiftUI
import UIKit

struct ScannerWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = ViewController
    
    let onDone: (_ path: String) -> Void
    
    init(onDone: @escaping (_ path: String) -> Void) {
        self.onDone = onDone
    }

    func makeUIViewController(context: Context) -> ViewController {
        let viewController = ViewController(onDone: onDone)
        return viewController
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
    }
}
