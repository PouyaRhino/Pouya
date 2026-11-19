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
| 0, 3, 46 | Straps, but safe as **inputs that idle LOW** (used below on purpose) |

## Verified pin map

| GPIO | Function | Part | Check |
|---|---|---|---|
| 0 | User button | onboard BOOT | Pulled up, pressed = LOW. Fine after boot |
| 1 | Battery voltage (ADC1) | 100k/100k divider from battery + | ADC1 works with Wi-Fi on (ADC2 doesn't) |
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
| 43 | Radar UART RX (UART1, 256000 baud) | LD2410C TX **through a 1k resistor** | 43 is the boot-log TX pin; the 1k stops the two outputs fighting for the first second after reset |
| 46 | Radar presence | LD2410C OUT | 3.3 V logic. Only matters at boot if BOOT is also held (then it may refuse download mode: just unplug the radar to flash over UART, or flash over native USB) |
| 47 | LCD MOSI | ST7789 | |
| 48 | Status RGB LED | onboard WS2812 | |
| EN | LCD RST | ST7789 RST | Display resets with the ESP32 |

**Free pins left: none.** If you need more later: drop the LCD CS (tie it to GND, frees 14), or move the touch pad to the S3's built-in touch sensing on a freed pin.

Other wiring:
- INMP441: VDD 3.3 V, **L/R to GND** (left channel).
- MAX98357A: VIN 5 V, GAIN unconnected (9 dB), SD unconnected (mono mix of L+R, on). Speaker on its + and - outputs (bridge-tied: never connect either speaker wire to GND).
- Camera on a bare OV5640 module: PWDN to GND, RESET to 3.3 V via 10k. Not needed on the S3-CAM board.

## Head / body split (robot case)

The ESP32 lives in the head; the battery side lives in the body. **8 wires go through the neck tube** (12 mm bore, 30 AWG silicone, leave a 3 cm loop so the head can turn about ±90°):

| # | Wire | From (body) | To (head) |
|---|---|---|---|
| 1 | 5 V | IP5306 5 V out | MAX98357A VIN, and through the Schottky to the ESP32 5V pin |
| 2 | GND | IP5306 GND | ESP32 GND |
| 3 | 3.3 V | AHT20 + BMP280 VCC | ESP32 3V3 |
| 4 | VBAT sense | 100k/100k divider middle (divider sits in the body) | GPIO1 |
| 5 | Radar TX | LD2410C TX (1k resistor at the radar end) | GPIO43 |
| 6 | Radar OUT | LD2410C OUT | GPIO46 |
| 7 | SDA | AHT20 + BMP280 SDA | GPIO4 |
| 8 | SCL | AHT20 + BMP280 SCL | GPIO5 |

Everything else stays in the head: display, camera, mic, amp + speaker, BH1750, TTP223 (head pat on the top of the head). The radar gets its 5 V and GND locally in the body. The amp is glued to the inside of the head's back lid, next to the speaker. **No pin changes**, `pins.h` is the same.

## Which board: the CAM board (recommended) or the plain N16R8

- **ESP32-S3 N16R8 CAM board with OV5640 (in transit): use this one.** Its camera connector has the 2.8 V and 1.5 V supplies the OV5640 needs and uses exactly the camera pins above. The 78 mm ribbon on your separate OV5640 module lets the lens sit up in the "forehead" of the case.
- Plain N16R8 board + 24-pin FPC adapter: only works if the adapter has its own 2.8 V and 1.5 V regulators (look for two small 5-pin LDO chips on it). If it's just a pin breakout, the camera won't power up properly.

## Power plan

```
USB-C 5V ──> [IP5306 module] ──5.1V──┬──> LD2410C VCC (5 V)
                │ charge             ├──> MAX98357A VIN (5 V)
             LiPo 3000 mAh           └──>|── Schottky ──> ESP32 board 5V pin ──> board's 3.3 V regulator
             (JST 1.25)                                     └──> 3.3 V: display, mic, sensors, camera
```

- **Charger: IP5306 Type-C module (to buy).** Charge + 5 V boost + "run while charging" in one board. Your owned 5 V boost boards are boost-only: they can't charge the LiPo, so they're spares.
- **Schottky diode (SS34 or 1N5819) into the ESP32 5V pin.** It stops the IP5306 and the ESP32's own USB port back-feeding each other when you plug in the USB cable for flashing.
- **Power switch:** the SS12F15 slide switches you own are rated **0.3 A**, too weak for the battery line (peaks ~1.5 A). Use the IP5306's KEY input instead: a small tact button on KEY to GND. One press = on, two quick presses = off. Bonus: wire KEY through a 10k resistor to a GPIO later if you want software power-off.
- **Battery sense:** 100k from battery + to GPIO1, 100k from GPIO1 to GND. Draws 18 µA. Reading × 2 = battery volts.

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

IP5306 gives 2.4 A, so peaks are fine. The board's AMS1117 3.3 V regulator (usually 800 mA to 1 A) handles the 3.3 V loads (~300 mA peak).

**Battery life (3000 mAh × 3.7 V × ~85% boost efficiency ≈ 9.4 Wh):**
- Awake with face, no camera: ~6 h
- "Room empty" mode (screen off, Wi-Fi light sleep, radar on ~120 mA): ~15 h
- Plan on it mostly living on USB power at the desk, with the battery for moving it around.

### Heat
In the robot case the ESP32 and camera are in the head and the AHT20/BMP280 are in the body, behind their own side vents, so they read close to room temperature. The head's back lid has vents for the ESP32. Still expect the AHT20 to read 0.5 to 2 °C high: calibrate an offset in software against a room thermometer.
