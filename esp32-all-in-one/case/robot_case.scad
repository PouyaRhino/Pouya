// Robot desk pet case: head + body, separate arms and antenna. OpenSCAD 2021+.
// World axes: X right, Y back (the face is at y = 0), Z up. All sizes in mm.
// Values marked MEASURE are guesses: measure your part, change the number, re-export.
//
// Export one part:  openscad -D 'PART="head"' -o stl/robot_head.stl robot_case.scad
// Parts: head, headlid, body, bodylid, arm (print 2), antenna, facetest
// Views: assembly, hero, exploded, cutaway, clash (must be empty)

PART = "assembly";
$fn = 48;

W   = 2;     // wall
CLR = 0.3;   // fit clearance per side

// ---------- head: ESP32 board, display, camera, speaker, mic, light, head-pat ----------
HW = 72; HD = 50; HH = 60; HR = 12;     // outer size, corner radius (front view)

// ---------- body: battery, charger, radar, temp/pressure ----------
BW = 78; BD = 50; BH = 48; BR = 8;

// ---------- neck: tube on the body lid, socket in the head floor ----------
NECK_OD  = 20;  NECK_ID = 12;   // 8 wires pass through the bore
NECK_GAP = 6;                   // visible neck between body and head
NECK_IN  = 6;                   // how far the tube goes into the head
NECK_FIT = 0.4;                 // socket = OD + this. Smaller = stiffer head turn
HX = (BW - HW) / 2;  HZ = BH + NECK_GAP;   // head position on the body

// ---------- display: 2.0" ST7789 landscape (MEASURE all) ----------
LCD_PCB = [52, 36.5];  LCD_T = 4.2;        // board w x h, thickness incl. glass
LCD_WIN = [44, 33];                         // visible glass area
LCD_Z   = 25;                               // display centre height in head

// ---------- camera: OV5640 module on its flex (MEASURE) ----------
CAM_Z = 51;  CAM_LENS = 8;  CAM_BODY = 8.6;

// ---------- ESP32-S3 N16R8 CAM board, lies flat behind the display (MEASURE) ----------
ESP = [65, 28.5];  ESP_X = (HW - 65) / 2;  ESP_Y = 12;
ESP_SO = 14;                                 // seat height above the floor (wires run under it)
ESP_Z  = W + ESP_SO;                         // underside of the board
USB_Z  = ESP_Z + 1.6 + 1.6;                  // USB-C centre, port on the right end

// ---------- speaker 35 x 25 x 6.5 on the left wall ----------
SPK = [6.5, 35, 25];  SPK_Y = HD - W - 35 - CLR;  SPK_Z = 22;   // back lid holds it in

// ---------- battery 65 x 36 x 10 LiPo flat on the body floor ----------
BAT = [65, 36, 10];  BAT_X = (BW - 65) / 2;  BAT_Y = 3;

// ---------- IP5306 Type-C charger/boost module (to buy, MEASURE) ----------
IPM = [25, 17];  IPM_X = BW / 2;  IPM_Z = W + BAT[2] + 2;   // on 2 mm foam tape on the battery
IPM_USB_Z = IPM_Z + 1.6 + 1.6;

// ---------- radar HLK-LD2410C behind the chest panel ----------
RAD = [22, 16];  RAD_Z = 32;

// ---------- screw bosses (M2 x 6 self-tapping) ----------
HBOSS = [[6, 6], [HW - 6, 6], [6, HH - 6], [HW - 6, HH - 6]];          // head, x/z
BBOSS = [[5, 5], [BW - 5, 5], [5, BD - 5], [BW - 5, BD - 5]];          // body, x/y

ARM_Y = 30;  ARM_Z = 34;          // arm socket on the body sides
ANT_Y = 40;                        // antenna hole on top of the head

// ======================================================================
// helpers
module rr2(w, h, r) translate([r, r]) offset(r) square([w - 2 * r, h - 2 * r]);
module xz(y0, y1) translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();
module boxc(c, s) translate(c - s / 2) cube(s);
module xcyl(c, d, l) translate(c) rotate([0, 90, 0]) cylinder(d = d, h = l);
module ycyl(c, d, l) translate(c) rotate([-90, 0, 0]) cylinder(d = d, h = l);
module zcyl(c, d, l) translate(c) cylinder(d = d, h = l);
module xslot(c, len, d) hull() for (s = [-1, 1]) xcyl(c + [0, s * (len - d) / 2, 0], d, W + 2);

// ======================================================================
// HEAD (local coords: x 0..HW, y 0..HD, z 0..HH). Prints face-down, no supports.
module head_shell() {
    difference() {
        union() {
            difference() {
                xz(0, HD) rr2(HW, HH, HR);
                xz(W, HD + 1) translate([W, W]) rr2(HW - 2 * W, HH - 2 * W, HR - W);
            }
            intersection() { head_inside(); xz(0, HD) rr2(HW, HH, HR); }
        }
        head_cuts();
    }
}

module head_inside() {
    // display pocket frame (open at the bottom for the flex cable)
    p = LCD_PCB + [2 * CLR, 2 * CLR];
    difference() {
        boxc([HW / 2, W + (LCD_T + 0.5) / 2, LCD_Z], [p[0] + 3, LCD_T + 0.5, p[1] + 3]);
        boxc([HW / 2, W + LCD_T / 2, LCD_Z], [p[0], LCD_T + 2, p[1]]);
        boxc([HW / 2, W + LCD_T / 2, LCD_Z - p[1] / 2], [22, LCD_T + 2, 4]);
    }
    // camera holder
    difference() {
        boxc([HW / 2, W + 3.5, CAM_Z], [12.6, 7, 12]);
        boxc([HW / 2, W + 4.5, CAM_Z], [CAM_BODY + 2 * CLR, 7, CAM_BODY + 2 * CLR]);
    }
    // speaker front stop and ledge on the left wall
    translate([W, W, SPK_Z - 1.5]) cube([5, SPK_Y - CLR - W, SPK[2] + 1.5]);                 // front stop
    translate([W, SPK_Y, SPK_Z - 1.5]) cube([4, SPK[1], 1.5]);
    // ESP32 board: two side rails from the face wall back, with lips that locate the board
    for (i = [0, 1]) {
        x0 = ESP_X + i * ESP[0];
        difference() {
            translate([x0 - (i == 1 ? 5 : 1.4), W, W]) cube([6.4, ESP_Y + ESP[1] + 1.4 - W, ESP_SO + 1.4]);
            translate([ESP_X - CLR, ESP_Y - CLR, ESP_Z]) cube([ESP[0] + 2 * CLR, ESP[1] + 2 * CLR, 5]);
        }
    }
    // neck collar in the floor
    zcyl([HW / 2, HD / 2, 0], NECK_OD + NECK_FIT + 5, NECK_IN + 3);
    // antenna socket tube under the top wall
    zcyl([HW / 2, ANT_Y, HH - W - 7], 10, 7);
    // back-lid bosses, with a cone under each so they print without support
    for (b = HBOSS) {
        ycyl([b[0], HD - W - 10, b[1]], 6, 10);
        translate([b[0], HD - W - 10, b[1]]) rotate([90, 0, 0]) cylinder(d1 = 6, d2 = 1, h = 6);
    }
}

module head_cuts() {
    // display window with a bevel
    hull() {
        boxc([HW / 2, -0.5, LCD_Z], [LCD_WIN[0] + 2, 1, LCD_WIN[1] + 2]);
        boxc([HW / 2, (0.8 + W + 1) / 2, LCD_Z], [LCD_WIN[0], W + 1 - 0.8, LCD_WIN[1]]);
    }
    // camera lens hole with a cone
    ycyl([HW / 2, -1, CAM_Z], CAM_LENS + 0.4, W + 2);
    translate([HW / 2, -0.01, CAM_Z]) rotate([-90, 0, 0]) cylinder(d1 = CAM_LENS + 3, d2 = CAM_LENS + 0.4, h = 1);
    // speaker grille, left side
    for (k = [0 : 4]) boxc([W / 2, SPK_Y + SPK[1] / 2, SPK_Z + 4 + k * 4.25], [W + 2, SPK[1] - 8, 2]);
    // USB-C, right side
    hull() for (s = [-1, 1]) xcyl([HW - W - 1, ESP_Y + ESP[1] / 2 + s * 3, USB_Z], 6.5, W + 2);
    // top: mic hole, light-sensor window, antenna hole
    zcyl([18, HD / 2, HH - W - 1], 2.5, W + 2);
    zcyl([HW - 18, HD / 2, HH - W - 1], 6, W + 2);
    zcyl([HW / 2, ANT_Y, HH - W - 8], 6, W + 10);
    // neck socket and wire hole
    zcyl([HW / 2, HD / 2, -1], NECK_OD + NECK_FIT, NECK_IN + 1);
    zcyl([HW / 2, HD / 2, -1], NECK_ID + 2, NECK_IN + 6);
    // screw holes in the bosses
    for (b = HBOSS) ycyl([b[0], HD - W - 9, b[1]], 1.8, 10);
}

module head_lid() {
    difference() {
        xz(HD - W, HD) offset(-CLR) translate([W, W]) rr2(HW - 2 * W, HH - 2 * W, HR - W);
        for (b = HBOSS) ycyl([b[0], HD - W - 1, b[1]], 2.4, W + 2);
        // vents
        for (k = [0 : 5]) boxc([HW / 2, HD - W / 2, 16 + k * 5], [30, W + 2, 2]);
    }
}

// ======================================================================
// BODY (local = world). Prints floor-down, no supports.
module body_shell() {
    difference() {
        union() {
            difference() {
                linear_extrude(BH) rr2(BW, BD, BR);
                translate([W, W, W]) linear_extrude(BH) rr2(BW - 2 * W, BD - 2 * W, BR - W);
            }
            intersection() { body_inside(); linear_extrude(BH) rr2(BW, BD, BR); }
        }
        body_cuts();
    }
}

module body_inside() {
    // battery end stops and back stops
    for (x = [BAT_X - 1.5 - CLR, BAT_X + BAT[0] + CLR]) translate([x, 10, W]) cube([1.5, 20, 6]);
    for (x = [15, BW - 30]) translate([x, BAT_Y + BAT[1] + CLR, W]) cube([15, 1.5, BAT[2] + 2]);
    // ledge under the back of the charger module
    translate([IPM_X - 7, BD - W - 4, W]) cube([14, 4, IPM_Z - W]);
    // radar slide-in rails (radar drops in from the top until it hits the stop)
    difference() {
        union() {
            for (s = [-1, 1]) boxc([BW / 2 + s * (RAD[0] / 2 + 0.5), W + 2, RAD_Z], [3, 4, RAD[1] + 4]);
            boxc([BW / 2, W + 1.5, RAD_Z - RAD[1] / 2 - 1], [RAD[0] - 4, 3, 2]);
        }
        boxc([BW / 2, W + 0.8 + CLR / 2, RAD_Z + 2], [RAD[0] + 2 * CLR, 1.6 + CLR, RAD[1] + 4]);
    }
    // lid bosses with support cones
    for (b = BBOSS) {
        zcyl([b[0], b[1], BH - W - 10], 6, 10);
        translate([b[0], b[1], BH - W - 16]) cylinder(d1 = 1, d2 = 6, h = 6);
    }
}

module body_cuts() {
    // chest panel: 1 mm thin window for the radar
    translate([0, -1, 0]) xz(0, 2) translate([BW / 2 - 15, RAD_Z - 12]) rr2(30, 24, 4);
    // back: charger USB-C, LED light slot, power button
    hull() for (s = [-1, 1]) ycyl([IPM_X + s * 3, BD - W - 1, IPM_USB_Z], 6.5, W + 2);
    boxc([IPM_X, BD - W / 2, IPM_USB_Z + 6], [8, W + 2, 2.5]);
    ycyl([BW - 14, BD - W - 1, 32], 7, W + 2);
    // side vents for the temp/pressure sensors
    for (x = [-1, BW - W - 1], k = [0 : 3]) boxc([x + W / 2 + 1, 10 + k * 3.5, 31], [W + 2, 2, 18]);
    // arm sockets
    for (x = [-1, BW - W - 1]) xcyl([x, ARM_Y, ARM_Z], 6, W + 2);
    // rubber foot recesses
    for (x = [9, BW - 9], y = [9, BD - 9]) zcyl([x, y, -1], 8.4, 1.8);
    // lid screw holes
    for (b = BBOSS) zcyl([b[0], b[1], BH - W - 9], 1.8, 10);
}

module body_lid() {
    difference() {
        union() {
            translate([0, 0, BH - W]) linear_extrude(W) offset(-CLR) translate([W, W]) rr2(BW - 2 * W, BD - 2 * W, BR - W);
            zcyl([BW / 2, BD / 2, BH - W], NECK_OD, W + NECK_GAP + NECK_IN - 0.5);
            zcyl([BW / 2, BD / 2, BH], NECK_OD + 6, 1);
        }
        zcyl([BW / 2, BD / 2, BH - W - 1], NECK_ID, 30);
        for (b = BBOSS) zcyl([b[0], b[1], BH - W - 1], 2.4, W + 2);
    }
}

// ======================================================================
// ARM and ANTENNA (local coords = print orientation)
module arm_local() {
    linear_extrude(7) hull() { circle(d = 14); translate([0, -24]) circle(d = 10); }
    translate([0, 0, 7]) cylinder(d = 5.7, h = 3.5);
    translate([0, 0, 10.5]) cylinder(d1 = 5.7, d2 = 4.7, h = 0.5);
}
module antenna_local() {
    cylinder(d = 5.7, h = 16);
    translate([0, 0, 8]) cylinder(d = 9, h = 1.2);
    translate([0, 0, 19]) sphere(d = 10);
}

// placed in the world
module arm_right() translate([BW + 7, ARM_Y, ARM_Z]) multmatrix([[0, 0, -1, 0], [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]]) arm_local();
module arm_left()  translate([BW, 0, 0]) mirror([1, 0, 0]) arm_right();
module antenna_placed() translate([HX + HW / 2, ANT_Y, HZ + HH - 8]) antenna_local();

// ======================================================================
// dummy parts for renders and the clash check
module head_parts(eyes = true) {
    color("#151515") translate([HW / 2 - LCD_PCB[0] / 2, W, LCD_Z - LCD_PCB[1] / 2]) cube([LCD_PCB[0], LCD_T, LCD_PCB[1]]);
    if (eyes) color("#39e6ff") for (s = [-1, 1])
        translate([HW / 2 + s * 11, W - 0.05, LCD_Z + 1]) rotate([90, 0, 0]) linear_extrude(0.1) offset(3) square([6, 10], center = true);
    color("#333") boxc([HW / 2, W + 4.5, CAM_Z], [CAM_BODY, 5, CAM_BODY]);
    color("#2b8a6e") translate([ESP_X, ESP_Y, ESP_Z]) cube([ESP[0], ESP[1], 1.6]);
    color("#c0c0c0") translate([ESP_X + 10, ESP_Y + 1.5, ESP_Z + 1.6]) cube([18, 25.5, 3.2]);
    color("#999") translate([HW - W - 7.5, ESP_Y + ESP[1] / 2 - 4.5, ESP_Z + 1.6]) cube([7.5, 9, 3.2]);
    color("#222") translate([W, SPK_Y, SPK_Z]) cube(SPK);
    color("#3355cc") boxc([18, HD / 2, HH - W - 1.05], [14, 14, 1.8]);           // INMP441 mic
    color("#3355cc") boxc([HW - 18, HD / 2, HH - W - 1.05], [14, 18.5, 1.8]);    // BH1750
    color("#d33") boxc([HW / 2, 24, HH - W - 1.05], [15, 11, 1.8]);              // TTP223 pad
    color("#6a3") translate([HW - W - 20, HD - W - CLR - 3.2, 24]) cube([18, 3, 18]);   // MAX98357A on the back lid
}

module body_parts() {
    color("#7aa0c8") translate([BAT_X, BAT_Y, W]) cube(BAT);
    color("#2255aa") translate([IPM_X - IPM[0] / 2, BD - W - IPM[1], IPM_Z]) cube([IPM[0], IPM[1], 1.6]);
    color("#aaa") translate([IPM_X - 4.5, BD - W - 7.5, IPM_Z + 1.6]) cube([9, 7.5, 3.2]);
    color("#3a8a3a") translate([BW / 2 - RAD[0] / 2, W, RAD_Z - RAD[1] / 2]) cube([RAD[0], 1.6, RAD[1]]);
    color("#8844aa") translate([BW - W - 2, 9, 24]) cube([1.6, 12, 12]);    // AHT20 at right vents
    color("#8844aa") translate([W + 0.4, 9, 24]) cube([1.6, 12, 12]);       // BMP280 at left vents
}

SHELL = "#efece6";  ACCENT = "#ff8a3d";

module assembly(e = 0, cut = false) {
    // e = explode distance
    module cutter() if (cut) translate([BW / 2, -50, -50]) cube([200, 200, 300]);
    difference() { color(SHELL) body_shell(); cutter(); }
    difference() { color(ACCENT) translate([0, 0, e * 0.8]) body_lid(); cutter(); }
    body_parts();
    translate([HX, 0, HZ + e * 1.8]) {
        difference() { color(SHELL) head_shell(); if (cut) translate([HW / 2 - HX + HX, -50, -50]) cube([200, 200, 300]); }
        difference() { color(ACCENT) translate([0, e, 0]) head_lid(); if (cut) translate([HW / 2, -50, -50]) cube([200, 200, 300]); }
        head_parts();
    }
    if (!cut) {
        color(ACCENT) translate([0, 0, e * 2.8]) antenna_placed();
        color(ACCENT) translate([e * 0.6, 0, 0]) arm_right();
        color(ACCENT) translate([-e * 0.6, 0, 0]) arm_left();
    }
}

// shells against parts: render to STL, the result must be empty
module clash() {
    intersection() { body_shell(); body_parts(); }
    intersection() { body_lid(); body_parts(); }
    translate([HX, 0, HZ]) {
        intersection() { head_shell(); head_parts(false); }
        intersection() { head_lid(); head_parts(false); }
    }
    intersection() { translate([HX, 0, HZ]) head_shell(); body_lid(); }
}

// ======================================================================
if (PART == "head")          rotate([90, 0, 0]) head_shell();          // face on the bed
else if (PART == "headlid")  translate([0, 0, HD]) rotate([-90, 0, 0]) head_lid();
else if (PART == "body")     body_shell();
else if (PART == "bodylid")  translate([0, 0, -(BH - W)]) body_lid();
else if (PART == "arm")      arm_local();
else if (PART == "antenna")  antenna_local();
else if (PART == "facetest") rotate([90, 0, 0]) intersection() { head_shell(); translate([-1, -1, -1]) cube([HW + 2, 9, HH + 2]); }
else if (PART == "assembly" || PART == "hero") assembly();
else if (PART == "exploded") assembly(22);
else if (PART == "cutaway")  assembly(0, true);
else if (PART == "clash")    clash();
