shader_type spatial;

uniform int spiral_type : hint_range(1, 5) = 1;
uniform vec3 color : source_color;
uniform float rays : hint_range(0., 20., 1) = 6;
uniform float speed : hint_range(0., 20., .01) = .5;
uniform float fade : hint_range(0., 3., .01) = .1;
uniform float thickness : hint_range(0., 1., .01) = .3;
uniform bool clockwise = true;

// Not used by all spirals
uniform float tiers: hint_range(0., 20., 1) = 4;
uniform float stretch : hint_range(0., 10., .1) = 6.28;
uniform vec3 s5color2 : source_color;

void fragment() {
    // Get the UV coordinates of the mesh
    vec2 uv = UV;

    // Calculate radius and angle based on UV coordinates
    float r = length(uv - vec2(0.5));  // Calculate distance from center
    float angle = atan(uv.y - 0.5, uv.x - 0.5);  // Calculate angle from center

    vec3 base_color = color;  // Base color of the spiral
    float alpha = 1.0;  // Set base alpha value

    // Different spiral effects based on spiral_type
    if (spiral_type == 1)
        alpha = 1. - smoothstep(-.1, .1, fract((2. * r - (angle + PI) / TAU) * rays + (clockwise ? 1. : -1.) * TIME * speed) - thickness);
    else if (spiral_type == 2)
        alpha = 1. - smoothstep(0., thickness, abs(.5 - fract((2. * r - (angle + PI) / TAU) * rays + (clockwise ? 1. : -1.) * TIME * speed)));
    else if (spiral_type == 3)
        alpha *= 1. - smoothstep(0.0, thickness, fract(tiers * (2. * r)) / tiers - mod(tiers * (angle + PI) - (clockwise ? 1. : -1.) * TIME, TAU) / (stretch * tiers));
    else if (spiral_type == 4)
        alpha *= 1. - smoothstep(0.0, thickness, abs(fract(tiers * (2. * r)) / tiers - mod(tiers * (angle + PI) - (clockwise ? 1. : -1.) * TIME, TAU) / (stretch * tiers)));
    else if (spiral_type == 5)
        base_color = mix(color, s5color2, thickness * fract((2. * r - (angle + PI) / TAU) * rays + (clockwise ? 1. : -1.) * TIME * speed));

    // Apply fade effect based on distance from the center
    alpha *= pow(2. * (.5 - r), fade * 4.);

    // Final color and alpha output
    ALBEDO = base_color;
    ALPHA = alpha;  // Ensure alpha is clamped to a reasonable range
}
