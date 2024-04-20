//
//  Config.swift
//  Segment3D
//
//  Created by I Made Indra Mahaarta on 24/03/24.
//

import Foundation

struct Config {
    static let apiUrl: String = {
        guard let str = Bundle.main.object(forInfoDictionaryKey: "ApiUrl") as? String else {
            fatalError("APIUrl not set in plist for this environment")
        }
        
        return str
    }()
    
    static let storageUrl: String = {
        guard let str = Bundle.main.object(forInfoDictionaryKey: "StorageUrl") as? String else {
            fatalError("StorageUrl not set in plist for this environment")
        }
        
        return str
    }()
    
    static let googleClientId: String = {
        guard let str = Bundle.main.object(forInfoDictionaryKey: "GoogleClientID") as? String else {
            fatalError("GoogleClientID not set in plist for this environment")
        }
        
        return str
    }()
}

