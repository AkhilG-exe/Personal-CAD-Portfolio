// ============================================================================
// hydroengine.scad
// Parametric hydrogen-fueled turbofan jet engine concept.
//
// Axis convention: the engine axis runs along +Z (front intake at Z=0,
// exhaust at Z=engine_length). All geometry is derived from the five
// top-level parameters below, so the whole model rescales with a single edit.
// ============================================================================

$fn           = 80;          // global facet resolution for smooth cylinders/balls
engine_length = 200;         // overall engine length along the Z axis (mm)
fan_diameter  = 90;          // fan rotor tip diameter (mm)
blade_count   = 18;          // number of fan blades on the rotor disc
show_cutaway  = true;       // true => slice out a 90-degree quadrant for renders

// ----------------------------------------------------------------------------
// Derived engineering parameters (all lengths in mm, angles in degrees)
// ----------------------------------------------------------------------------
FAN_R     = fan_diameter / 2;                 // fan tip radius            = 45
HUB_R     = FAN_R * 0.24;                     // spinner / blade root radius ~ 11
SHAFT_R   = 5;                                // low-pressure (LP) spool radius
SHELL_T   = 3;                                // generic casing wall thickness
BLADE_T   = 1.2;                              // default blade section half-thickness

// Station boundaries along +Z (front -> aft)
COMP_Z0   = 36;                               // fan outlet / core inlet flange
COMB_Z0   = 104;                              // combustor inlet flange
EXH_Z0    = 146;                              // turbine inlet station
NOZ_Z0    = 172;                              // nozzle throat region begins

// Component counts and the variable-geometry nozzle setting
comp_blades = 20;                             // rotor blades per compressor stage
stator_n    = 18;                             // stator vanes per inter-stage row
turb_blades = 20;                             // HP turbine rotor blade count
noz_flaps   = 12;                             // overlapping thrust-flap petals
noz_teeth   = 16;                             // sawtooth chevrons on the shroud
nozzle_open = 26;                             // flap deflection angle (deg), 0 = shut

// ----------------------------------------------------------------------------
// Outer nacelle / core-casing contour: [axial station, outer radius] samples.
// The shell is lofted between consecutive samples, giving the engine its
// characteristic fan hump -> squeezed core -> combustor bulge -> nozzle taper.
// ----------------------------------------------------------------------------
outer_contour = [
    [ 2, 54],   // intake lip plane (lip torus centreline R=51, tube 6)
    [ 8, 54],   // nacelle belly around the fan
    [22, 54],
    [34, 51],   // taper begins aft of the spinner
    [46, 36],   // converge onto the slender compressor casing
    [98, 36],   // compressor casing (LH2 coil wraps on its outside)
    [110, 44],  // combustor flare
    [132, 46],  // combustor belly
    [142, 41],  // turbine casing entry
    [160, 33],
    [176, 28],
    [196, 22]   // stealth-nozzle shroud trailing edge
];

// ----------------------------------------------------------------------------
// Airfoil helper: a symmetric biconvex 2-D blade section. Chord `c` runs along
// +X; `t` is the maximum half-thickness at mid-chord via an elliptical loading
//  y = 2*t*sqrt(u*(1-u)), giving a rounded nose and a paper-thin trailing edge.
// ----------------------------------------------------------------------------
function profile_pts(c, t, n = 18) =
    [ for (i = [0 : n]) let(u = 1 - i / n) [ c * u,  2 * t * sqrt(u * (1 - u)) ] ]
  + [ for (i = [0 : n]) let(u =     i / n) [ c * u, -2 * t * sqrt(u * (1 - u)) ] ];

// ----------------------------------------------------------------------------
// axial_vane: one twisted, raked vane whose root sits at the local origin and
// whose tip reaches `span` mm along +X. The extrusion (Z) is re-axed to the
// radial direction with rotate([0,90,0]), then leaned axially by `rake`, so
// `twist` becomes a genuine spanwise torsion of the aerofoil section.
// ----------------------------------------------------------------------------
module axial_vane(span = 30, c = 12, t = 1.2, rake = -18, twist = -42) {
    rotate([0, rake, 0])
        rotate([0, 90, 0])
            linear_extrude(height = span, twist = twist, slices = 20, $fn = 24)
                polygon(profile_pts(c, t));
}

// ----------------------------------------------------------------------------
// rotor_ring: a full annulus of `n` vanes mounted at radius `r_root`, each
// extending out to `r_tip`. Shared by the fan, compressor and HP turbine.
// ----------------------------------------------------------------------------
module rotor_ring(z, r_root, r_tip, n, rake, twist, c, t, col) {
    color(col, 0.95)
    for (i = [0 : n - 1])
        rotate([0, 0, i * 360 / n])
            translate([r_root, 0, z])
                axial_vane(span = r_tip - r_root, c = c, t = t,
                           rake = rake, twist = twist);
}

// ----------------------------------------------------------------------------
// stator_ring: the stationary counterpart - vanes hung from the casing inner
// wall at `r_out`, pointing inward to `r_in` (mirrored rotor vanes).
// ----------------------------------------------------------------------------
module stator_ring(z, r_out, r_in, n, rake, c, t, col) {
    color(col, 0.95)
    for (i = [0 : n - 1])
        rotate([0, 0, i * 360 / n])
            translate([r_out, 0, z])
                mirror([1, 0, 0])
                    axial_vane(span = r_out - r_in, c = c, t = t,
                               rake = rake, twist = -10);
}

// ============================================================================
// FAN STAGE  (Z 0..36) - lip, spinner, rotor and exit guide vanes
// ============================================================================
module fan_stage() {

    // Intake lip: a torus whose centreline radius (51) matches the shell nose.
    color("DarkGray")
    rotate_extrude($fn = 72)
        translate([51, 0]) circle(d = 6, $fn = 24);

    // Aerodynamic spinner: a rounded nose cap that bleeds into a slimming
    // ogive cone (ogive = FAN_R*0.32 -> 3:1 slenderness) and finishes on the
    // fan hub barrel that carries the blade shanks.
    ogive = FAN_R * 0.32;
    color("SlateGray") {
        translate([0, 0, 10]) sphere(r = 2.5);                  // nose cap tip
        translate([0, 0, 10])
            cylinder(r1 = 2.5, r2 = HUB_R, h = ogive);          // ogive cone 10..24.4
        translate([0, 0, 10 + ogive])
            cylinder(r = HUB_R, h = 11);                        // hub barrel 24.4..35.4
    }

    // Fan rotor: blade_count twisted blades raked over the spinner.
    // The disc plane sits at Z=26 just behind the ogive shoulder; the span
    // leaves ~7 mm of tip clearance to the nacelle inner wall (FAN_R vs 49.9).
    rotor_ring(26, HUB_R + 0.5, FAN_R - 3, blade_count,
               rake = -22, twist = -48, c = 13, t = 1.4, col = "CornflowerBlue");

    // Splitter cone tip for the core inlet (guides the bypass flow).
    color("SlateGray")
        translate([0, 0, 33]) rotate_extrude($fn = 48)
            translate([24, 0]) circle(d = 4, $fn = 16);

    // Outlet guide vanes: straighten the flow in the bypass annulus (14..44).
    rotor_ring(30, 14, 44, 18, rake = 4, twist = 8, c = 7, t = 1.0,
               col = "SteelBlue");
}

// ============================================================================
// COMPRESSOR STAGE  (Z 36..104) - drum spool, rotor discs and LH2 cooling coil
// ============================================================================
module compressor_stage() {

    // High-pressure compressor drum: the visible spool core of the machine.
    color("Silver")
        translate([0, 0, COMP_Z0]) {
            cylinder(r = 11, h = COMB_Z0 - COMP_Z0);            // drum body
            translate([0, 0, -4]) cylinder(r = 11, h = 4);      // coupling to fan hub
        }

    // Rotor discs + blades: straight rotor rows at 1/4-station spacing.
    // Blade tip radius 31.5 keeps 1.5 mm clearance to the casing ID (36-3).
    rotor_rows = [54, 68, 82, 94];
    for (z = rotor_rows) {
        color("Silver")
            translate([0, 0, z])
                difference() {
                    cylinder(r = 31.5, h = 4);
                    cylinder(r = 12, h = 6);                    // bore clears the drum
                }
        rotor_ring(z, 12, 31.5, comp_blades,
                   rake = 14, twist = -30, c = 7.5, t = 1.0, col = "SteelBlue");
    }

    // Inter-stage stators: hung from the casing wall, counter-staggered.
    for (z = [61, 75, 89])
        stator_ring(z, 32.5, 13, stator_n, rake = -22,
                    c = 6, t = 0.9, col = "Silver");

    // --- Liquid-hydrogen cryogenic cooling jacket ---------------------------
    // A helix of small tube segments wrapped around the compressor casing
    // (R=38, just outside the R=36 shell). Each segment is the hull of two
    // low-$fn spheres so the loop renders cheaply yet looks like a coiled pipe.
    tube  = 2.5;                     // cooling-channel tube diameter
    R     = 38;                      // helix pitch-circle radius
    turns = 9;                       // wraps over the ~38 mm jacket length
    z0    = 58; z1 = 96;             // axial extent of the jacket
    n     = 130;                     // segment steps around the helix
    color("DodgerBlue", 0.98)
    for (i = [0 : n - 1]) {
        a0 = i * 360 * turns / n;  a1 = (i + 1) * 360 * turns / n;
        zA = z0 + (i / n)     * (z1 - z0);
        zB = z0 + ((i + 1) / n) * (z1 - z0);
        hull() {
            translate([R * cos(a0), R * sin(a0), zA]) sphere(d = tube, $fn = 8);
            translate([R * cos(a1), R * sin(a1), zB]) sphere(d = tube, $fn = 8);
        }
    }

    // Header rings and a supply stub that feeds the jacket from below.
    color("DodgerBlue") {
        translate([0, 0, z0 - 1]) rotate_extrude($fn = 36)
            translate([R, 0]) circle(d = 4, $fn = 12);
        rotate([0, 0, 180]) translate([R + 6, 0, z0]) rotate([0, 90, 0])
            cylinder(d = 4, h = 12);                            // radial feed stub
    }
}

// ============================================================================
// COMBUSTOR STAGE  (Z 104..146) - micro-swirl injector ring + perforated liner
// ============================================================================
module combustor_stage() {

    // Annular dome / head plate that closes the compressor exit annulus.
    color("Orange")
        translate([0, 0, 106])
            difference() {
                cylinder(r = 30, h = 2);
                cylinder(r = 13, h = 3);                        // centre bore for HP shaft
            }

    // Micro-swirl fuel injector manifold ring: a torus fed by radial nozzle
    // ports angled slightly off-radial to spin the entering LH2/air mixture.
    color("Orange")
        translate([0, 0, 110]) rotate_extrude($fn = 48)
            translate([32, 0]) circle(d = 5, $fn = 16);         // manifold ring

    color("DarkOrange")
    for (i = [0 : 11])
        rotate([0, 0, i * 30 + 4])                              // +4 deg swirl stagger
            translate([31.5, 0, 110])
                rotate([0, 90, 0])                              // port axis radial
                    cylinder(r = 0.9, h = 8, center = true, $fn = 8);

    // Perforated combustion-chamber liner: a thin-walled flame tube drilled
    // with 4 rows of 8 dilution holes so the annulus air can mix with the flame.
    color("Sienna", 0.98)
    difference() {
        cylinder(r = 29, h = 32);                               // liner wall 108..140
        translate([0, 0, -0.5]) cylinder(r = 28, h = 33);       // hollow interior
        for (row = [0 : 3])
            for (a = [0 : 7])
                rotate([0, 0, a * 45])
                    translate([28.5, 0, 112 + row * 9])
                        rotate([0, 90, 0])
                            cylinder(r = 1.2, h = 4, center = true, $fn = 12);
    }

    // Spark igniter: an airframe access plug angled through the shell onto the
    // liner dome (only visible in the cutaway view).
    color("Gold")
    rotate([0, 0, 210])
        translate([39, 0, 124]) rotate([0, -52, 0]) {
            cylinder(d = 4, h = 24, center = true, $fn = 20);
            translate([0, 0, 12]) sphere(d = 5, $fn = 24);      // electrode tip
        }
}

// ============================================================================
// EXHAUST STAGE  (Z 146..200) - HP turbine + variable-geometry stealth nozzle
// ============================================================================
module exhaust_stage() {

    // --- High-pressure turbine ----------------------------------------------
    // First the casing shroud rings keep the hot gas contained (the shell
    // already provides the outer wall, these are structural flange rings).
    color("DarkGray")
    for (z = [EXH_Z0, EXH_Z0 + 12, EXH_Z0 + 26])
        translate([0, 0, z]) rotate_extrude($fn = 36)
            translate([34, 0]) circle(d = 3, $fn = 12);

    // Nozzle-guide stator (row 1) and HP rotor (row 2): rotor blades are
    // heavily twisted, stators counter-staggered to remove turbine swirl.
    stator_ring(150, 32, 13, 16, rake = -26, c = 7, t = 0.9, col = "SteelBlue");

    color("Silver")
        translate([0, 0, 158])
            difference() {
                cylinder(r = 28, h = 4);
                cylinder(r = 9, h = 6);                         // bore onto HP shaft
            }
    rotor_ring(158, 12, 29, turb_blades,
               rake = -14, twist = -58, c = 9, t = 1.1, col = "OrangeRed");

    // Exhaust cone / centre plug: bites into the jet to spread thrust profile.
    color("DimGray")
        translate([0, 0, 172]) {
            cylinder(r1 = 8, r2 = 1, h = 22);
            translate([0, 0, 22]) sphere(r = 1.5);
        }

    // --- Variable-geometry stealth nozzle -----------------------------------
    // A ring of `noz_flaps` petals, each slightly wider than its angular pitch
    // (factor 1.45) so they OVERLAP like a deck of cards. `nozzle_open` swings
    // each petal about its tangential hinge to vector/close the jet nozzle.
    tw = 2 * 22 * sin(180 / noz_flaps) * 1.45;      // petal width (overlap)
    color("SlateGray", 0.98)
    for (i = [0 : noz_flaps - 1])
        rotate([0, 0, i * 360 / noz_flaps])
            translate([0, 0, 184])
                rotate([0, nozzle_open, 0])
                    linear_extrude(height = tw, center = true)
                        polygon([[20, 0], [25, 0], [27, 16], [21, 16]]);

    // Sawtooth chevron ring: 3-facet pyramids on the shroud trailing edge,
    // the classic stealth-engine radar-scattering signature.
    color("DarkGray")
    for (i = [0 : noz_teeth - 1])
        rotate([0, 0, i * 360 / noz_teeth])
            translate([22, 0, 194])
                cylinder(r1 = 5, r2 = 0, h = 7, $fn = 3);       // 3-sided spike, tip aft
}

// ============================================================================
// CONCENTRIC SPOOLS - fuel/hydrogen delivery + structural shafting
// ============================================================================
module spool_shaft() {
    color("Silver") {
        // LP spool runs the full length, linking fan spinner and exhaust plug.
        cylinder(r = SHAFT_R, h = engine_length + 4);
    }
}

// ============================================================================
// OUTER SHELL - lofted hollow casing built from the contour samples
// ============================================================================
module outer_shell() {
    color("LightGray", 0.98)
    for (i = [0 : len(outer_contour) - 2]) {
        seg = outer_contour[i];
        nxt = outer_contour[i + 1];
        z  = seg[0]; r  = seg[1];
        r2 = nxt[1];  h  = nxt[0] - z;
        difference() {
            translate([0, 0, z]) cylinder(r1 = r, r2 = r2, h = h);     // outer skin
            translate([0, 0, z - 0.5])
                cylinder(r1 = r - SHELL_T, r2 = r2 - SHELL_T, h = h + 1);
        }
    }
}

// A few V-band clamp rings at the major module joints (mechanical detail).
module vbands() {
    color("DarkGray")
    for (zr = [[36, 51], [104, 41], [146, 40], [172, 30]])
        translate([0, 0, zr[0]]) rotate_extrude($fn = 36)
            translate([zr[1], 0]) circle(d = 3.5, $fn = 12);
}

// ============================================================================
// MASTER ASSEMBLY
// ============================================================================
module engine_core() {
    vbands();
    outer_shell();
    spool_shaft();
    fan_stage();
    compressor_stage();
    combustor_stage();
    exhaust_stage();
}

// 90-degree quadrant wedge used for the cutaway check.
// Its size is scaled off the fan so it scales with the whole model.
module cutaway_quadrant() {
    big = fan_diameter * 3;                       // reaches far past the shell
    translate([0, 0, -30])
        linear_extrude(height = engine_length + 60)
            polygon([[0, 0], [big, 0], [0, big]]); // +X/+Y sector = 90 degrees
}

module hydrogen_engine_assembly() {
    if (show_cutaway)
        difference() {
            engine_core();
            cutaway_quadrant();                    // exposes fan, spool, coil, combustor
        }
    else
        engine_core();
}

// ---- instantiate the model --------------------------------------------------
hydrogen_engine_assembly();