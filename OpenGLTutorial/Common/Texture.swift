//
//  Texture.swift
//  OpenGLTutorial
//
//  Created by 201510003 on 2023/09/18.
//

import GLKit

func loadBMP_custom(imagePath: String) -> GLuint {
    guard let fileURL = URL(string: imagePath) else {
        return 0
    }
    
    let ext = fileURL.pathExtension
    let name = fileURL.deletingPathExtension().lastPathComponent
    guard let url = Bundle.main.url(forResource: name, withExtension: ext),
          let stream = InputStream(url: url) else {
        return 0
    }
    
    
    /**
     * +--------+---------+-------------
     * | Offset | Size    | Description
     * | 00     | 2 bytes | BM
     * | 02     | 4 bytes | The size of the BMP file in bytes
     * | 06     | 2 bytes | Reserved
     * | 08     | 2 bytes | Reserved
     * | 10     | 4 bytes | The offset, i.e. starting address, of the byte where the bitmap image data (pixel array) can be found.
     * | 14     | 4 bytes | the size of this header, in bytes
     * | 18     | 4 bytes | the bitmap width in pixels (signed integer)
     * | 22     | 4 bytes | the bitmap height in pixels (signed integer)
     * | 26     | 2 bytes | the number of color planes (must be 1)
     * | 28     | 2 bytes | the number of bits per pixel, which is the color depth of the image. Typical values are 1, 4, 8, 16, 24 and 32.
     * | 30     | 4 bytes | the compression method being used. See the next table for a list of possible values
     * | 34     | 4 bytes | the image size. This is the size of the raw bitmap data; a dummy 0 can be given for BI_RGB bitmaps
     * | 38     | 4 bytes | the horizontal resolution of the image. (pixel per metre, signed integer)
     * | 42     | 4 bytes | the vertical resolution of the image. (pixel per metre, signed integer)
     * | 46     | 4 bytes | the number of colors in the color palette, or 0 to default to 2n
     * | 50     | 4 bytes | the number of important colors used, or 0 when every color is important; generally ignored
     * +--------+---------+-------------
     */
    
    stream.open()
    let headerSize = 54
    var buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: headerSize)
    
    // Read the header, i.e. the 54 first bytes
    // If less than 54 bytes are read, problem
    let read = stream.read(buffer, maxLength: headerSize)
    defer {
        stream.close()
    }
    
    guard read > 0 else {
        return 0
    }
    
    let header = Data(bytes: buffer, count: headerSize)
    printHexDumpForBytes(bytes: header)
    if case let .success(result) = CStruct().unpack(header, format: "cc8xi4xii2xhii"),
       let result = result {
        // A BMP files always begins with "BM"
        if result[0].description != "B"
            || result[1].description != "M" {
            return 0
        }
        
        // Read the information about the image
        var dataPos = Int(result[2].description)!
        var imageSize = Int(result[7].description)!
        let width = Int(result[3].description)!
        let height = Int(result[4].description)!
        
        // Some BMP files are misformatted, guess missing information
        if imageSize == 0 {
            imageSize = width * height * 3 // 3 : one byte for each Red, Green and Blue component
        }
        if dataPos == 0 {
            dataPos = 54 // The BMP header is done that way
        }
        
        var data = UnsafeMutablePointer<UInt8>.allocate(capacity: imageSize)
        stream.read(data, maxLength: imageSize)
        stream.close()
        for i in 0..<width * height {
            let index = i * 3
            let b = data[index]
            let g = data[index + 1]
            let r = data[index + 2]
            data[index] = r
            data[index + 1] = g
            data[index + 2] = b
        }
        
        // Create one OpenGL texture
        var textureID: GLuint = 0
        glGenTextures(1, &textureID)
        
        // "Bind" the newly created texture : all future texture functions will modify this texture
        glBindTexture(GLenum(GL_TEXTURE_2D), textureID)
        
        // Give the image to OpenGL
        glTexImage2D(
            GLenum(GL_TEXTURE_2D),
            0,
            GL_RGB,
            GLsizei(width),
            GLsizei(height),
            0,
            GLenum(GL_RGB),
            GLenum(GL_UNSIGNED_BYTE),
            data
        )
        
        // ... nice trilinear filtering ...
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_REPEAT)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR_MIPMAP_LINEAR)
        // ... which requires mipmaps. Generate them automatically.
        glGenerateMipmap(GLenum(GL_TEXTURE_2D))
        
        // Return the ID of the texture we just created
        return textureID
    }
    return 0
}
