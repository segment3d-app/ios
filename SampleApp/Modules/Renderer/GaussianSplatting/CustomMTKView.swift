import UIKit
import MetalKit

class CustomMTKView: MTKView {
    var touchesMovedHandler: ((Set<UITouch>, UIEvent?) -> Void)?
    var touchesBeganHandler: ((Set<UITouch>, UIEvent?) -> Void)?
    var touchesEndedHandler: ((Set<UITouch>, UIEvent?) -> Void)?
    var pinchGestureHandler: ((UIPinchGestureRecognizer) -> Void)?
    var rotationHandler: ((UIRotationGestureRecognizer) -> Void)?

    // Implement the override methods to call the handlers
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesMovedHandler?(touches, event)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesBeganHandler?(touches, event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEndedHandler?(touches, event)
    }
    
    func setupGestureRecognizers() {
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture(_:)))
        self.addGestureRecognizer(rotationGestureRecognizer)
        self.addGestureRecognizer(pinchRecognizer)
    }

    
    @objc func handleRotationGesture(_ recognizer: UIRotationGestureRecognizer) {
        rotationHandler?(recognizer)
    }
    
    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        pinchGestureHandler?(recognizer)
    }
}

