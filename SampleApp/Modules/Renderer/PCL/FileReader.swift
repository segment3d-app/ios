//
//  FileReader.swift
//  PointCloudSegmenter
//
//  Created by User01 on 08/05/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import SceneKit
import ARKit

class FileReader {
    
    static func readFile(url: URL) -> [[Double]] {
        var data = ""
        
        do {
            data = try String(contentsOfFile: url.path, encoding: .ascii)
        } catch {
            print(error)
        }
        
        let myStrings = data.components(separatedBy: .newlines)
        var pointCloud = [[Double]]()
        
        for line in myStrings {
            if (line.components(separatedBy: .whitespaces).count != 6) {
                continue
            }

            let x = Double(line.components(separatedBy: .whitespaces)[0])!
            let y = Double(line.components(separatedBy: .whitespaces)[1])!
            let z = Double(line.components(separatedBy: .whitespaces)[2])!
            let r = Double(line.components(separatedBy: .whitespaces)[3])!
            let g = Double(line.components(separatedBy: .whitespaces)[4])!
            let b = Double(line.components(separatedBy: .whitespaces)[5])!
            
            pointCloud.append([x, y, z, r, g, b])
            
        }
        
        return pointCloud
    }
}
