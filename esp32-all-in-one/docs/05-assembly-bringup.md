# 5. Assembly and bring-up, step by step

Rule of thumb: **test every part on the breadboard first, then build it into the case.** Debugging inside a closed case is painful.

## Step 0: before parts arrive
- [ ] Order the missing parts in the [buy list](07-buy-list.md) (the IP5306 charger matters most).
- [ ] Install VS Code + PlatformIO. Open `firmware/bringup`, press Build. It downloads the toolchain the first time (~10 min).
- [ ] Install OpenSCAD. Open `case/robot_case.scad` and look around.

## Step 1: board alone (5 min)
1. Plug the S3 CAM board into your PC via its **native USB** port (often labeled "USB", not "COM"/"UART").
2. Upload the bring-up firmware. If upload fails: hold BOOT, tap RST, release BOOT, upload again.
3. Open the serial monitor. You should see `PSRAM 8388608 bytes, flash 16777216 bytes`. If PSRAM is 0, the `memory_type = qio_opi` setting is wrong for your board.

## Step 2: display (15 min)
1. Wire per [pin map](03-pinmap-power.md): VCC 3.3 V, GND, SCL→21, SDA→47, CS→14, DC→38, BL→39, RST→EN.
2. Type `d`. Colors cycle, then a yellow frame. **All four edges of the frame must be visible.** If the top or bottom is cut or has a noise strip, change `LCD_OFFSET_Y` in `main.cpp` (try 0, 12, 20, 24).
3. Leave it running: you get blinking eyes. 🎉

## Step 3: sensors (10 min)
1. AHT20+BMP280 and BH1750: VCC 3.3 V, GND, SDA→4, SCL→5.
2. Type `s`. Expect `0x23`, `0x38`, `0x77` (or `0x76`). Type `e` for readings.

## Step 4: camera (10 min)
1. On the CAM board the camera is already wired. Connect the 78 mm OV5640 ribbon, contacts facing the right way (gold side to the connector's contacts), latch closed.
2. Reset. The log should say `camera OK, sensor PID 0x5640`. Type `s`: `0x3C` now appears too.
3. Type `c`: live camera mirror on the display. Any key stops it and prints fps.

## Step 5: audio (20 min)
1. MAX98357A: VIN 5 V, GND, BCLK→40, LRC→41, DIN→42. Speaker to the + and - screw/pads.
2. INMP441: VDD 3.3 V, GND, L/R→GND, SCK→40, WS→41, SD→2.
3. Type `t`: three beeps. Type `m`: talk, the bars should jump.
4. Hiss or no sound? Check BCLK/LRC aren't swapped, and the amp has real 5 V.

## Step 6: radar and touch (15 min)
1. LD2410C: VCC **5 V**, GND, its TX → **1k resistor** → GPIO43, OUT → GPIO46. Leave its RX unconnected.
2. Install the **HLKRadarTool** phone app, connect over Bluetooth, set the max distance to ~1.5 m (gates 0 to 2) so it only sees you at your desk, not people walking by.
3. Type `r`: distance and energy values. Walk away: OUT drops after the timeout you set.
4. TTP223: VCC 3.3 V, GND, OUT→3. Type `k` and touch it.

## Step 7: power (30 min, careful)
1. **Check the LiPo plug polarity** against the IP5306 board's battery pads with a multimeter. JST 1.25 batteries from different sellers are wired both ways. Reversed = dead charger.
2. Solder the battery leads (or a JST 1.25 socket) to the IP5306 B+ / B-.
3. Press its key: measure 5.0 to 5.2 V on its output. Charge through its USB-C: its LEDs show the level.
4. Wire: IP5306 5 V → LD2410C + MAX98357A VIN directly, and → Schottky diode (stripe toward the ESP32) → ESP32 **5V** pin. GND to GND everywhere.
5. Battery sense: 100k + 100k divider from battery + to GND, middle to GPIO1. Type `b`: should show 3.7 to 4.2 V.
6. Unplug USB from the PC, power from the battery only, repeat `a` (all tests). If the board resets during beeps, the 5 V sags: add the 470 µF capacitor across the amp's VIN/GND.

## Step 8: print and dry fit
1. Measure parts, update `MEASURE` values in `case/robot_case.scad`, print `robot_facetest.stl`, check the display and camera fit.
2. Print head, head lid, body, body lid, 2 arms, antenna ([settings](04-case.md)).
3. Dry fit every part with no wires: display, camera, ESP32 on its rails, speaker, battery, radar, both lids. Push the head onto the neck and check it turns. Fix and reprint now if needed.

## Step 9: wiring harness
- Use 30 AWG silicone wire, cut each wire ~2 cm longer than the straight path. Color code: red 5 V, orange 3.3 V, black GND, others signals.
- Solder wires **directly to the ESP32 pins** (no headers): the board sits on rails 14 mm above the head floor and the wires run underneath.
- The **8 neck wires** ([list](03-pinmap-power.md#head--body-split-robot-case)): cut them 3 cm longer than needed so the head can turn. Twist them loosely together.
- Make detachable: speaker on a PH 2.0 plug, battery on its JST 1.25 (both owned).
- Build 3.3 V and GND as small "star" splices: one wire from the board to a splice, then branches.

## Step 10: build into the case
**Body first:**
1. Battery flat on the floor between the stop ribs.
2. IP5306 on 2 mm foam tape on top of the battery, USB-C into the back slot. Power button into the 7 mm hole on the back (hot glue from inside).
3. Radar: slide it down into the front rails, **antenna side facing the front**, until it hits the stop.
4. AHT20 on the right wall behind the vents, BMP280 on the left wall (foam tape).
5. Thread the 8 neck wires up through the body lid's neck tube. Screw the body lid on (4 × M2 × 6). Press 4 rubber feet into the recesses underneath.

**Then the head:**
6. Display into its frame, glass against the window. 2 to 4 small dots of glue on the frame edge (never on the glass).
7. Camera into its holder in the forehead. A dot of glue on the side. The ribbon folds down to the board.
8. Mic under the small top hole (a ring of foam tape around the hole stops echo), BH1750 under the top window, TTP223 pad glued under the middle of the top.
9. Speaker against the left grille, front edge against the stop.
10. Push the head onto the neck, pull the neck wires up through the head floor.
11. ESP32 board onto its rails, USB-C to the right-side hole. Connect the camera ribbon. Solder the neck wires. 2 dots of hot glue on the rails.
12. Amp glued to the inside of the back lid (right half), wired to the speaker.
13. Run the tests again (`a`) before closing. Screw on the back lid (4 × M2 × 6).
14. Push in the arms and the antenna.

## Step 11: flash the real firmware
See the [firmware plan](06-firmware-plan.md). From now on prefer OTA updates so you don't have to open the case.

## Safety notes
- Never short or puncture the LiPo. If it ever puffs up, stop using it.
- Don't charge unattended until you've watched a full charge cycle once and the IP5306 stays cool.
- Keep the battery away from the soldering iron: solder the harness first, plug the battery in last.
