NEMA17_SIDE_LEN = 42.3 + 0.5;
NEMA17_CENTER_RADIUS = 11 + 0.4;
NEMA17_SCREW_HOLE_OFFSET = (NEMA17_SIDE_LEN - 31) / 2;
SPACER_THICKNESS = 2;
STAND_THICKNESS = SPACER_THICKNESS;
gear_diameter = 34;

include <inc/circumscribed_polygon.scad>;

module nema17_frame(thickness=2) {
    difference() {
        cube([NEMA17_SIDE_LEN, NEMA17_SIDE_LEN, thickness]);
        _coord1 = NEMA17_SCREW_HOLE_OFFSET;
        _coord2 = NEMA17_SIDE_LEN - NEMA17_SCREW_HOLE_OFFSET;
        screw_hole_pos = [
            [_coord1, _coord1],
            [_coord2, _coord2],
            [_coord2, _coord1],
            [_coord1, _coord2]
        ];
        for (i=screw_hole_pos) {
            translate([i[0], i[1], 0]) {
                #cylinder_outer(radius=1.5, height=thickness, fn=8);
            }
        }
        _center = NEMA17_SIDE_LEN / 2;
        translate([_center, _center, 0]) {
            #cylinder_outer(radius=NEMA17_CENTER_RADIUS, height=thickness, fn=6);
        }
    }
}

module gear_cut() {
    cylinder(d=gear_diameter+2, h=8);
}

module frame_stand(width, height, thickness=STAND_THICKNESS, frame_thickness=SPACER_THICKNESS) {
    linear_extrude(height=thickness) {
        polygon([[0, 0], [width, 0], [frame_thickness, height], [0, height]]);
    }
}

module titan_aero_mount() {
    height = NEMA17_SIDE_LEN + 2*2;
    difference() {
        union() {
            cube([56,height,10]);
            translate([56-30,0,10]) {
                cube([30, height, 4]);
            }
        }
        // TODO screw holes
        translate([3, 20, 0]) {
            cylinder(d=3.9, h=10);
            translate([0,0,6]) cylinder(d=7.2, h=4);
        }
        translate([33, 20, 0]) {
            cylinder(d=3.9, h=14);
            translate([0,0,6]) cylinder(d=7.2, h=8);
        }
        translate([53, 20, 0]) {
            cylinder(d=3.9, h=14);
            translate([0,0,6]) cylinder(d=7.2, h=8);
        }
        translate([56-30-4, NEMA17_SCREW_HOLE_OFFSET+2, NEMA17_SCREW_HOLE_OFFSET + 4+10])
            rotate([0, -90, 0])
                #gear_cut();
    }
    translate([26, 0, 14]) {
        translate([0, NEMA17_SIDE_LEN + STAND_THICKNESS*2, 0]) rotate([90, 0, 0])
            frame_stand(width=30, height=NEMA17_SIDE_LEN);
        translate([0, STAND_THICKNESS, 0])rotate([90, 0, 0])
            frame_stand(width=30, height=NEMA17_SIDE_LEN);
        rotate([0, -90, 0]) translate([0, STAND_THICKNESS, -SPACER_THICKNESS]) {
            nema17_frame();
        }
    }
}


titan_aero_mount();
//nema17_frame();
//frame_stand(12, 24);