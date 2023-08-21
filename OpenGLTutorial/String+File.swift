//
//  String+File.swift
//  OpenGLTutorial
//
//  Created by 201510003 on 2023/08/21.
//

import Foundation

// Reference:
// https://github.com/JohnSundell/Files
extension String {
    var url: URL {
        return URL(fileURLWithPath: self)
    }
    
    var name: String {
        return url.pathComponents.last!
    }
    
    var nameExcludingExtension: String {
        let components = name.split(separator: ".")
        guard components.count > 1 else { return name }
        return components.dropLast().joined()
    }
    
    var `extension`: String? {
        let components = name.split(separator: ".")
        guard components.count > 1 else { return nil }
        return String(components.last!)
    }
}
