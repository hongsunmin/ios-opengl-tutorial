//
//  Ex2ViewController.swift
//  OpenGLTutorial
//
//  Created by 201510003 on 10/16/23.
//
// Reference:
// https://stackoverflow.com/questions/12428108/ios-how-to-draw-a-yuv-image-using-opengl
// https://cho001.tistory.com/230

import GLKit

class Ex2ViewController: UIViewController {
    
    @IBOutlet
    var glkView: GLKView!
    
    private var context: EAGLContext?
    
    private var vertexArrayID: GLuint = 0
    private var textures = [GLuint](repeating: 0, count: 3)
    private var vertexbuffer: GLuint = 0
    private var uvbuffer: GLuint = 0
    private var indexbuffer: GLuint = 0
    private var programID: GLuint = 0
    
    private var textureIDs = [Int32](repeating: 0, count: 3)
    
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



private extension Ex2ViewController {
    
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
                vertexFilePath: "Ex2.vertexshader",
                fragmentFilePath: "Ex2.fragmentshader"
            )
            
            // Load the texture using any two methods
            textures = readYUV()
            
            // Get a handle for our "image" uniform
            textureIDs[0] = glGetUniformLocation(programID, "image_y")
            textureIDs[1] = glGetUniformLocation(programID, "image_u")
            textureIDs[2] = glGetUniformLocation(programID, "image_v")
            
            // Our vertices. Three consecutive floats give a 3D vertex; Three consecutive vertices give a triangle.
            let vertexBufferData: [GLfloat] = [
                -1.0,  1.0, 0.0, // upper-left
                -1.0, -1.0, 0.0, // lower-left
                 1.0, -1.0, 0.0, // lower-right
                 1.0,  1.0, 0.0  // upper-right
            ]
            
            // Two UV coordinatesfor each vertex. They were created with Blender.
            let uvBufferData: [GLfloat] = [
                0.0, 0.0, // upper-left
                0.0, 1.0, // lower-left
                1.0, 1.0, // lower-right
                1.0, 0.0  // upper-right
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
        glDeleteTextures(3, &textures)
        
        EAGLContext.setCurrent(nil)
        
        context = nil
    }
    
    func readYUV() -> [GLuint] {
        guard let fileURL = URL(string: "BigBuckBUNNY_1920x1080_P420.yuv") else {
            return [0]
        }
        
        let ext = fileURL.pathExtension
        let name = fileURL.deletingPathExtension().lastPathComponent
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let stream = InputStream(url: url) else {
            return [0]
        }
        
        stream.open()
        let imageSize = (GLsizei(1920), GLsizei(1080))
        var textures = [GLuint](repeating: 0, count: 3)
        let widths = [GLsizei](arrayLiteral: imageSize.0, imageSize.0 / 2, imageSize.0 / 2)
        let heights = [GLsizei](arrayLiteral: imageSize.1, imageSize.1 / 2, imageSize.1 / 2)
        glGenTextures(3, &textures)
        let counts = [0, 0, 0].enumerated().compactMap { Int(widths[$0.offset] * heights[$0.offset]) }
        for (i, count) in counts.enumerated() {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
            let read = stream.read(buffer, maxLength: count)
            
            // "Bind" the newly created texture : all future texture functions will modify this texture
            glBindTexture(GLenum(GL_TEXTURE_2D), textures[i])
            
            // Give the image to OpenGL
            glTexImage2D(
                GLenum(GL_TEXTURE_2D),
                0,
                GL_LUMINANCE,
                GLsizei(widths[i]),
                GLsizei(heights[i]),
                0,
                GLenum(GL_LUMINANCE),
                GLenum(GL_UNSIGNED_BYTE),
                buffer
            )
            buffer.deallocate()
            
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        }
        
        defer {
            stream.close()
        }
        return textures
    }
}



extension Ex2ViewController: GLKViewDelegate {
    
    func glkView(_ view: GLKView, drawIn rect: CGRect) {
        effect.prepareToDraw()
        // Clear the screen
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
        
        // Use our shader
        glUseProgram(programID)
        
        for (i, texture) in textures.enumerated() {
            // Bind our texture in Texture Unit 0~2
            glActiveTexture(GLenum(GL_TEXTURE0 + Int32(i)))
            glBindTexture(GLenum(GL_TEXTURE_2D), texture)
            // Set our "image_y, image_u, image_v" sampler to use Texture Unit 0~2
            glUniform1i(textureIDs[i], GLint(i))
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
