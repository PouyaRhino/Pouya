// "Pebble" desk pet case: big soft head with a black face plate, on a small stand.
// OpenSCAD 2021+. All sizes in mm. Values marked MEASURE are guesses: measure your part,
// change the number, re-export.
//
// Head local axes: X right, Y back (face at y = 0), Z up.  Stand local axes: the same, stand front at y = 0.
// Export one part:  openscad -D 'PART="head"' -o stl/pebble/pebble_head.stl pebble_case.scad
// Parts: head, face, headlid, stand, standlid, post, facetest, snaptest
// Everything snaps together: no glue, no screws.
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

// ---------------- snap fits: no glue, no screws (PETG, 0.4 mm nozzle) ----------------
// Lids: one flexing beam per edge. The beam is printed flat, so it bends along the layers (strong).
// A bump on the beam clicks into a groove inside the shell wall.
LID_CLR = 0.2;                                 // gap around a lid
BEAM_T = 1.2; BEAM_SLOT = 1.0; BEAM_H = 5;     // beam thickness, slot behind it, height from the outside face
BUMP = LID_CLR + 0.7;                          // bump = gap + 0.7 mm grip
// Face plate: 4 arms on its back hook behind 4 catches inside the head
ARM_L = 10; ARM_T = 1.0; ARM_W = 7; HOOK = 1.0; ARM_X = [22, 56];
// Neck: twist lock. Push the post up 45 degrees turned, turn it until it clicks.
EAR_R = 18; EAR_W = 7; TWIST = 45;
// Head on neck: 4-finger collet with a bead that clicks into a groove in the socket
COLLET_L = 9; BEAD = 0.3;
// Crush ribs hold the display, camera and speaker without glue (interference per side)
CRUSH = 0.15;
// lid stops (the old screw bosses, now without holes)
HBOSS = [[7.5, 7.5], [HW - 7.5, 7.5], [7.5, HH - 7.5], [HW - 7.5, HH - 7.5]];   // head x/z
SBOSS = [[5.8, 5.8], [SW - 5.8, 5.8], [5.8, SD - 5.8], [SW - 5.8, SD - 5.8]];   // stand x/y
// boards under the head top: [x centre, width, depth]  (MEASURE)
TOPB = [[MIC_X, 14, 14], [HW / 2, 15, 11], [LUX_X, 14, 18.5]]; TOPB_T = 1.6;

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
// snap-fit building blocks
// edge frame: local a = along the edge, b = outward (0 at the lid edge), c = inward from the outside face
module frame(e) multmatrix([[e[1][0], e[2][0], e[3][0], e[0][0]], [e[1][1], e[2][1], e[3][1], e[0][1]],
                            [e[1][2], e[2][2], e[3][2], e[0][2]], [0, 0, 0, 1]]) children();
module beam(L) {
    translate([-L / 2, -BEAM_T, 0]) cube([L, BEAM_T, BEAM_H]);
    // bump: gentle lead-in on the inner side, steeper hold side (can still be pried off)
    translate([-(L - 8) / 2, 0, 0]) rotate([90, 0, 90]) linear_extrude(L - 8)
        polygon([[-0.3, BEAM_H], [0, BEAM_H], [BUMP, 4.0], [BUMP, 3.0], [0, 2.4], [-0.3, 2.4]]);
}
module beam_slot(L) translate([-L / 2, -BEAM_T - BEAM_SLOT, -1]) cube([L, BEAM_SLOT, W + 2]);
module groove(L) translate([-(L - 7) / 2, -0.1, 2.2]) cube([L - 7, BUMP + 0.25, 3.0]);

E = W + LID_CLR;
// [origin, a, b, c, length]
LIDH = [[[HW / 2, HD, HH - E], [1, 0, 0], [0, 0, 1], [0, -1, 0], 28],     // head back lid: top
        [[HW / 2, HD, E], [1, 0, 0], [0, 0, -1], [0, -1, 0], 28],          // bottom
        [[E, HD, HH / 2], [0, 0, 1], [-1, 0, 0], [0, -1, 0], 26],          // left
        [[HW - E, HD, HH / 2], [0, 0, 1], [1, 0, 0], [0, -1, 0], 26]];     // right
LIDS = [[[E, SD / 2, 0], [0, 1, 0], [-1, 0, 0], [0, 0, 1], 26],          // stand bottom lid: left
        [[SW - E, SD / 2, 0], [0, 1, 0], [1, 0, 0], [0, 0, 1], 26],       // right
        [[SW / 2, SD - E, 0], [1, 0, 0], [0, 1, 0], [0, 0, 1], 26]];      // back (front uses 2 fixed tabs)

module rib_y(x, z, y0, l, k = CRUSH) ycyl([x, y0, z], 1.2, l);   // crush rib along y

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

YC = LIP + FACE_T + ARM_L + 0.15;   // front face of the face-plate catches
module face_catch(x, top) {
    zt = top ? FACE_Z + FACE[1] / 2 + 0.3 : FACE_Z - FACE[1] / 2 - 0.3;   // tip, just outside the plate edge
    zw = top ? HH - W : W;                                                  // inner wall surface
    d = abs(zw - zt);
    x0 = x - ARM_W / 2 - 0.5;
    translate([x0, YC, top ? zt : 0]) cube([ARM_W + 1, 2.5, top ? HH - zt : zt]);
    hull() {   // 45 degree underside so it prints without support
        translate([x0, YC, top ? zt + 1.2 : 0]) cube([ARM_W + 1, 2.5, top ? HH - zt - 1.2 : zt - 1.2]);
        translate([x0, YC - (d - 1.3), top ? zw - 0.1 : 0]) cube([ARM_W + 1, 2.5 + d - 1.3, top ? W + 0.1 : W + 0.1]);
    }
}

module head_inside() {
    // pocket ring that locates the face plate behind the lip
    difference() {
        xz(LIP - 0.01, LIP + FACE_T + 1.5) face_prof(CLR + 1.2);
        xz(LIP - 1, LIP + FACE_T + 3) face_prof(CLR);
    }
    // 4 catches for the face-plate arms
    for (x = ARM_X, t = [true, false]) face_catch(x, t);
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
            if (i == 0) translate([3.5, 21, 8]) cube([ESP_X - 0.1 - 3.5, 30, 20]);                 // room for the clip arm
        }
    }
    // left: long flexing clip arm (bends 1.2 mm at 0.6 % strain), hook over the board edge
    translate([4.5, 19, 8]) cube([1.5, 42 - 19, ESP_Z + 3.6 - 8]);
    translate([6, 34, 0]) rotate([90, 0, 0]) translate([0, 0, -8]) linear_extrude(8)
        polygon([[-0.01, ESP_Z + 1.75], [1.2, ESP_Z + 1.75], [1.2, ESP_Z + 2.4], [-0.01, ESP_Z + 3.6]]);
    // right: two fixed lips. Slide the USB end under them, then press the left end down: click.
    for (yy = [[13, 19], [33, 40]]) {
        translate([ESP_X + ESP[0] - 0.7, yy[0], ESP_Z + 1.9]) cube([HW - W - (ESP_X + ESP[0] - 0.7) - 2, yy[1] - yy[0], 1.2]);
        translate([ESP_X + ESP[0] + CLR, yy[0], ESP_Z + 1.3]) cube([HW - W - (ESP_X + ESP[0] + CLR) - 2, yy[1] - yy[0], 0.7]);
    }
    // rails under the top for mic, head-pat pad and light sensor: slide in from the back
    for (b = TOPB) for (s = [-1, 1]) {
        xe = b[0] + s * (b[1] / 2 + CLR);                  // slot edge
        y0 = TOP_Y - b[2] / 2 - CLR;                        // board front
        zl = HH - W - TOPB_T - CLR - 1.0;                    // lip bottom
        translate([s < 0 ? xe - 2 : xe, y0, zl]) cube([2, 44 - y0, HH - zl]);                     // rail
        translate([s < 0 ? xe : xe - 0.8, y0, zl]) cube([0.8, 44 - y0, 1.0]);                     // lip
        translate([s < 0 ? xe - 2 : xe - 0.8, y0 - 1.5, zl]) cube([2.8, 1.5, HH - zl]);          // front stop
    }
    // neck collar in the floor
    zcyl([HW / 2, HD / 2, 0], NECK_OD + NECK_FIT + 5, NECK_IN + 2);
    // back-lid stops (old bosses) with support cones
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
    // neck socket + groove for the collet bead + wire hole
    zcyl([HW / 2, HD / 2, -1], NECK_OD + NECK_FIT, NECK_IN + 1);
    zcyl([HW / 2, HD / 2, 3.15], NECK_OD + NECK_FIT + 2 * (BEAD + 0.15), 1.7);
    zcyl([HW / 2, HD / 2, -1], NECK_ID + 2, NECK_IN + 6);
    // grooves for the back-lid beams
    for (e = LIDH) frame(e) groove(e[4]);
    // pry notch under the head, bottom right of the back lid (a coin opens the lid)
    translate([55, HD - 1.2, 1]) cube([6, 2, 1.01]);
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
            // 4 snap arms: they hook behind the catches in the head (1.5 % strain)
            for (x = ARM_X, top = [true, false]) {
                z0 = top ? FACE_Z + FACE[1] / 2 - ARM_T : FACE_Z - FACE[1] / 2;
                zo = top ? z0 + ARM_T : z0;   // outer face
                s = top ? 1 : -1;
                yt = yb + ARM_L;
                translate([x - ARM_W / 2, yb - 0.01, z0]) cube([ARM_W, ARM_L + 0.01, ARM_T]);
                translate([x - ARM_W / 2, 0, 0]) rotate([90, 0, 90]) linear_extrude(ARM_W)
                    polygon([[yt - 2.4, zo - s * 0.01], [yt - 0.6, zo + s * HOOK], [yt, zo + s * HOOK], [yt, zo - s * 0.01]]);
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
    // crush ribs: display (left/right) and camera (left/right) press-fit, no glue
    for (s = [-1, 1]) {
        for (dz = [-9, 9]) rib_y(HW / 2 + s * (LCD_PCB[0] / 2 + 0.6 - CRUSH), LCD_Z + dz, yb - 1.2, LCD_T + 1.6);
        rib_y(HW / 2 + s * (CAM_BODY / 2 + 0.6 - CRUSH), CAM_Z, yb + 0.5, 5.5);
    }
}

// HEAD BACK LID: speaker grille, speaker pocket, amp rails, vents, 4 snap beams
module head_lid() {
    yi = HD - W;   // inner face
    difference() {
        union() {
            xz(yi, HD) offset(-LID_CLR) inset2(HW, HH, HR, W, $fn = FN_BIG);
            for (e = LIDH) frame(e) beam(e[4]);
            // speaker pocket (crush ribs hold it)
            difference() {
                translate([SPK_X - CLR - 1.2, yi - 5, SPK_Z - CLR - 1.2]) cube([SPK[0] + 2 * CLR + 2.4, 5.01, SPK[2] + 2 * CLR + 2.4]);
                translate([SPK_X - CLR, yi - 6, SPK_Z - CLR]) cube([SPK[0] + 2 * CLR, 7, SPK[2] + 2 * CLR]);
                for (s = [0, 1]) translate([SPK_X + SPK[0] / 2 - 5, yi - 6, SPK_Z - 3 + s * (SPK[2] + 3)]) cube([10, 7, 3]);   // wire gaps
            }
            // amp board rails: slide the amp in from the right until it stops
            for (top = [false, true]) {
                zr = top ? AMP_Z + AMP[2] + CLR : AMP_Z - CLR - 1.6;
                zl = top ? AMP_Z + AMP[2] - 0.8 : AMP_Z - CLR;
                translate([AMP_X - 2, yi - 3.1, zr]) cube([AMP[0] + 3, 3.11, 1.6]);
                translate([AMP_X - 2, yi - 3.1, zl]) cube([AMP[0] + 3, 1.2, 0.8 + CLR]);
            }
            translate([AMP_X - 2, yi - 3.1, AMP_Z - CLR - 1.6]) cube([2 - CLR, 3.11, AMP[2] + 2 * CLR + 3.2]);
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
        for (e = LIDH) frame(e) beam_slot(e[4]);
    }
    for (s = [-1, 1]) {
        for (dz = [-6, 6]) rib_y(s < 0 ? SPK_X - 0.6 + CRUSH : SPK_X + SPK[0] + 0.6 - CRUSH, SPK_Z + SPK[2] / 2 + dz, yi - 5, 5);
        rib_y(SPK_X + SPK[0] / 2 + s * 8, s < 0 ? SPK_Z - 0.6 + CRUSH : SPK_Z + SPK[2] + 0.6 - CRUSH, yi - 5, 5);
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

// rails for a board standing against the front wall; it slides in from below
module front_rails(xc, w, z0, ztop) difference() {
    union() {
        for (s = [-1, 1]) boxc([xc + s * (w / 2 + 1), W + 2, (z0 + SH) / 2], [3, 4, SH - z0]);
        if (ztop < SH - W) translate([xc - w / 2 - 1, W - 0.01, ztop]) cube([w + 2, 2, SH - W - ztop + 0.01]);   // top stop
    }
    translate([xc - w / 2 - CLR, W - 0.01, z0 - 1]) cube([w + 2 * CLR, 1.6 + CLR + 0.01, min(ztop, SH) - z0 + 1]);
}

module stand_inside() {
    // radar rails (slides in from below up to the top) and sensor rails
    front_rails(SW / 2, RAD[0], RAD_Z - RAD[1] / 2 - 1, SH + 1);
    for (x = SENS_X) front_rails(x + 6, 12, 4, 18.2);
    // lid stops (full height columns)
    for (b = SBOSS) zcyl([b[0], b[1], W], 5, SH - W);
    // neck twist lock: per side a lip under the post's ear, an outer wall and an end stop
    for (k = [0, 1]) translate([NB[0], NB[1], 0]) rotate(180 * k) {
        translate([13.5, -8, FLANGE_Z - 1.4]) cube([7, 11.7, 1.2]);                       // lip
        translate([18.6, -8, FLANGE_Z - 1.4]) cube([1.9, 11.7, SH - W - FLANGE_Z + 1.41]); // outer wall
        translate([13, EAR_W / 2 + 0.2, FLANGE_Z - 1.4]) cube([7.5, 3, SH - W - FLANGE_Z + 1.41]);   // end stop
        // detent rib: the flange pawl clicks past it in the last few degrees
        rotate(82) translate([13.2, 0, FLANGE_Z - 0.1]) cylinder(d = 1.2, h = SH - W - FLANGE_Z + 0.11);
    }
    // hold-down ribs: battery and charger cannot lift once the lid is on
    for (x = [7, SW - 9]) translate([x, 12, W + BAT[2] + 0.5]) cube([2, 24, SH - W - (W + BAT[2] + 0.5) + 0.01]);
    for (x = [IPM_X - 11, IPM_X + 9]) translate([x, 44, IPM_Z + 1.8]) cube([2, 4, SH - W - (IPM_Z + 1.8) + 0.01]);
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
    // grooves for the bottom-lid beams, slots for its 2 front tabs
    for (e = LIDS) frame(e) groove(e[4]);
    for (x = SENS_X) translate([x + 2.5, 0.9, 2.4]) cube([7, W - 0.9 + 0.01, 1.5]);
    // pry notch under the back edge (a coin opens the lid)
    translate([52, SD - W - 0.01, -1]) cube([8, 1, 1.9]);
}

// STAND BOTTOM LID: battery cradle, charger support, sensor vents, feet, 3 snap beams + 2 front tabs
// Fit: hook the front tabs in, then press the back down. Click.
module stand_lid() {
    difference() {
        union() {
            linear_extrude(W) offset(-LID_CLR) inset2(SW, SD, SR, W, $fn = FN_BIG);
            for (e = LIDS) frame(e) beam(e[4]);   // the side beams also stop the battery left/right
            // battery back stops
            for (x = [14, SW - 28]) translate([x, BAT_Y + BAT[1] + CLR, W]) cube([14, 1.5, BAT[2] + 0.5]);
            // block under the back of the charger
            translate([IPM_X - 5, BAT_Y + BAT[1] + 2, W]) cube([10, SD - E - BEAM_T - BEAM_SLOT - 0.2 - (BAT_Y + BAT[1] + 2), IPM_Z - W]);
            // front: posts under the sensors with the tabs that hook into the front wall
            for (x = SENS_X) {
                translate([x + 2, E, W - 0.01]) cube([8, 1.8, 3.8]);
                translate([x + 3, 1.2, 2.6]) cube([6, E - 1.2 + 0.01, 1.0]);
            }
            // post under the radar
            translate([SW / 2 - 6, E + 0.1, W - 0.01]) cube([12, 1.5, RAD_Z - RAD[1] / 2 - W - 0.1]);
        }
        // vents under the temp/pressure sensors
        for (x = SENS_X) for (k = [0 : 1]) boxc([x + 6, 5 + k * 2.2, W / 2], [10, 1.2, W + 2]);
        // rubber feet recesses
        for (x = [11, SW - 11], y = [11, SD - 11]) zcyl([x, y, -1], 8.4, 1.8);
        for (e = LIDS) frame(e) beam_slot(e[4]);
    }
}

// NECK POST: twist-locks under the stand top, tube tilted back by TILT, 4-finger collet on top
module post_local() {    // in stand coordinates, locked position
    difference() {
        union() {
            zcyl([NB[0], NB[1], FLANGE_Z], 25, 1.5);
            for (k = [0, 1]) translate([NB[0], NB[1], FLANGE_Z]) rotate(180 * k) translate([12, -EAR_W / 2, 0]) cube([EAR_R - 12, EAR_W, 1.5]);
            // pawl nubs on the flange edge
            for (k = [0, 1]) translate([NB[0], NB[1], FLANGE_Z]) rotate(90 + 180 * k) linear_extrude(1.5) polygon([[12.3, -1], [13.0, 0], [12.3, 1]]);
            intersection() {
                translate(NB) rotate([-TILT, 0, 0]) union() {
                    translate([0, 0, -6]) cylinder(d = NECK_OD, h = 6 + T0 + NECK_IN - 0.5);
                    // bead
                    translate([0, 0, T0 + 4 - 0.6]) cylinder(d1 = NECK_OD, d2 = NECK_OD + NECK_FIT + 2 * BEAD, h = 0.6);
                    translate([0, 0, T0 + 4]) cylinder(d1 = NECK_OD + NECK_FIT + 2 * BEAD, d2 = NECK_OD, h = 0.6);
                }
                translate([0, 0, FLANGE_Z]) cube([SW, SD, 100]);
            }
        }
        translate(NB) rotate([-TILT, 0, 0]) {
            translate([0, 0, -20]) cylinder(d = NECK_ID, h = 60);
            ct = T0 + NECK_IN - 0.5 - COLLET_L;
            translate([0, 0, ct]) cylinder(d = NECK_ID + 2, h = 20);
            for (a = [45 : 90 : 315]) rotate(a) translate([0, -0.6, ct]) cube([15, 1.2, 20]);
        }
        // pawl slots: a thin arc of the flange flexes when it passes the detent rib
        for (k = [0, 1]) translate([NB[0], NB[1], FLANGE_Z - 1]) rotate(90 - 38 + 180 * k)
            rotate_extrude(angle = 76) translate([10.6, 0]) square([0.9, 3.5]);
    }
}
module post_turned(a) translate(NB) rotate(a) translate(-NB) post_local();

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
    color("#6a3") { translate([AMP_X, HD - W - 1.6, AMP_Z]) cube([AMP[0], 1.6, AMP[2]]);
                    translate([AMP_X + 1.5, HD - W - AMP[1], AMP_Z + 1.5]) cube([AMP[0] - 3, AMP[1] - 1.6, AMP[2] - 3]); }
    for (b = TOPB) color("#3355cc") {
        translate([b[0] - b[1] / 2, TOP_Y - b[2] / 2, HH - W - TOPB_T]) cube([b[1], b[2], TOPB_T]);
        translate([b[0] - b[1] / 2 + 1.5, TOP_Y - b[2] / 2 + 1.5, HH - W - TOPB_T - 1.2]) cube([b[1] - 3, b[2] - 3, 1.2]);
    }
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

// clash check. Run with -D CRUSH=-0.05 so the crush ribs (meant to press) do not show up.
CI = -1;   // pair to show, -1 = all
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
    // post pushed up from below while turned -TWIST: path of the flange + ears
    c(12) intersection() { stand_shell(); translate([0, 0, W]) linear_extrude(FLANGE_Z - W + 1.49) projection(cut = true)
            translate([0, 0, -FLANGE_Z - 0.75]) post_turned(-TWIST); }
    // turning it to the locked position (ears + flange only, in 5 degree steps)
    c(13) intersection() { stand_shell(); for (a = [-TWIST : 5 : -5]) intersection() { post_turned(a); translate([0, 0, FLANGE_Z - 0.01]) cube([SW, SD, 1.52]); } }
}

// ======================================================================
// snap test print: a piece of the stand top with the neck lock (use the real post),
// and a small frame + lid with the same lid beams. About 25 min, 10 g.
module snaptest() {
    // A: stand top around the neck, top on the bed
    translate([-(NB[0] - 25), -(SD - NB[1] - 25), 0]) translate([0, SD, SH]) rotate([180, 0, 0])
        intersection() { stand_shell(); translate([NB[0] - 25, NB[1] - 25, SH - W - 4]) cube([50, 50, 10]); }
    // B: frame (stand wall section) with grooves, and its lid
    FW = 44; FD = 24; FR = 6; FH = 8;
    EB = [[[E, FD / 2, 0], [0, 1, 0], [-1, 0, 0], [0, 0, 1], 26], [[FW - E, FD / 2, 0], [0, 1, 0], [1, 0, 0], [0, 0, 1], 26]];
    translate([56, 0, 0]) {
        difference() {
            linear_extrude(FH) difference() { rr2(FW, FD, FR); inset2(FW, FD, FR, W); }
            for (e = EB) frame(e) groove(e[4]);
        }
        translate([0, FD + 6, 0]) difference() {
            union() { linear_extrude(W) offset(-LID_CLR) inset2(FW, FD, FR, W); for (e = EB) frame(e) beam(e[4]); }
            for (e = EB) frame(e) beam_slot(e[4]);
        }
    }
}

// ======================================================================
if (PART == "head")           rotate([90, 0, 0]) head_shell();                       // face on the bed
else if (PART == "face")      rotate([90, 0, 0]) translate([0, -LIP, 0]) face_plate(); // front on the bed
else if (PART == "headlid")   translate([0, 0, HD]) rotate([-90, 0, 0]) head_lid();   // outside on the bed
else if (PART == "stand")     translate([0, SD, SH]) rotate([180, 0, 0]) stand_shell();     // top on the bed
else if (PART == "standlid")  stand_lid();
else if (PART == "post")      translate([0, 0, -FLANGE_Z]) post_local();
else if (PART == "facetest")  rotate([90, 0, 0]) intersection() { head_shell(); translate([-1, -1, -1]) cube([HW + 2, 18, HH + 2]); }
else if (PART == "snaptest")  snaptest();
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
