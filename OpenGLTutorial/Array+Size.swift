//
//  Array+Size.swift
//  OpenGLTutorial
//
//  Created by 201510003 on 2023/08/21.
//

import Foundation

extension Array {
    func size() -> Int {
        return MemoryLayout<Element>.stride * count
    }
}
