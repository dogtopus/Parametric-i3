// PRUSA iteration3
// Functions used in many files
// GNU GPL v3
// Josef Průša <josefprusa@me.com>
// Václav 'ax' Hůla <axtheb@gmail.com>
// Vlnofka <>
// http://www.reprap.org/wiki/Prusa_Mendel
// http://github.com/josefprusa/Prusa3

function c2y(vec3) = [
    sqrt(pow(vec3.x, 2) + pow(vec3.y, 2)),
    atan2(vec3.y, vec3.x),
    (vec3.z ? vec3.z : 0)
];

function y2c(vec3) = [
    vec3.x * cos(vec3.y),
    vec3.x * sin(vec3.y),
    (vec3.z ? vec3.z : 0)
];

module nut(d,h,horizontal=true){
    cornerdiameter =  (d / 2) / cos (180 / 6);
    cylinder(h = h, r = cornerdiameter, $fn = 6);
    if(horizontal){
        for(i = [1:6]){
            rotate([0,0,60*i]) translate([-cornerdiameter-0.2,0,0]) rotate([0,0,-45]) cube([2,2,h]);
        }
    }
}

module fillet(radius, height=100, $fn=0) {
    //this creates acutal fillet
    translate([-radius, -radius, -height / 2 - 0.02]) difference() {
        cube([radius * 2, radius * 2, height + 0.04]);
        if ($fn == 0 && (radius == 2 || radius == 3 || radius == 4)) {
            cylinder(r=radius, h=height + 0.04, $fn=4 * radius);
        } else {
            cylinder(r=radius, h=height + 0.04, $fn=$fn);
        }

    }
}

module cube_fillet(size, radius=-1, vertical=[3,3,3,3], top=[0,0,0,0], bottom=[0,0,0,0], center=false, $fn=0){
    //
    if (fillet_strategy == "regular") {
        if (center) {
            cube_fillet_inside(size, radius, vertical, top, bottom, $fn);
        } else {
            translate([size[0]/2, size[1]/2, size[2]/2])
                cube_fillet_inside(size, radius, vertical, top, bottom, $fn);
        }
    } else {
        if (fillet_strategy == "chamfer") {
            if (center) {
                cube_fillet_inside(size, radius, vertical, top, bottom, 4);
            } else {
                translate([size[0]/2, size[1]/2, size[2]/2])
                    cube_fillet_inside(size, radius, vertical, top, bottom, 4);
            }

        } else {
            cube(size, center);
        }
    }

}

module cube_negative_fillet(size, radius=-1, vertical=[3,3,3,3], top=[0,0,0,0], bottom=[0,0,0,0], $fn=0){

    j=[1,0,1,0];

    for (i=[0:3]) {
        if (radius > -1) {
            rotate([0, 0, 90*i]) translate([size[1-j[i]]/2, size[j[i]]/2, 0]) fillet(radius, size[2], $fn=$fn);
        } else {
            rotate([0, 0, 90*i]) translate([size[1-j[i]]/2, size[j[i]]/2, 0]) fillet(vertical[i], size[2], $fn=$fn);
        }
        rotate([90*i, -90, 0]) translate([size[2]/2, size[j[i]]/2, 0 ]) fillet(top[i], size[1-j[i]], $fn=$fn);
        rotate([90*(4-i), 90, 0]) translate([size[2]/2, size[j[i]]/2, 0]) fillet(bottom[i], size[1-j[i]], $fn=$fn);

    }
}

module cube_fillet_inside(size, radius=-1, vertical=[3,3,3,3], top=[0,0,0,0], bottom=[0,0,0,0], $fn=0){
    //makes CENTERED cube with round corners
    // if you give it radius, it will fillet vertical corners.
    //othervise use vertical, top, bottom arrays
    //when viewed from top, it starts in upper right corner (+x,+y quadrant) , goes counterclockwise
    //top/bottom fillet starts in direction of Y axis and goes CCW too


    if (radius == 0) {
        cube(size, center=true);
    } else {
        difference() {
            cube(size, center=true);
            cube_negative_fillet(size, radius, vertical, top, bottom, $fn);
        }
    }
}


module nema17(places=[1,1,1,1], size=15.5, h=10, holes=false, shadow=false, $fn=24){
    for (i=[0:3]) {
        if (places[i] == 1) {
            rotate([0, 0, 90*i]) translate([size, size, 0]) {
                if (holes) {
                    rotate([0, 0, -90*i])  translate([0,0,-10]) screw(r=1.7, slant=false, head_drop=13, $fn=$fn, h=h+12);
                } else {
                    rotate([0, 0, -90*i]) cylinder(h=h, r=5.5, $fn=$fn);
                }
            }
        }
    }
    if (shadow) {
        %translate ([0, 0, shadow+21+3]) cube([42,42,42], center = true);
    //flange
        %translate ([0, 0, shadow+21+3-21-1]) cylinder(r=11,h=2, center = true, $fn=20);
    //shaft
        %translate ([0, 0, shadow+21+3-21-7]) cylinder(r=2.5,h=14, center = true);
    }
}

t8_nut_m3_offset = 8;

module t8_nut(thread_length=10.0, base_thickness=3.5, thread_zoffset=-1.5, flip=false, $fn=24) {
    _t8_hole = 8.4;
    module _base2d() {
        difference() {
            circle(d=22);
            for (rot=[0:90:270]) {
                translate(y2c([t8_nut_m3_offset, rot])) circle(d=3.4);
            }
            circle(d=_t8_hole);
        }
    }
    module _thread2d() {
        difference() {
            circle(d=10.2);
            circle(d=_t8_hole);
        }
    }

    if (flip) {
        translate([0, 0, -thread_length - thread_zoffset]) linear_extrude(thread_length) {
            _thread2d();
        }
    } else {
        translate([0, 0, thread_zoffset]) linear_extrude(thread_length) {
            _thread2d();
        }
    }
    linear_extrude(base_thickness) {
        _base2d();
    }
}

module screw(h=20, r=2, r_head=3.5, head_drop=0, slant=use_box_frame, poly=false, $fn=0){
    //makes screw with head
    //for substraction as screw hole
    if (poly) {
        cylinder_poly(h=h, r=r, $fn=$fn);
    } else {
        cylinder(h=h, r=r, $fn=$fn);
    }
    if (slant) {
        translate([0, 0, head_drop-0.01]) cylinder(h=r_head, r2=0, r1=r_head, $fn=$fn);
    }

    if (head_drop > 0) {
        translate([0, 0, -0.01]) cylinder(h=head_drop+0.01, r=r_head, $fn=$fn);
    }
}

module plate_screw(long=0) {
    if (!use_box_frame) {
        translate([0, 0, -long]) screw(head_drop=14 + long, h=30 + long, r_head=3.6, r=1.7, $fn=24, slant=false);
    } else {
        translate([0, 0, -2 - long]) screw(head_drop=14 + long, h=30 + long, r_head=4.5, r=2, $fn=24, slant=true);
    }
}

//radius of the idler assembly (to surface that touches belt, ignoring guide walls)
function idler_assy_r_inner(idler_bearing) = (idler_bearing[0] / 2) + (6 * single_wall_width + 0.2) * idler_bearing[3];
//outer radius of the idler assembly (to smooth side of belt) 
function idler_assy_r_outer(idler_bearing) = idler_assy_r_inner(idler_bearing) + belt_thickness + 1;


module idler_assy(idler_bearing = [22, 7, 8, 1]) {

    //bearing axle
    translate([0,0,-1]) cylinder(h = 120, r=(idler_bearing[2] + 1) / 2, $fn=small_hole_segments, center=true);
    //bearing shadow
    %cylinder(h = idler_bearing[1], r=idler_bearing[0]/2, center=true);
    //belt shadow
    %cylinder(h = belt_width, r=idler_assy_r_outer(idler_bearing), center=true);

    cylinder(h = idler_width + 1, r=idler_assy_r_outer(idler_bearing) + 0.5, center=true);
}

module belt(len, side = 0){
    //belt. To be substracted from model
    //len is in +Z, smooth side in +X, Y centered
    translate([-0.5, 0, 0]) maketeeth(len);
    translate([0, -4.5, -0.01]) cube([belt_thickness, 9, len + 0.02]);
    if (side != 0) {
    translate([0, -4.5 + side, -0.01]) cube_fillet([belt_thickness, 9, len + 0.02], vertical = [3, 0, 0, 0]);
    }
}

module maketeeth(len){
    //Belt teeth. 
    for (i = [0 : len / belt_tooth_distance]) {
        translate([0, 0, i * belt_tooth_distance]) cube([2, 9, belt_tooth_distance * belt_tooth_ratio], center = true);
    }
}

module hsi(d_min, depth, d_taper=-1, depth_taper=-1) {
    translate([0, 0, -depth]) cylinder(d=d_min, h=depth);
    if (d_taper > 0 && depth_taper > 0) {
        translate([0, 0, -depth_taper]) cylinder(d1=d_min, d2=d_taper, h=depth_taper);
    } else if (d_taper > 0 || depth_taper > 0) {
        echo("hsi: Ignoring invalid taper parameter.");
    }
}