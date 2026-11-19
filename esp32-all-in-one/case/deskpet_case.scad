// ============================================================
// ESP32-S3 all-in-one desk pet - parametric case (OpenSCAD)
// ============================================================
// Parts:  PART="shell" | "sled" | "lid" | "stand" | "facetest" | "assembly" | "hero" | "exploded"
// "facetest" = only the first 7 mm of the shell: a 30-minute print to check
// the display, camera and radar fit before the 3+ hour shell print.
// Export: openscad -D 'PART="shell"' -o stl/shell.stl deskpet_case.scad
//
// Coordinates (all parts): X = width (left->right seen from the front),
// Y = height (bottom->top of the standing device), Z = depth from the
// front face (z=0) towards the back. The shell is modelled exactly in its
// print orientation: face down on the bed.
//
// Every value marked MEASURE is a best guess from listings. Measure your
// own part with calipers and change it here BEFORE printing the shell.
// ============================================================

PART = "assembly";
$fn = 48;

// ---------- display choice ----------
DISPLAY = "2.01";                 // "2.01" (Estardyn 240x296) or "1.69" (240x280 IPS)

// [active area w, h], [glass w, h], [module PCB w, h], PCB+glass thickness
disp = DISPLAY == "2.01"
  ? [[32.4, 39.9], [35.0, 44.0], [36.5, 52.0], 4.0]     // MEASURE
  : [[28.2, 32.9], [30.5, 37.5], [32.0, 44.0], 3.6];    // MEASURE
disp_aa    = disp[0];
disp_glass = disp[1];
disp_pcb   = disp[2];
disp_t     = disp[3];
// The flex/pins usually leave the glass at the bottom, so the glass sits
// high on the PCB. Offset of glass centre above PCB centre:
disp_glass_shift = (disp_pcb[1] - disp_glass[1]) / 2 - 1;  // MEASURE

// ---------- other parts (MEASURE) ----------
batt      = [36, 65, 10];        // PL103665 LiPo  (w, h, t)  - from listing
esp_pcb   = [28.5, 65, 1.6];     // S3 N16R8 (CAM) dev board (w, h, t)
esp_holes = [[2.5, 2.5], [26.0, 2.5], [2.5, 62.5], [26.0, 62.5]]; // hole centres, MEASURE (many boards have none: use zip-tie slots)
cam_mod   = [8.6, 8.6, 6.0];     // OV5640 module body, lens square
cam_lens  = 8.2;                 // lens barrel diameter
cam_fov   = 120;                 // lens FOV, for the window cone
radar     = [22, 16, 1.6];       // LD2410C (w, h, pcb t)
spk       = [35, 25, 6.5];       // 2535 speaker (l, w, depth)
chg_mod   = [25, 21, 6];         // IP5306 Type-C module (w, l, h incl. USB-C)  MEASURE
usb_cut   = [10.0, 4.2];         // USB-C receptacle opening (w, h)

// ---------- case ----------
W      = 62;      // outer width
H      = 96;      // outer height
D_shell= 44;      // shell depth incl. face (lid adds lid_t)
R      = 9;       // corner radius (front view)
wall   = 2.0;     // side walls (5 perimeters at 0.4 mm)
face   = 2.0;     // front face thickness
thin   = 1.0;     // face thickness in front of the radar (mmWave sees through PETG)
lid_t  = 3.0;
clr    = 0.3;     // fit clearance per side

// positions on the face (x centre, y centre)
disp_c  = [W/2, 52];
cam_c   = [W/2, 86];
radar_c = [W/2, 12];

// sled (internal plate the ESP32 board is tied to)
sled_z  = 28;     // front surface of the sled
sled_t  = 2.4;
sled_x0 = 11;     // leave room for the side speaker

// screw bosses (M2 self-tapping) and magnet bosses (3x1 mm magnets)
boss_d   = 6;
pilot_d  = 1.7;   // M2 self-tap pilot in PETG
m2_clear = 2.3;
mag_d    = 3.25;  // 3 mm magnet press fit (adjust +-0.05 for your printer)
mag_h    = 1.2;
boss_xy  = [[wall+3.2, wall+3.2], [W-wall-3.2, wall+3.2],
            [wall+3.2, H-wall-3.2], [W-wall-3.2, H-wall-3.2]];
mag_xy   = [[wall+2.6, 66], [W-wall-2.6, 66]];

// ============================================================
module rrect(w, h, r) { offset(r) offset(-r) square([w, h]); }

module outer2d() { rrect(W, H, R); }
module inner2d() { translate([wall, wall]) rrect(W-2*wall, H-2*wall, R-wall); }

// ---------------- SHELL ----------------
module shell() {
  difference() {
    union() {
      difference() {
        linear_extrude(D_shell) outer2d();
        translate([0, 0, face]) linear_extrude(D_shell) inner2d();
      }
      // corner screw bosses
      for (p = boss_xy) translate([p[0], p[1], face]) cylinder(d = boss_d, h = D_shell - face);
      // side magnet bosses
      for (p = mag_xy) translate([p[0] - 2.4, p[1] - 3, face + 6]) cube([4.8, 6, D_shell - face - 6]);
      display_frame();
      cam_holder();
      radar_frame();
      speaker_cradle();
      sled_posts();
    }
    // screw pilots and magnet pockets
    for (p = boss_xy) translate([p[0], p[1], D_shell - 10]) cylinder(d = pilot_d, h = 11);
    for (p = mag_xy) translate([p[0], p[1], D_shell - mag_h]) cylinder(d = mag_d, h = 2);
    // display window (active area + 0.6 mm), chamfered outward
    translate([disp_c[0], disp_c[1], -0.01])
      hull() {
        translate([0, 0, face]) linear_extrude(0.01) square(disp_aa + [0.6, 0.6], center = true);
        linear_extrude(0.01) square(disp_aa + [0.6 + 2*face, 0.6 + 2*face], center = true);
      }
    // glass recess so the glass sits 0.8 mm into the face
    translate([disp_c[0], disp_c[1], face - 0.8])
      linear_extrude(2) square(disp_glass + [2*clr, 2*clr], center = true);
    // camera window: cone sized for the FOV
    translate([cam_c[0], cam_c[1], -0.01]) {
      cone_r = cam_lens/2 + 0.3 + face * tan(cam_fov/2);
      cylinder(r1 = cone_r, r2 = cam_lens/2 + 0.3, h = face + 0.02);
    }
    // thin the face in front of the radar
    translate([radar_c[0], radar_c[1], thin])
      linear_extrude(face) square([radar[0] + 2, radar[1] + 2], center = true);
    // speaker grille (left wall, x = 0)
    for (i = [0:5]) translate([-1, 18 + i*4.6, 14]) cube([wall + 2, 2.2, spk[1] - 4]);
    // mic hole (top wall) + light sensor window (top wall)
    translate([W/2 - 10, H - wall - 1, 20]) rotate([-90, 0, 0]) cylinder(d = 1.6, h = wall + 2);
    translate([W/2 + 10, H - wall - 1, 14]) rotate([-90, 0, 0]) cylinder(d = 4.0, h = wall + 2);
    // vents for the temp/humidity sensor (right wall, low, far from the ESP32)
    for (i = [0:3]) translate([W - wall - 1, 8 + i*4, 12]) cube([wall + 2, 2, 8]);
    // bottom wall: USB-C for the ESP32 board (data/flash) and the charger
    translate([esp_x() + esp_pcb[0]/2 - usb_cut[0]/2, -1, esp_usb_z() - usb_cut[1]/2])
      cube([usb_cut[0], wall + 2, usb_cut[1]]);
    translate([W - wall - 1 - chg_mod[0]/2 - usb_cut[0]/2, -1, D_shell - 2 - chg_mod[2]/2 - usb_cut[1]/2 - 1])
      cube([usb_cut[0], wall + 2, usb_cut[1]]);
  }
}

// ESP board placement on the sled (front side, components face the display)
function esp_x() = sled_x0 + (W - wall - sled_x0 - esp_pcb[0]) / 2;
function esp_usb_z() = sled_z - 3 - 1.6 - 1.7;   // standoff 3, pcb, half USB-C height

module display_frame() {
  // locating frame around the module PCB, 3 mm tall, with 2 clip lips
  h = disp_t + 1.2;
  pc = [disp_c[0], disp_c[1] - disp_glass_shift];
  translate([pc[0], pc[1], face])
    difference() {
      linear_extrude(h) square(disp_pcb + [2*clr + 2.4, 2*clr + 2.4], center = true);
      translate([0, 0, -1]) linear_extrude(h + 2) square(disp_pcb + [2*clr, 2*clr], center = true);
      // gap for the FPC / pins at the bottom
      translate([-9, -disp_pcb[1]/2 - 3, -1]) cube([18, 4, h + 2]);
    }
}

module cam_holder() {
  translate([cam_c[0], cam_c[1], face])
    difference() {
      linear_extrude(cam_mod[2] - 1) square([cam_mod[0] + 2*clr + 2.4, cam_mod[1] + 2*clr + 2.4], center = true);
      translate([0, 0, -1]) linear_extrude(cam_mod[2] + 2) square([cam_mod[0] + 2*clr, cam_mod[1] + 2*clr], center = true);
      translate([-4, -cam_mod[1]/2 - 3, -1]) cube([8, 4, cam_mod[2] + 2]);   // ribbon exit (downwards)
    }
}

module radar_frame() {
  translate([radar_c[0], radar_c[1], face])
    difference() {
      linear_extrude(3) square([radar[0] + 2*clr + 2.4, radar[1] + 2*clr + 2.4], center = true);
      translate([0, 0, -1]) linear_extrude(5) square([radar[0] + 2*clr, radar[1] + 2*clr], center = true);
      translate([-radar[0]/2 - 3, -4, -1]) cube([4, 8, 5]);   // wire exit
    }
}

module speaker_cradle() {
  // two ribs on the left wall hold the speaker against the grille
  for (dy = [0, spk[0] + 2*clr + 1.6])
    translate([wall, 15 - 1.6 + dy - 0.0, 12]) cube([spk[2] + 1, 1.6, spk[1] + 2]);
}

// four columns on the top and bottom walls: the sled rests on them and is
// screwed down with M2 self-tappers (prints without supports)
sled_post_xy = [[16, wall + 3], [46, wall + 3], [16, H - wall - 3], [46, H - wall - 3]];
module sled_posts() {
  for (p = sled_post_xy)
    translate([p[0] - 3, p[1] < H/2 ? wall - 0.5 : p[1] - 3, face])
      difference() {
        cube([6, 6.5, sled_z - face]);
        translate([3, p[1] < H/2 ? 3.5 : 3, sled_z - face - 8]) cylinder(d = pilot_d, h = 9);
      }
}

// ---------------- SLED ----------------
module sled2d() {
  difference() {
    intersection() {
      offset(-clr) inner2d();
      translate([sled_x0, 0]) square([W, H]);
    }
    for (p = boss_xy) translate(p) circle(d = boss_d + 1);
    for (p = mag_xy) translate([p[0] - 3, p[1] - 3.6]) square([6, 7.2]);
  }
}
module sled() {
  difference() {
    union() {
      linear_extrude(sled_t) sled2d();
      // standoffs for the ESP board (if it has holes)
      for (p = esp_holes) translate([esp_x() + p[0], (H - esp_pcb[1])/2 + p[1], -3]) cylinder(d = 4.5, h = 3);
    }
    for (p = esp_holes) translate([esp_x() + p[0], (H - esp_pcb[1])/2 + p[1], -4]) cylinder(d = pilot_d, h = 10);
    // screw holes onto the 4 posts
    for (p = sled_post_xy) translate([p[0], p[1], -1]) cylinder(d = m2_clear, h = sled_t + 2);
    // zip-tie slots (3 mm ties) each side of the board, 3 heights
    for (yy = [0.2, 0.5, 0.8]) for (xx = [esp_x() - 3.5, esp_x() + esp_pcb[0] + 1.5])
      translate([xx, (H - esp_pcb[1])/2 + yy*esp_pcb[1] - 1.75, -1]) cube([2, 3.5, sled_t + 2]);
    // wire pass-through windows (left strip, between speaker and board)
    translate([sled_x0 + 2.5, H/2 + 14, -1]) cube([6, 16, sled_t + 2]);
    translate([sled_x0 + 2.5, H/2 - 30, -1]) cube([6, 16, sled_t + 2]);
    // camera ribbon slot above the board
    translate([W/2 - 9, H - 13, -1]) cube([18, 2.5, sled_t + 2]);
  }
}

// ---------------- LID ----------------
module lid() {
  difference() {
    union() {
      linear_extrude(lid_t) outer2d();
      // locating lip that drops into the shell
      translate([0, 0, -2]) difference() {
        linear_extrude(2) offset(-clr) inner2d();
        translate([0, 0, -1]) linear_extrude(4) offset(-1.6) inner2d();
        for (p = concat(boss_xy)) translate([p[0], p[1], -1]) cylinder(d = boss_d + 1, h = 4);
        for (p = mag_xy) translate([p[0] - 3, p[1] - 3.6, -1]) cube([6, 7.2, 4]);
      }
      // battery cradle ribs (battery lies against the lid, centred)
      bx = (W - batt[0]) / 2; by = 24;
      for (x = [bx - 1.6 - clr, bx + batt[0] + clr]) translate([x, by + 6, -batt[2] + 2]) cube([1.6, batt[1] - 12, batt[2] - 2]);
      translate([bx, by + batt[1] + clr, -6]) cube([batt[0], 1.6, 6]);
      translate([bx + 6, by - 1.6 - clr, -6]) cube([batt[0] - 12, 1.6, 6]);
    }
    // screw holes, countersunk from the outside
    for (p = boss_xy) translate([p[0], p[1], -3]) {
      cylinder(d = m2_clear, h = 10);
      translate([0, 0, 3 + lid_t - 1.3]) cylinder(d1 = m2_clear, d2 = 4.2, h = 1.31);
    }
    // magnet pockets (glue magnets with matching polarity!)
    for (p = mag_xy) translate([p[0], p[1], -0.01]) cylinder(d = mag_d, h = mag_h);
    // rear vents (top, hot air out)
    for (i = [0:4]) translate([W/2 - 14 + i*7, H - 14, -1]) cube([3, 8, lid_t + 2]);
    // charger LED window
    translate([W - wall - 1 - chg_mod[0]/2 + 6, 14, -1]) cylinder(d = 2.5, h = lid_t + 2);
  }
}

// ---------------- STAND ----------------
// A cradle the pet sits in: tilts it back for a better view of the screen,
// and leaves a channel under the bottom wall for right-angle USB-C plugs.
tilt = 10;
module stand() {
  D = D_shell + lid_t;
  difference() {
    hull() {
      translate([-3, -3, 0]) cube([W + 6, D + 10, 4]);
      translate([-3, -3, 0]) cube([W + 6, 6, 12]);
    }
    // seat
    translate([0, 3, 10]) rotate([tilt, 0, 0]) translate([-clr, -clr, -20 + 4]) cube([W + 2*clr, D + 2*clr, 30]);
    // cable channel (front to back) under the USB ports
    translate([8, -10, 3]) cube([W - 16, D + 30, 20]);
  }
}

// ---------------- dispatch ----------------
if (PART == "shell") shell();
else if (PART == "sled")  rotate([180, 0, 0]) sled();   // standoffs up
else if (PART == "lid")   rotate([180, 0, 0]) lid();   // print outer face down
else if (PART == "stand") stand();
else if (PART == "hero") {
  // presentation render: standing upright on its stand, face lit with eyes
  rotate([90, 0, 0]) translate([0, 0, -D_shell]) {
    color("#262626") shell();
    color("#050505") translate([disp_c[0] - disp_glass[0]/2, disp_c[1] - disp_glass[1]/2, face - 0.8]) cube([disp_glass[0], disp_glass[1], 0.8]);
    for (sx = [-1, 1]) color("#3ee6ff") translate([disp_c[0] + sx*8 - 5, disp_c[1] - 7, face - 0.9]) cube([10, 14, 0.2]);
    color("#444") translate([0, 0, D_shell]) lid();
  }
}
else if (PART == "exploded") {
  // shell face-down at the bottom, parts lifted out along Z (towards the back)
  color("#2b2b2b") shell();
  color("#111") translate([disp_c[0] - disp_glass[0]/2, disp_c[1] - disp_glass[1]/2, -12]) cube([disp_glass[0], disp_glass[1], 1]);
  color("#1a7f5a") translate([esp_x(), (H - esp_pcb[1])/2, sled_z + 30 - 3 - esp_pcb[2]]) cube(esp_pcb);
  color("orange") translate([0, 0, sled_z + 30]) sled();
  color("#3a6fd8") translate([(W - batt[0])/2, 24, D_shell + 50 - batt[2]]) cube(batt);
  color("#555") translate([0, 0, D_shell + 75]) lid();
}
else if (PART == "facetest") intersection() { shell(); translate([-1, -1, -1]) cube([W + 2, H + 2, 8]); }
else {
  color("dimgray") shell();
  color("orange", 0.9) translate([0, 0, sled_z]) sled();
  color("gray", 0.6) translate([0, 0, D_shell]) lid();
  // ghost parts for fit checking
  %translate([(W - batt[0])/2, 24, D_shell - batt[2]]) cube(batt);
  %translate([esp_x(), (H - esp_pcb[1])/2, sled_z - 3 - esp_pcb[2]]) cube(esp_pcb);
  %translate([disp_c[0] - disp_pcb[0]/2, disp_c[1] - disp_glass_shift - disp_pcb[1]/2, face]) cube([disp_pcb[0], disp_pcb[1], disp_t]);
  %translate([wall, 15, 12]) cube([spk[2], spk[0], spk[1]]);
}
