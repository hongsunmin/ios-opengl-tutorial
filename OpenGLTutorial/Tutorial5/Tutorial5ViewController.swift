//
//  Tutorial5ViewController.swift
//  OpenGLTutorial
//
//  Created by 201510003 on 2023/09/18.
//

import GLKit

class Tutorial5ViewController: GLKViewController {
    
    private var context: EAGLContext?
    
    private var vertexArrayID: GLuint = 0
    private var texture: GLuint = 0
    private var vertexbuffer: GLuint = 0
    private var uvbuffer: GLuint = 0
    private var programID: GLuint = 0
    
    private var matrixID: Int32 = 0
    private var textureID: Int32 = 0
    
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}



private extension Tutorial5ViewController {
    
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
                vertexFilePath: "TransformVertexShader2.vertexshader",
                fragmentFilePath: "TextureFragmentShader.fragmentshader"
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
            
            // Load the texture using any two methods
            texture = loadBMP_custom(imagePath: "uvtemplate.bmp")
            
            // Get a handle for our "myTextureSampler" uniform
            textureID = glGetUniformLocation(programID, "myTextureSampler")
            
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
            
            // Two UV coordinatesfor each vertex. They were created with Blender.
            let uvBufferData: [GLfloat] = [
                0.000059, 1.0-0.000004,
                0.000103, 1.0-0.336048,
                0.335973, 1.0-0.335903,
                1.000023, 1.0-0.000013,
                0.667979, 1.0-0.335851,
                0.999958, 1.0-0.336064,
                0.667979, 1.0-0.335851,
                0.336024, 1.0-0.671877,
                0.667969, 1.0-0.671889,
                1.000023, 1.0-0.000013,
                0.668104, 1.0-0.000013,
                0.667979, 1.0-0.335851,
                0.000059, 1.0-0.000004,
                0.335973, 1.0-0.335903,
                0.336098, 1.0-0.000071,
                0.667979, 1.0-0.335851,
                0.335973, 1.0-0.335903,
                0.336024, 1.0-0.671877,
                1.000004, 1.0-0.671847,
                0.999958, 1.0-0.336064,
                0.667979, 1.0-0.335851,
                0.668104, 1.0-0.000013,
                0.335973, 1.0-0.335903,
                0.667979, 1.0-0.335851,
                0.335973, 1.0-0.335903,
                0.668104, 1.0-0.000013,
                0.336098, 1.0-0.000071,
                0.000103, 1.0-0.336048,
                0.000004, 1.0-0.671870,
                0.336024, 1.0-0.671877,
                0.000103, 1.0-0.336048,
                0.336024, 1.0-0.671877,
                0.335973, 1.0-0.335903,
                0.667969, 1.0-0.671889,
                1.000004, 1.0-0.671847,
                0.667979, 1.0-0.335851
            ]
            
            glGenBuffers(1, &vertexbuffer)
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexbuffer)
            glBufferData(GLenum(GL_ARRAY_BUFFER),
                         vertexBufferData.size(),
                         vertexBufferData,
                         GLenum(GL_STATIC_DRAW))
            
            glGenBuffers(1, &uvbuffer)
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), uvbuffer)
            glBufferData(GLenum(GL_ARRAY_BUFFER),
                         uvBufferData.size(),
                         uvBufferData,
                         GLenum(GL_STATIC_DRAW))
        }
    }
    
    func tearDownGL() {
        EAGLContext.setCurrent(context)
        
        glDeleteVertexArraysOES(1, &vertexArrayID)
        glDeleteBuffers(1, &vertexbuffer)
        glDeleteBuffers(1, &uvbuffer)
        glDeleteProgram(programID)
        glDeleteTextures(1, &texture)
        
        EAGLContext.setCurrent(nil)
        
        context = nil
    }
}



extension Tutorial5ViewController: GLKViewControllerDelegate {
    
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
        
        // Bind our texture in Texture Unit 0
        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_2D), texture)
        // Set our "myTextureSampler" sampler to use Texture Unit 0
        glUniform1i(textureID, 0)
        
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
        
        // 2nd attribute buffer : UVs
        let vertexAttribColor = GLuint(GLKVertexAttrib.texCoord0.rawValue)
        glEnableVertexAttribArray(vertexAttribColor)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), uvbuffer)
        glVertexAttribPointer(
            vertexAttribColor,                         // attribute. No particular reason for 0, but must match the layout in the shader.
            2,                                         // size : U+V => 2
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
