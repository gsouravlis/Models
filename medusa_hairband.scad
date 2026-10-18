// ============================================================================
// Parametric Medusa Hairband — Wavy Serpent Spine & Sinuous Viper Comb Teeth
// ============================================================================
// Modeled after `Artifacts/medusa_concept_4_sinuous_teeth.png`:
//   - An ergonomic horseshoe headband with a broad, sweeping undulating
//     serpentine spine that transitions into smooth flared temple tips.
//   - Sinuous S-curving comb teeth emerging seamlessly from the underside of
//     the wavy spine, alternating between sculpted diamond Viper Heads (with
//     recessed blind eye sockets) and tapered Sinuous Serpent Tails.
//   - Engineered for FDM 3D printing in PLA/PETG (and optional UV resin coat):
//       * Self-supporting S-curve angles (< 30 deg overhang)
//       * Flared root fillets buried cleanly inside the spine centerline
//       * Solid central web behind the recessed eye sockets
//       * Smooth hemispherical rounded snout and tail tips
//
// Render Modes (`render_mode`):
//   "display"       - Concept-art orientation (spine on top, teeth hanging down)
//   "print_bed"     - Flipped flat on Z=0 for support-free upright 3D printing
//   "tooth_closeup" - Close-up inspection of one Viper tooth + one Tail tooth
// ============================================================================

/* [View & Export] */
render_mode = "display"; // ["display", "print_bed", "tooth_closeup"]

/* [Headband Arch Dimensions] */
arch_width = 132;          // Inner side-to-side width of headband (mm)
arch_height = 144;         // Front-to-back height of headband arch (mm)
arch_max_angle = 112;      // Half-angle of horseshoe arch from crown to temple tips (deg)
temple_pinch = 9.0;        // Inward ergonomic curve near lower temple ends (mm)
temple_flare_out = 6.5;    // Graceful outward S-flare at the very ends behind ears (mm)

/* [Wavy Serpent Spine] */
spine_width = 6.8;         // Radial width of the main wavy band ribbon (mm)
spine_height = 5.4;        // Vertical height/thickness of the upper wavy band (mm)
num_spine_waves = 3.5;     // Broad sweeping serpent waves across the arch (matches Concept 4)
spine_wave_amp = 5.5;      // Radial wave amplitude of the undulating spine (mm)
wave_end_angle = 82;       // Angle where spine waves feather into smooth temple arms (deg)

/* [Snake Teeth Layout] */
num_teeth = 21;            // Total number of sinuous teeth (odd = centered viper at crown)
teeth_max_angle = 75;      // Half-angle span covered by the comb teeth (deg)
tooth_pattern = "alternating"; // ["alternating", "all_vipers", "two_vipers_one_tail"]
inward_cant_deg = 5;       // Subtle inward tilt of teeth so they hug the head (deg)

/* [Viper Head Tooth Geometry] */
viper_length = 32.0;       // Total length of viper-head teeth below spine (mm)
neck_width = 3.5;          // Tangential width of the snake body/neck (mm)
tooth_thickness = 2.9;     // Radial thickness of the snake body/neck (mm)
root_flare_w = 5.0;        // Reinforced tangential width at the spine joint (mm)
root_flare_t = 4.2;        // Reinforced radial thickness at the spine joint (mm)

head_length = 9.8;         // Length of the diamond viper head (mm)
head_width = 8.0;          // Maximum width across the viper's diamond cheeks (mm)
head_thickness = 3.5;      // Thickness of the viper head (mm)
snout_tip_w = 1.9;         // Rounded snout diameter at the apex tip (mm)
eye_socket_depth = 1.05;   // Depth of recessed blind eye sockets on each side (mm)

/* [Sinuous Tail Tooth Geometry] */
tail_length = 26.0;        // Total length of alternating serpent tail teeth (mm)
tail_tip_w = 1.6;          // Rounded tip diameter of the serpent tail (mm)

/* [S-Curve Undulation] */
s_curve_amp = 2.5;         // Tangential S-wave amplitude of each snake tooth (mm)
s_curve_cycles = 1.15;     // Number of S-wave undulations along each tooth

/* [Resolution] */
$fn = 48;
arch_steps = 180;
tooth_slices = 48;

// ============================================================================
// Helper Functions
// ============================================================================
function clamp(v, lo, hi) = max(lo, min(hi, v));
function smoothstep(t) = let(c = clamp(t, 0, 1)) c * c * (3 - 2 * c);
function lerp(a, b, t) = a + (b - a) * t;

// Smooth envelope that is 1.0 in the toothed zone and feathers to 0 at temple arms
function wave_envelope(ang) =
    let(a = abs(ang))
    (a <= wave_end_angle - 16) ? 1.0 :
    (a >= wave_end_angle + 12) ? 0.0 :
    1.0 - smoothstep((a - (wave_end_angle - 16)) / 28.0);

// Ergonomic temple pinch + outward S-flare at the lower tips (like Concept 4)
function temple_offset(ang) =
    let(a = abs(ang))
    (a <= wave_end_angle - 10) ? 0.0 :
    let(u = clamp((a - (wave_end_angle - 10)) / (arch_max_angle - (wave_end_angle - 10)), 0, 1))
    -temple_pinch * sin(u * 135) + temple_flare_out * pow(u, 2.8);

// Radial wave offset at angle `ang`
function spine_wave_offset(ang) =
    spine_wave_amp * cos(ang * num_spine_waves * 180 / wave_end_angle) * wave_envelope(ang);

// Base smooth arch point (without rapid wave wiggle, used for clean normal orientation)
function base_arch_pt(ang) =
    let(
        rx = arch_width / 2 + temple_offset(ang),
        ry = arch_height / 2
    )
    [rx * sin(ang), ry * cos(ang)];

// Smooth arch normal angle (deg) so teeth & cross-sections follow the head curve
function base_arch_normal_ang(ang) =
    let(
        d = 0.5,
        p1 = base_arch_pt(ang - d),
        p2 = base_arch_pt(ang + d),
        dx = p2[0] - p1[0],
        dy = p2[1] - p1[1]
    )
    atan2(dx, dy);

// Centerline XY coordinates of the wavy horseshoe spine at angle `ang` (deg)
function spine_center_pt(ang) =
    let(
        w_off = spine_wave_offset(ang) + spine_width / 2,
        rx = arch_width / 2 + temple_offset(ang) + w_off,
        ry = arch_height / 2 + w_off
    )
    [rx * sin(ang), ry * cos(ang)];

// Determine whether tooth `idx` (centered at 0) is a Viper Head or a Serpent Tail
function is_viper_tooth(idx) =
    (tooth_pattern == "all_vipers") ? true :
    (tooth_pattern == "two_vipers_one_tail") ? ((abs(idx) % 3) != 1) :
    ((abs(idx) % 2) == 0);

// ============================================================================
// 1. Wavy Serpent Horseshoe Spine
// ============================================================================
module wavy_serpent_spine() {
    for (i = [0 : arch_steps - 1]) {
        ang1 = -arch_max_angle + (i / arch_steps) * (2 * arch_max_angle);
        ang2 = -arch_max_angle + ((i + 1) / arch_steps) * (2 * arch_max_angle);
        hull() {
            spine_node(ang1);
            spine_node(ang2);
        }
    }
}

// Each node of the spine is a 3D beveled disk/lozenge centered on the wavy path.
// Because a circular/elliptical disk in XY is isotropic under wave slope changes,
// the wavy ribbon maintains a lush, uniform width around every wave crest!
module spine_node(ang) {
    tip_dist = arch_max_angle - abs(ang);
    tip_scale_w = (tip_dist < 14) ? lerp(0.58, 1.0, smoothstep(tip_dist / 14)) : 1.0;
    tip_scale_h = (tip_dist < 14) ? lerp(0.55, 1.0, smoothstep(tip_dist / 14)) : 1.0;

    w = spine_width * tip_scale_w;
    h = spine_height * tip_scale_h;
    pt = spine_center_pt(ang);

    translate([pt[0], pt[1], 0])
        hull() {
            // Flat-bottomed beveled base at Z = 0..0.9 (for print bed adhesion)
            translate([0, 0, 0.45])
                linear_extrude(height = 0.9, center = true, scale = 1.08)
                    circle(d = w * 0.88, $fn = 28);
            // Full-width mid body
            translate([0, 0, h * 0.5])
                linear_extrude(height = h * 0.45, center = true)
                    circle(d = w, $fn = 28);
            // Smoothly crowned/chamfered top rim at Z = h
            translate([0, 0, h - 0.5])
                linear_extrude(height = 1.0, center = true, scale = 0.82)
                    circle(d = w * 0.94, $fn = 28);
        }
}

// ============================================================================
// 2. Viper Head Comb Tooth (S-Curved Body + Diamond Viper Head + Recessed Eyes)
// ============================================================================
// Built along +Z from z = 0 (at the spine underside) to z = viper_length.

function viper_width_at(u) =
    // u in [0, 1] along tooth length:
    //   0.00 - 0.16: Flared root fillet tapering into sleek neck
    //   0.16 - 0.64: Undulating snake body/neck
    //   0.64 - 0.77: Flare out into broad diamond viper cheeks
    //   0.77 - 0.96: Crisp triangular taper from cheeks to rounded snout
    //   0.96 - 1.00: Smooth hemispherical snout tip cap
    (u < 0.16) ? lerp(root_flare_w, neck_width, smoothstep(u / 0.16)) :
    (u < 0.64) ? lerp(neck_width, neck_width * 0.92, (u - 0.16) / 0.48) :
    (u < 0.77) ? lerp(neck_width * 0.92, head_width, smoothstep((u - 0.64) / 0.13)) :
    (u < 0.96) ? lerp(head_width, snout_tip_w, pow((u - 0.77) / 0.19, 0.90)) :
                 snout_tip_w * sqrt(max(0.08, 1 - pow((u - 0.96) / 0.04, 2)));

function viper_thick_at(u) =
    (u < 0.16) ? lerp(root_flare_t, tooth_thickness, smoothstep(u / 0.16)) :
    (u < 0.64) ? tooth_thickness :
    (u < 0.77) ? lerp(tooth_thickness, head_thickness, smoothstep((u - 0.64) / 0.13)) :
    (u < 0.96) ? lerp(head_thickness, snout_tip_w * 0.95, (u - 0.77) / 0.19) :
                 snout_tip_w * 0.95 * sqrt(max(0.08, 1 - pow((u - 0.96) / 0.04, 2)));

// S-curve lateral offset X(u) that starts at 0 at the root and smoothly
// levels out to a straight, symmetrical head for u >= 0.70
function snake_s_offset(u, phase_sign = 1, amp = s_curve_amp) =
    let(
        u_eff = (u < 0.70) ? u : 0.70 + (u - 0.70) * (1 - smoothstep((u - 0.70) / 0.18)) * 0.35,
        env = sin(clamp(u_eff, 0, 1) * 180)
    )
    phase_sign * amp * env * sin(u_eff * s_curve_cycles * 360);

module viper_tooth(phase_sign = 1, length_scale = 1.0) {
    L = viper_length * length_scale;
    head_u = 0.785;
    head_z_center = L * head_u;
    head_x_center = snake_s_offset(head_u, phase_sign, s_curve_amp);

    difference() {
        union() {
            // Root anchor buried inside the center of the wavy spine (z = -2.2 to 0)
            hull() {
                translate([0, 0, -2.2])
                    tooth_slice_3d(root_flare_w * 0.95, root_flare_t * 0.95);
                translate([0, 0, 0])
                    tooth_slice_3d(root_flare_w, root_flare_t);
            }
            for (i = [0 : tooth_slices - 1]) {
                u1 = i / tooth_slices;
                u2 = (i + 1) / tooth_slices;
                z1 = u1 * L;
                z2 = u2 * L;
                x1 = snake_s_offset(u1, phase_sign, s_curve_amp);
                x2 = snake_s_offset(u2, phase_sign, s_curve_amp);
                hull() {
                    translate([x1, 0, z1])
                        tooth_slice_3d(viper_width_at(u1), viper_thick_at(u1));
                    translate([x2, 0, z2])
                        tooth_slice_3d(viper_width_at(u2), viper_thick_at(u2));
                }
            }
        }

        // Sculpted Recessed Blind Eye Sockets (on BOTH front and back faces of head)
        translate([head_x_center, 0, head_z_center])
            viper_recessed_eyes();
    }
}

module tooth_slice_3d(w, t) {
    scale([max(0.2, w) / 2, max(0.2, t) / 2, 1])
        linear_extrude(height = 0.14, center = true)
            circle(r = 1.0, $fn = 24);
}

// Recessed slanted viper eye sockets (blind indents with solid center web
// and thick outer cheek walls)
module viper_recessed_eyes() {
    eye_x_offset = head_width * 0.185;
    eye_slant = -22; // angled inward toward the snout tip

    for (side_x = [-1, 1]) {
        for (face_y = [-1, 1]) {
            translate([
                side_x * eye_x_offset,
                face_y * (head_thickness / 2 - eye_socket_depth + 0.45),
                0
            ])
                rotate([0, side_x * eye_slant, 0])
                    scale([0.78, 0.95, 1.45])
                        sphere(r = 1.05, $fn = 20);
        }
    }
}

// ============================================================================
// 3. Sinuous Serpent Tail Tooth (Alternating Shorter Wavy Tooth)
// ============================================================================
function tail_width_at(u) =
    (u < 0.16) ? lerp(root_flare_w * 0.90, neck_width * 0.90, smoothstep(u / 0.16)) :
    (u < 0.96) ? lerp(neck_width * 0.90, tail_tip_w, pow((u - 0.16) / 0.80, 0.85)) :
                 tail_tip_w * sqrt(max(0.08, 1 - pow((u - 0.96) / 0.04, 2)));

function tail_thick_at(u) =
    (u < 0.16) ? lerp(root_flare_t * 0.92, tooth_thickness * 0.90, smoothstep(u / 0.16)) :
    (u < 0.96) ? lerp(tooth_thickness * 0.90, tail_tip_w, (u - 0.16) / 0.80) :
                 tail_tip_w * sqrt(max(0.08, 1 - pow((u - 0.96) / 0.04, 2)));

module serpent_tail_tooth(phase_sign = -1, length_scale = 1.0) {
    L = tail_length * length_scale;
    amp = s_curve_amp * 0.92;

    union() {
        hull() {
            translate([0, 0, -2.2])
                tooth_slice_3d(root_flare_w * 0.88, root_flare_t * 0.88);
            translate([0, 0, 0])
                tooth_slice_3d(root_flare_w * 0.90, root_flare_t * 0.92);
        }
        for (i = [0 : tooth_slices - 1]) {
            u1 = i / tooth_slices;
            u2 = (i + 1) / tooth_slices;
            z1 = u1 * L;
            z2 = u2 * L;
            x1 = snake_s_offset(u1, phase_sign, amp);
            x2 = snake_s_offset(u2, phase_sign, amp);
            hull() {
                translate([x1, 0, z1])
                    tooth_slice_3d(tail_width_at(u1), tail_thick_at(u1));
                translate([x2, 0, z2])
                    tooth_slice_3d(tail_width_at(u2), tail_thick_at(u2));
            }
        }
    }
}

// ============================================================================
// 4. Complete Medusa Hairband Assembly
// ============================================================================
module medusa_hairband_assembly() {
    half_count = floor(num_teeth / 2);

    union() {
        // 1. Undulating Wavy Horseshoe Spine
        wavy_serpent_spine();

        // 2. Array of Sinuous Viper & Tail Comb Teeth along the Arch Centerline
        for (idx = [-half_count : half_count]) {
            u_arch = (num_teeth <= 1) ? 0 : idx / half_count;
            ang = u_arch * teeth_max_angle;

            // Gentle length taper toward the lower sides (like Concept 4)
            len_scale = lerp(1.0, 0.76, pow(abs(u_arch), 2.0));

            // Position right on the centerline of the wavy spine so the root
            // is 100% embedded inside the wavy band without poking out the sides
            pt = spine_center_pt(ang);
            norm_a = base_arch_normal_ang(ang);

            // Alternate S-wave phase so neighboring snakes weave organically
            phase_sign = ((idx % 2) == 0) ? 1 : -1;

            translate([pt[0], pt[1], spine_height - 0.9])
                rotate([0, 0, -norm_a])
                    rotate([-inward_cant_deg, 0, 0]) {
                        if (is_viper_tooth(idx)) {
                            viper_tooth(phase_sign = phase_sign, length_scale = len_scale);
                        } else {
                            serpent_tail_tooth(phase_sign = phase_sign, length_scale = len_scale);
                        }
                    }
        }
    }
}

// ============================================================================
// 5. Render Mode Dispatcher
// ============================================================================
color([0.38, 0.42, 0.47]) {
    if (render_mode == "print_bed") {
        // Flat spine on Z=0, teeth extending upward in +Z for support-free printing
        medusa_hairband_assembly();
    } else if (render_mode == "tooth_closeup") {
        // Side-by-side close-up of one Viper Tooth and one Serpent Tail Tooth
        translate([-9, 0, 0])
            viper_tooth(phase_sign = 1, length_scale = 1.0);
        translate([9, 0, 0])
            serpent_tail_tooth(phase_sign = -1, length_scale = 1.0);
    } else {
        // "display" mode: oriented like medusa_concept_4_sinuous_teeth.png
        // (Wavy spine on top, sinuous teeth hanging downward)
        translate([0, 0, viper_length + spine_height])
            rotate([180, 0, 0])
                medusa_hairband_assembly();
    }
}
