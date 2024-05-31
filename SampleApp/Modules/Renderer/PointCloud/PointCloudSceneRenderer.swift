import Foundation
import UIKit
import SceneKit

class PointCloudSceneRenderer: UIViewController {
    var sceneView: SCNView!
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
        
        sceneView = SCNView(frame: self.view.frame)
        sceneView.allowsCameraControl = true
        sceneView.showsStatistics = true
        sceneView.backgroundColor = .black
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
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let chosenCloud = self.chosenCloud else { return }
            
            let scene = SCNScene()
            let pointCloud = FileReader.readFile(url: chosenCloud)
            
            let vertices = pointCloud.map { point -> SCNVector3 in
                return SCNVector3(point[0], point[1], point[2])
            }
            
            let colors = pointCloud.map { point -> UIColor in
                let r = point[3] / 255.0
                let g = point[4] / 255.0
                let b = point[5] / 255.0
                return UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
            }
            
            let geometry = self.createPointCloudGeometry(vertices: vertices, colors: colors)
            
            let node = SCNNode(geometry: geometry)
            scene.rootNode.addChildNode(node)
            
            DispatchQueue.main.async {
                self.spinnerView.stopAnimating()
                self.sceneView.scene = scene
            }
        }
    }
    
    private func createPointCloudGeometry(vertices: [SCNVector3], colors: [UIColor]) -> SCNGeometry {
        let vertexData = vertices.flatMap { [$0.x, $0.y, $0.z] }
        let colorData = colors.flatMap { color -> [Float] in
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return [Float(red), Float(green), Float(blue), Float(alpha)]
        }
        
        let vertexSource = SCNGeometrySource(data: Data(bytes: vertexData, count: vertexData.count * MemoryLayout<Float>.size),
                                             semantic: .vertex,
                                             vectorCount: vertices.count,
                                             usesFloatComponents: true,
                                             componentsPerVector: 3,
                                             bytesPerComponent: MemoryLayout<Float>.size,
                                             dataOffset: 0,
                                             dataStride: MemoryLayout<Float>.size * 3)
        
        let colorSource = SCNGeometrySource(data: Data(bytes: colorData, count: colorData.count * MemoryLayout<Float>.size),
                                            semantic: .color,
                                            vectorCount: colors.count,
                                            usesFloatComponents: true,
                                            componentsPerVector: 4,
                                            bytesPerComponent: MemoryLayout<Float>.size,
                                            dataOffset: 0,
                                            dataStride: MemoryLayout<Float>.size * 4)
        
        let indices = Array(0..<vertices.count)
        let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<Int32>.size)
        let element = SCNGeometryElement(data: indexData,
                                         primitiveType: .point,
                                         primitiveCount: vertices.count,
                                         bytesPerIndex: MemoryLayout<Int32>.size)
        
        let geometry = SCNGeometry(sources: [vertexSource, colorSource], elements: [element])
        geometry.firstMaterial?.isDoubleSided = true
        geometry.firstMaterial?.lightingModel = .constant
        print(geometry)
        
        return geometry
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.scene = nil
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        sceneView.removeFromSuperview()
        sceneView = nil
    }
}
