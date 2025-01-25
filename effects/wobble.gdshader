shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float brightness = 1.0;
uniform float contrast = 1.0;
uniform float saturation = 1.0;

uniform float wave_speed = 10.0; // Speed of the wave
uniform float wave_amplitude = 0.05; // Amplitude of the wave
uniform float wave_frequency = 10.0; // Frequency of the wave

void fragment() {
    vec2 uv = SCREEN_UV;
    float wave = sin((uv.x + TIME * wave_speed) * wave_frequency) * wave_amplitude;
    uv.y += wave;

    vec3 c = textureLod(screen_texture, uv, 0.0).rgb;

    c.rgb = mix(vec3(0.0), c.rgb, brightness);
    c.rgb = mix(vec3(0.5), c.rgb, contrast);
    c.rgb = mix(vec3(dot(vec3(1.0), c.rgb) * 0.33333), c.rgb, saturation);

    COLOR.rgb = c;
}
