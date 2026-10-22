shader_type canvas_item;

uniform sampler2D province_id_tex : filter_nearest;
uniform sampler2D province_lut_tex : filter_nearest;
uniform int selected_province_id = 1;
uniform int hovered_province_id = -1;
uniform vec2 tex_size = vec2(1280.0, 720.0);

void fragment() {
	vec4 id_sample = texture(province_id_tex, UV);
	// Kanal R menyimpan ID Provinsi (1..255) ketika digenerate oleh MapView
	int prov_id = int(round(id_sample.r * 255.0));
	
	if (prov_id == 0) {
		// Lautan / Samudra dengan pola garis lintang halus
		float wave = sin(UV.y * 180.0 + UV.x * 40.0) * 0.012;
		COLOR = vec4(0.055 + wave, 0.095 + wave, 0.155 + wave, 1.0);
	} else {
		// Ambil warna provinsi dari 1D LUT Texture (256x1)
		float lut_u = (float(prov_id) + 0.5) / 256.0;
		vec4 fill_color = texture(province_lut_tex, vec2(lut_u, 0.5));
		
		// Deteksi perbatasan provinsi (Border Detection 4 arah)
		vec2 px = 1.5 / tex_size;
		int id_r = int(round(texture(province_id_tex, UV + vec2(px.x, 0.0)).r * 255.0));
		int id_l = int(round(texture(province_id_tex, UV - vec2(px.x, 0.0)).r * 255.0));
		int id_u = int(round(texture(province_id_tex, UV + vec2(0.0, px.y)).r * 255.0));
		int id_d = int(round(texture(province_id_tex, UV - vec2(0.0, px.y)).r * 255.0));
		
		bool is_border = (id_r != prov_id) || (id_l != prov_id) || (id_u != prov_id) || (id_d != prov_id);
		
		if (prov_id == selected_province_id) {
			fill_color.rgb = mix(fill_color.rgb, vec3(1.0, 0.92, 0.55), 0.28);
		} else if (prov_id == hovered_province_id) {
			fill_color.rgb = mix(fill_color.rgb, vec3(1.0, 1.0, 1.0), 0.15);
		}
		
		if (is_border) {
			if (prov_id == selected_province_id) {
				fill_color.rgb = vec3(1.0, 0.84, 0.25);
			} else {
				fill_color.rgb = mix(fill_color.rgb, vec3(0.04, 0.05, 0.08), 0.78);
			}
		}
		
		COLOR = fill_color;
	}
}
