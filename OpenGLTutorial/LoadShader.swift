//
//  LoadShader.swift
//  OpenGLTutorial
//
//  Created by 201510003 on 2023/08/21.
//

import GLKit

func loadShaders(vertexFilePath: String, fragmentFilePath: String) -> GLuint {
    // Create the shaders
    let vertexShaderID = glCreateShader(GLenum(GL_VERTEX_SHADER))
    let fragmentShaderID = glCreateShader(GLenum(GL_FRAGMENT_SHADER))
    
    // Read the Vertex Shader code from the file
    var vertexShaderCode: String
    if let vertexShaderUrl = Bundle.main.url(forResource: vertexFilePath.nameExcludingExtension,
                                             withExtension: vertexFilePath.extension),
       let unwrapVertexShaderCode = try? String(contentsOf: vertexShaderUrl) {
        vertexShaderCode = unwrapVertexShaderCode
    } else {
        print("Impossible to open %s. Are you in the right directory ? Don't forget to read the FAQ !\(vertexFilePath)")
        return 0
    }
    
    // Read the Fragment Shader code from the file
    var fragmentShaderCode: String?
    if let fragmentShaderUrl = Bundle.main.url(forResource: fragmentFilePath.nameExcludingExtension,
                                               withExtension: fragmentFilePath.extension) {
        fragmentShaderCode = try? String(contentsOf: fragmentShaderUrl)
    }
    
    var result = GL_FALSE
    var infoLogLength: GLint = 0
    
    // Compile Vertex Shader
    print("Compiling shader : \(vertexFilePath)")
    vertexShaderCode.withCString {
        var ptr: UnsafePointer<GLchar>? = $0
        glShaderSource(vertexShaderID, 1, &ptr, nil)
    }
    glCompileShader(vertexShaderID)
    
    // Check Vertex Shader
    glGetShaderiv(vertexShaderID, GLenum(GL_COMPILE_STATUS), &result)
    glGetShaderiv(vertexShaderID, GLenum(GL_INFO_LOG_LENGTH), &infoLogLength)
    if infoLogLength > 0 {
        let bufferSize = Int(infoLogLength) + 1
        var vertexShaderErrorMessage = [GLchar](repeating: 0, count: bufferSize)
        glGetShaderInfoLog(vertexShaderID, infoLogLength, nil, &vertexShaderErrorMessage)
        print("\(String(cString: vertexShaderErrorMessage))")
    }
    
    // Compile Fragment Shader
    print("Compiling shader : \(fragmentFilePath)")
    fragmentShaderCode?.withCString {
        var ptr: UnsafePointer<GLchar>? = $0
        glShaderSource(fragmentShaderID, 1, &ptr, nil)
    }
    glCompileShader(fragmentShaderID)
    
    // Check Fragment Shader
    glGetShaderiv(fragmentShaderID, GLenum(GL_COMPILE_STATUS), &result)
    glGetShaderiv(fragmentShaderID, GLenum(GL_INFO_LOG_LENGTH), &infoLogLength)
    if infoLogLength > 0 {
        let bufferSize = Int(infoLogLength) + 1
        var fragmentShaderErrorMessage = [GLchar](repeating: 0, count: bufferSize)
        glGetShaderInfoLog(fragmentShaderID, infoLogLength, nil, &fragmentShaderErrorMessage)
        print("\(String(cString: fragmentShaderErrorMessage))")
    }
    
    // Link the program
    print("Linking program")
    let programID = glCreateProgram()
    glAttachShader(programID, vertexShaderID)
    glAttachShader(programID, fragmentShaderID)
    glLinkProgram(programID)
    
    // Check the program
    glGetProgramiv(programID, GLenum(GL_LINK_STATUS), &result)
    glGetProgramiv(programID, GLenum(GL_INFO_LOG_LENGTH), &infoLogLength)
    if infoLogLength > 0 {
        let bufferSize = Int(infoLogLength) + 1
        var programErrorMessage = [GLchar](repeating: 0, count: bufferSize)
        glGetProgramInfoLog(programID, infoLogLength, nil, &programErrorMessage)
        print("\(String(cString: programErrorMessage))")
    }
    
    glDetachShader(programID, vertexShaderID)
    glDetachShader(programID, fragmentShaderID)
    
    glDeleteShader(vertexShaderID)
    glDeleteShader(fragmentShaderID)
    return programID
}
