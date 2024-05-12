//
//  Utils.swift
//  MetalSplatter SampleApp
//
//  Created by I Made Indra Mahaarta on 11/05/24.
//

import Foundation
import UIKit

func getImages(forDirectory directoryPath: String) -> [UIImage] {
    var images: [UIImage] = []
    
    // Get file URLs for all JPEG images in the directory
    let fileManager = FileManager.default
    do {
        let directoryURL = getDocumentsDirectory().appendingPathComponent(directoryPath, isDirectory: true)
        let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        // Filter JPEG image URLs
        let jpegFileURLs = fileURLs.filter { $0.pathExtension.lowercased() == "jpeg" }
        
        // Convert file URLs to UIImage objects
        for fileURL in jpegFileURLs {
            if let image = UIImage(contentsOfFile: fileURL.path) {
                images.append(image)
            } else {
                print("Failed to load image from file: \(fileURL)")
            }
        }
    } catch {
        print("Error reading contents of directory: \(error.localizedDescription)")
    }
    
    return images
}

func getPointCloud(forDirectory directoryPath: String) -> URL? {
    print("masuk pcl")
    let fileManager = FileManager.default
    do {
        let directoryURL = getDocumentsDirectory().appendingPathComponent(directoryPath, isDirectory: true)
        let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        let pclFiles = fileURLs.filter { $0.pathExtension.lowercased() == "ply" }
        print(pclFiles[0])
        return pclFiles[0]
    } catch {
        print("Error reading contents of directory: \(error.localizedDescription)")
        return nil
    }
}
