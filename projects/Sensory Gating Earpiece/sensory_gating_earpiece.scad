// ============================================================================
//  sensory_gating_earpiece.scad
//  Ultra-Compact BTE Sensory Gating Earpiece
//
//  Design intent:
//    A non-invasive, Behind-The-Ear sensor platform worn snugly behind the
//    pinna.  A single organic curved pod houses a micro-PCB, a Size-312
//    button-cell battery (behind a hinged access door), a dual microphone
//    port arrangement for directional acoustic filtering, and two gold
//    bio-sensing contact pads that press against the mastoid skin.
//    A tapered acoustic ear hook curls forward and down from the crest of
//    the housing to route the filtered signal into the ear canal opening.
//
//  Coordinate frame:
//    +X = outward (lateral),  -X = toward the head (medial / skin side)
//    +Y = forward (toward the mouth),  -Y = rear (behind the ear)
//    +Z = up
//
//  Cutaway logic:
//    The cutaway is applied ONLY at the top level (render_master below).
//    A single 90-degree CSG cutter box removes the +X/+Y quadrant so the
//    lateral wall, the front crest and one side of the hook fall away.
//    The exposed cross-sections show the battery chamber (split along the
//    y = 0 plane), the green PCB slot on the medial wall, the dual mic
//    ports and the hollow acoustic tube feeding the ear hook.
//
//  Render hints:
//    - F5 = fast preview, F6 = final CGAL render.
//    - Set show_cutaway = false for the assembled exterior only.
// ============================================================================

$fn = 60;

// ---------------------------------------------------------------------------
// 1. GLOBAL PARAMETERS
// ---------------------------------------------------------------------------
shell_length      = 28.0;     // Length of the main BTE housing (mm)
shell_width       =  8.0;     // Width of the earpiece body (mm)
shell_height      = 12.0;     // Height of the main curve (mm)
wall_thickness    =  1.2;     // Hollow enclosure wall (mm)
battery_d         =  7.9;     // Standard Size 312 button cell diameter (mm)
battery_h         =  3.6;     // Size 312 cell thickness (mm)
show_cutaway      = true;     // true = remove the +X/+Y quadrant

// ---------------------------------------------------------------------------
// 2. FACET BUDGET - internal/curved parts need fewer facets than global $fn
// ---------------------------------------------------------------------------
body_fn           = 40;     // organic pod spheres (hull of ellipsoids)
tube_fn           = 48;     // ear hook + acoustic tubing
detail_fn         = 32;     // small electronics (mic ports, cell rings)

// ---------------------------------------------------------------------------
// 3. CUTAWAY CUTTER CONSTANTS (top-level subtraction only)
// ---------------------------------------------------------------------------
cutaway_size      = 100;
cutaway_depth     = 300;
cutaway_z0        = -50;

// ---------------------------------------------------------------------------
// 4. SHELL - sagittal half-extent table for the organic body spine
//     Format:  [ x, y, z,  sx (lateral), sy (front-back), sz (vertical) ]
//     x = 0 keeps the whole device on the sagittal plane; sx = width/2.
//     The spine runs from the deep rear lobe up and forward to the crest,
//     roughly tracing a 28 mm arc at a ~12 mm rise (per shell_length /
//     shell_height), then the ear hook continues over the top ridge.
// ---------------------------------------------------------------------------
body_sec = [
    [0, -8.5,  0.5, 4.2, 6.4, 3.6],   // rear lobe (deep, hugs the mastoid)
    [0, -5.5,  3.5, 4.2, 6.6, 4.0],
    [0, -2.0,  6.5, 4.2, 6.8, 5.4],   // battery bulge (cell zone)
    [0,  2.0,  9.0, 4.0, 5.6, 4.8],
    [0,  5.5,  9.6, 3.6, 4.4, 3.4],   // top ridge / mic crest
    [0,  8.0,  8.6, 3.2, 3.4, 2.8]    // hook root, blends into the hook
];

// ---------------------------------------------------------------------------
// 5. ACOUSTIC EAR HOOK - tapered tube + internal bore
// ---------------------------------------------------------------------------
hook_p = [
    [0,  9.5, 10.5],   // root: merged with the crest
    [0, 11.0,  8.0],
    [0, 12.5,  5.0],
    [0, 13.2,  2.2]    // tip: aimed at the ear-canal opening
];
hook_r = [3.4, 2.9, 2.3, 1.6];        // outer taper, root -> tip

bore_p = concat([[0, 8.2, 8.8]], hook_p);   // bore lead-in reaches the body
bore_r = [1.6, 1.8, 1.4, 1.0, 0.5];         // lumen taper inside the wall

// ---------------------------------------------------------------------------
// 6. ELECTRONICS / ELECTRODE PLACEMENT
// ---------------------------------------------------------------------------
pcb_pos   = [-2.3, -1.4, 4.8];   // medial wall, long axis along the body arc
pcb_rot   = [-8, 0, 0];          // slight forward lean to follow the curve
pcb_size  = [1.5, 14, 6];        // 1.5 mm thick, 14 mm long, 6 mm wide

battery_pos = [2.0, -1.0, 6.5];  // lateral half of the bulge (door side)
door_pos    = [4.05, -1.0, 6.5]; // proud of the +X lateral face
hinge_pos   = [3.7, -4.9, 6.5];  // living-hinge tab on the door's rear edge

mic_front_pos = [0,  4.6, 11.2]; // forward-facing port on the crest
mic_rear_pos  = [0, -0.6, 11.8]; // rear-facing port on the crest
mic_tilt       = 28;             // front/rear yaw-offset for directionality

tube_p = [[0, 3.2, 9.4], [0, 6.0, 9.0], [0, 8.2, 8.8]];  // mic -> hook bore
tube_r = [1.2, 1.1, 1.0];

electrode_p = [[-3.0, -6.4, 2.4], [-3.0, -4.2, 7.2]];    // medial inner face
electrode_d = 5.2;

// ============================================================================
// HELPER - oriented tapered tube (all path points lie in the sagittal plane)
// ============================================================================
module tube_segment(p1, p2, r1, r2) {
    v   = p2 - p1;
    L   = norm(v);
    ang = atan2(-v[1], v[2]);      // X-axis rotation maps +Z onto the segment
    translate(p1)
        rotate([ang, 0, 0])
            cylinder(h = L, r1 = r1, r2 = r2, $fn = tube_fn);
}

module tapered_tube(pts, radii) {
    union() {
        for (i = [0 : len(pts) - 2])
            tube_segment(pts[i], pts[i + 1], radii[i], radii[i + 1]);
        translate(pts[0])
            sphere(r = radii[0], $fn = tube_fn);
        translate(pts[len(pts) - 1])
            sphere(r = radii[len(pts) - 1], $fn = tube_fn);
    }
}

// ============================================================================
// HELPER - organic body pod from the spine table (hull of scaled spheres)
// ============================================================================
module body_pod(sec, off) {
    hull()
        for (s = sec)
            translate([s[0], s[1], s[2]])
                scale([s[3] - off, s[4] - off, s[5] - off])
                    sphere(r = 1, $fn = body_fn);
}

// ============================================================================
// 7. OUTER HOUSING - hollow shell + tapered acoustic ear hook
// ============================================================================
module outer_housing() {
    // Hollow main pod: true difference() keeps the internals readable
    color([0.95, 0.96, 0.98, 0.95])
    difference() {
        body_pod(body_sec, 0);
        body_pod(body_sec, wall_thickness);
    }

    // Tapered acoustic ear hook with an open lumen for sound delivery
    color([0.45, 0.78, 0.95, 0.95])
    difference() {
        tapered_tube(hook_p, hook_r);
        tapered_tube(bore_p, bore_r);
    }
}

// ============================================================================
// 8. MICRO-PCB BLOCK - green 14 x 6 x 1.5 mm board on the medial wall
// ============================================================================
module micro_pcb() {
    color("darkgreen")
        translate(pcb_pos)
            rotate(pcb_rot)
                cube(pcb_size, center = true);

    // Component detailing (traces / riser chip) for shelf appeal
    color([0.12, 0.14, 0.16])
        translate([pcb_pos[0] + 0.8,
                   pcb_pos[1] - 1.5,
                   pcb_pos[2] + 2.2])
            cube([0.4, 2.4, 1.3], center = true);
    color([0.75, 0.72, 0.55])
        translate([pcb_pos[0] + 0.8,
                   pcb_pos[1] + 2.0,
                   pcb_pos[2] - 2.4])
            cube([0.4, 1.6, 1.0], center = true);
}

// ============================================================================
// 9. BATTERY COMPARTMENT - cylindrical cell slot + hinged access door
// ============================================================================
module battery_compartment() {
    // Size 312 button cell seated toward the lateral access door
    color([0.88, 0.90, 0.94])
        translate(battery_pos)
            rotate([0, 90, 0])
                cylinder(d = battery_d, h = battery_h, $fn = detail_fn);
    // Metallic countertop ring on the exposed (+X) pole
    color([0.72, 0.66, 0.55])
        translate(battery_pos + [1.7, 0, 0])
            rotate([0, 90, 0])
                cylinder(d = battery_d - 1.6, h = 0.4, $fn = detail_fn);

    // Access door cap, slightly proud of the +X lateral face
    color([0.97, 0.97, 0.99])
        translate(door_pos)
            rotate([0, 90, 0])
                cylinder(d = battery_d + 0.7, h = 0.6, $fn = detail_fn);
    // Living-hinge tab bridging the door's rear edge to the shell
    color([0.97, 0.97, 0.99])
        translate(hinge_pos)
            cube([0.8, 1.6, 2.0], center = true);
}

// ============================================================================
// 10. DUAL MICROPHONES - 1 mm front/back sensing ports on the top ridge
// ============================================================================
module microphones() {
    color("dimgray")
    union() {
        // Forward port (accepts speech-band / echo information)
        translate(mic_front_pos)
            rotate([-mic_tilt, 0, 0])
                cylinder(d = 1.0, h = 2.2, $fn = detail_fn);
        // Rear port (environmental reference for gating)
        translate(mic_rear_pos)
            rotate([mic_tilt, 0, 0])
                cylinder(d = 1.0, h = 2.2, $fn = detail_fn);
    }
}

// ============================================================================
// 11. ACOUSTIC TUBING - translucent mic-to-hook sound channel
// ============================================================================
module acoustic_tubing() {
    color([0.55, 0.85, 1.0, 0.45])
        tapered_tube(tube_p, tube_r);
}

// ============================================================================
// 12. INTERNAL ELECTRONICS ASSEMBLY
// ============================================================================
module internal_electronics() {
    micro_pcb();
    battery_compartment();
    microphones();
    acoustic_tubing();
}

// ============================================================================
// 13. BIO-SENSING CONTACT PADS - gold electrodes on the medial inner face
// ============================================================================
module contact_electrodes() {
    color("gold")
    for (p = electrode_p)
        translate(p)
            rotate([0, 90, 0])
                cylinder(d = electrode_d, h = 0.5, $fn = detail_fn);
}

// ============================================================================
// 14. MASTER ASSEMBLY - all sub-assemblies in one coordinate frame
// ============================================================================
module full_earpiece() {
    outer_housing();
    internal_electronics();
    contact_electrodes();
}

// ============================================================================
// 15. TOP-LEVEL RENDER - 90-degree cutaway applied ONLY here
// ============================================================================
module render_master() {
    if (show_cutaway) {
        difference() {
            full_earpiece();
            // Quadrant cutter: removes the +X/+Y wedge, exposing internals
            translate([0, 0, cutaway_z0])
                cube([cutaway_size, cutaway_size, cutaway_depth]);
        }
    } else {
        full_earpiece();
    }
}

render_master();