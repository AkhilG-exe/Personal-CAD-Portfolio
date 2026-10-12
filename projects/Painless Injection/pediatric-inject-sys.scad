// ============================================================================
//  pediatric_inject_sys.scad
//  Pediatric Low-Pain Insulin Delivery Pen - Slim Refactor
//
//  Design intent:
//    An ultra-compact, sleek pen-style injector sized for small hands.
//    A hollow outer shell houses a glass 3 mL cartridge, a flexible-rib
//    alignment sleeve, a metallic kinetic absorber coil, a color-coded
//    plunger/actuator, and a Luer-lock needle hub.
//
//  Cutaway logic (CRUCIAL):
//    The cutaway is applied ONLY at the top level (see render_master below).
//    No individual module subtracts the cutter. full_assembly() instantiates
//    every sub-module so a single 90-degree quadrant subtraction exposes all
//    internals - vial, plunger, spring, sleeve and needle hub - at once.
//
//  Render hints:
//    - F5 = fast preview, F6 = final CGAL render.
//    - Set show_cutaway = true to slice open the +X/+Y quadrant.
// ============================================================================

$fn = 64;

// ---------------------------------------------------------------------------
// 1. GLOBAL PARAMETERS
// ---------------------------------------------------------------------------
main_diameter      = 20;     // Slim pen body OD (mm)
device_height      = 75;     // Overall length (mm)
wall_thickness     = 2;      // Hollow shell wall (mm)
show_cutaway       = true;   // true = remove a clean 90-degree quadrant
top_cap_height     = 12;     // Removable twist-open top cap (mm)

// ---------------------------------------------------------------------------
// 2. DERIVED SHELL CONSTANTS
// ---------------------------------------------------------------------------
casing_id          = main_diameter - 2 * wall_thickness;  // 16.0 mm cavity
casing_r           = main_diameter / 2;                   // 10.0 mm
casing_base_z      = 4;                                   // Shell sits on base
casing_top_z       = 66;                                  // Open top, cap above

cutaway_width      = 100;    // Oversized cutter (top-level subtraction only)
cutaway_depth      = 200;

// ---------------------------------------------------------------------------
// 3. Z-HEIGHT LAYOUT TABLE  (footplate top = z 0)
//    0  -  4   base guard / footplate
//    4  -  8   alignment ring + hub boss
//    7  - 10   crown ring (glass flange seat)
//    8  - 58   alignment sleeve (ribs grip the glass)
//    8  -  9.4 glass crimped flange
//    9.4- 52   glass cartridge body
//   13  - 38   fluid volume
//   13  - 52   retention-rib zone
//   14  - 53   kinetic absorber coil (wraps the sleeve)
//   38  - 42   rubber stopper (bung)
//   40  - 72   plunger guide rod (crimson)
//   52  - 60   green guide channel (0.2 mm radial rod clearance)
//   60  - 66   cap skirt (bayonet over the casing collar)
//   61.5- 65.5 pre-compressed drive spring
//   66  - 75   cap crown / drive button
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// 4. NEEDLE HUB / BASE PARAMETERS
// ---------------------------------------------------------------------------
foot_d             = 30.0;   // Skin-contact footplate (low insertion pressure)
foot_h             = 4.0;
align_ring_h       = 4.0;
align_ring_od      = casing_id - 0.4;   // 15.6 mm, drops into the cavity
align_ring_bore    = 13.0;              // clears the 12 mm hub boss

luer_collar_od     = 13.5;   // Threaded Luer-lock receiver (below the plate)
luer_collar_bore   = 4.6;
luer_collar_h      = 4.0;
luer_flange_d      = 15.5;   // Snap-under retention flange
luer_flange_h      = 0.8;
luer_thread_d      = 9.0;    // Simulated thread ridge

hub_od             = 12.0;   // Internal boss carrying the fluid channel
hub_z0             = 4.0;
hub_z1             = 9.0;
crown_od           = 13.6;   // Ring cradling the crimped glass flange
crown_bore         = 12.8;
crown_z0           = 7.0;
crown_z1           = 10.0;
fluid_pass_d       = 2.0;    // Fluid passage, septum -> needle
cannula_d          = 0.7;    // Micro-needle mock cannula
cannula_z0         = -2.0;
cannula_z1         = 11.0;

// ---------------------------------------------------------------------------
// 5. CARTRIDGE CHAMBER PARAMETERS
// ---------------------------------------------------------------------------
sleeve_inner_d     = 11.8;   // Bore gripping the 11.5 mm glass cartridge
sleeve_od          = 13.6;   // 6.8 mm radius, leaves a 1.2 mm coil annulus
sleeve_z0          = 8.0;
sleeve_z1          = 58.0;
sleeve_flare_z1    = 11.0;   // Bottom flare accepts the crimped flange
sleeve_flare_d     = 14.0;

rib_count          = 4;      // Flexible retention ribs on the diagonals
rib_d              = 0.9;
rib_radius         = (sleeve_inner_d - rib_d) / 2;   // 5.45 mm pitch circle
rib_z0             = 13.0;
rib_z1             = 52.0;

cartridge_d        = 11.5;   // Standard 3 mL medical cartridge OD
glass_flange_d     = 12.6;
glass_flange_z0    = 8.0;
glass_flange_h     = 1.4;
glass_z0           = 9.4;
glass_z1           = 52.0;
cartridge_h        = glass_z1 - glass_z0;      // 42.6 mm explicit vial height
liquid_d           = cartridge_d - 0.6;   // 10.9 mm visual fluid column
liquid_z0          = 13.0;
liquid_z1          = 38.0;

// ---------------------------------------------------------------------------
// 6. PLUNGER / DRIVE PARAMETERS
// ---------------------------------------------------------------------------
bung_d             = cartridge_d - 0.2;   // 11.3 mm rubber stopper pad
bung_h             = 4.0;
bung_z0            = 38.0;                // Initial (full-dose) position
wiper_d            = cartridge_d;         // Wiper rings seal against the glass
rod_d              = 3.0;
rod_z1             = 72.0;
drive_seat_d       = 8.0;
drive_seat_z0      = 60.0;
drive_seat_h       = 1.2;
drive_coil_r       = 3.2;
drive_wire_r       = 0.6;
drive_coils        = 4;
drive_pitch        = 1.0;                 // Tight pitch = pre-compressed
drive_z0           = 61.5;
button_d           = 14.0;
button_z0          = 70.0;

guide_z0           = glass_z1 + 0.01;          // 52.0 (+0.01 clear of the vial)
guide_z1           = drive_seat_z0 - 0.01;     // 60.0 (-0.01 clear of the seat)
guide_od           = 7.8;                      // 0.2 mm shy of the cap guide bore
guide_clearance    = 0.2;                      // Radial clearance to the rod
guide_bore         = rod_d + 2 * guide_clearance;   // 3.4 mm bore (0.2/side gap)

// ---------------------------------------------------------------------------
// 7. KINETIC ABSORBER (coil wrapped around the cartridge sleeve)
// ---------------------------------------------------------------------------
kinetic_mean_r     = (sleeve_od / 2 + casing_id / 2) / 2;   // 7.4 mm
kinetic_wire_r     = 0.5;
kinetic_coils      = 8;
kinetic_z0         = 14.0;
kinetic_total_h    = 39.0;

// ---------------------------------------------------------------------------
// 8. TOP CAP PARAMETERS
// ---------------------------------------------------------------------------
cap_od             = main_diameter + 2;   // 22 mm chunky grip
cap_skirt_z0       = 60.0;
cap_skirt_top      = 66.0;
cap_guide_bore     = 8.0;
cap_button_seat_d  = 15.5;
bayonet_angle      = 45;

// ---------------------------------------------------------------------------
// 9. ERGONOMICS - view window and grip ridges
// ---------------------------------------------------------------------------
window_z_center    = 33.0;
window_h           = 30.0;
window_w           = 6.0;
grip_groove_count  = 5;
grip_groove_w      = 1.0;
grip_groove_gap    = 3.0;
grip_groove_start  = -6.0;

// ============================================================================
// FACET BUDGET - internal parts need fewer facets than visible skin
// ============================================================================
spring_fn          = 20;
internal_fn        = 32;
skin_fn            = 64;

// ============================================================================
// HELIX MATH - one parametric centerline powers every spring
// ============================================================================
function helix_point(i, n, coils, pitch, r, z0) =
    let (frac = i / n,
         a    = frac * 360 * coils)
    [ r * cos(a),
      r * sin(a),
      z0 + frac * coils * pitch ];

module coil_spring(coil_count, pitch, radius, wire_r, z0) {
    n = round(32 * coil_count);
    union() {
        for (i = [0 : n - 1]) {
            hull() {
                translate(helix_point(i,     n, coil_count, pitch, radius, z0))
                    sphere(r = wire_r, $fn = spring_fn);
                translate(helix_point(i + 1, n, coil_count, pitch, radius, z0))
                    sphere(r = wire_r, $fn = spring_fn);
            }
        }
    }
}

// ============================================================================
// HELPER - rounded ring (soft fillets on base, cap and casing rims)
// ============================================================================
module rim_torus(ring_r, cross_r, fn = skin_fn) {
    rotate_extrude($fn = fn)
        translate([ring_r, 0, 0])
            circle(r = cross_r, $fn = fn);
}

// ============================================================================
// 10. TOP CAP - twist-open lid (part of the outer casing group)
// ============================================================================
module top_cap() {
    color([0.98, 0.86, 0.62])
    difference() {
        union() {
            // Skirt wrapping the casing collar
            cylinder(h = cap_skirt_top - cap_skirt_z0, d = cap_od, $fn = skin_fn);
            // Solid crown above the skirt
            translate([0, 0, cap_skirt_top])
                cylinder(h = device_height - cap_skirt_top, d = cap_od, $fn = skin_fn);
            // Rounded crown edge
            translate([0, 0, device_height])
                rim_torus(cap_od / 2 - 2, 2);
        }
        // Hollow skirt bore over the casing
        translate([0, 0, cap_skirt_z0 - 0.1])
            cylinder(h = cap_skirt_top - cap_skirt_z0 + 0.2,
                     d = main_diameter + 0.8, $fn = skin_fn);
        // Central guide bore for the plunger rod + drive spring
        translate([0, 0, cap_skirt_z0 - 0.1])
            cylinder(h = button_z0 - cap_skirt_z0 + 0.2,
                     d = cap_guide_bore, $fn = skin_fn);
        // Counterbore seating the thumb button (+0.01 overtravel, no z-fight)
        translate([0, 0, button_z0 - 0.01])
            cylinder(h = device_height - button_z0 + 0.11,
                     d = cap_button_seat_d, $fn = skin_fn);
        // Vertical grip flutes around the crown (+0.01 overtravel, no z-fight)
        for (a = [0 : 30 : 359])
            rotate([0, 0, a])
                translate([cap_od / 2 + 0.1, 0, 70.5])
                    cube([1.6, 5.0, 9.02], center = true);
    }

    // Bayonet lugs inside the skirt (engage the casing slots)
    color([0.98, 0.86, 0.62])
    for (b = [bayonet_angle, bayonet_angle + 180])
        rotate([0, 0, b])
            translate([main_diameter / 2 + 0.9, 0, 62.5])
                cube([1.4, 9.0, 1.5], center = true);
}

// ============================================================================
// 11. HOLLOW OUTER CASING - true difference() so internals stay visible
// ============================================================================
module outer_casing() {
    color([0.96, 0.97, 0.99])
    difference() {
        union() {
            // Main thin-wall tube, open at the top for cartridge loading
            translate([0, 0, casing_base_z])
                cylinder(h = casing_top_z - casing_base_z, d = main_diameter,
                         $fn = skin_fn);
            // Soft bottom edge fillet
            translate([0, 0, casing_base_z])
                rim_torus(casing_r - wall_thickness, wall_thickness);
        }

        // TRUE hollow cavity: 2 mm wall all around
        translate([0, 0, casing_base_z - 0.1])
            cylinder(h = casing_top_z - casing_base_z + 0.2,
                     d = casing_id, $fn = skin_fn);

        // Bayonet key slots in the top collar (accept the cap lugs)
        for (b = [bayonet_angle, bayonet_angle + 180])
            rotate([0, 0, b])
                translate([casing_r - 0.7, 0, casing_top_z - 1.0])
                    cube([2.6, 11.0, 4.0], center = true);

        // Integrated view window (inspect fluid level)
        translate([casing_r + 0.1, 0, window_z_center])
            cube([window_w, wall_thickness + 1.0, window_h], center = true);

        // Side grip ridges (soft-touch texture)
        for (g = [0 : grip_groove_count - 1])
            translate([0, -casing_r, grip_groove_start + g * grip_groove_gap])
                cube([main_diameter + 2, 2.0, grip_groove_w], center = true);
    }

    // Translucent window lens seated just inside the slot
    color([0.55, 0.82, 1.0, 0.35])
    translate([casing_r - wall_thickness + 0.6, 0, window_z_center])
        cube([1.2, window_w + 1.4, window_h - 2.0], center = true);

    // Removable top cap
    top_cap();
}

// ============================================================================
// 12. CARTRIDGE VIAL - sleeve, flexible ribs, glass vial, fluid, kinetic coil
// ============================================================================
module cartridge_vial() {
    // ---- flexible-rib alignment sleeve --------------------------------
    color([0.93, 0.94, 0.96])
    difference() {
        union() {
            // Bottom flare that slides over the crimped glass flange
            translate([0, 0, sleeve_z0])
                cylinder(h = sleeve_flare_z1 - sleeve_z0,
                         d = sleeve_flare_d, $fn = skin_fn);
            // Main sleeve body
            translate([0, 0, sleeve_flare_z1])
                cylinder(h = sleeve_z1 - sleeve_flare_z1,
                         d = sleeve_od, $fn = skin_fn);
        }
        // Body bore: sleeves the glass with 0.15 mm air per side
        translate([0, 0, sleeve_z0 - 0.1])
            cylinder(h = sleeve_z1 - sleeve_z0 + 0.2,
                     d = sleeve_inner_d, $fn = skin_fn);
        // Flare bore: clearance over the crimped flange
        translate([0, 0, sleeve_z0 - 0.1])
            cylinder(h = sleeve_flare_z1 - sleeve_z0 + 0.2,
                     d = sleeve_flare_d - 0.4, $fn = skin_fn);
    }

    // ---- flexible retention ribs (grip the glass without rattling) ------
    color([0.72, 0.80, 0.88])
    for (a = [45, 135, 225, 315])
        rotate([0, 0, a])
            translate([rib_radius, 0, rib_z0])
                cylinder(h = rib_z1 - rib_z0, d = rib_d, $fn = internal_fn);

    // ---- explicit glass cartridge (fluid vial) -----------------------------
    color([0.2, 0.6, 1.0, 0.4])
    union() {
        // Crimped flange that seats on the needle-hub crown
        translate([0, 0, glass_flange_z0])
            cylinder(h = glass_flange_h, d = glass_flange_d, $fn = skin_fn);
        // Distinct vial body visible inside the cutaway
        translate([0, 0, glass_z0 + cartridge_h / 2])
            cylinder(h = cartridge_h, d = 11.5, center = true);
    }

    // ---- explicit fluid volume (amber) ---------------------------------
    color([0.95, 0.80, 0.35, 0.65])
    translate([0, 0, liquid_z0])
        cylinder(h = liquid_z1 - liquid_z0, d = liquid_d, $fn = skin_fn);

    // ---- metallic kinetic absorber coil around the sleeve ---------------
    color("silver")
    coil_spring(kinetic_coils,
                kinetic_total_h / kinetic_coils,
                kinetic_mean_r,
                kinetic_wire_r,
                kinetic_z0);
}

// ============================================================================
// 13. PLUNGER MECHANISM - crimson rod/actuator, stopper, pre-loaded spring
// ============================================================================
module plunger_mechanism() {
    // ---- dark rubber stopper (bung) -------------------------------------
    color("darkslategrey")
    union() {
        translate([0, 0, bung_z0])
            cylinder(h = bung_h, d = bung_d, $fn = skin_fn);
        // Two wiper rings seal against the glass bore
        for (z = [bung_z0 - 0.1, bung_z0 + bung_h - 1.0])
            translate([0, 0, z])
                cylinder(h = 1.0, d = wiper_d, $fn = skin_fn);
        // Spigot the rod threads into
        translate([0, 0, bung_z0 + bung_h])
            cylinder(h = 1.4, d = rod_d + 1.6, $fn = internal_fn);
    }

    // ---- crimson plunger guide rod --------------------------------------
    color("crimson")
    union() {
        translate([0, 0, bung_z0])
            cylinder(h = rod_z1 - bung_z0, d = rod_d, $fn = internal_fn);
        // Spring seat collar riveted on the rod
        translate([0, 0, drive_seat_z0])
            cylinder(h = drive_seat_h, d = drive_seat_d, $fn = internal_fn);
    }

    // ---- pre-compressed drive spring ------------------------------------
    color([0.72, 0.76, 0.80])
    coil_spring(drive_coils, drive_pitch, drive_coil_r, drive_wire_r, drive_z0);

    // ---- crimson thumb drive button -------------------------------------
    color("crimson")
    union() {
        translate([0, 0, button_z0])
            cylinder(h = device_height - button_z0 - 1.5, d = button_d,
                     $fn = skin_fn);
        translate([0, 0, device_height])
            rim_torus(button_d / 2 - 1.5, 1.5);
    }
}

// ============================================================================
// 14. NEEDLE HUB - dark base guard, Luer-lock, fluid path, mock cannula
// ============================================================================
module needle_hub() {
    // ---- dark base guard / footplate ------------------------------------
    color("darkslategrey")
    union() {
        cylinder(h = foot_h, d1 = foot_d, d2 = foot_d - 3, $fn = skin_fn);
        // Rounded outer rim so it never digs into the skin
        rim_torus(foot_d / 2 - 2.5, 2.5);
        // Alignment ring locating the shell on the base
        difference() {
            translate([0, 0, foot_h])
                cylinder(h = align_ring_h, d = align_ring_od, $fn = skin_fn);
            translate([0, 0, foot_h - 0.1])
                cylinder(h = align_ring_h + 0.2, d = align_ring_bore,
                         $fn = skin_fn);
        }
    }

    // ---- Luer-lock receiver on the plate underside ----------------------
    color([0.85, 0.85, 0.89])
    union() {
        // Snap-under flange
        translate([0, 0, -luer_flange_h])
            cylinder(h = luer_flange_h, d = luer_flange_d, $fn = internal_fn);
// Threaded collar (bore +0.01 overtravel, no z-fight)
        difference() {
            cylinder(h = luer_collar_h, d = luer_collar_od, $fn = internal_fn);
            translate([0, 0, -0.01])
                cylinder(h = luer_collar_h + 0.11, d = luer_collar_bore,
                         $fn = internal_fn);
        }
        // Two thread ridges standing proud of the collar bore
        for (z = [1.15, 3.15])
            difference() {
                translate([0, 0, z])
                    cylinder(h = 0.5, d = luer_thread_d, $fn = internal_fn);
                translate([0, 0, z - 0.1])
                    cylinder(h = 0.7, d = luer_collar_bore, $fn = internal_fn);
            }
    }

    // ---- internal hub boss + crown seat ---------------------------------
    color([0.88, 0.90, 0.92])
    difference() {
        union() {
            // Boss transferring load from the sleeve to the plate
            translate([0, 0, hub_z0])
                cylinder(h = hub_z1 - hub_z0, d = hub_od, $fn = skin_fn);
            // Crown ring cradling the glass flange
            translate([0, 0, crown_z0])
                cylinder(h = crown_z1 - crown_z0, d = crown_od, $fn = skin_fn);
        }
        // Crown bore receiving the flange
        translate([0, 0, crown_z0 - 0.1])
            cylinder(h = crown_z1 - crown_z0 + 0.2, d = crown_bore,
                     $fn = skin_fn);
        // Fluid passage bore through the boss (cartridge -> needle)
        translate([0, 0, -0.1])
            cylinder(h = crown_z1 + 1.0, d = fluid_pass_d, $fn = skin_fn);
        // Funnel lead-in facing the cartridge septum
        translate([0, 0, crown_z0 - 2.0])
            cylinder(h = 3.0, d1 = fluid_pass_d, d2 = 9.0, $fn = skin_fn);
    }

    // ---- micro-needle mock cannula --------------------------------------
    color([0.75, 0.76, 0.80])
    translate([0, 0, cannula_z0])
        cylinder(h = cannula_z1 - cannula_z0, d = cannula_d, $fn = internal_fn);
}

// ============================================================================
// 15. GREEN GUIDE CHANNEL - centres the crimson rod, 0.2 mm radial clearance
//     Bore ends get +0.01 overtravel so coplanar faces never z-fight.
// ============================================================================
module guide_channel() {
    color([0.2, 0.75, 0.45])
    difference() {
        // Guide sleeve in the casing neck, just above the glass vial
        translate([0, 0, guide_z0])
            cylinder(h = guide_z1 - guide_z0, d = guide_od, $fn = internal_fn);
        // Rod bore: rod (3.0) has a 0.2 mm gap all around inside 3.4 mm bore
        translate([0, 0, guide_z0 - 0.01])
            cylinder(h = guide_z1 - guide_z0 + 0.02, d = guide_bore,
                     $fn = internal_fn);
    }
}

// ============================================================================
// 16. MASTER ASSEMBLY - every internal sub-assembly in one coordinate frame
// ============================================================================
module full_assembly() {
    outer_casing();
    cartridge_vial();      // Glass cartridge + sleeve + kinetic coil
    plunger_mechanism();   // Inner plunger rod, stopper, drive spring
    needle_hub();          // Bottom base guard, Luer & needle assembly
    guide_channel();       // Green guide sleeve around the plunger rod
}

// ============================================================================
// 17. TOP-LEVEL RENDER - cutaway applied ONLY here
// ============================================================================
module render_master() {
    if (show_cutaway) {
        difference() {
            full_assembly();
            // 90-degree quadrant cutter box (removes the +X/+Y quadrant)
            translate([0, 0, -10])
                cube([cutaway_width, cutaway_width, cutaway_depth]);
        }
    } else {
        full_assembly();
    }
}

render_master();
