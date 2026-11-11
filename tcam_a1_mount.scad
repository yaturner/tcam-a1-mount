// tCam-Mini mount for a Bambu Lab A1 (not mini): hangs from the filament-cutter
// trigger at the right end of the gantry, looking left along the gantry and down.
//
// The trigger socket and arm are grizzie17's "Wyze Cam3 Mount for A1 (not Mini)"
// interface part (CC BY-NC-SA 4.0), imported unchanged except that its Wyze rail
// is cut off. Download it yourself and point `interface_stl` at it. Because the
// exported bracket contains that geometry, bracket_a1.stl is CC BY-NC-SA 4.0 too.
//
// Frame = that interface STL's own frame: +X points to the printer's LEFT (along
// the gantry, away from the trigger), +Z up, the socket sits round x -12..2.
//
// The case is the P1S case with a new base (case_base_a1): a lug and pad on one
// long side carry an M3 pivot and the 1.75 mm filament pin, so the case hangs
// long-side-down like the tcam_mini_basic enclosure it replaces. The lid is the
// unchanged P1S case_lid.
//
// Tilt (lens below horizontal) 20..60 deg in 5 deg steps:
//   20/30/40/50/60 -> pin in case hole A (R 18.5)
//   25/35/45/55    -> pin in case hole B (R 15)

part = "assembly";   // assembly | bracket | case_base_a1 | case_lid | bracket_world | case_at
pitch = 40;          // tilt for assembly / case_at
interface_stl = "/media/yaturner/windowsext/STL FIles/wyze-cam3-mount-for-a1-not-mini-model_files/camera-mount-v34-a1-interface.stl";

use <tcam_p1s_mount.scad>   // the P1S project's case: case_base(), case_lid(), board()
$fn = 48;

// ---- case dimensions (must match tcam_p1s_mount.scad) ----
case_len = 51.6; half_e = 20.95; wall = 1.6;
d_back = -9.65; d_front_in = 2.35; d_front = 3.95;
zc = (d_back + d_front_in) / 2;   // pivot / pin height in the case (-3.65)

// ---- side hinge on the case (case-local coords: x along the long axis, y across, z = lens) ----
piv_x   = -4.5;                   // pivot sits in a lug past the case's far end
pad_out = 2.5;                    // pad thickness outside the side wall
face_y  = -half_e - pad_out;      // bearing face (-23.45)
lug     = [-9.5, -12];            // lug: x from -9.5, y from face_y to -12
pin_r_even = 18.5; pin_r_odd = 15;
pin_d_case = 1.95; pin_d_arm = 1.85; pin_depth = 2;
stops = [20, 25, 30, 35, 40, 45, 50, 55, 60];

// ---- placement (interface frame) ----
H  = [1, 0, 0];        // look direction at 0 tilt: to the printer's left
UP = [0, 0, 1];
A  = [0, 1, 0];        // pivot axis; the case extends from the bracket plate along +A
AXLE = [77, -26.55, -6];
arm_w = [0.3, 4.3];    // plate thickness band along -A
function d_dir(t) = cos(t) * H - sin(t) * UP;          // lens
function l_dir(t) = cross(A, d_dir(t));                // case long axis, toward the USB end
function frame4(x, y, z, o) =
    [[x[0], y[0], z[0], o[0]], [x[1], y[1], z[1], o[1]], [x[2], y[2], z[2], o[2]], [0, 0, 0, 1]];
// case-local (x, y, z) -> world, with the pivot point (piv_x, face_y, zc) on AXLE
module place_case(t)
    multmatrix(frame4(l_dir(t), A, d_dir(t), AXLE - piv_x * l_dir(t) - face_y * A - zc * d_dir(t)))
        children();
function pin_uv(t) = let(r = (t % 10 == 0) ? pin_r_even : pin_r_odd) [-r * sin(t), -r * cos(t)];

// ---------------- case base with the side hinge ----------------
module case_base_a1() {
    difference() {
        union() {
            case_base();
            hull() {   // lug past the far end
                translate([lug[0], face_y, d_back + 1]) cube([-lug[0] + 0.5, lug[1] - face_y, d_front_in - d_back - 1]);
                translate([lug[0] + 1, face_y, d_back]) cube([-lug[0] - 0.5, lug[1] - face_y, d_front_in - d_back]);
            }
            translate([lug[0], face_y, d_back]) cube([18 - lug[0], -19.4 - face_y, d_front_in - d_back]);   // side pad
        }
        translate([piv_x, face_y - 1, zc]) rotate([-90, 0, 0]) cylinder(h = 11, d = 2.5);   // M3 self-tap pilot
        for (r = [pin_r_even, pin_r_odd])
            translate([piv_x + r, face_y - 0.01, zc]) rotate([-90, 0, 0]) cylinder(h = pin_depth + 0.01, d = pin_d_case);
    }
}

// ---------------- bracket ----------------
module interface_trimmed() difference() {
    import(interface_stl);
    translate([38, -40, -20]) cube([30, 80, 32.45]);   // Wyze rail (z < 12.45 past x 38)
}
// plate in its own plane: u along H, v up, w along -A (away from the case)
module arm_frame() multmatrix(frame4(H, UP, -A, AXLE)) children();
web_x = [38, 86]; web_z = [4, 25.4];   // 2.2 mm above the case's highest point (z 1.8)
module plate() {
    vt = web_z[1] - AXLE[2];
    arm_frame() difference() {
        translate([0, 0, arm_w[0]]) linear_extrude(arm_w[1] - arm_w[0]) hull() {
            circle(r = 6);
            for (t = stops) translate(pin_uv(t)) circle(r = 2.6);
            translate([web_x[0] - AXLE[0], web_z[0] - AXLE[2]]) square([web_x[1] - web_x[0], vt - (web_z[0] - AXLE[2])]);
            translate([-12, -2]) square([18, 1]);
        }
        translate([0, 0, -1]) cylinder(h = 10, d = 3.3);
        for (t = stops) translate(concat(pin_uv(t), -1)) cylinder(h = 10, d = pin_d_arm);
    }
}
module bracket_world() union() {
    interface_trimmed();
    // web from the interface's top bar out over the plate
    translate([web_x[0], AXLE[1] - arm_w[1], web_z[0]]) cube([web_x[1] - web_x[0], 2 - (AXLE[1] - arm_w[1]), web_z[1] - web_z[0]]);
    plate();
}
// print like grizzie17's part, on its back (the interface's y = 2 face down);
// the plate is then on top and needs supports under it (build plate only)
module bracket() translate([0, 0, 2]) rotate([-90, 0, 0]) bracket_world();

// ---------------- render ----------------
if (part == "case_base_a1")  translate([0, 0, -d_back]) case_base_a1();
if (part == "case_lid")      rotate([180, 0, 0]) translate([0, 0, -d_front]) case_lid();
if (part == "bracket")       bracket();
if (part == "bracket_world") bracket_world();
if (part == "case_at")       place_case(pitch) { case_base_a1(); case_lid(); }
if (part == "assembly") {
    color("orange") bracket_world();
    place_case(pitch) { color("dimgray") case_base_a1(); color("gainsboro", 0.7) case_lid(); }
}
