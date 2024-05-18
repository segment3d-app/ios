import Foundation
import UIKit
import SceneKit
import ARKit

class VisualizeControllerV2: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    var sceneView: ARSCNView!
    var chosenCloud: URL! = getPointCloud(forDirectory: "2024-05-19_021749")
    
    var tappedNode: SCNNode!
    var prevColor: Any!
    var firstCoordinate: SCNVector3!
    var secondCoordinate: SCNVector3!
    var distanceLine: SCNNode!
    
    var backButton = UIButton(type: .system)
    var modeButton = UIButton(type: .system)
    var infoText = UILabel()
    
    var volumeMode = true
    var volumeText = "Click to get volume"
    var distanceText = "Click two points"
    
    var volumeArray = [Double]()
    
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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(rec:)))
        sceneView.addGestureRecognizer(tap)
        
        // Initialize and set up the back button
        backButton.setBackgroundImage(.init(systemName: "arrowshape.turn.up.left.fill"), for: .normal)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(toMainMenu), for: .touchUpInside)
        backButton.tintColor = .white
        view.addSubview(backButton)
        
        // Auto Layout constraints
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.leftAnchor.constraint(equalTo: view.leftAnchor),
            sceneView.rightAnchor.constraint(equalTo: view.rightAnchor),
            
            backButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 50),
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            backButton.widthAnchor.constraint(equalToConstant: 50),
            backButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        // Load and display the point cloud
        var xDir: Float = Float.infinity
        var yDir: Float = Float.infinity
        var zDir: Float = Float.infinity

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
            if xDir == Float.infinity {
                xDir = 0 - node.position.x
                yDir = 0 - node.position.y
                zDir = -7 - node.position.z
            }
            
            node.position.x += xDir
            node.position.y += yDir
            node.position.z += zDir
            
            node.name = String(x+y*z)
            scene.rootNode.addChildNode(node)
        }
        
        sceneView.scene = scene
        sceneView.scene.background.contents = UIColor.black
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    @objc func toMainMenu() {
        sceneView.session.pause()
    }
    
    @objc func changeMode() {
        volumeMode = !volumeMode
        
        if volumeMode {
            modeButton.setBackgroundImage(.init(systemName: "rectangle.fill"), for: .normal)
            infoText.text = volumeText
            firstCoordinate = nil
            secondCoordinate = nil
            
            if distanceLine != nil {
                distanceLine.removeFromParentNode()
            }
            distanceLine = nil
        } else {
            modeButton.setBackgroundImage(.init(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
            infoText.text = distanceText
            if tappedNode != nil {
                sceneView.scene.rootNode.childNodes.filter({ $0.name == tappedNode.name }).forEach({
                    let material = $0.geometry!.firstMaterial!
                    material.diffuse.contents = prevColor
                })
            }
            tappedNode = nil
        }
    }
    
    @objc func handleTap(rec: UITapGestureRecognizer) {
       if rec.state == .ended {
           let location: CGPoint = rec.location(in: sceneView)
           let hits = self.sceneView.hitTest(location, options: nil)
           
           if !hits.isEmpty {
               if volumeMode {
                   handleTapVolume(hits: hits)
               } else {
                   handleTapDistance(hits: hits)
               }
           }
       }
    }
    
    func handleTapVolume(hits: [SCNHitTestResult]) {
        if tappedNode != nil {
            sceneView.scene.rootNode.childNodes.filter({ $0.name == tappedNode.name }).forEach({
                let material = $0.geometry!.firstMaterial!
                material.diffuse.contents = prevColor
            })
        }
        
        tappedNode = hits.first?.node
        sceneView.scene.rootNode.childNodes.filter({ $0.name == tappedNode.name }).forEach({
            let material = $0.geometry!.firstMaterial!
            prevColor = material.diffuse.contents
            material.diffuse.contents = UIColor.white
        })
        
        let id = Int(tappedNode.name!)!
        let vol = volumeArray[id]
        let volRounded = Double(round(1000 * vol) / 1000)
        
        if vol == -1 {
            infoText.text = "Volume undefined"
        } else if vol < 0.001 {
            infoText.text = "Volume < 0.001 m^3"
        } else {
            infoText.text = "Volume: \(volRounded) m^3"
        }
    }
    
    func handleTapDistance(hits: [SCNHitTestResult]) {
        if firstCoordinate == nil {
            firstCoordinate = hits.first?.worldCoordinates
            infoText.text = "Tap a second location"
            if distanceLine != nil {
                distanceLine.removeFromParentNode()
            }
        } else if secondCoordinate == nil {
            secondCoordinate = hits.first?.worldCoordinates
            
            let scene = sceneView.scene
            distanceLine = lineBetweenNodes(positionA: firstCoordinate, positionB: secondCoordinate, inScene: scene)
            let dist = getDistance(node1Pos: firstCoordinate, node2Pos: secondCoordinate)
            
            scene.rootNode.addChildNode(distanceLine)
            infoText.text = "Distance: \(dist) m\nTap a new location"
            
            firstCoordinate = nil
            secondCoordinate = nil
        }
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
    
    let sphere = SCNSphere(radius: 0.01)
    sphere.firstMaterial?.lightingModel = SCNMaterial.LightingModel.constant
    sphere.firstMaterial?.diffuse.contents = color
    
    let node = SCNNode(geometry: sphere)
    node.position = location
    
    return node
}


func getDistance(node1Pos: SCNVector3, node2Pos: SCNVector3) -> Float {
    let distance = SCNVector3(
        node2Pos.x - node1Pos.x,
        node2Pos.y - node1Pos.y,
        node2Pos.z - node1Pos.z
    )
    return sqrtf(distance.x * distance.x + distance.y * distance.y + distance.z * distance.z)
}

func lineBetweenNodes(positionA: SCNVector3, positionB: SCNVector3, inScene: SCNScene) -> SCNNode {
    let vector = SCNVector3(positionA.x - positionB.x, positionA.y - positionB.y, positionA.z - positionB.z)
    let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    let midPosition = SCNVector3((positionA.x + positionB.x) / 2, (positionA.y + positionB.y) / 2, (positionA.z + positionB.z) / 2)

    let lineGeometry = SCNCylinder()
    lineGeometry.radius = 0.005
    lineGeometry.height = CGFloat(distance)
    lineGeometry.radialSegmentCount = 5
    lineGeometry.firstMaterial!.diffuse.contents = UIColor.white

    let lineNode = SCNNode(geometry: lineGeometry)
    lineNode.position = midPosition
    lineNode.look(at: positionB, up: inScene.rootNode.worldUp, localFront: lineNode.worldUp)
    return lineNode
}
