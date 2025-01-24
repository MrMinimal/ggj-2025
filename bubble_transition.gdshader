shader_type canvas_item;

uniform vec4 key_color : source_color = vec4(0.0, 1.0, 0.0, 1.0); // Green by default
uniform float threshold : hint_range(0.0, 1.0) = 0.5;
uniform float smoothness : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    // Convert color to grayscale using luminance calculation
    float grayscale = dot(color.rgb, vec3(0.299, 0.587, 0.114));

    // Calculate color difference
    float diff = length(color.rgb - key_color.rgb);

    // Smooth step for better edge transition
    float mask = 1.0 - smoothstep(threshold, threshold + smoothness, diff);

    // Apply transparency and use grayscale
    COLOR = vec4(vec3(grayscale), color.a * (1.0 - mask));
}
