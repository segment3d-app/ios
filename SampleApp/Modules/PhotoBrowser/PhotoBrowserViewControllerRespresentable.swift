//
//  PhotoBrowserViewControllerRespresentable.swift
//  MetalSplatter SampleApp
//
//  Created by I Made Indra Mahaarta on 22/05/24.
//

import SwiftUI
import UIKit

struct PhotoBrowserViewControllerRepresentable: UIViewControllerRepresentable {
    var images: [String]
    
    func makeUIViewController(context: Context) -> PhotoBrowserViewController {
        return PhotoBrowserViewController(images: images)
    }
    
    func updateUIViewController(_ uiViewController: PhotoBrowserViewController, context: Context) {
        
    }
}
