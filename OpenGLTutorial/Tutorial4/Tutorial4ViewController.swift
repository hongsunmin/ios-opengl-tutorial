//
//  Tutorial4ViewController.swift
//  OpenGLTutorial
//
//  Created by 201510003 on 2023/08/23.
//

import GLKit

class Tutorial4ViewController: GLKViewController {
    
    private var context: EAGLContext?
    
    private var vertexArrayID: GLuint = 0
    private var vertexbuffer: GLuint = 0
    private var colorbuffer: GLuint = 0
    private var programID: GLuint = 0
    
    private var matrixID: Int32 = 0
    
    private var mvp: GLKMatrix4?
    
    private var effect = GLKBaseEffect()
    
    deinit {
        tearDownGL()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupGL()
    }
}



private extension Tutorial4ViewController {
    
    func setupGL() {
        context = EAGLContext(api: .openGLES3)
        EAGLContext.setCurrent(context)
        if let view = view as? GLKView,
           let context = context {
            view.context = context
            delegate = self
            
            // Dark blue background
            glClearColor(0.0, 0.0, 0.4, 0.0)
            
            glEnable(GLenum(GL_DEPTH_TEST))
            glDepthFunc(GLenum(GL_LESS))
            
            glGenVertexArraysOES(1, &vertexArrayID)
            glBindVertexArrayOES(vertexArrayID)
            
            // Create and compile our GLSL program from the shaders
            programID = loadShaders(
                vertexFilePath: "TransformVertexShader.vertexshader",
                fragmentFilePath: "ColorFragmentShader.fragmentshader"
            )
            
            // Get a handle for our "MVP" uniform
            matrixID = glGetUniformLocation(programID, "MVP")
            
            // Projection matrix : 45° Field of View, 4:3 ratio, display range : 0.1 unit <-> 100 units
            let projection = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45.0), 4.0 / 3.0, 0.1, 100.0)
            // Or, for an ortho camera :
            //let projection = GLKMatrix4MakeOrtho(-10.0, 10.0, -10.0, 10.0, 0.0, 100.0)
            
            // Camera matrix
            let view = GLKMatrix4MakeLookAt(
                4, 3, -3, // Camera is at (4, 3, -3), in World Space
                0, 0, 0, // and looks at the origin
                0, 1, 0  // Head is up (set to 0, -1, 0 to look upside-down)
            )
            
            // Model matrix : an identity matrix (model will be at the origin)
            let model = GLKMatrix4Identity
            // Our ModelViewProjection : multiplication of our 3 matrices
            mvp = GLKMatrix4Multiply(GLKMatrix4Multiply(projection, view), model) // Remember, matrix multiplication is the other way around
            
            // Our vertices. Three consecutive floats give a 3D vertex; Three consecutive vertices give a triangle.
            // A cube has 6 faces with 2 triangles each, so this makes 6*2=12 triangles, and 12*3 vertices
            let vertexBufferData: [GLfloat] = [
                -1.0,-1.0,-1.0,
                -1.0,-1.0, 1.0,
                -1.0, 1.0, 1.0,
                 1.0, 1.0,-1.0,
                -1.0,-1.0,-1.0,
                -1.0, 1.0,-1.0,
                 1.0,-1.0, 1.0,
                -1.0,-1.0,-1.0,
                 1.0,-1.0,-1.0,
                 1.0, 1.0,-1.0,
                 1.0,-1.0,-1.0,
                -1.0,-1.0,-1.0,
                -1.0,-1.0,-1.0,
                -1.0, 1.0, 1.0,
                -1.0, 1.0,-1.0,
                 1.0,-1.0, 1.0,
                -1.0,-1.0, 1.0,
                -1.0,-1.0,-1.0,
                -1.0, 1.0, 1.0,
                -1.0,-1.0, 1.0,
                 1.0,-1.0, 1.0,
                 1.0, 1.0, 1.0,
                 1.0,-1.0,-1.0,
                 1.0, 1.0,-1.0,
                 1.0,-1.0,-1.0,
                 1.0, 1.0, 1.0,
                 1.0,-1.0, 1.0,
                 1.0, 1.0, 1.0,
                 1.0, 1.0,-1.0,
                -1.0, 1.0,-1.0,
                 1.0, 1.0, 1.0,
                -1.0, 1.0,-1.0,
                -1.0, 1.0, 1.0,
                 1.0, 1.0, 1.0,
                -1.0, 1.0, 1.0,
                 1.0,-1.0, 1.0
            ]
            
            // One color for each vertex. They were generated randomly.
            let colorBufferData: [GLfloat] = [
                0.583,  0.771,  0.014,
                0.609,  0.115,  0.436,
                0.327,  0.483,  0.844,
                0.822,  0.569,  0.201,
                0.435,  0.602,  0.223,
                0.310,  0.747,  0.185,
                0.597,  0.770,  0.761,
                0.559,  0.436,  0.730,
                0.359,  0.583,  0.152,
                0.483,  0.596,  0.789,
                0.559,  0.861,  0.639,
                0.195,  0.548,  0.859,
                0.014,  0.184,  0.576,
                0.771,  0.328,  0.970,
                0.406,  0.615,  0.116,
                0.676,  0.977,  0.133,
                0.971,  0.572,  0.833,
                0.140,  0.616,  0.489,
                0.997,  0.513,  0.064,
                0.945,  0.719,  0.592,
                0.543,  0.021,  0.978,
                0.279,  0.317,  0.505,
                0.167,  0.620,  0.077,
                0.347,  0.857,  0.137,
                0.055,  0.953,  0.042,
                0.714,  0.505,  0.345,
                0.783,  0.290,  0.734,
                0.722,  0.645,  0.174,
                0.302,  0.455,  0.848,
                0.225,  0.587,  0.040,
                0.517,  0.713,  0.338,
                0.053,  0.959,  0.120,
                0.393,  0.621,  0.362,
                0.673,  0.211,  0.457,
                0.820,  0.883,  0.371,
                0.982,  0.099,  0.879
            ]
            
            glGenBuffers(1, &vertexbuffer)
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexbuffer)
            glBufferData(GLenum(GL_ARRAY_BUFFER),
                         vertexBufferData.size(),
                         vertexBufferData,
                         GLenum(GL_STATIC_DRAW))
            
            glGenBuffers(1, &colorbuffer)
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), colorbuffer)
            glBufferData(GLenum(GL_ARRAY_BUFFER),
                         colorBufferData.size(),
                         colorBufferData,
                         GLenum(GL_STATIC_DRAW))
        }
    }
    
    func tearDownGL() {
        EAGLContext.setCurrent(context)
        
        glDeleteVertexArraysOES(1, &vertexArrayID)
        glDeleteBuffers(1, &vertexbuffer)
        glDeleteBuffers(1, &colorbuffer)
        glDeleteProgram(programID)
        
        EAGLContext.setCurrent(nil)
        
        context = nil
    }
}



extension Tutorial4ViewController: GLKViewControllerDelegate {
    
    func glkViewControllerUpdate(_ controller: GLKViewController) {
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        effect.prepareToDraw()
        // Clear the screen
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
        
        // Use our shader
        glUseProgram(programID)
        
        // Send our transformation to the currently bound shader,
        // in the "MVP" uniform
//        withUnsafePointer(to: &mvp!.m) {
//            $0.withMemoryRebound(to: Float.self, capacity: 16) {
//                glUniformMatrix4fv(matrixID, 1, GLboolean(GL_FALSE), $0)
//            }
//        }
        withUnsafePointer(to: &mvp!.m) {
            let ptr = UnsafeRawPointer($0).bindMemory(to: Float.self, capacity: 16)
            glUniformMatrix4fv(matrixID, 1, GLboolean(GL_FALSE), ptr)
        }
        
        // 1rst attribute buffer : vertices
        let vertexAttribPosition = GLuint(GLKVertexAttrib.position.rawValue)
        glEnableVertexAttribArray(vertexAttribPosition)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexbuffer)
        glVertexAttribPointer(
            vertexAttribPosition,                      // attribute. No particular reason for 0, but must match the layout in the shader.
            3,                                         // size
            GLenum(GL_FLOAT),                          // type
            GLboolean(UInt8(GL_FALSE)),                // normalized?
            GLsizei(0),                                // stride
            nil                                        // array buffer offset
        )
        
        // 2nd attribute buffer : colors
        let vertexAttribColor = GLuint(GLKVertexAttrib.color.rawValue)
        glEnableVertexAttribArray(vertexAttribColor)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), colorbuffer)
        glVertexAttribPointer(
            vertexAttribColor,                         // attribute. No particular reason for 0, but must match the layout in the shader.
            3,                                         // size
            GLenum(GL_FLOAT),                          // type
            GLboolean(UInt8(GL_FALSE)),                // normalized?
            GLsizei(0),                                // stride
            nil                                        // array buffer offset
        )
        
        // Draw the triangle !
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 12*3) // 12*3 indices starting at 0 -> 12 triangle
        
        glDisableVertexAttribArray(vertexAttribPosition)
        glDisableVertexAttribArray(vertexAttribColor)
    }
}
