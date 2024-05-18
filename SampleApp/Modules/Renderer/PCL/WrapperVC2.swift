//
//  WrapperVC2.swift
//  MetalSplatter SampleApp
//
//  Created by I Made Indra Mahaarta on 19/05/24.
//

import SwiftUI

struct WrapperVC2: UIViewControllerRepresentable {
    func updateUIViewController(_ uiViewController: VisualizeControllerV2, context: Context) {
    }
    
    typealias UIViewControllerType = VisualizeControllerV2
    
    func makeUIViewController(context: Context) -> VisualizeControllerV2 {
        let viewController = VisualizeControllerV2()
        return viewController
    }
}
