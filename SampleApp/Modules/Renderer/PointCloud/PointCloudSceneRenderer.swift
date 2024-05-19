import Foundation
import UIKit
import SceneKit
import ARKit

class PointCloudSceneRenderer: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    var sceneView: ARSCNView!
    var chosenCloud: URL!
    var spinnerView: UIActivityIndicatorView!

    init(chosenCloud: URL) {
        self.chosenCloud = chosenCloud
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // Initialize and set up the ARSCNView
        sceneView = ARSCNView(frame: self.view.frame)
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = true
        sceneView.allowsCameraControl = true
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sceneView)
        
        spinnerView = UIActivityIndicatorView(style: .large)
        spinnerView.color = .white
        spinnerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinnerView)
        
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.leftAnchor.constraint(equalTo: view.leftAnchor),
            sceneView.rightAnchor.constraint(equalTo: view.rightAnchor),
            spinnerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinnerView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        spinnerView.startAnimating()
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self, let chosenCloud = self.chosenCloud else { return }
            
            let xDir: Float = 0
            let yDir: Float = 0
            let zDir: Float = -7
            
            let scene = SCNScene()
            let pointCloud = FileReader.readFile(url: chosenCloud)
            
            for point in pointCloud {
                let x = point[0]
                let y = point[1]
                let z = point[2]
                let r = point[3] / 255.0
                let g = point[4] / 255.0
                let b = point[5] / 255.0
                
                let node = getCircleNode(location: SCNVector3(x,y,z), r: Float(r), g: Float(g), b: Float(b))
                
                node.position.x += xDir
                node.position.y += yDir
                node.position.z += zDir
                
                node.name = String(x+y*z)
                scene.rootNode.addChildNode(node)
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.spinnerView.stopAnimating()
                
                self?.sceneView.scene = scene
                self?.sceneView.scene.background.contents = UIColor.black
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        sceneView.session.delegate = nil
        sceneView.removeFromSuperview()
        sceneView = nil
    }

    // MARK: - ARSCNViewDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) { }
    
    func sessionWasInterrupted(_ session: ARSession) { }
    
    func sessionInterruptionEnded(_ session: ARSession) { }
}

// Helper functions
func getCircleNode(location: SCNVector3, r: Float, g: Float, b: Float) -> SCNNode {
    // Create the color using the RGB values provided
    let color = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
    
    let sphere = SCNSphere(radius: 0.005)
    sphere.firstMaterial?.lightingModel = SCNMaterial.LightingModel.constant
    sphere.firstMaterial?.diffuse.contents = color
    
    let node = SCNNode(geometry: sphere)
    node.position = location
    
    return node
}
