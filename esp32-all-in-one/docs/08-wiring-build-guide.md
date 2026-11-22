# 8. Wiring and build guide (with pictures)

The picture version of [pin map](03-pinmap-power.md) + [assembly](05-assembly-bringup.md). Pins match [`pins.h`](../firmware/bringup/include/pins.h).

![Full wiring](img/wiring-full.png)

> **Owned-parts build (Nov 22):** USB-powered, no battery. Radar TX goes **straight to GPIO1** (no 1k), no battery divider, no IP5306, no diode. The pictures for steps 6 and 7 and the full diagram still show the old battery version: **where a picture and the text disagree, follow the text.**

**Rails:** red **5V** = the ESP32 board's 5V pin, which is the USB 5 V (radar and amp). Orange **3V3** = the ESP32's 3V3 pin. Black **GND** = all grounds joined.
**The two 5 V parts are the LD2410C radar and the MAX98357A amp.** Everything else is 3.3 V. Never put 5 V on a GPIO.

## Before you start: nothing to buy

Everything below uses owned parts ([buy list](07-buy-list.md)). Wire: strip the **Dupont jumpers** (and PH 2.0 / JST 1.25 pigtails) instead of 30 AWG silicone. Power: a **5 V 2 A phone charger** and any USB-C cable.

## How each step works

1. Wire only the parts in the picture, on a breadboard, with jumper wires.
2. Plug the board in by its **native USB** port and open the serial monitor of the [bring-up firmware](../firmware/bringup) (115200).
3. Type the test letter. Move on only when it passes.

Take "5V" from the board's **5V pin** (it's the USB 5 V) and "3V3" from its **3V3 pin**. That stays true in the finished build.

---

### Step 1 · Board alone
![](img/wiring-1-board.png)
- Upload the bring-up firmware. If upload fails: hold BOOT, tap RST, release BOOT, retry.
- **Pass:** log shows `PSRAM 8388608 bytes, flash 16777216 bytes`.

### Step 2 · Display
![](img/wiring-2-display.png)
- VCC→3V3, GND, SCL→21, SDA→47, CS→14, DC→38, BL→39, RST→EN.
- **Test `d`:** colours cycle, then a yellow frame. All 4 edges visible? If not, change `LCD_OFFSET_Y` in `main.cpp` (0, 12, 20, 24).

### Step 3 · Sensors (I2C)
![](img/wiring-3-sensors.png)
- AHT20+BMP280 and BH1750 all on the same 4 wires: 3V3, GND, SDA→4, SCL→5. On the bench, wire them straight to the board (no neck yet).
- **Test `s`:** finds `0x23`, `0x38`, `0x77` (or `0x76`). **Test `e`:** readings.

### Step 4 · Camera
![](img/wiring-4-camera.png)
- Ribbon only. Gold contacts toward the socket contacts, latch closed. Never plug it in with power on.
- **Pass:** log says `camera OK, sensor PID 0x5640`; `s` now also shows `0x3C`. **Test `c`:** live mirror on the display.

### Step 5 · Amp + speaker + mic
![](img/wiring-5-audio.png)
- Amp: **VIN→5V**, GND, BCLK→40, LRC→41, DIN→42. GAIN and SD unconnected. Speaker on + and −, **neither side to GND**.
- Mic: VDD→3V3, GND, L/R→GND, SCK→40, WS→41, SD→2. (Mic and amp share pins 40 and 41.)
- **Test `t`:** three beeps. **Test `m`:** talk, bars jump. Hiss or silence: BCLK/LRC swapped, or no real 5 V on the amp.

### Step 6 · Radar + touch
![](img/wiring-6-radar-touch.png)
- Radar: **VCC→5V**, GND, its **TX → GPIO1 directly** (no resistor), OUT→46. Its RX stays unconnected. (The picture shows the old TX → 1k → 43: ignore that part.)
- Set the range to ~1.5 m in the **HLKRadarTool** app (Bluetooth).
- Touch: VCC→3V3, GND, OUT→3.
- **Test `r`:** distance values. **Test `k`:** touch the pad.

### Step 7 · Power (USB only)
1. Nothing new to wire: radar and amp already take 5 V from the board's 5V pin.
2. Swap the PC for a **5 V 2 A phone charger**, plug into the board's native USB port, run **test `a`** (all). `b` now just says "not fitted".
3. Resets during beeps = 5 V sags: lower the volume (`vol` in `playTone()`, keep it ≤ 0.3) or use a stronger charger.
4. **Leave the LiPo out.** Nothing owned is known to charge it. If one of your 5 V boost boards turns out to be a charge + boost board, see the battery option in the [buy list](07-buy-list.md) first.

(The step 7 picture shows the old IP5306 + battery wiring. Skip it.)

### Step 8 · Into the case
![](img/build-8-assembly.png)

**Harness tips**
- Stripped Dupont jumpers (owned), each wire ~3 cm longer than the straight path; they're stiffer than silicone. Too short? Solder two together and tape the joint. Keep the colours: red 5 V, orange 3.3 V (white if your kit has no orange), black GND.
- Solder straight to the ESP32 pins (no headers): the board sits on rails and the wires run underneath.
- The **7 neck wires** (SDA, SCL, 3V3, radar TX→GPIO1, radar OUT, GND, 5V): +4 cm slack, twisted loosely. No resistor, divider or diode anywhere.
- Speaker on a PH 2.0 plug, so the lid comes off. The stand's battery bay stays empty.
- The USB-C cable plugs into the head's **right side** (the ESP32's own port). The hole at the back of the stand is unused.
- Insulate joints with electrical tape or a dab of hot glue.

Then flash the real firmware ([plan](06-firmware-plan.md)) and use OTA from then on.

---
Images are generated: `python3 img/src/wiring.py <dir> && node img/src/render.js <dir>` (needs Playwright). Edit `wiring.py` if a pin changes, together with `pins.h` and doc 3.
