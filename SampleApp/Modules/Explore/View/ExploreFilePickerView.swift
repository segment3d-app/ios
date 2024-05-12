//
//  ExploreFilePickerView.swift
//  Segment3D
//
//  Created by I Made Indra Mahaarta on 09/04/24.
//

import SwiftUI
import PhotosUI

enum MediaItem {
    case image(UIImage)
}

struct ExploreFilePickerView: UIViewControllerRepresentable {
    @Binding var pickerResult: [MediaItem]
    @Binding var isPresented: Bool
    let selectionLimit: Int
    var onDone: ([MediaItem]) -> Void
        
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .any(of: [.images])
        config.selectionLimit = selectionLimit

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: ExploreFilePickerView
        
        init(_ parent: ExploreFilePickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            var mediaItems: [MediaItem] = []

            let group = DispatchGroup()

            for result in results {
                group.enter()
                
                let providers = [result.itemProvider]
                for provider in providers {
                    if provider.canLoadObject(ofClass: UIImage.self) {
                        provider.loadObject(ofClass: UIImage.self) { (image, error) in
                            defer { group.leave() }
                            if let image = image as? UIImage {
                                mediaItems.append(.image(image))
                            }
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                self.parent.pickerResult = mediaItems
                self.parent.onDone(mediaItems)
            }
        }

    }
}

#Preview {
    ExploreFilePickerView(pickerResult: .constant([]), isPresented: .constant(true), selectionLimit: 1, onDone: {_ in})
}
