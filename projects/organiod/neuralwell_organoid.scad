$fn = 48;

plate_a    = 66;
dish_r     = 19.5;
rim_h      = 6.5;
floor_h    = 1.6;
ppitch     = 3.6;
half       = 2;
pillar_r   = 0.62;
pillar_h   = 2.6;
bed_r      = 11.0;
moat_r     = 14.0;
moat_w     = 2.2;
grow_blob  = true;
show_lid   = false;

glass  = [0.70, 0.78, 0.86, 0.60];
gold   = [0.85, 0.72, 0.25];
tissue = [0.93, 0.42, 0.50, 0.55];
pdms   = [0.45, 0.48, 0.55];
pcb    = [0.10, 0.30, 0.16];
dark   = [0.16, 0.17, 0.20];

fz = 2.2 + floor_h;

module dish() {
    color(glass) difference() {
        union() {
            translate([0, 0, 1.1]) minkowski() {
                cube([plate_a - 8, plate_a - 8, 2.2 - 1.2], center = true);
                sphere(r = 3.0, $fn = 24);
            }
            translate([0, 0, 2.2]) cylinder(r = dish_r, h = rim_h);
        }
        translate([0, 0, fz]) cylinder(r = dish_r - 1.9, h = rim_h + 2);
        translate([0, 0, fz - 0.55]) rotate_extrude($fn = 48)
            translate([moat_r, 0]) circle(r = moat_w / 2 + 0.35, $fn = 24);
    }
    color(dark) for (a = [0:90:270]) rotate([0, 0, a])
        translate([plate_a / 2 - 5, plate_a / 2 - 5, 1.1]) cylinder(r = 1.6, h = 2.2, center = true);
}

module pillar() {
    color(pdms) cylinder(r = 0.95, h = 0.8);
    color(gold) {
        translate([0, 0, 0.8]) cylinder(r = pillar_r - 0.12, h = pillar_h - 0.8 - pillar_r, $fn = 16);
        translate([0, 0, pillar_h - pillar_r]) cylinder(r1 = pillar_r - 0.1, r2 = 0.08, h = pillar_r * 1.6, $fn = 16);
    }
}

module bed() {
    for (j = [-half:half]) for (i = [-half:half]) {
        x = i * ppitch + (abs(j) % 2) * ppitch / 2;
        y = j * ppitch * 0.866;
        if (sqrt(x * x + y * y) <= bed_r) translate([x, y, fz]) pillar();
    }
    for (a = [0:60:300]) rotate([0, 0, a]) translate([6.5, 0, fz + 0.8]) {
        color(gold) cylinder(r = 1.5, h = 3.2, $fn = 24);
        color([0.12, 0.13, 0.15]) translate([0, 0, 0.2]) cylinder(r = 0.7, h = 3.6, $fn = 16);
    }
    if (grow_blob) color(tissue) {
        translate([0, 0, fz + pillar_h + 2.6]) sphere(r = 4.3);
        for (a = [0:120:359]) rotate([0, 0, a]) translate([2.6, 0, fz + pillar_h + 2.2]) sphere(r = 2.4);
        rotate([0, 0, 60]) translate([0, 0, fz + pillar_h + 1.4]) sphere(r = 2.8);
    }
}

module ports() {
    for (a = [210, 330]) rotate([0, 0, a]) translate([0, 0, fz + 0.6]) rotate([0, -90, 0]) {
        color(gold) translate([dish_r + 3, 0, 0]) cylinder(r = 1.5, h = 7, center = true, $fn = 24);
        color(dark) translate([dish_r + 3, 0, 0]) rotate([0, 90, 0]) cylinder(r = 0.75, h = 5, center = true, $fn = 16);
        color([0.72, 0.30, 0.55]) translate([dish_r + 7, 0, 0]) cylinder(r = 2.6, h = 1.6, center = true, $fn = 24);
    }
}

module edge_leads() {
    color(gold) {
        for (i = [0:5]) translate([-18 + i * 7, -plate_a / 2 + 4, 1.1]) cube([2.6, 4.4, 0.6], center = true);
        for (a = [-50:20:50]) rotate([0, 0, a]) translate([dish_r - 3, 0, 1.15]) cube([5, 0.5, 0.5]);
    }
}

module lid() {
    color(glass) {
        translate([0, 0, fz + rim_h + 1.4]) difference() {
            cylinder(r = dish_r + 3, h = 1.8);
            translate([0, 0, -0.4]) cylinder(r = dish_r - 1.0, h = 2.4);
        }
        for (v = [-1, 1]) translate([v * 4, 0, fz + rim_h + 1.5]) cube([3.4, 9, 1.6], center = true);
    }
    color(gold) translate([0, 0, fz + rim_h + 4.2]) {
        cylinder(r = 7, h = 1.2);
        sphere(r = 2.4);
    }
}

module neuralwell() {
    dish();
    bed();
    ports();
    edge_leads();
    if (show_lid) lid();
}

neuralwell();