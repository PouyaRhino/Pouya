# 3. Pin map and power plan

The code copy of this table is [`firmware/bringup/include/pins.h`](../firmware/bringup/include/pins.h). If you change a pin, change both.

## Pins you must not use (ESP32-S3 N16R8)

| GPIO | Why |
|---|---|
| 19, 20 | Native USB D-/D+ (flashing, serial console) |
| 26 to 32 | Internal flash, not on the headers |
| 35, 36, 37 | **Octal PSRAM** on the R8 module. Using them crashes the board |
| 45 | Strap for flash voltage. Must be LOW at boot or the board won't start. Left unconnected |
| 44 | UART0 RX, driven by the board's USB-UART chip. Left unconnected |
| 43 | UART0 TX, prints the boot log. Left unconnected (it used to take the radar through a 1k) |
| 0, 3, 46 | Straps, but safe as **inputs that idle LOW** (used below on purpose) |

## Verified pin map

| GPIO | Function | Part | Check |
|---|---|---|---|
| 0 | User button | onboard BOOT | Pulled up, pressed = LOW. Fine after boot |
| 1 | Radar UART RX (UART1, 256000 baud) | LD2410C TX, **direct, no resistor** | Plain GPIO, no strap, never driven at boot. Moved here from 43 in the owned-parts build |
| 2 | I2S DIN | INMP441 SD | |
| 3 | Head-pat touch | TTP223 OUT | TTP223 idles LOW. GPIO3 strap is ignored unless an eFuse is burned |
| 4 | I2C SDA + camera SCCB | OV5640, AHT20, BMP280, BH1750 | Addresses 0x3C, 0x38, 0x77/0x76, 0x23: no clash |
| 5 | I2C SCL + camera SCCB | same | Sensor boards already have pull-ups |
| 6 | Camera VSYNC | OV5640 | Standard S3-CAM / S3-EYE map |
| 7 | Camera HREF | OV5640 | |
| 8, 9, 10, 11, 12, 16, 17, 18 | Camera D2, D1, D3, D0, D4, D7, D6, D5 | OV5640 | |
| 13 | Camera PCLK | OV5640 | |
| 15 | Camera XCLK (20 MHz) | OV5640 | |
| 14 | LCD CS | ST7789 | |
| 21 | LCD SCLK | ST7789 | |
| 38 | LCD DC | ST7789 | Some boards put the RGB LED on 38. If yours does, the LED flickers: harmless, or remove its jumper |
| 39 | LCD backlight (PWM) | ST7789 BL | Max ~40 mA through the module's transistor |
| 40 | I2S BCLK | MAX98357A BCLK + INMP441 SCK | One I2S port, full duplex, saves 2 pins |
| 41 | I2S WS/LRC | MAX98357A LRC + INMP441 WS | |
| 42 | I2S DOUT | MAX98357A DIN | |
| 46 | Radar presence | LD2410C OUT | 3.3 V logic. Only matters at boot if BOOT is also held (then it may refuse download mode: just unplug the radar to flash over UART, or flash over native USB) |
| 47 | LCD MOSI | ST7789 | |
| 48 | Status RGB LED | onboard WS2812 | |
| EN | LCD RST | ST7789 RST | Display resets with the ESP32 |

**Free pins left: none** (43 is free but avoid it, it prints the boot log). No battery sense in this build. If you need more later: drop the LCD CS (tie it to GND, frees 14), or move the touch pad to the S3's built-in touch sensing on a freed pin.

Other wiring:
- INMP441: VDD 3.3 V, **L/R to GND** (left channel).
- MAX98357A: VIN 5 V, GAIN unconnected (9 dB), SD unconnected (mono mix of L+R, on). Speaker on its + and - outputs (bridge-tied: never connect either speaker wire to GND).
- Camera on a bare OV5640 module: PWDN to GND, RESET to 3.3 V via 10k. Not needed on the S3-CAM board.

## Head / stand split (Pebble case)

The ESP32 lives in the head; the radar and AHT20/BMP280 live in the stand (the battery bay stays empty in the USB build). **7 wires go through the neck post** (12 mm bore, stripped Dupont jumpers, leave a 3 to 4 cm loop):

| # | Wire | From (stand) | To (head) |
|---|---|---|---|
| 1 | 5 V | LD2410C VCC | ESP32 **5V pin** (USB 5 V). Amp VIN also taps it in the head |
| 2 | GND | LD2410C + sensor GND | ESP32 GND |
| 3 | 3.3 V | AHT20 + BMP280 VCC | ESP32 3V3 |
| 4 | Radar TX | LD2410C TX (no resistor) | GPIO1 |
| 5 | Radar OUT | LD2410C OUT | GPIO46 |
| 6 | SDA | AHT20 + BMP280 SDA | GPIO4 |
| 7 | SCL | AHT20 + BMP280 SCL | GPIO5 |

Everything else stays in the head: display, camera, mic, amp + speaker (both on the head's back lid), BH1750, TTP223. The only pin change from the first plan: radar RX 43 → 1, battery sense dropped. `pins.h` matches.

## Which board: the CAM board (recommended) or the plain N16R8

- **ESP32-S3 N16R8 CAM board with OV5640 (in transit): use this one.** Its camera connector has the 2.8 V and 1.5 V supplies the OV5640 needs and uses exactly the camera pins above. The 78 mm ribbon on your separate OV5640 module lets the lens sit up in the "forehead" of the case.
- Plain N16R8 board + 24-pin FPC adapter: only works if the adapter has its own 2.8 V and 1.5 V regulators (look for two small 5-pin LDO chips on it). If it's just a pin breakout, the camera won't power up properly.

## Power plan (owned-parts build: USB only)

```
USB-C charger 5 V 2 A ──> ESP32 board USB port ──> board 5V pin ──┬──> LD2410C VCC (5 V, in the stand)
                               │                                  └──> MAX98357A VIN (5 V)
                               └──> board's 3.3 V regulator ──> display, mic, sensors, camera
```

- **No battery, no charger board.** None of the owned parts is known to charge a LiPo (the 5 V boost boards are probably boost-only), so the LiPo stays out. See the [buy list](07-buy-list.md) for the check that could change this, and the optional battery build.
- **Use a 5 V 2 A phone charger**, not a PC port, once the amp and camera are in. A PC port gives 0.5 to 0.9 A.
- **The board's 5V pin is the USB 5 V** (on most S3 boards through a small diode, so 4.7 to 5.0 V). The radar and the amp are both happy with that.
- **No Schottky, no power button:** one 5 V source, plug in = on.
- **Keep the volume capped** (`vol` ≤ 0.3 in firmware). Full 3 W peaks can pull ~0.8 A on their own and reset the board.

### Power budget (5 V side, from datasheet typicals)

| Load | Typical | Peak |
|---|---|---|
| ESP32-S3 + PSRAM, Wi-Fi on | 120 mA | 350 mA (Wi-Fi TX) |
| OV5640 streaming | 120 mA | 150 mA |
| Display + backlight (2.01") | 35 mA | 45 mA |
| LD2410C | 80 mA | 90 mA |
| MAX98357A + speaker (speech, mid volume) | 60 mA | 800 mA (loud peaks, 3 W into 4 Ω) |
| Mic + sensors | 3 mA | 3 mA |
| **Awake, idle face, no camera** | **~300 mA** | |
| **Talking + camera** | **~450 mA** | **~1.3 A** |

A 2 A charger covers the ~1.3 A worst case; with the volume cap the real peak is ~0.8 A. The board's AMS1117 3.3 V regulator (usually 800 mA to 1 A) handles the 3.3 V loads (~300 mA peak).

**Battery life:** none in this build. It runs as long as it's plugged in.

### Heat
In the Pebble case the ESP32 and camera are in the head and the AHT20/BMP280 are in the stand, with vents underneath, so they read close to room temperature. The head's back lid has vents for the ESP32. Still expect the AHT20 to read 0.5 to 2 °C high: calibrate an offset in software against a room thermometer.
