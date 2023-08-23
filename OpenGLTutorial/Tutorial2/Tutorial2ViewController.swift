//
//  Tutorial2ViewController.swift
//  OpenGLTutorial
//
//  Created by 201510003 on 2023/08/18.
//
// Reference:
// https://www.kodeco.com/5146-glkit-tutorial-for-ios-getting-started-with-opengl-es
// https://github.com/kosuke/swift-opengl

import GLKit

class Tutorial2ViewController: GLKViewController {
    
    private var context: EAGLContext?
    
    private var vertexArrayID: GLuint = 0
    private var vertexbuffer: GLuint = 0
    private var programID: GLuint = 0
    
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



private extension Tutorial2ViewController {
    
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
    
    func tearDownGL() {
        EAGLContext.setCurrent(context)
        
        glDeleteVertexArraysOES(1, &vertexArrayID)
        glDeleteBuffers(1, &vertexbuffer)
        glDeleteProgram(programID)
        
        EAGLContext.setCurrent(nil)
        
        context = nil
    }
}



extension Tutorial2ViewController: GLKViewControllerDelegate {
    
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
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexbuffer)
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
