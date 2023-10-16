#version 300 core

precision mediump float;

in vec2 uv;

out vec3 color;

uniform sampler2D image_y;
uniform sampler2D image_u;
uniform sampler2D image_v;

void main() {
    float y = texture(image_y, uv).r;
    float u = texture(image_u, uv).r - 0.5;
    float v = texture(image_v, uv).r - 0.5;
    float r = y +             1.402 * v;
    float g = y - 0.344 * u - 0.714 * v;
    float b = y + 1.772 * u;
    color = vec3(r, g, b);
}
