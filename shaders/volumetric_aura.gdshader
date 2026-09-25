shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 aura_color : source_color = vec4(1.0, 0.52, 0.08, 1.0);
uniform float intensity : hint_range(0.0, 4.0) = 1.35;
uniform float pulse_phase : hint_range(0.0, 6.28318) = 0.0;
uniform float edge_power : hint_range(0.5, 5.0) = 2.2;
// Accessibility scale for every emissive pulse in the game, set from the
// player's settings by GameSettings.apply_pulse_global (CLAUDE.md 11). One
// means the authored pulse, zero means none - the value holds at the pulse's
// own mean, so turning it off changes motion and never brightness.
global uniform float bespren_pulse_amount;

float hash21(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float radius = length(centered);
	float radial = pow(clamp(1.0 - radius, 0.0, 1.0), edge_power);
	// The vapor steps with the phase, which is a flicker; at zero it holds still.
	float vapor = hash21(floor(centered * 22.0 + pulse_phase * bespren_pulse_amount)) * 0.10;
	float pulse = 0.82 + sin(pulse_phase) * 0.18 * bespren_pulse_amount;
	float source_alpha = texture(TEXTURE, UV).a;
	float alpha = (radial + vapor * radial) * pulse * source_alpha;
	COLOR = vec4(aura_color.rgb * intensity * alpha, aura_color.a * alpha);
}

