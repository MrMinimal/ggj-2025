shader_type spatial;
render_mode blend_add, cull_front, depth_test_disabled, ambient_light_disabled;

uniform sampler2D caustics_noise: filter_linear;

// Remove fixed box_size since we'll use the actual mesh scale
// uniform vec3 box_size = vec3(4.0);

// Caustics Parameters
uniform float caustics_scale = 4.0;
uniform float caustics_speed = 0.1;
uniform float caustics_strength: hint_range(0.0, 4.0) = 1.0;
uniform float caustics_power: hint_range(0.25, 8.0) = 2.0;
uniform float caustics_fade_radius = 2.0;
uniform float caustics_fade_strength: hint_range(0.0,1.0) = 0.5;
uniform float caustics_luminance_mask_strength: hint_range(-2.0, 2.0) = 0.2;
uniform float chroma_split: hint_range(0.0, .02) = 0.002;
uniform sampler2D luma_gradient : hint_default_white;

// Screen Textures
uniform sampler2D DEPTH_TEXTURE: hint_depth_texture;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture;

void vertex(){}

float insideBox3D(vec3 v, vec3 bottomLeft, vec3 topRight) {
    vec3 s = step(bottomLeft, v) - step(topRight, v);
    return s.x * s.y * s.z; 
}

float check_encompass_point(vec3 p, mat4 world_matrix){
    // Get the actual scale from the model matrix
    vec3 scale = vec3(
        length(vec3(world_matrix[0].xyz)),
        length(vec3(world_matrix[1].xyz)),
        length(vec3(world_matrix[2].xyz))
    );
    
    // Use half the actual scale for the box boundaries
    vec3 hs = scale / 2.0;
    
    vec3 bl = -hs + world_matrix[3].xyz;
    vec3 tr = hs + world_matrix[3].xyz;
    
    return insideBox3D(p, bl, tr);
}

mediump vec2 panner(mediump vec2 uv, mediump float speed, mediump float tiling){
    return (vec2(1, 0) * TIME * speed) + (uv * tiling);
}

mediump vec3 aberration_sample(sampler2D _CausticsTexture, mediump vec2 uv, float split){
    mediump vec2 uv1 = uv + vec2(split, split);
    mediump vec2 uv2 = uv + vec2(split, -split);
    mediump vec2 uv3 = uv + vec2(-split, -split);
    
    mediump float r = texture(_CausticsTexture, uv1).r;
    mediump float g = texture(_CausticsTexture, uv2).r;
    mediump float b = texture(_CausticsTexture, uv3).r;
    
    return vec3(r, g, b);
}

float luminance(vec3 color){
    return (0.299*color.r + 0.587*color.g + 0.114*color.b);
}

varying vec3 positionWS;
varying vec3 positionOS;
varying vec3 screen_color;
varying float bbox_mask;

void fragment(){
    float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
    vec3 ndc;
    if (OUTPUT_IS_SRGB){
        ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
    } else {
        ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth); 
    }
    vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    view.xyz /= view.w;
    vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    
    positionWS = world.xyz / world.w;
    positionOS = positionWS - MODEL_MATRIX[3].xyz;
    bbox_mask = check_encompass_point(positionWS, MODEL_MATRIX);
    
    screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
    
    ALBEDO = vec3(1.0);
    METALLIC = 0.0;
    ROUGHNESS = 1.0;
}

mat3 makeRotationDir(vec3 direction, vec3 up){
    mat3 rm;
    
    vec3 xaxis = cross(up, direction);
    xaxis = normalize(xaxis);
    
    vec3 yaxis = cross(direction, xaxis);
    yaxis = normalize(yaxis);
    
    rm[0].x = xaxis.x;
    rm[0].y = yaxis.x;
    rm[0].z = direction.x;
    
    rm[1].x = xaxis.y;
    rm[1].y = yaxis.y;
    rm[1].z = direction.y;
    
    rm[2].x = xaxis.z;
    rm[2].y = yaxis.z;
    rm[2].z = direction.z;
    
    return rm;
}

void light(){
    if (!LIGHT_IS_DIRECTIONAL) {
        // Only process directional lights!
    }
    else 
    {
        // Get the actual scale from the model matrix for UV scaling
        vec3 mesh_scale = vec3(
            length(vec3(MODEL_MATRIX[0].xyz)),
            length(vec3(MODEL_MATRIX[1].xyz)),
            length(vec3(MODEL_MATRIX[2].xyz))
        );
        float avg_scale = (mesh_scale.x + mesh_scale.y + mesh_scale.z) / 3.0;
        
        vec3 world_light = (INV_VIEW_MATRIX * vec4(LIGHT, 0.0)).xyz;
        mat3 lrm = makeRotationDir(world_light, vec3(0.0, 1.0, 0.0));
        mat4 t = mat4(lrm);
        
        // Scale the position by the inverse of the mesh scale to maintain consistent caustics size
        mediump vec2 uv = (t * vec4(positionWS / avg_scale, 1.0)).xy;
        mediump vec2 uv1 = panner(uv, 0.75 * caustics_speed, 1.0 / caustics_scale);
        mediump vec2 uv2 = panner(uv, caustics_speed, -1.0 / caustics_scale);
        
        mediump vec3 caus1 = aberration_sample(caustics_noise, uv1, chroma_split);
        mediump vec3 caus2 = aberration_sample(caustics_noise, uv2, chroma_split);
        caus1.rgb = pow(caus1.rgb, vec3(caustics_power));
        caus2.rgb = pow(caus2.rgb, vec3(caustics_power));
        
        mediump vec3 c = min(caus1.rgb, caus2.rgb) * caustics_strength;
        
        mediump float scene_luma = luminance(screen_color);
        scene_luma = texture(luma_gradient, vec2(scene_luma)).r;
        mediump float luminanceMask = mix(1.0, scene_luma, caustics_luminance_mask_strength);
        
        // Scale the fade radius with the mesh scale
        mediump float scaled_fade_radius = caustics_fade_radius * avg_scale;
        mediump float edgeFadeMask = 1.0 - clamp((distance(positionOS, vec3(0.0)) - scaled_fade_radius) / (1.0 - caustics_fade_strength), 0.0, 1.0);
        
        if (OUTPUT_IS_SRGB) {
            DIFFUSE_LIGHT += c * bbox_mask * luminanceMask * edgeFadeMask;
        } else {
            DIFFUSE_LIGHT += c * bbox_mask * luminanceMask * edgeFadeMask;
        }
        
        if (OUTPUT_IS_SRGB) {
            ALPHA = smoothstep(.0005, .001, DIFFUSE_LIGHT.g);
        } else {
            ALPHA = smoothstep(.0005, .001, DIFFUSE_LIGHT.g);
        }
    }
}