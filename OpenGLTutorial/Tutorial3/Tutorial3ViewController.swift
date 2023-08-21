//
//  Tutorial3ViewController.swift
//  OpenGLTutorial
//
//  Created by 201510003 on 2023/08/21.
//
// Reference:
// https://github.com/iosdevzone/IDZSwiftGLKit
// https://koodev.tistory.com/11
// https://gyutts.tistory.com/15

import GLKit

class Tutorial3ViewController: GLKViewController {
    
    private var context: EAGLContext?
    
    private var vertexArrayID: GLuint = 0
    private var vertexbuffer: GLuint = 0
    private var programID: GLuint = 0
    
    private var matrixID: Int32 = 0
    
    private var mvp: GLKMatrix4?
    
    private var effect = GLKBaseEffect()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupGL()
    }
}



private extension Tutorial3ViewController {
    
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
                vertexFilePath: "SimpleTransform.vertexshader",
                fragmentFilePath: "SingleColor.fragmentshader"
            )
            
            // Get a handle for our "MVP" uniform
            matrixID = glGetUniformLocation(programID, "MVP")
            
            // Projection matrix : 45° Field of View, 4:3 ratio, display range : 0.1 unit <-> 100 units
            let projection = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45.0), 4.0 / 3.0, 0.1, 100.0)
            // Or, for an ortho camera :
            //let projection = GLKMatrix4MakeOrtho(-10.0, 10.0, -10.0, 10.0, 0.0, 100.0)
            
            // Camera matrix
            let view = GLKMatrix4MakeLookAt(
                4, 3, 3, // Camera is at (4, 3, 3), in World Space
                0, 0, 0, // and looks at the origin
                0, 1, 0  // Head is up (set to 0, -1, 0 to look upside-down)
            )
            
            // Model matrix : an identity matrix (model will be at the origin)
            let model = GLKMatrix4Identity
            // Our ModelViewProjection : multiplication of our 3 matrices
            mvp = GLKMatrix4Multiply(GLKMatrix4Multiply(projection, view), model) // Remember, matrix multiplication is the other way around
            
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
}



extension Tutorial3ViewController: GLKViewControllerDelegate {
    
    func glkViewControllerUpdate(_ controller: GLKViewController) {
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        effect.prepareToDraw()
        // Clear the screen
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
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
        glVertexAttribPointer(
            vertexAttribPosition,                      // attribute. No particular reason for 0, but must match the layout in the shader.
            3,                                         // size
            GLenum(GL_FLOAT),                          // type
            GLboolean(UInt8(GL_FALSE)),                // normalized?
            GLsizei(MemoryLayout<GLfloat>.stride * 3), // stride
            nil                                        // array buffer offset
        )
        
        // Draw the triangle !
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 3) // 3 indices starting at 0 -> 1 triangle
        glDisableVertexAttribArray(0)
    }
}
