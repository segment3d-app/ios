//
//  PointCloudSceneView.swift
//  MetalSplatter SampleApp
//
//  Created by I Made Indra Mahaarta on 19/05/24.
//

import SwiftUI

struct PointCloudSceneView: UIViewControllerRepresentable {
    var chosenCloud: URL!
    
    func updateUIViewController(_ uiViewController: PointCloudSceneRenderer, context: Context) {
    }
    
    typealias UIViewControllerType = PointCloudSceneRenderer
    
    func makeUIViewController(context: Context) -> PointCloudSceneRenderer {
        let viewController = PointCloudSceneRenderer(chosenCloud: chosenCloud)
        return viewController
    }
}
