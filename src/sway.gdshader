shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
uniform sampler2D albedo_texture : filter_nearest, source_color;
uniform vec3 scale = vec3(1,1,1);
uniform float wind_strength : hint_range(0.1, 1.0, 0.02);
uniform float wind_speed : hint_range(0.5, 2.0, 0.1);

void vertex() {
    float time_offset = TIME * wind_speed;
    float sway = (1.0 - UV.y) * wind_strength;

    VERTEX.x += sin(NODE_POSITION_WORLD.x + time_offset) * sway;
    VERTEX.z += cos(NODE_POSITION_WORLD.z + time_offset) * sway;
    VERTEX *= scale;

    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
        INV_VIEW_MATRIX[0],
        INV_VIEW_MATRIX[1],
        INV_VIEW_MATRIX[2],
        MODEL_MATRIX[3]
    );
}

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = tex.rgb;
    ALPHA = tex.a;
}