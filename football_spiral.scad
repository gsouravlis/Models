// ============================================================================
// Parametric Spiral Football Fidget ("Impossible Passthrough" Style)
// ============================================================================
// Modeled after the two-piece interlocking spiral toy in Spiral.webp, shaped
// as a pointed American football with a flat standing base.
//
// How the Seamless Geometry Works (Zero Flat Ledges!):
//   1. Top Tip Transition:
//      Piece B (White) owns the central core cylinder (`core_radius`) plus N
//      helical fins. Piece A (Brown) owns the complementary outer ribs at
//      `r > core_radius + clearance`. As the football envelope naturally tapers
//      narrower than `core_radius` near the top tip, the top tip automatically
//      becomes solid White while the Brown ribs feather out in smooth, rounded
//      arches just below the tip—with open helical channels all the way out!
//   2. Bottom Base Transition:
//      Near the bottom base, a smooth parabolic inner cup (`bottom_cavity_r(z)`)
//      tapers radially inward below the football's outer surface. Piece B's
//      white fins follow this inner taper (disappearing beneath the brown outer
//      shell in smooth U-shaped arches), while Piece A forms a solid, sturdy
//      base at the bottom.
//
// Render Modes (`render_mode`):
//   "assembled"     - Complete two-tone spiral football nested together
//   "exploded"      - Inner piece partially twisted & lifted out (action view)
//   "side_by_side"  - Both pieces next to each other in upright orientation
//   "print_plate"   - Both pieces oriented flat on Z=0 for 3D printing
//   "outer_only"    - Only Piece A (Brown outer/bottom spiral shell)
//   "inner_only"    - Only Piece B (White inner/top spiral core)
// ============================================================================

/* [View & Export] */
render_mode = "inner_only"; // ["assembled", "exploded", "side_by_side", "print_plate", "outer_only", "inner_only"]
exploded_lift = 25;       // Vertical lift (mm) in "exploded" mode

/* [Football Proportions] */
football_height = 108;    // Total height of the football (mm)
football_diameter = 64;   // Maximum equatorial diameter (mm)
pointiness = 0.65;        // 0.0 = pure ellipsoid, 1.0 = sharp ogive football arch
bottom_flat_r = 13.5;     // Flat standing base radius at bottom (mm)
top_tip_r = 5.0;          // Rounded tip radius at top (mm, < core_radius)
base_cup_height = 20.0;   // Height of the lower parabolic cup transition (mm)
base_floor_h = 5.0;       // Solid floor thickness at the very bottom of Piece A (mm)

/* [Spiral & Interlock Parameters] */
num_spirals = 6;          // Number of spiral ribs per piece (6 matches Spiral.webp)
total_twist = 220;        // Total helical twist from bottom to top (degrees)
radial_curve_deg = 22;    // 2D pinwheel curvature (degrees) for radial interlocking
core_radius = 12.2;       // Central core radius on Piece B (mm)
clearance = 0.35;         // Radial/helical gap between pieces for 3D printing (mm)
z_clearance = 0.5;        // Vertical seating clearance in the bottom cup (mm)
rib_fillet = 2.2;         // Corner rounding radius on spiral ribs (mm)

/* [Resolution] */
$fn = 72;
extrude_slices = 110;

// ============================================================================
// Derived Constants & Helper Functions
// ============================================================================
half_h = football_height / 2;
max_r = football_diameter / 2;
twist_per_mm = total_twist / football_height;

// Classic Football Brown & White (change to Green/White if desired!)
color_outer = [0.55, 0.26, 0.11]; // Pigskin Football Brown
color_inner = [0.95, 0.95, 0.93]; // Crisp White

function clamp(v, lo, hi) = max(lo, min(hi, v));

// Asymmetric football profile:
// - Bottom (-half_h) tapers to `bottom_flat_r` for a stable standing base
// - Top (+half_h) tapers to a pointed football tip (`top_tip_r < core_radius`)
function football_r(z) =
    let(
        t = clamp(abs(z) / half_h, 0, 1),
        end_r = (z < 0) ? bottom_flat_r : top_tip_r,
        ellip = sqrt(max(0, 1 - t * t)),
        ogive = 1 - pow(t, 1.85),
        norm_r = (1 - pointiness) * ellip + pointiness * ogive
    )
    end_r + (max_r - end_r) * norm_r;

// Inner conical/parabolic cup radius near the bottom base:
// Starts at a flat circle of radius `core_radius * 0.8` (for bed adhesion when
// printing Piece B upright) and slopes outward at ~50 deg (support-free!) until
// it passes outside the football surface.
function bottom_cavity_r(z) =
    let(
        z_bot = -half_h + base_floor_h,
        z_top = -half_h + base_cup_height,
        r_floor = core_radius * 0.82,
        r_top = football_r(z_top) + 1.5,
        u = clamp((z - z_bot) / (z_top - z_bot), 0, 1)
    )
    (z < z_bot) ? 0 : r_floor + (r_top - r_floor) * u;

// ============================================================================
// 1. 3D Envelopes (Outer Football & Inner Bottom Cup)
// ============================================================================
module football_envelope(r_trim = 0) {
    steps = 96;
    pts = [
        [0, -half_h],
        for (i = [0 : steps])
            let(
                z = -half_h + (i / steps) * football_height,
                // Smooth rounding at very bottom standing edge and top tip
                bot_d = z - (-half_h),
                top_d = half_h - z,
                bot_chamfer = (bot_d < 1.8) ? (1.8 - bot_d) * 0.45 : 0,
                top_dome = (top_d < 3.5) ? pow((3.5 - top_d) / 3.5, 2) * top_tip_r : 0,
                r = max(0.05, football_r(z) - r_trim - bot_chamfer - top_dome)
            )
            [r, z],
        [0, half_h]
    ];
    rotate_extrude(convexity = 4)
        polygon(pts);
}

// The 3D volume allowed for Piece B (flat bottom pad + support-free 50-deg taper)
module inner_allowed_envelope(radial_gap = 0, z_shift = 0) {
    steps = 96;
    z_min = -half_h + base_floor_h + z_shift;
    pts = [
        [0, z_min],
        for (i = [0 : steps])
            let(
                z = z_min + (i / steps) * (half_h - z_min),
                top_d = half_h - z,
                top_dome = (top_d < 3.5) ? pow((3.5 - top_d) / 3.5, 2) * top_tip_r : 0,
                r_fb = football_r(z) - top_dome - 0.03,
                r_cav = (z - z_shift < -half_h + base_cup_height)
                        ? (bottom_cavity_r(z - z_shift) - radial_gap)
                        : (max_r + 5),
                r = max(0.05, min(r_fb, r_cav))
            )
            [r, z],
        [0, half_h]
    ];
    rotate_extrude(convexity = 4)
        polygon(pts);
}

// ============================================================================
// 2. 2D Interlocking Pinwheel Cross-Section
// ============================================================================
module single_vane_2d(r_in, r_out, ang_w) {
    n_pts = 16;
    outer_pts = [
        for (i = [0 : n_pts])
            let(
                u = i / n_pts,
                r = r_in + u * (r_out - r_in),
                a = radial_curve_deg * sin(u * 140) - ang_w / 2
            )
            [r * cos(a), r * sin(a)]
    ];
    inner_pts = [
        for (i = [n_pts : -1 : 0])
            let(
                u = i / n_pts,
                r = r_in + u * (r_out - r_in),
                a = radial_curve_deg * sin(u * 140) + ang_w / 2
            )
            [r * cos(a), r * sin(a)]
    ];
    polygon(concat(outer_pts, inner_pts));
}

// 2D cross-section of Piece B (Central Core + N Curved Blades)
module inner_profile_2d(extra_offset = 0) {
    pitch_ang = 360 / num_spirals;
    vane_ang = pitch_ang * 0.48;
    r_bound = max_r + 5;

    offset(r = rib_fillet, $fn = 20)
    offset(delta = -rib_fillet + extra_offset) {
        union() {
            circle(r = core_radius, $fn = 48);
            for (k = [0 : num_spirals - 1]) {
                rotate([0, 0, k * pitch_ang])
                    single_vane_2d(core_radius * 0.55, r_bound, vane_ang);
            }
        }
    }
}

// 2D cross-section of Piece A (Complementary N Outer Ribs)
module outer_profile_2d() {
    r_bound = max_r + 4;
    offset(r = rib_fillet, $fn = 20)
    offset(delta = -rib_fillet) {
        difference() {
            circle(r = r_bound, $fn = 64);
            inner_profile_2d(extra_offset = clearance);
        }
    }
}

// ============================================================================
// 3. 3D Piece A (Outer / Bottom-Anchored Football Spiral)
// ============================================================================
module piece_outer() {
    color(color_outer)
    intersection() {
        football_envelope(r_trim = 0);

        union() {
            // 1. Full-height helical outer ribs
            translate([0, 0, -half_h])
                linear_extrude(
                    height = football_height,
                    twist = total_twist,
                    slices = extrude_slices,
                    convexity = 10
                )
                outer_profile_2d();

            // 2. Solid lower base shell (everything outside the inner parabolic cup)
            difference() {
                translate([0, 0, -half_h])
                    cylinder(h = base_cup_height + 1, r = max_r + 4);
                inner_allowed_envelope(radial_gap = -clearance, z_shift = -z_clearance);
            }
        }
    }
}

// ============================================================================
// 4. 3D Piece B (Inner / Top-Tip Football Spiral Core)
// ============================================================================
module piece_inner() {
    color(color_inner)
    intersection() {
        // Slightly inset by 0.02mm on exterior only to avoid OpenCSG preview Z-fighting
        inner_allowed_envelope(radial_gap = 0.02, z_shift = 0);

        translate([0, 0, -half_h])
            linear_extrude(
                height = football_height,
                twist = total_twist,
                slices = extrude_slices,
                convexity = 10
            )
            inner_profile_2d(extra_offset = 0);
    }
}

// ============================================================================
// 5. Scene Assembly & Render Modes
// ============================================================================
if (render_mode == "assembled") {
    piece_outer();
    piece_inner();
}
else if (render_mode == "exploded") {
    piece_outer();
    translate([0, 0, exploded_lift])
        rotate([0, 0, -twist_per_mm * exploded_lift])
        piece_inner();
}
else if (render_mode == "side_by_side") {
    translate([-football_diameter * 0.62, 0, 0])
        piece_outer();
    translate([football_diameter * 0.62, 0, 0])
        piece_inner();
}
else if (render_mode == "print_plate") {
    // Both pieces oriented upright with their flat bases resting on Z = 0
    translate([-football_diameter * 0.65, 0, half_h])
        piece_outer();
    translate([football_diameter * 0.65, 0, half_h - base_floor_h])
        piece_inner();
}
else if (render_mode == "outer_only") {
    translate([0, 0, half_h])
        piece_outer();
}
else if (render_mode == "inner_only") {
    translate([0, 0, half_h - base_floor_h])
        piece_inner();
}
