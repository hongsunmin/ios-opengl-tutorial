//
//  Ex1ViewController.swift
//  OpenGLTutorial
//
//  Created by 201510003 on 10/10/23.
//
// Reference:
// https://stackoverflow.com/questions/36669448/drawing-2d-bitmap-in-opengl-es-ios
// https://gist.github.com/zainab-ali/18d5eccd5677eaa4976d

import GLKit

class Ex1ViewController: UIViewController {

    @IBOutlet
    var glkView: GLKView!
    
    private var context: EAGLContext?
    
    private var vertexArrayID: GLuint = 0
    private var texture: GLuint = 0
    private var vertexbuffer: GLuint = 0
    private var uvbuffer: GLuint = 0
    private var indexbuffer: GLuint = 0
    private var programID: GLuint = 0
    
    private var textureID: Int32 = 0
    
    private let indices: [GLubyte] = [
        0, 1, 2,
        0, 2, 3
    ]
    
    private var effect = GLKBaseEffect()
    
    deinit {
        tearDownGL()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onOrientationChange(notification:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        setupOpenGL()
        glkView.display()
    }
    
    @objc
    func onOrientationChange(notification: Notification) {
        DispatchQueue.main.async {
            self.glkView.display()
        }
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



private extension Ex1ViewController {
    
    func setupOpenGL() {
        context = EAGLContext(api: .openGLES3)
        EAGLContext.setCurrent(context)
        if let context = context {
            glkView.context = context
            glkView.delegate = self
            
            // Dark blue background
            glClearColor(0.0, 0.0, 0.4, 0.0)
            
            glEnable(GLenum(GL_DEPTH_TEST))
            glDepthFunc(GLenum(GL_LESS))
            
            glGenVertexArraysOES(1, &vertexArrayID)
            glBindVertexArrayOES(vertexArrayID)
            
            // Create and compile our GLSL program from the shaders
            programID = loadShaders(
                vertexFilePath: "Ex1.vertexshader",
                fragmentFilePath: "Ex1.fragmentshader"
            )
            
            // Load the texture using any two methods
            texture = loadBMP_custom(imagePath: "uvtemplate.bmp")
            
            // Get a handle for our "image" uniform
            textureID = glGetUniformLocation(programID, "image")
            
            // Our vertices. Three consecutive floats give a 3D vertex; Three consecutive vertices give a triangle.
            let vertexBufferData: [GLfloat] = [
                -1.0,  1.0, 0.0, // upper-left
                -1.0, -1.0, 0.0, // lower-left
                 1.0, -1.0, 0.0, // lower-right
                 1.0,  1.0, 0.0  // upper-right
            ]
            
            // Two UV coordinatesfor each vertex. They were created with Blender.
            let uvBufferData: [GLfloat] = [
                0.0, 1.0, // upper-left
                0.0, 0.0, // lower-left
                1.0, 0.0, // lower-right
                1.0, 1.0  // upper-right
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
            
            glGenBuffers(1, &indexbuffer)
            glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexbuffer)
            glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER),
                         indices.size(),
                         indices,
                         GLenum(GL_STATIC_DRAW))
        }
    }
    
    func tearDownGL() {
        EAGLContext.setCurrent(context)
        
        glDeleteVertexArraysOES(1, &vertexArrayID)
        glDeleteBuffers(1, &vertexbuffer)
        glDeleteBuffers(1, &uvbuffer)
        glDeleteBuffers(1, &indexbuffer)
        glDeleteProgram(programID)
        glDeleteTextures(1, &texture)
        
        EAGLContext.setCurrent(nil)
        
        context = nil
    }
}



extension Ex1ViewController: GLKViewDelegate {
    
    func glkView(_ view: GLKView, drawIn rect: CGRect) {
        effect.prepareToDraw()
        // Clear the screen
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
        
        // Use our shader
        glUseProgram(programID)
        
        // Bind our texture in Texture Unit 0
        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_2D), texture)
        // Set our "image" sampler to use Texture Unit 0
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
        
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(indices.count), GLenum(GL_UNSIGNED_BYTE), nil)
        
        glDisableVertexAttribArray(vertexAttribPosition)
        glDisableVertexAttribArray(vertexAttribColor)
    }
}
