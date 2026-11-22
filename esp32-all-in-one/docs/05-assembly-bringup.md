# 5. Assembly and bring-up, step by step

Rule of thumb: **test every part on the breadboard first, then build it into the case.** Debugging inside a closed case is painful.

## Step 0: before parts arrive
**Pictures for every step: [wiring and build guide](08-wiring-build-guide.md).**

- [ ] Nothing to order: the owned-parts build is USB-powered ([buy list](07-buy-list.md)). Optional: check whether one of your 5 V boost boards can charge a LiPo (chip marking).
- [ ] Install VS Code + PlatformIO. Open `firmware/bringup`, press Build. It downloads the toolchain the first time (~10 min).
- [ ] Install OpenSCAD. Open `case/pebble_case.scad` and look around.

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
1. LD2410C: VCC **5 V**, GND, its TX → **GPIO1** (direct, no resistor), OUT → GPIO46. Leave its RX unconnected.
2. Install the **HLKRadarTool** phone app, connect over Bluetooth, set the max distance to ~1.5 m (gates 0 to 2) so it only sees you at your desk, not people walking by.
3. Type `r`: distance and energy values. Walk away: OUT drops after the timeout you set.
4. TTP223: VCC 3.3 V, GND, OUT→3. Type `k` and touch it.

## Step 7: power (5 min, USB only)
1. Nothing new to wire: radar and amp already get 5 V from the board's 5V pin (the USB 5 V).
2. Swap the PC for a 5 V 2 A phone charger and repeat `a` (all tests). If the board resets during beeps, lower the volume (`vol` ≤ 0.3 in `playTone()`).
3. Leave the LiPo out: nothing owned is known to charge it. The battery option is in the [buy list](07-buy-list.md).

## Step 8: print and dry fit
1. Measure parts, update `MEASURE` values in `case/pebble_case.scad`, print `pebble_snaptest.stl` (25 min) and check that the lid clicks on and off and the real neck post twist-locks. Then print `pebble_face.stl` and `pebble_facetest.stl` and check that the face plate clicks in, and that the display and camera press in.
2. Print head, head back lid, stand, stand bottom lid and neck post ([settings](04-case.md)).
3. Dry fit with no wires: face plate into the head, ESP32 on its rails, speaker in the lid pocket, radar in its rails (battery cradle stays empty), both lids on. Push the head onto the neck. Fix and reprint now if needed.

## Step 9: wiring harness
- Use stripped Dupont jumpers (owned), cut each wire ~3 cm longer than the straight path (solder two together if one is too short). Color code: red 5 V, orange 3.3 V, black GND, others signals.
- Solder wires **directly to the ESP32 pins** (no headers): the board sits on rails 14 mm above the head floor and the wires run underneath.
- The **7 neck wires** ([list](03-pinmap-power.md#head--stand-split-pebble-case)): 3 cm longer than needed, twisted loosely together.
- Make detachable: speaker on a PH 2.0 plug (owned).

## Step 10: build into the case
**Stand first:**
1. Neck post: from inside the stand, push the tube up through the top hole with the ears turned 45° away from the left/right hooks, then turn it until it clicks. The tube now leans to the **back**.
2. Radar: slide it up into the front rails, **antenna side facing the front**, until it touches the top.
3. AHT20 and BMP280: slide each up into its own front rails, left and right of the radar, until it touches the top stop.
4. Battery cradle stays empty in the USB build.
5. Thread the 7 neck wires up through the post. Bottom lid: hook its 2 front tabs into the slots in the front wall, then press the back up until it clicks. The back USB-C hole and the power-key rails stay empty (they are for the optional battery build). To open: a coin in the notch under the back edge.

**Then the head:**
6. Display into the face plate pocket (glass forward) and camera into its pocket: both press in past small ribs. Push the face plate into the head from the back until its 4 arms click behind the catches. To remove: lid off, press the arms in.
7. Slide the 3 top boards in from the back along their rails, parts facing down, until they stop: mic (left, over the small hole), TTP223 pad (middle), BH1750 (right, under the window).
8. Pull the neck wires up through the head floor and push the head onto the neck post until it clicks. It can still turn by hand.
9. ESP32 board: slide its USB-C end under the 2 lips on the right rail, then press the left end down until the clip clicks. Connect the camera ribbon and the display. Solder the neck wires.
10. Speaker presses into the pocket on the back lid. Amp slides into its rails from the right until it stops. Wire them.
11. Run the tests again (`a`) before closing. Press the back lid in until all 4 sides click. To open: a coin in the notch under the head, bottom right of the lid.

## Step 11: flash the real firmware
See the [firmware plan](06-firmware-plan.md). From now on prefer OTA updates so you don't have to open the case.

## Safety notes
- The LiPo is not used in this build. Don't connect it to any board that can't charge and protect it.
- If you later add a charger board: check the JST 1.25 plug polarity with a meter first, and watch one full charge before leaving it unattended.
