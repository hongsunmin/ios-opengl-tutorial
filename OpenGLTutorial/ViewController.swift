//
//  ViewController.swift
//  OpenGLTutorial
//
//  Created by 201510003 on 2023/08/18.
//
// Reference:
// https://www.kodeco.com/5146-glkit-tutorial-for-ios-getting-started-with-opengl-es
// https://github.com/kosuke/swift-opengl

import GLKit

class ViewController: GLKViewController {
    
    private var context: EAGLContext?
    
    private var vertexArrayID: GLuint = 0
    private var vertexbuffer: GLuint = 0
    private var programID: GLuint = 0
    
    private var effect = GLKBaseEffect()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupGL()
    }
}



private extension ViewController {
    
    func setupGL() {
        context = EAGLContext(api: .openGLES3)
        EAGLContext.setCurrent(context)
        if let view = view as? GLKView,
           let context = context {
            view.context = context
            delegate = self
            
            // Dark blue background
            glClearColor(0.0, 0.0, 0.4, 0.0)
            
            glGenVertexArraysOES(1, &vertexArrayID)
            glBindVertexArrayOES(vertexArrayID)
            
            // Create and compile our GLSL program from the shaders
            programID = loadShaders(
                vertexFilePath: "SimpleVertexShader.vertexshader",
                fragmentFilePath: "SimpleFragmentShader.fragmentshader"
            )
            
            let vertexBufferData: [GLfloat] = [
                -1.0, -1.0, 0.0,
                 1.0, -1.0, 0.0,
                 0.0, 1.0, 0.0
            ]
            
            glGenBuffers(1, &vertexbuffer)
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexbuffer)
            glBufferData(GLenum(GL_ARRAY_BUFFER),
                         vertexBufferData.size(),
                         vertexBufferData,
                         GLenum(GL_STATIC_DRAW))
        }
    }
    
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
}



extension ViewController: GLKViewControllerDelegate {
    
    func glkViewControllerUpdate(_ controller: GLKViewController) {
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        effect.prepareToDraw()
        // Clear the screen
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        // Use our shader
        glUseProgram(programID)
        
        // 1rst attribute buffer : vertices
        let vertexAttribPosition = GLuint(GLKVertexAttrib.position.rawValue)
        glEnableVertexAttribArray(vertexAttribPosition)
        glVertexAttribPointer(vertexAttribPosition,
                              3,
                              GLenum(GL_FLOAT),
                              GLboolean(UInt8(GL_FALSE)),
                              GLsizei(MemoryLayout<GLfloat>.stride * 3),
                              nil)
        
        // Draw the triangle !
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 3) // 3 indices starting at 0 -> 1 triangle
        glDisableVertexAttribArray(0)
    }
}



extension Array {
    func size() -> Int {
        return MemoryLayout<Element>.stride * count
    }
}



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
