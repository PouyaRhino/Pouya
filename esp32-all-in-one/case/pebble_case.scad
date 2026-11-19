// "Pebble" desk pet case: big soft head with a black face plate, on a small stand.
// OpenSCAD 2021+. All sizes in mm. Values marked MEASURE are guesses: measure your part,
// change the number, re-export.
//
// Head local axes: X right, Y back (face at y = 0), Z up.  Stand local axes: the same, stand front at y = 0.
// Export one part:  openscad -D 'PART="head"' -o stl/pebble/pebble_head.stl pebble_case.scad
// Parts: head, face, headlid, stand, standlid, post, facetest
// Views: assembly, exploded, cutaway, clash (must be empty)
// World-placed parts for the Blender renders: w_head, w_face, w_headlid, w_stand, w_standlid, w_post, w_glass

PART = "assembly";
$fn = 48;
FN_BIG = 96;            // smoothness of the big outer curves

W   = 2;     // wall
CLR = 0.3;   // fit clearance per side

// ---------------- head ----------------
HW = 78; HD = 58; HH = 62;      // outer size
HR = 16;                         // corner radius seen from the front
HE_F = 3; HE_B = 1.5;           // rounding of the front / back edges
LIP = 1.5;                       // front lip that holds the face plate

// face plate (print in black)
FACE = [66, 51]; FACE_R = 11; FACE_T = 2.4; FACE_Z = 31;
OPEN = [63, 49]; OPEN_R = 9.5;  // opening in the head that shows the face

// display 2.0" ST7789, landscape (MEASURE)
LCD_PCB = [52, 36.5]; LCD_T = 4.2; LCD_WIN = [44, 33]; LCD_Z = 26.5;
// camera OV5640 module (MEASURE)
CAM_Z = 51; CAM_LENS = 8; CAM_BODY = 8.6;
// ESP32-S3 N16R8 CAM board, flat on two rails (MEASURE)
ESP = [65, 28.5]; ESP_X = (HW - 65) / 2; ESP_Y = 12; ESP_SO = 14;
ESP_Z = W + ESP_SO; USB_Z = ESP_Z + 3.2;
// speaker 35 x 25 x 6.5 on the back lid, amp next to it
SPK = [35, 6.5, 25]; SPK_X = 12; SPK_Z = 25;
AMP = [18, 3.5, 18]; AMP_X = 52; AMP_Z = 28;
// top: mic, light sensor, head-pat pad
MIC_X = 22; LUX_X = 56; TOP_Y = 30;

// ---------------- stand ----------------
SW = 72; SD = 54; SH = 22; SR = 10; SE_T = 3; SE_B = 1.5;
BAT = [65, 36, 10]; BAT_X = (SW - 65) / 2; BAT_Y = 8.5;          // LiPo 65 x 36 x 10
IPM = [25, 17]; IPM_X = SW / 2; IPM_Y = SD - W - 17 - 0.4;      // IP5306 module (to buy, MEASURE)
IPM_Z = W + BAT[2] + 0.5;  IPM_USB_Z = IPM_Z + 1.6 + 1.6;
RAD = [22, 16]; RAD_Z = SH - W - 8 - 0.3;                        // LD2410C, slides up to the top
SENS_X = [10, 50];                                               // AHT20 / BMP280 on the front wall

// ---------------- neck ----------------
TILT = 6;                          // head looks up by this many degrees
NECK_OD = 20; NECK_ID = 12; NECK_FIT = 0.4;
NECK_IN = 8;                       // socket depth in the head
GAP = 5.5;                         // head floor centre above the stand top
NB = [SW / 2, SD / 2, SH];         // where the neck axis crosses the stand top
T0 = GAP / cos(TILT);              // axis length from the stand top to the head floor
FLANGE_Z = SH - W - 1.5;

// screw bosses (M2 x 6 self-tapping)
HBOSS = [[7.5, 7.5], [HW - 7.5, 7.5], [7.5, HH - 7.5], [HW - 7.5, HH - 7.5]];   // head x/z
SBOSS = [[5.8, 5.8], [SW - 5.8, 5.8], [5.8, SD - 5.8], [SW - 5.8, SD - 5.8]];   // stand x/y

// ======================================================================
// helpers
module rr2(w, h, r) translate([r, r]) offset(r) square([w - 2 * r, h - 2 * r]);
module inset2(w, h, r, i) translate([i, i]) rr2(w - 2 * i, h - 2 * i, max(r - i, 0.5));
module xz(y0, y1) translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();
module boxc(c, s) translate(c - s / 2) cube(s);
module xcyl(c, d, l) translate(c) rotate([0, 90, 0]) cylinder(d = d, h = l);
module ycyl(c, d, l) translate(c) rotate([-90, 0, 0]) cylinder(d = d, h = l);
module zcyl(c, d, l) translate(c) cylinder(d = d, h = l);

// rounded slab along Y: rounded-rect outline in XZ, rounded front/back edges
module yslab(w, h, r, d, ef, eb, n = 8) hull() for (i = [0 : n]) {
    a = 90 * i / n;
    translate([0, ef * (1 - cos(a)), 0]) xz(0, 0.01) inset2(w, h, r, ef * (1 - sin(a)), $fn = FN_BIG);
    translate([0, d - 0.01 - eb * (1 - cos(a)), 0]) xz(0, 0.01) inset2(w, h, r, eb * (1 - sin(a)), $fn = FN_BIG);
}
// rounded slab along Z: rounded-rect outline in XY, rounded top/bottom edges
module zslab(w, d, r, h, et, eb, n = 8) hull() for (i = [0 : n]) {
    a = 90 * i / n;
    translate([0, 0, eb * (1 - cos(a))]) linear_extrude(0.01) inset2(w, d, r, eb * (1 - sin(a)), $fn = FN_BIG);
    translate([0, 0, h - 0.01 - et * (1 - cos(a))]) linear_extrude(0.01) inset2(w, d, r, et * (1 - sin(a)), $fn = FN_BIG);
}
module face_prof(o = 0) translate([HW / 2 - FACE[0] / 2 - o, FACE_Z - FACE[1] / 2 - o]) rr2(FACE[0] + 2 * o, FACE[1] + 2 * o, FACE_R + o);
module open_prof(o = 0) translate([HW / 2 - OPEN[0] / 2 - o, FACE_Z - OPEN[1] / 2 - o]) rr2(OPEN[0] + 2 * o, OPEN[1] + 2 * o, OPEN_R + o);

// ======================================================================
// HEAD SHELL. Prints face-down, no supports.
module head_outer() yslab(HW, HH, HR, HD, HE_F, HE_B);
module head_cavity() xz(LIP, HD + 1) inset2(HW, HH, HR, W, $fn = FN_BIG);

module head_shell() {
    difference() {
        union() {
            difference() { head_outer(); head_cavity(); }
            intersection() { head_inside(); head_outer(); }
        }
        head_cuts();
    }
}

module head_inside() {
    // pocket ring that locates the face plate behind the lip
    difference() {
        xz(LIP - 0.01, LIP + FACE_T + 1.5) face_prof(CLR + 1.2);
        xz(LIP - 1, LIP + FACE_T + 3) face_prof(CLR);
    }
    // ESP32 rails, starting with a 45 degree slope so they print without support
    for (i = [0, 1]) {
        x0 = i == 0 ? W : ESP_X + ESP[0] - 5;
        w = ESP_X + 5 - W;
        y0 = 10; L = ESP_Y + ESP[1] + 1.4 - y0; h = ESP_SO + 1.4;
        difference() {
            hull() {
                translate([x0, y0, W]) cube([w, L, h]);
                translate([i == 0 ? W : HW - W - 0.01, y0 - w, W]) cube([0.01, L + w, h]);
            }
            translate([ESP_X - CLR, ESP_Y - CLR, ESP_Z]) cube([ESP[0] + 2 * CLR, ESP[1] + 2 * CLR, 5]);
            translate([ESP_X + 3, ESP_Y - 6, ESP_Z - 6]) cube([ESP[0] - 6, ESP[1] + 12, 12]);   // keep wire room clear
        }
    }
    // neck collar in the floor
    zcyl([HW / 2, HD / 2, 0], NECK_OD + NECK_FIT + 5, NECK_IN + 2);
    // back-lid bosses with support cones
    for (b = HBOSS) {
        ycyl([b[0], HD - W - 10, b[1]], 5.5, 10);
        translate([b[0], HD - W - 10, b[1]]) rotate([90, 0, 0]) cylinder(d1 = 5.5, d2 = 1, h = 5);
    }
}

module head_cuts() {
    // face opening with a small outside chamfer
    hull() {
        xz(-0.01, 0.01) open_prof(0.8);
        xz(0.8, LIP + 0.5) open_prof(0);
    }
    // USB-C on the right side
    hull() for (s = [-1, 1]) xcyl([HW - W - 1, ESP_Y + ESP[1] / 2 + s * 3, USB_Z], 6.5, W + 2);
    // top: mic pinhole and light-sensor window
    zcyl([MIC_X, TOP_Y, HH - W - 1], 2, W + 2);
    zcyl([LUX_X, TOP_Y, HH - W - 1], 4, W + 2);
    // neck socket + wire hole
    zcyl([HW / 2, HD / 2, -1], NECK_OD + NECK_FIT, NECK_IN + 1);
    zcyl([HW / 2, HD / 2, -1], NECK_ID + 2, NECK_IN + 6);
    // screw pilot holes
    for (b = HBOSS) ycyl([b[0], HD - W - 9, b[1]], 1.8, 10);
}

// FACE PLATE. Print face-down in black PETG on a smooth bed for a glossy "glass" look.
module face_plate() {
    yb = LIP + FACE_T;   // back of the plate
    difference() {
        union() {
            xz(LIP, yb) face_prof(0);
            // display pocket (open at the bottom for the flex cable)
            difference() {
                boxc([HW / 2, yb + (LCD_T + 0.4) / 2, LCD_Z], [LCD_PCB[0] + 2 * CLR + 2.4, LCD_T + 0.4, LCD_PCB[1] + 2 * CLR + 2.4]);
                boxc([HW / 2, yb + LCD_T / 2, LCD_Z], [LCD_PCB[0] + 2 * CLR, LCD_T + 2, LCD_PCB[1] + 2 * CLR]);
                boxc([HW / 2, yb + LCD_T / 2, LCD_Z - LCD_PCB[1] / 2], [24, LCD_T + 2, 4]);
            }
            // camera pocket
            difference() {
                boxc([HW / 2, yb + 3, CAM_Z], [CAM_BODY + 2 * CLR + 2, 6, CAM_BODY + 2 * CLR + 2]);
                boxc([HW / 2, yb + 4, CAM_Z], [CAM_BODY + 2 * CLR, 8, CAM_BODY + 2 * CLR]);
            }
        }
        // display window with a bevel
        hull() {
            boxc([HW / 2, LIP - 0.5, LCD_Z], [LCD_WIN[0] + 1.6, 1, LCD_WIN[1] + 1.6]);
            boxc([HW / 2, LIP + 0.8 + (FACE_T) / 2, LCD_Z], [LCD_WIN[0], FACE_T, LCD_WIN[1]]);
        }
        // counterbore from the back so the display glass sits close behind the window
        boxc([HW / 2, yb - 0.6, LCD_Z], [LCD_PCB[0] + 2 * CLR, 1.21 + 0.01, LCD_PCB[1] + 2 * CLR]);
        // camera hole with a cone
        ycyl([HW / 2, LIP - 1, CAM_Z], CAM_LENS + 0.4, FACE_T + 2);
        translate([HW / 2, LIP - 0.01, CAM_Z]) rotate([-90, 0, 0]) cylinder(d1 = CAM_LENS + 2.4, d2 = CAM_LENS + 0.4, h = 1);
    }
}

// HEAD BACK LID: speaker grille, speaker pocket, vents
module head_lid() {
    yi = HD - W;   // inner face
    difference() {
        union() {
            xz(yi, HD) offset(-CLR) inset2(HW, HH, HR, W, $fn = FN_BIG);
            // speaker pocket (push fit, a dot of glue)
            difference() {
                translate([SPK_X - CLR - 1.2, yi - 5, SPK_Z - CLR - 1.2]) cube([SPK[0] + 2 * CLR + 2.4, 5.01, SPK[2] + 2 * CLR + 2.4]);
                translate([SPK_X - CLR, yi - 6, SPK_Z - CLR]) cube([SPK[0] + 2 * CLR, 7, SPK[2] + 2 * CLR]);
                for (s = [0, 1]) translate([SPK_X + SPK[0] / 2 - 5, yi - 6, SPK_Z - 3 + s * (SPK[2] + 3)]) cube([10, 7, 3]);   // wire gaps
            }
        }
        // speaker grille: round holes on a hex grid
        for (i = [-4 : 4], j = [-4 : 4]) {
            x = SPK_X + SPK[0] / 2 + i * 3.2 + (j % 2 == 0 ? 0 : 1.6);
            z = SPK_Z + SPK[2] / 2 + j * 2.8;
            if (pow(x - SPK_X - SPK[0] / 2, 2) / pow(14, 2) + pow(z - SPK_Z - SPK[2] / 2, 2) / pow(10.5, 2) <= 1)
                ycyl([x, yi - 1, z], 1.6, W + 2);
        }
        // warm-air vents above the amp
        for (k = [0 : 2]) boxc([AMP_X + AMP[0] / 2, HD - W / 2, 50 + k * 3], [16, W + 2, 1.5]);
        for (b = HBOSS) ycyl([b[0], yi - 1, b[1]], 2.4, W + 2);
    }
}

// ======================================================================
// STAND. Prints top-down (flat top on the bed), open at the bottom, no supports.
module stand_outer() zslab(SW, SD, SR, SH, SE_T, SE_B);
module stand_shell() {
    difference() {
        union() {
            difference() {
                stand_outer();
                translate([0, 0, -1]) linear_extrude(SH - W + 1) inset2(SW, SD, SR, W, $fn = FN_BIG);
            }
            intersection() { stand_inside(); stand_outer(); }
        }
        stand_cuts();
    }
}

module stand_inside() {
    // radar rails on the front wall (radar slides in from the bottom up to the top)
    difference() {
        for (s = [-1, 1]) boxc([SW / 2 + s * (RAD[0] / 2 + 1), W + 2, (RAD_Z - RAD[1] / 2 - 1 + SH - W) / 2], [3, 4, SH - W - (RAD_Z - RAD[1] / 2 - 1)]);
        boxc([SW / 2, W + 0.8 + CLR / 2, RAD_Z], [RAD[0] + 2 * CLR, 1.6 + CLR, RAD[1] + 10]);
    }
    // lid bosses (full height columns)
    for (b = SBOSS) zcyl([b[0], b[1], W], 5, SH - W);
}

module stand_cuts() {
    // chest window: front wall thinned to 1 mm behind the radar
    boxc([SW / 2, W - 0.5 + 0.01, RAD_Z], [RAD[0] + 4, 1, RAD[1] + 2]);
    // neck hole
    zcyl([NB[0], NB[1], SH - W - 1], NECK_OD + 1, W + 2);
    // back: charger USB-C, LED slot, power button
    hull() for (s = [-1, 1]) ycyl([IPM_X + s * 3, SD - W - 1, IPM_USB_Z], 6.5, W + 2);
    boxc([IPM_X + 11, SD - W / 2, IPM_USB_Z], [5, W + 2, 2]);
    ycyl([SW - 12, SD - W - 1, 9], 6.5, W + 2);
    // screw pilot holes
    for (b = SBOSS) zcyl([b[0], b[1], -1], 1.8, 9);
}

// STAND BOTTOM LID: battery cradle, charger support, sensor vents, feet
module stand_lid() {
    difference() {
        union() {
            linear_extrude(W) offset(-CLR) inset2(SW, SD, SR, W, $fn = FN_BIG);
            // battery end stops and back stops
            for (x = [BAT_X - 0.9 - CLR, BAT_X + BAT[0] + CLR]) translate([x, 15, W]) cube([0.9, 22, 6]);
            for (x = [14, SW - 28]) translate([x, BAT_Y + BAT[1] + CLR, W]) cube([14, 1.5, BAT[2] + 0.5]);
            // block under the back of the charger
            translate([IPM_X - 5, BAT_Y + BAT[1] + 2, W]) cube([10, IPM_Y + IPM[1] - BAT_Y - BAT[1] - 2.5, IPM_Z - W]);
        }
        // vents under the temp/pressure sensors
        for (x = SENS_X) for (k = [0 : 2]) boxc([x + 6, 3 + k * 2.2, W / 2], [10, 1.2, W + 2]);
        // rubber feet recesses
        for (x = [11, SW - 11], y = [11, SD - 11]) zcyl([x, y, -1], 8.4, 1.8);
        for (b = SBOSS) zcyl([b[0], b[1], -1], 2.4, W + 2);
    }
}

// NECK POST: flange glued under the stand top, tube tilted back by TILT
module post_local() {    // in stand coordinates
    difference() {
        union() {
            zcyl([NB[0], NB[1], FLANGE_Z], 26, 1.5);
            intersection() {
                translate(NB) rotate([-TILT, 0, 0]) translate([0, 0, -6]) cylinder(d = NECK_OD, h = 6 + T0 + NECK_IN - 0.5);
                translate([0, 0, FLANGE_Z]) cube([SW, SD, 100]);
            }
        }
        translate(NB) rotate([-TILT, 0, 0]) translate([0, 0, -20]) cylinder(d = NECK_ID, h = 60);
    }
}

// head placement on the stand
module head_place() translate(NB + [0, T0 * sin(TILT), T0 * cos(TILT)]) rotate([-TILT, 0, 0]) translate([-HW / 2, -HD / 2, 0]) children();

// ======================================================================
// dummy parts for renders and the clash check
module head_parts() {
    color("#111") translate([HW / 2 - LCD_PCB[0] / 2, LIP + FACE_T - 1.2, LCD_Z - LCD_PCB[1] / 2]) cube([LCD_PCB[0], LCD_T, LCD_PCB[1]]);
    color("#333") boxc([HW / 2, LIP + FACE_T + 2.5, CAM_Z], [CAM_BODY, 5, CAM_BODY]);
    color("#2b8a6e") translate([ESP_X, ESP_Y, ESP_Z]) cube([ESP[0], ESP[1], 1.6]);
    color("#c0c0c0") translate([ESP_X + 10, ESP_Y + 1.5, ESP_Z + 1.6]) cube([18, 25.5, 3.2]);
    color("#999") translate([HW - W - 7.5, ESP_Y + ESP[1] / 2 - 4.5, ESP_Z + 1.6]) cube([7.5, 9, 3.2]);
    color("#222") translate([SPK_X, HD - W - SPK[1], SPK_Z]) cube(SPK);
    color("#6a3") translate([AMP_X, HD - W - AMP[1], AMP_Z]) cube(AMP);
    color("#3355cc") boxc([MIC_X, TOP_Y, HH - W - 1.05], [14, 14, 1.8]);
    color("#3355cc") boxc([LUX_X, TOP_Y, HH - W - 1.05], [14, 18.5, 1.8]);
    color("#d33") boxc([HW / 2, TOP_Y, HH - W - 1.05], [15, 11, 1.8]);
}
module stand_parts() {
    color("#7aa0c8") translate([BAT_X, BAT_Y, W]) cube(BAT);
    color("#2255aa") translate([IPM_X - IPM[0] / 2, IPM_Y, IPM_Z]) cube([IPM[0], IPM[1], 1.6]);
    color("#aaa") translate([IPM_X - 4.5, IPM_Y + IPM[1] - 6.5, IPM_Z + 1.6]) cube([9, 7.5, 3.2]);
    color("#3a8a3a") translate([SW / 2 - RAD[0] / 2, W, RAD_Z - RAD[1] / 2]) cube([RAD[0], 1.6, RAD[1]]);
    for (x = SENS_X) color("#8844aa") translate([x, W, 6]) cube([12, 1.6, 12]);
}

SHELL = "#e9e3d8"; DARK = "#2a2a2c"; FACEC = "#0b0b0d";

module assembly(e = 0, cut = false) {
    module cutter() if (cut) translate([-50, -50, -50]) cube([50 + (cut ? 36 : 0), 300, 300]);
    difference() { union() {
        color(DARK) stand_shell();
        color(DARK) translate([0, 0, -e]) stand_lid();
        color("#555") translate([0, 0, e * 0.6]) post_local();
        translate([0, 0, e * 1.3]) head_place() {
            color(SHELL) head_shell();
            color(FACEC) translate([0, -e * 0.8, 0]) face_plate();
            color(SHELL) translate([0, e * 0.8, 0]) head_lid();
        }
    } cutter(); }
    if (e == 0) { stand_parts(); head_place() head_parts(); }
}

CI = -1;   // clash pair to show, -1 = all
module clash() {
    module c(i) if (CI == -1 || CI == i) children();
    c(0) intersection() { stand_shell(); stand_parts(); }
    c(1) intersection() { stand_lid(); stand_parts(); }
    c(2) intersection() { stand_shell(); stand_lid(); }
    c(3) intersection() { post_local(); stand_parts(); }
    c(4) intersection() { head_shell(); head_parts(); }
    c(5) intersection() { head_lid(); head_parts(); }
    c(6) intersection() { face_plate(); head_parts(); }
    c(7) intersection() { face_plate(); head_shell(); }
    c(8) intersection() { head_lid(); head_shell(); }
    c(9) intersection() { head_place() head_shell(); stand_shell(); }
    c(10) intersection() { head_place() head_shell(); post_local(); }
    c(11) intersection() { post_local(); stand_shell(); }
}

// ======================================================================
if (PART == "head")           rotate([90, 0, 0]) head_shell();                       // face on the bed
else if (PART == "face")      rotate([90, 0, 0]) translate([0, -LIP, 0]) face_plate(); // front on the bed
else if (PART == "headlid")   translate([0, 0, HD]) rotate([-90, 0, 0]) head_lid();   // outside on the bed
else if (PART == "stand")     translate([0, SD, SH]) rotate([180, 0, 0]) stand_shell();     // top on the bed
else if (PART == "standlid")  stand_lid();
else if (PART == "post")      translate([0, 0, -FLANGE_Z]) post_local();
else if (PART == "facetest")  rotate([90, 0, 0]) intersection() { head_shell(); translate([-1, -1, -1]) cube([HW + 2, 7, HH + 2]); }
else if (PART == "assembly")  assembly();
else if (PART == "exploded")  assembly(18);
else if (PART == "cutaway")   assembly(0, true);
else if (PART == "clash")     clash();
else if (PART == "w_head")    head_place() head_shell();
else if (PART == "w_face")    head_place() face_plate();
else if (PART == "w_headlid") head_place() head_lid();
else if (PART == "w_glass")   head_place() translate([HW / 2 - LCD_PCB[0] / 2, LIP + FACE_T - 1.2, LCD_Z - LCD_PCB[1] / 2]) cube([LCD_PCB[0], 0.6, LCD_PCB[1]]);
else if (PART == "w_stand")   stand_shell();
else if (PART == "w_standlid") stand_lid();
else if (PART == "w_post")    post_local();
