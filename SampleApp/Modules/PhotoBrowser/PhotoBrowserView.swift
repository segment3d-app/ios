//
//  PhotoBrowserView.swift
//  MetalSplatter SampleApp
//
//  Created by I Made Indra Mahaarta on 22/05/24.
//

import SwiftUI

struct PhotoBrowserView: View {
    var images: [String]
    var assetId: String
    var onSegment: (_ url: String) -> Void
    
    var body: some View {
        PhotoBrowserViewControllerRepresentable(images: images, assetId: assetId, onSegment: onSegment)
            .edgesIgnoringSafeArea(.all)
    }
}
