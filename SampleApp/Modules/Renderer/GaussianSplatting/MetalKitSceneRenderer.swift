import Metal
import MetalKit
import MetalSplatter
import SampleBoxRenderer
import simd
import SwiftUI

class MetalKitSceneRenderer: NSObject, MTKViewDelegate {
    let metalKitView: MTKView
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    
    var model: ModelIdentifier?
    var modelRenderer: (any ModelRenderer)?
    
    let inFlightSemaphore = DispatchSemaphore(value: Constants.maxSimultaneousRenders)
    
    var lastRotationUpdateTimestamp: Date? = nil
    var rotation: Angle = .zero
    
    var drawableSize: CGSize = .zero
    
    var fovy = Angle(degrees: 50)
    
    var lastTouchPosition: CGPoint?
    var accumulatedXRotation = Angle.zero
    var accumulatedYRotation = Angle.zero
    var xRotation: Angle = .zero
    var yRotation: Angle = .zero
    
    init?(_ metalKitView: MTKView) {
        self.device = metalKitView.device!
        guard let queue = self.device.makeCommandQueue() else { return nil }
        self.commandQueue = queue
        self.metalKitView = metalKitView
        metalKitView.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        metalKitView.depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8
        metalKitView.sampleCount = 1
        metalKitView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
    }
    
    func load(_ model: ModelIdentifier?) throws {
        guard model != self.model else { return }
        self.model = model
        
        modelRenderer = nil
        switch model {
        case .gaussianSplat(let url):
            let splat = try SplatRenderer(device: device,
                                          colorFormat: metalKitView.colorPixelFormat,
                                          depthFormat: metalKitView.depthStencilPixelFormat,
                                          stencilFormat: metalKitView.depthStencilPixelFormat,
                                          sampleCount: metalKitView.sampleCount,
                                          maxViewCount: 1,
                                          maxSimultaneousRenders: Constants.maxSimultaneousRenders)
            try splat.read(from: url)
            modelRenderer = splat
        case .sampleBox:
            modelRenderer = try! SampleBoxRenderer(device: device,
                                                   colorFormat: metalKitView.colorPixelFormat,
                                                   depthFormat: metalKitView.depthStencilPixelFormat,
                                                   stencilFormat: metalKitView.depthStencilPixelFormat,
                                                   sampleCount: metalKitView.sampleCount,
                                                   maxViewCount: 1,
                                                   maxSimultaneousRenders: Constants.maxSimultaneousRenders)
        case .none:
            break
        }
    }
    
    private var viewport: ModelRendererViewportDescriptor {
        let projectionMatrix = matrix_perspective_right_hand(fovyRadians: Float(fovy.radians),
                                                             aspectRatio: Float(drawableSize.width / drawableSize.height),
                                                             nearZ: 0.1,
                                                             farZ: 100.0)
        
        let xRotationMatrix = matrix4x4_rotation(radians: Float(xRotation.radians), axis: SIMD3<Float>(0, 1, 0))
        let yRotationMatrix = matrix4x4_rotation(radians: Float(yRotation.radians), axis: SIMD3<Float>(-1, 0, 0))
        let rotationMatrix = xRotationMatrix * yRotationMatrix
        
        let translationMatrix = matrix4x4_translation(0.0, 0.0, Constants.modelCenterZ)
        let commonUpCalibration = matrix4x4_rotation(radians: .pi, axis: SIMD3<Float>(0, 0, 1))
        
        let viewport = MTLViewport(originX: 0, originY: 0, width: drawableSize.width, height: drawableSize.height, znear: 0, zfar: 1)
        
        return ModelRendererViewportDescriptor(viewport: viewport,
                                               projectionMatrix: projectionMatrix,
                                               viewMatrix: translationMatrix * rotationMatrix * commonUpCalibration,
                                               screenSize: SIMD2(x: Int(drawableSize.width), y: Int(drawableSize.height)))
    }
    
    func handleTouchBegan(touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {
        guard let touch = touches.first else { return }
        lastTouchPosition = touch.location(in: view)
    }
    
    func handleTouchMoved(touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {
        guard let touch = touches.first, let lastPosition = lastTouchPosition else { return }
        let currentTouchPosition = touch.location(in: view)
        let rotationDeltaX = currentTouchPosition.x - lastPosition.x
        let rotationDeltaY = currentTouchPosition.y - lastPosition.y
        lastTouchPosition = currentTouchPosition
        
        let sensitivity: CGFloat = 0.5
        
        xRotation += Angle(degrees: Double(rotationDeltaX) * sensitivity)
        yRotation -= Angle(degrees: Double(rotationDeltaY) * sensitivity)
    }
    
    func handleTouchEnded(touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {
        lastTouchPosition = nil
    }
    
    func handlePinchGesture(recognizer: UIPinchGestureRecognizer, in view: UIView) {
        let _: CGFloat = 1.0
        if recognizer.state == .changed {
            let scale = Float(recognizer.scale)
            fovy.degrees = max(15, min(fovy.degrees * (1 / Double(scale)), 90))
            recognizer.scale = 1
        }
    }
    
    func handleRotationGesture(_ recognizer: UIRotationGestureRecognizer, in view: UIView) {
        if recognizer.state == .changed {
            let rotationDelta = CGFloat(recognizer.rotation)
            
            let touchPoint = recognizer.location(in: view)
            guard let lastPosition = lastTouchPosition else {
                lastTouchPosition = touchPoint
                return
            }
            let directionVector = CGPoint(x: touchPoint.x - lastPosition.x, y: touchPoint.y - lastPosition.y)
            let predominantDirection = abs(directionVector.x) > abs(directionVector.y) ? "horizontal" : "vertical"
            
            if predominantDirection == "horizontal" {
                yRotation += Angle(radians: Double(rotationDelta))
            } else {
                xRotation += Angle(radians: Double(rotationDelta))
            }
            
            recognizer.rotation = 0
            lastTouchPosition = touchPoint
        }
    }
    
    func draw(in view: MTKView) {
        guard let modelRenderer else { return }
        guard let drawable = view.currentDrawable else { return }
        
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            inFlightSemaphore.signal()
            return
        }
        
        let semaphore = inFlightSemaphore
        commandBuffer.addCompletedHandler { (_ commandBuffer)-> Swift.Void in
            semaphore.signal()
        }
        
        modelRenderer.render(viewports: [viewport],
                             colorTexture: view.multisampleColorTexture ?? drawable.texture,
                             colorStoreAction: view.multisampleColorTexture == nil ? .store : .multisampleResolve,
                             depthTexture: view.depthStencilTexture,
                             stencilTexture: view.depthStencilTexture,
                             rasterizationRateMap: nil,
                             renderTargetArrayLength: 0,
                             to: commandBuffer)
        
        commandBuffer.present(drawable)
        
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        drawableSize = size
    }
}
