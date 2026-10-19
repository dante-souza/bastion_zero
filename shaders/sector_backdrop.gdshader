shader_type canvas_item;
render_mode unshaded, blend_disabled;

// Neon pass: every sector backdrop in one GPU pass. Replaces ~40 CanvasItem
// polygons that GDScript rebuilt every frame on the J8; TIME animates it, so
// the CPU does no per-frame work for the background at all.
// Palette rule: everything here is cool (blue/violet band) or near-neutral.
// Warm belongs to hostiles and green to XP, so neither appears in a backdrop.

uniform vec4 sky_top : source_color = vec4(0.008, 0.02, 0.035, 1.0);
uniform vec4 sky_bottom : source_color = vec4(0.03, 0.118, 0.224, 1.0);
uniform vec4 line_color : source_color = vec4(0.086, 0.545, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(0.404, 0.847, 1.0, 1.0);
uniform vec4 accent : source_color = vec4(0.35, 0.45, 1.0, 1.0);
uniform vec4 aura_color : source_color = vec4(0.05, 0.33, 0.76, 0.42);
// 0 horizon, 1 aurora, 2 rift, 3 foundry, 4 radar, 5 null, 6 menu
uniform int theme = 0;
// 0 crest, 1 twin, 2 shelf, 3 jagged (same curves as ArenaBackground.horizon_y)
uniform int shape = 0;
uniform bool low_fx = true;
uniform bool show_horizon = true;
uniform vec2 world = vec2(720.0, 1280.0);
// The world-space window this rect shows; SECTORS cards show a crop.
uniform vec4 view = vec4(0.0, 0.0, 720.0, 1280.0);
uniform vec2 aura_center = vec2(360.0, 1050.0);
uniform vec2 aura_radius = vec2(440.0, 400.0);
uniform float brightness = 1.0;

const float CREST_Y = 990.0;
const float EDGE_Y = 1120.0;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x),
		mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x), f.y);
}

float horizon_y(float x) {
	float cx = clamp(x, 0.0, world.x);
	float u = clamp(2.0 * x / world.x - 1.0, -1.0, 1.0);
	if (shape == 1) {
		float l = exp(-pow((cx - 190.0) / 135.0, 2.0));
		float r = exp(-pow((cx - 530.0) / 135.0, 2.0));
		return 1118.0 - 112.0 * max(l, r);
	} else if (shape == 2) {
		return 1032.0 + 88.0 * smoothstep(0.72, 1.0, abs(u));
	} else if (shape == 3) {
		float saw = abs(mod(cx, 60.0) - 30.0) / 30.0;
		return mix(CREST_Y + 8.0, EDGE_Y, u * u) - 16.0 * saw;
	}
	return mix(CREST_Y, EDGE_Y, u * u);
}

// Anti-aliased line of `width` screen pixels around distance d (world units).
float aa_line(float d, float width, float px) {
	return 1.0 - smoothstep(width * 0.5 * px, (width * 0.5 + 1.0) * px, abs(d));
}

float grid_line(float coord, float width) {
	float fw = max(fwidth(coord), 1e-4);
	float f = abs(fract(coord) - 0.5);
	return 1.0 - smoothstep(0.5 - width * fw, 0.5 - (width - 1.0) * fw, f);
}

// One soft mote per cell; cells drift with `flow`, so motes travel.
float motes(vec2 p, float cell, vec2 flow, float density, float size) {
	vec2 q = p + flow * TIME;
	vec2 id = floor(q / cell);
	float h = hash12(id);
	vec2 at = (id + 0.2 + 0.6 * vec2(hash12(id + 7.1), hash12(id + 3.7))) * cell;
	float twinkle = 0.55 + 0.45 * sin(TIME * (1.5 + 2.0 * h) + h * 40.0);
	return step(1.0 - density, h) * twinkle * (1.0 - smoothstep(0.0, size, length(q - at)));
}

void fragment() {
	vec2 p = view.xy + UV * view.zw;
	float px = max(fwidth(p.x), 1e-3); // world units per screen pixel
	float hy = horizon_y(p.x);
	float d = p.y - hy; // < 0 is the field, > 0 is behind the line
	float field = 1.0 - smoothstep(-2.0, 2.0, d);

	vec3 col = mix(sky_top.rgb, sky_bottom.rgb, smoothstep(0.0, 1.0, p.y / world.y));

	// Guardian aura: smooth elliptical falloff (was a 32-triangle fan).
	float a = 1.0 - length((p - aura_center) / aura_radius);
	col += aura_color.rgb * aura_color.a * smoothstep(0.0, 1.0, max(a, 0.0));

	// Perspective battle floor: rays converge far above the screen, rungs
	// tighten with distance and scroll toward the Guardian.
	float vy = p.y + 900.0;
	float depth = 1900.0 / max(vy, 1.0);
	float rays = grid_line((p.x - 360.0) / vy * 9.0, 1.2);
	float rungs = grid_line(depth * 3.0 - TIME * 0.22, 1.2);
	float fade = smoothstep(-150.0, 950.0, p.y) * field;
	float floor_alpha = (theme == 6) ? 0.20 : 0.16;
	col += line_color.rgb * max(rays, rungs) * fade * floor_alpha;

	if (theme == 1) {
		// Aurora: two slow violet ribbons over the upper field.
		for (int i = 0; i < 2; i++) {
			float fi = float(i);
			float wave = 230.0 + fi * 150.0
				+ 46.0 * sin(p.x * 0.010 + TIME * (0.35 + 0.1 * fi) + sin(p.x * 0.004 - TIME * 0.2) * 2.0);
			float band = exp(-abs(p.y - wave) / (26.0 + 14.0 * fi));
			float curtain = 0.6 + 0.4 * sin(p.x * 0.07 + TIME * 0.9 + fi * 2.0);
			col += mix(accent.rgb, core_color.rgb, 0.25 * fi) * band * curtain * 0.30;
		}
	} else if (theme == 2) {
		// Cinder Rift: a live energy crack splitting the sky down to the dip.
		// Slow and soft on purpose: a sharp bright zigzag would read as Arc.
		float jag = 18.0 * sin(p.y * 0.008 + TIME * 0.45) + 7.0 * sin(p.y * 0.023 - TIME * 0.8);
		float dx = abs(p.x - 360.0 - jag);
		float reach = smoothstep(-60.0, 120.0, p.y) * smoothstep(980.0, 520.0, p.y);
		float breathe_rift = 0.85 + 0.15 * sin(TIME * 1.7 - p.y * 0.01);
		col += accent.rgb * (exp(-dx / 70.0) * 0.20 + exp(-dx / 9.0) * 0.22) * reach * breathe_rift;
		col += core_color.rgb * exp(-dx / 2.2) * 0.14 * reach;
		if (!low_fx) {
			// Swarm streaks: thin diagonal shards falling fast.
			vec2 s = vec2(p.x + p.y * 0.35, p.y);
			vec2 sq = vec2(s.x, s.y - TIME * 420.0);
			vec2 id = floor(sq / vec2(46.0, 260.0));
			float h = hash12(id);
			vec2 local = sq - (id + vec2(0.5, 0.0)) * vec2(46.0, 260.0);
			float streak = step(0.80, h) * (1.0 - smoothstep(0.6, 1.8, abs(local.x - (h - 0.8) * 120.0)))
				* smoothstep(0.0, 120.0, local.y) * (1.0 - smoothstep(120.0, 140.0, local.y));
			col += accent.rgb * streak * 0.32 * field;
		}
	} else if (theme == 3) {
		// Iron Shelf: hex armour plating lit by a slow scanning bar.
		vec2 hp = p / 46.0;
		vec2 r = vec2(1.0, 1.7320508);
		vec2 ha = mod(hp, r) - r * 0.5;
		vec2 hb = mod(hp - r * 0.5, r) - r * 0.5;
		vec2 hc = dot(ha, ha) < dot(hb, hb) ? ha : hb;
		vec2 ab = abs(hc);
		float edge = 0.5 - max(dot(ab, normalize(r)), ab.x);
		float hex = 1.0 - smoothstep(0.0, 0.05, edge);
		float scan_y = mod(TIME * 150.0, 1600.0) - 250.0;
		float trail = step(p.y, scan_y) * exp(-(scan_y - p.y) / 170.0);
		float bar = exp(-abs(p.y - scan_y) / 3.0);
		col += line_color.rgb * hex * field * (0.035 + 0.22 * trail);
		col += core_color.rgb * bar * field * 0.30;
		// Struts below the flat shelf (was eight GDScript lines).
		float strut = grid_line(p.x / 90.0, 1.6) * smoothstep(0.0, 12.0, d);
		col += line_color.rgb * strut * 0.10;
	} else if (theme == 4) {
		// Drop Zone: a radar sweeps the field from the Guardian.
		vec2 rel = p - aura_center;
		float ang = atan(rel.y, rel.x);
		float sweep = fract((ang - TIME * 1.1) / TAU);
		float dist = length(rel);
		float wedge = pow(1.0 - sweep, 10.0) * smoothstep(1250.0, 500.0, dist) * smoothstep(140.0, 420.0, dist);
		float rings = grid_line(dist / 150.0, 1.3) * smoothstep(1300.0, 300.0, dist);
		col += accent.rgb * wedge * 0.07 * field;
		col += line_color.rgb * rings * field * (0.07 + 0.22 * pow(1.0 - sweep, 4.0));
	} else if (theme == 5) {
		// Null Expanse: cold stars, a slow void eye, drifting fog.
		vec2 rel = p - vec2(360.0, 300.0);
		float dist = length(rel);
		float ang = atan(rel.y, rel.x) / TAU;
		float arc1 = exp(-abs(dist - 190.0) / 2.5) * step(0.35, fract(ang * 3.0 + TIME * 0.025));
		float arc2 = exp(-abs(dist - 265.0) / 2.0) * step(0.55, fract(ang * 5.0 - TIME * 0.018));
		col += core_color.rgb * (arc1 * 0.20 + arc2 * 0.14);
		col += accent.rgb * exp(-dist / 160.0) * 0.07;
		float n = noise(vec2(p.x * 0.006 - TIME * 0.05, p.y * 0.012));
		if (!low_fx) {
			n = n * 0.65 + 0.35 * noise(vec2(p.x * 0.015 + TIME * 0.08, p.y * 0.03));
			col += core_color.rgb * motes(p, 38.0, vec2(0.0), 0.12, 1.6) * 0.45 * smoothstep(700.0, 100.0, p.y);
		}
		float band = smoothstep(130.0, 330.0, p.y) * (1.0 - smoothstep(560.0, 760.0, p.y));
		col = mix(col, vec3(0.62, 0.70, 0.85), smoothstep(0.35, 0.85, n) * band * 0.16);
	} else if (theme == 6) {
		// Menus: violet light from the projector below, slanted light leaks.
		vec2 rel = p - vec2(360.0, 1180.0);
		float cone = exp(-abs(rel.x) / (60.0 + max(-rel.y, 0.0) * 0.45)) * smoothstep(-900.0, -100.0, rel.y);
		col += accent.rgb * cone * 0.20;
		float leak = exp(-abs(p.x * 0.6 - p.y + 220.0 + 40.0 * sin(TIME * 0.2)) / 90.0);
		col += accent.rgb * leak * 0.10;
	}

	if (!low_fx || theme == 6) {
		// Rising motes, in the sector's own core color.
		col += core_color.rgb * motes(p, 92.0, vec2(0.0, 22.0), 0.42, 2.4) * 0.38 * field;
	}

	if (show_horizon) {
		// Neon horizon: tight core, wide halo, a shield haze rising above it
		// and a pulse that travels the line. Distance is corrected for slope
		// so steep ridges keep the same stroke width.
		float slope = (horizon_y(p.x + 2.0) - horizon_y(p.x - 2.0)) / 4.0;
		float dn = d / sqrt(1.0 + slope * slope);
		float halo = exp(-abs(dn) / 26.0) * 0.30 + exp(-abs(dn) / 90.0) * 0.12;
		float haze = field * exp(d / 170.0) * 0.08;
		float pulse_x = mod(TIME * 170.0, world.x + 500.0) - 250.0;
		float pulse = exp(-pow((p.x - pulse_x) / 80.0, 2.0)) * exp(-abs(dn) / 10.0);
		float breathe = 0.92 + 0.08 * sin(TIME * 1.4);
		col += line_color.rgb * (halo * breathe + haze);
		col = mix(col, line_color.rgb, aa_line(dn, 3.2, px) * 0.95);
		col = mix(col, core_color.rgb, aa_line(dn, 1.2, px));
		col += core_color.rgb * pulse * 0.65;
	}

	COLOR = vec4(col * brightness, 1.0);
}
