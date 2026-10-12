$fn = 48;

cols        = 8;
rows        = 6;
pitch       = 6.0;
planes      = 6;
sheet_margin = 6.5;
sheet_z     = 2.0;
stack_gap   = 5.4;
wire_r      = 0.34;
wire_gap    = 1.2;
line_rise   = 0.7;
mem_r       = 1.4;
post_r      = 2.6;
post_off    = 5.0;
via_r       = 1.05;
via_ring_r  = 9.0;
axon_r      = 4.0;
myelin_or   = 5.7;
tray_z      = 3.2;
fins_n      = 12;
cap_r       = 15.0;
cap_h       = 5.0;
fin_h       = 18.0;

pcb    = [0.10, 0.34, 0.13];
gold   = [0.85, 0.72, 0.25];
diel   = [0.60, 0.63, 0.67];
dark   = [0.16, 0.17, 0.20];
steel  = [0.32, 0.34, 0.38];
myelin = [0.92, 0.93, 0.94];

SX   = (cols - 1) * pitch + 2 * sheet_margin;
SY   = (rows - 1) * pitch + 2 * sheet_margin;
dZ   = sheet_z + stack_gap;
topz = tray_z + (planes - 1) * dZ + sheet_z;
capz = topz + 4.0;
stack_top = capz + cap_h + fin_h + 6.0;

function cell_pt(i, j, off) =
    [ (i - (cols - 1) / 2) * pitch + off,
      (j - (rows - 1) / 2) * pitch + off ];

module synapse_cell(zm) {
    color(dark)  cylinder(r = mem_r, h = 1.5, center = true);
    color(gold)  translate([0, 0, 0.75]) cylinder(r = 0.55, h = 0.6, $fn = 24);
}

module plane(k) {
    off = (k % 2) ? pitch / 2 : 0;
    z   = tray_z + k * dZ + sheet_z / 2;
    lo  = z + sheet_z / 2 + line_rise;
    hi  = lo + wire_gap;
    q   = (k % 2) ? [hi, lo] : [lo, hi];

    color(diel) translate([0, 0, z]) minkowski() {
        cube([SX - 4.2, SY - 4.2, sheet_z - 1.0], center = true);
        sphere(r = 2.1, $fn = 24);
    }
    color(gold) {
        for (j = [0:rows - 1]) {
            p = cell_pt(0, j, off);
            translate([0, p[1], q[0]]) rotate([0, 90, 0])
                cylinder(h = (cols - 1) * pitch, r = wire_r, center = true);
        }
        for (i = [0:cols - 1]) {
            p = cell_pt(i, 0, off);
            translate([p[0], 0, q[1]]) rotate([90, 0, 0])
                cylinder(h = (rows - 1) * pitch, r = wire_r, center = true);
        }
    }
    for (i = [0:cols - 1], j = [0:rows - 1]) {
        p = cell_pt(i, j, off);
        translate([p[0], p[1], (lo + hi) / 2]) synapse_cell(0);
    }
}

module tray() {
    color(pcb) translate([0, 0, tray_z / 2]) minkowski() {
        cube([SX + 16, SY + 16, tray_z - 1.2], center = true);
        sphere(r = 3.0, $fn = 24);
    }
    color(gold) {
        for (i = [0:9])
            translate([-27 + i * 6, -SY / 2 - 7, tray_z / 2]) cube([3.4, 4, 0.8], center = true);
        for (s = [0, 1]) translate([s ? SX / 2 + 6 : -SX / 2 - 6, 0, 3.0])
            cylinder(r = 2.6, h = 6, center = true);
    }
    color(dark) {
        for (s = [0, 1]) translate([s ? SX / 2 + 6 : -SX / 2 - 6, 0, 3.0])
            rotate([0, 90, 0]) cylinder(r = 1.0, h = 7, center = true, $fn = 24);
        for (a = [0:90:270]) rotate([0, 0, a]) translate([(SX + 16) / 2 - 5, (SY + 16) / 2 - 5, tray_z / 2])
            cylinder(r = 1.6, h = tray_z + 1, center = true);
    }
}

module main_posts() {
    px = SX / 2 - post_off;
    py = SY / 2 - post_off;
    color(steel) {
        for (sx = [0, 1], sy = [0, 1]) {
            translate([sx ? px : -px, sy ? py : -py, stack_top / 2])
                cylinder(r = post_r, h = stack_top, center = true);
            for (k = [0:planes - 1]) {
                zc = tray_z + k * dZ + sheet_z / 2;
                translate([sx ? px : -px, sy ? py : -py, zc])
                    cylinder(r = post_r + 1.3, h = 1.6, center = true);
            }
        }
    }
}

module tsv_cluster() {
    color(steel) {
        for (a = [0:60:300]) rotate([0, 0, a]) {
            translate([via_ring_r, 0, stack_top / 2])
                cylinder(r = via_r + 0.7, h = stack_top, center = true);
            for (k = [0:planes - 1]) {
                zc = tray_z + k * dZ + sheet_z / 2;
                translate([via_ring_r, 0, zc]) cylinder(r = via_r + 1.6, h = 1.6, center = true);
            }
        }
    }
}

module axon_column() {
    color(dark) translate([0, 0, stack_top / 2 - 2]) cylinder(r = axon_r, h = stack_top, center = true);
    color(myelin) {
        for (k = [0:planes - 2]) {
            zg = tray_z + k * dZ + sheet_z + stack_gap / 2;
            translate([0, 0, zg]) difference() {
                cylinder(r = myelin_or, h = 1.6, center = true);
                cylinder(r = axon_r, h = 1.8, center = true);
            }
        }
    }
}

module cortex_cap() {
    color(dark) {
        translate([0, 0, capz + cap_h / 2]) cylinder(r = cap_r, h = cap_h, center = true);
        for (a = [0:360 / fins_n:359]) rotate([0, 0, a])
            translate([0, 0, capz]) cube([cap_r * 2 - 4, 2.2, fin_h], center = true);
        translate([0, 0, capz + cap_h + 4.5]) sphere(r = 4.5);
    }
    color(gold) {
        translate([0, 0, capz]) cylinder(r = cap_r + 1.0, h = 2.2, center = true);
        translate([0, 0, capz + cap_h + 2.0]) cylinder(r = 8, h = 1.2, center = true);
    }
}

module neuro_crossbar() {
    tray();
    for (k = [0:planes - 1]) plane(k);
    main_posts();
    tsv_cluster();
    axon_column();
    cortex_cap();
}

neuro_crossbar();