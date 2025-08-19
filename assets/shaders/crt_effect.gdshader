shader_type canvas_item;

// Scanline effect parameters
uniform float line_thickness : hint_range(0.1, 10.0) = 1.0;
uniform float line_spacing : hint_range(1.0, 10.0) = 3.0;
uniform float scan_opacity : hint_range(0.0, 1.0) = 0.1;
uniform vec4 scan_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float crt_bend : hint_range(0.0, 0.1) = 0.03;
uniform float noise_strength : hint_range(0.0, 0.1) = 0.02;
uniform float brightness : hint_range(0.5, 1.5) = 1.1;
uniform float vignette_strength : hint_range(0.0, 0.5) = 0.25;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    // CRT bending effect
    vec2 uv = SCREEN_UV;
    if (crt_bend > 0.0) {
        vec2 center_dist = uv - 0.5;
        float dist_squared = dot(center_dist, center_dist);
        uv = uv + center_dist * dist_squared * crt_bend;
        
        // Discard pixels outside the "screen"
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
            COLOR = vec4(0.0, 0.0, 0.0, 1.0);
            return;
        }
    }
    
    // Sample the screen texture at the distorted position
    vec4 color = texture(TEXTURE, uv);
    
    // Scanlines effect (only applied if scan_opacity > 0)
    if (scan_opacity > 0.001) {
        float scanline = mod(SCREEN_UV.y * SCREEN_PIXEL_SIZE.y * line_spacing, line_thickness);
        if (scanline < 0.5 * line_thickness) {
            color = mix(color, scan_color, scan_opacity);
        }
    }
    
    // Add subtle noise
    float noise = random(SCREEN_UV + TIME) * noise_strength;
    color.rgb = mix(color.rgb, vec3(noise), noise);
    
    // Adjust brightness
    color.rgb *= brightness;
    
    // Add vignette effect
    float vignette = distance(SCREEN_UV, vec2(0.5));
    vignette = smoothstep(0.5, 1.0, vignette);
    color.rgb = mix(color.rgb, vec3(0.0), vignette * vignette_strength);
    
    COLOR = color;
}
