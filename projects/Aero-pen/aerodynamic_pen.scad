// ============================================================================
//  aerodynamic_pen.scad
// ----------------------------------------------------------------------------
//  Fully parametric, modular concept model of a LOW-DRAG / AERODYNAMIC pen body
//  intended for 3D printing (FDM / SLA).
//
//  Design geometry
//  ---------------
//   - Cross-section   : a polar "laminar teardrop" airfoil,
//                       r(θ) = Rmax · [ floor + (1-floor)·|cos(θ/2)|^n ],
//                       with a rounded leading "nose" (θ = 0°) and a blunt
//                       boat-tail style trailing edge (θ = 180°).
//   - Long axis       : stacked linear_extrude() sections with per-section
//                       twist and scale so the profile tapers smoothly toward
//                       the writing tip (Z = 0) and toward the rear end cap.
//   - Grip            : 3 finger-contour pockets at 120° spacing, each placed
//                       exactly on the true (twisted) shell surface.
//   - Boundary layer  : helical micro-flute grooves that track the twisted
//                       airfoil exactly, simulating drag-reducing fluting.
//   - Internals       : stepped aperture cone (tip) + straight cartridge bore.
//
//  Z = 0 is the writing-point aperture reference plane (z measured along the
//  cartridge axis).  All angles are in degrees, all lengths in mm.
// ============================================================================

// ----------------------------------------------------------------------------
// 1. GLOBAL PARAMETERS
// ----------------------------------------------------------------------------
$fn = 80;                                  // faceting resolution (smooth renders)

pen_length          = 145;                 // overall body length  [mm]
max_diameter        = 12;                  // maximum body width    [mm]
refill_diameter     = 4.2;                 // Parker/Bic cartridge bore
refill_tip_diameter = 2.3;                 // ball-point aperture at Z = 0
twist_angle         = 120;                 // total helical twist across pen_length

// .... airfoil profile of the cross-section ..............................
profile_exp         = 0.78;                // laminar-drop exponent n  (r ∝ |cos(θ/2)|^n)
profile_floor       = 0.45;                // normalized blunt trailing-edge radius

// .... longitudinal taper ................................................
front_len           = 22;                  // nose-taper zone            (Z = 0..22)
mid_len             = 96;                  // constant-section aero shaft (Z = 22..118)
rear_len            = 27;                  // taper toward end cap       (Z = 118..145)
cap_len             = 12;                  // solid aero end-cap spike   (Z = 145..157)
tip_scale           = 0.32;                // section scale at Z = 0 (writing tip)
cap_scale           = 0.55;                // section scale at start of the end cap

// .... printed round nose collar (bridges bore to thin airfoil tip) .......
nozzle_h            = 16;                  // collar axial length
nozzle_tip_r        = 2.2;                 // collar outer radius at Z = 0
nozzle_base_r       = 2.8;                 // collar outer radius at its top

// .... internal bore .....................................................
z_cone_top          = 15;                  // aperture cone -> cartridge shaft joint  (Z)
z_bore_top          = 116;                 // cartridge shaft end (rear cap is solid)

// .... ergonomic grip pockets ............................................
grip_roll           = 15;                  // roll offset of the triple pocket
grip_z0             = 31;                  // grip zone axial start
grip_len            = 18;                  // grip zone axial length
dimple_depth        = 1.3;                 // pocket radial bite   (finger contour depth)
dimple_width        = 7.5;                 // pocket tangential extent
dimple_len          = 18;                  // pocket axial extent

// .... helical micro-flutes (boundary-layer control grooves) ...............
flute_locals        = [45,135,225,315];    // profile-local angular lines
flute_radius        = 0.9;                 // groove tube radius
flute_inset         = 0.45;                // tube-center inset below the surface
flute_z0            = 36;                  // axial start of fluting
flute_z1            = 113;                 // axial end of fluting
flute_step          = 3.2;                 // hull-chain step along the helix

// .... feature toggles (handy for inspecting single sub-systems) ...........
_ENABLE_BORE        = true;
_ENABLE_GRIP        = true;
_ENABLE_FLUTES      = true;

// .... derived constants .................................................
Rmax          = max_diameter / 2;          // max profile radius
bore_r        = refill_diameter / 2;
tip_r         = refill_tip_diameter / 2;
twist_per_mm  = twist_angle / pen_length;  // deg of twist per mm of length
profile_facets= 96;                        // angular resolution of the 2D profile

twist_front   = twist_angle * front_len / pen_length;   // 18.21 deg
twist_mid     = twist_angle * mid_len   / pen_length;   // 79.45 deg
twist_rear    = twist_angle * rear_len  / pen_length;   // 22.34 deg

// ----------------------------------------------------------------------------
// 2. PROFILE MATHEMATICS
// ----------------------------------------------------------------------------

// 2.1 generic helpers
function lerp(a, b, t)     = a + (b - a) * t;
function clamp(v, lo, hi)  = min(max(v, lo), hi);
function smoothstep(a, b, x) = let (t = clamp((x - a) / (b - a), 0, 1))
                                   t * t * (3 - 2 * t);   // C1-smooth easing

// 2.2 polar teardrop radius
//     r(θ) = Rmax · [ floor + (1-floor) · |cos(θ/2)|^n ]
//       θ =   0°  ->  r = Rmax              (rounded leading nose, max thickness)
//       θ = 180°  ->  r = Rmax · floor      (blunted trailing edge / Kamm tail)
//     Raising n thins the shoulders earlier; raising floor fattens the tail.
function teardrop_radius(local_deg) =
    Rmax * ( profile_floor + (1 - profile_floor)
             * pow(abs(cos(local_deg / 2)), profile_exp) );

// 2.3 longitudinal scale: combines nose-taper, constant shaft and rear taper.
//     The easing keeps the profile transition free of kinks.
function scale_at(z) =
      z <= front_len                     ? lerp(tip_scale, 1, smoothstep(0, front_len, z))
    : z <= front_len + mid_len           ? 1
    : lerp(1, cap_scale, smoothstep(front_len + mid_len, pen_length, z));

// 2.4 surface point: for a profile-LOCAL angle phi at height z, the shell is
//     twisted by twist_per_mm*z degrees, so the WORLD bearing of that local
//     angle equals `phi + twist_per_mm*z` and the radius is the (scaled)
//     teardrop radius. This single mapping drives every later feature.
function surface_point(phi, z) =
    let ( r = scale_at(z) * teardrop_radius(phi),
          b = phi + twist_per_mm * z )
    [ r * cos(b), r * sin(b), z ];

// 2.5 flute centerline = surface point pulled INWARD by flute_inset, so every
//     groove bites a constant depth regardless of local surface radius.
function flute_point(phi, z) =
    let ( r = teardrop_radius(phi) - flute_inset,
          b = phi + twist_per_mm * z )
    [ r * cos(b), r * sin(b), z ];

// ----------------------------------------------------------------------------
// 3. TEARDROP PROFILE  (2D polygon)
// ----------------------------------------------------------------------------
//  The outline is sampled parametrically from the polar form. The polar
//  definition guarantees a star-shaped, closed, simply-connected loop whose
//  maximum radius sits at θ = 0° (the rounded "nose" direction).
module teardrop_profile() {
    polygon([
        for (i = [0 : profile_facets - 1])
            let (a = i * 360 / profile_facets)
            [ teardrop_radius(a) * cos(a),
              teardrop_radius(a) * sin(a) ]
    ]);
}

// ----------------------------------------------------------------------------
// 4. EXTRUDED AERO SECTION  (building block of pen_body)
// ----------------------------------------------------------------------------
//  linear_extrude with a {twist, relative-scale}.  The profile is pre-scaled by
//  s_bot, so the cross-section spans exactly s_bot (bottom) -> s_top (top); the
//  bottom of every section is pre-aligned with the cumulative twist `rot` of the
//  section below it, keeping the helix continuous from tip to cap.
module _aero_section(h, s_bot, s_top, tw, rot = 0) {
    rotate([0, 0, rot])
        linear_extrude(height = h, twist = tw, scale = s_top / s_bot,
                       slices = max(2, ceil(h / 2)))
            scale([s_bot, s_bot])
                teardrop_profile();
}

// ----------------------------------------------------------------------------
// 5. ROUNDED PRINTED NOSE COLLAR
// ----------------------------------------------------------------------------
//  The airfoil neck thins faster than the 4.2 mm bore permits, so a short
//  rotation-symmetric collar forms the actual writing point and guarantees the
//  clean, concentric 2.3 mm aperture at Z = 0.
module _nose_collar() {
    cylinder(h = nozzle_h, r1 = nozzle_tip_r, r2 = nozzle_base_r);
}

// ----------------------------------------------------------------------------
// 6. PEN BODY  (outer shell, union of tapered+twisted sections)
// ----------------------------------------------------------------------------
module pen_body() {
    ov = 0.02;                                  // tiny overlaps for watertight unions

    union() {
        // nose taper        : Z = 0..22,   twist 0    -> 18.2 deg, scale 0.32 -> 1
        _aero_section(front_len, tip_scale, 1.0, twist_front, 0);

        // constant aero shaft: Z = 22..118, twist 18.2 -> 97.6 deg, scale 1 -> 1
        translate([0, 0, front_len - ov])
            _aero_section(mid_len + ov, 1.0, 1.0, twist_mid, twist_front);

        // rear taper        : Z = 118..145, twist 97.6 -> 120 deg, scale 1 -> 0.55
        translate([0, 0, front_len + mid_len - ov])
            _aero_section(rear_len + ov, 1.0, cap_scale, twist_rear, twist_front + twist_mid);

        // solid aero end-cap spike : Z = 145..157, straight, scale 0.55 -> ~0
        translate([0, 0, front_len + mid_len + rear_len - ov])
            _aero_section(cap_len + ov, cap_scale, 0.02, 0, twist_angle);

        // round the very tip of the cap spike
        translate([0, 0, pen_length + cap_len - 0.6]) sphere(r = 1.6);

        // printed nose collar
        _nose_collar();
    }
}

// ----------------------------------------------------------------------------
// 7. GRIP SECTION  (3 finger-contour pockets, 120° apart)
// ----------------------------------------------------------------------------
//  Each pocket is a tri-axial ellipsoid whose centre sits exactly ON the shell
//  surface.  Its shortest axis points along the pocket's world bearing (radial),
//  its longest along the pen axis, so the boolean cut leaves a smooth concave
//  saddle that the thumb, index and middle fingers lock into.
module grip_section() {
    zc = grip_z0 + grip_len / 2;                 // pocket mid-height
    for (i = [0 : 2]) {
        b   = grip_roll + i * 120;               // world bearing of the pocket
        phi = b - twist_per_mm * zc;             // profile-local angle of that bearing
        pt  = surface_point(phi, zc);            // true point on the shell

        translate(pt)
            rotate([0, 0, b])                    // radial axis <- world bearing
                scale([dimple_depth, dimple_width / 2, dimple_len / 2])
                    sphere(r = 1);
    }
}

// ----------------------------------------------------------------------------
// 8. HELICAL MICRO-FLUTES
// ----------------------------------------------------------------------------
//  For each profile-local angle a strand of overlapping spheres is laid along
//  the twisting shell and hulled pairwise.  Because every sphere sits on the
//  true surface line, the strand follows the rotating airfoil exactly and the
//  subtraction cuts a groove of essentially constant depth - a print-friendly
//  stand-in for drag-reducing boundary-layer micro-fluting.
module micro_flutes() {
    for (phi = flute_locals)
        for (z = [flute_z0 : flute_step : flute_z1])
            hull() {
                translate(flute_point(phi, z))
                    sphere(r = flute_radius, $fn = 20);
                translate(flute_point(phi, z + flute_step))
                    sphere(r = flute_radius, $fn = 20);
            }
}

// ----------------------------------------------------------------------------
// 9. INTERNAL CORE  (refill housing + stepped tip aperture)
// ----------------------------------------------------------------------------
//  A tapered cone converges the 4.2 mm cartridge shaft down to the 2.3 mm
//  aperture at Z = 0 (the writing-point plane); a straight shaft continues to
//  z_bore_top, after which the rear taper & end cap stay solid.
module _refill_bore() {
    ov = 0.05;
    // stepped aperture cone      : Z = 0      -> z_cone_top
    cylinder(h = z_cone_top + ov, r1 = tip_r, r2 = bore_r);
    // straight cartridge shaft   : Z = z_cone_top -> z_bore_top
    translate([0, 0, z_cone_top - ov])
        cylinder(h = z_bore_top - z_cone_top + ov, r = bore_r);
}

// ----------------------------------------------------------------------------
// 10. ASSEMBLY
// ----------------------------------------------------------------------------
module aerodynamic_pen() {
    difference() {
        pen_body();
        if (_ENABLE_BORE)   _refill_bore();
        if (_ENABLE_GRIP)   grip_section();
        if (_ENABLE_FLUTES) micro_flutes();
    }
}

// ---- render the full model -------------------------------------------------
aerodynamic_pen();