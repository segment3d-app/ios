import SwiftUI
import MetalKit

private typealias ViewRepresentable = UIViewRepresentable

struct MetalKitSceneView: ViewRepresentable {
    var modelIdentifier: ModelIdentifier?
    
    class Coordinator {
        var renderer: MetalKitSceneRenderer?
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    func makeUIView(context: UIViewRepresentableContext<MetalKitSceneView>) -> MTKView {
        makeView(context.coordinator)
    }
    
    private func makeView(_ coordinator: Coordinator) -> MTKView {
        let metalKitView = CustomMTKView()
        
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            metalKitView.device = metalDevice
        }
        
        let renderer = MetalKitSceneRenderer(metalKitView)
        coordinator.renderer = renderer
        metalKitView.delegate = renderer
        
        metalKitView.touchesBeganHandler = { [weak renderer] touches, event in
            renderer?.handleTouchBegan(touches: touches, with: event, in: metalKitView)
        }
        metalKitView.touchesMovedHandler = { [weak renderer] touches, event in
            renderer?.handleTouchMoved(touches: touches, with: event, in: metalKitView)
        }
        metalKitView.touchesEndedHandler = { [weak renderer] touches, event in
            renderer?.handleTouchEnded(touches: touches, with: event, in: metalKitView)
        }
        metalKitView.setupGestureRecognizers()
        metalKitView.pinchGestureHandler = { [weak renderer] recognizer in
            renderer?.handlePinchGesture(recognizer: recognizer, in: metalKitView)
        }
        metalKitView.rotationHandler = { [weak renderer] recognizer in
            renderer?.handleRotationGesture(recognizer, in: metalKitView)
        }
        
        
        do {
            try renderer?.load(modelIdentifier)
        } catch {
            print("Error loading model: \(error.localizedDescription)")
        }
        
        return metalKitView
    }
    
    func updateUIView(_ view: MTKView, context: UIViewRepresentableContext<MetalKitSceneView>) {
        updateView(context.coordinator)
    }
    
    private func updateView(_ coordinator: Coordinator) {
        do {
            try coordinator.renderer?.load(modelIdentifier)
        } catch {
            print("Error loading model: \(error.localizedDescription)")
        }
    }
}
