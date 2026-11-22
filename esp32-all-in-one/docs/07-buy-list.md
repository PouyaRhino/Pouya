# 7. Buy list: owned-parts build (nothing to buy)

You asked to build with what you have (Nov 22, 2026). Checked against the parts inventory (AliExpress orders, Nov 2 to 10). The parts still **in transit** (CAM board, MAX98357A, mic, LD2410C, AHT20+BMP280, BH1750, TTP223) count as owned.

**Result: the Pebble builds as a USB-powered desk pet with zero new parts.** The only thing owned parts can't do safely is charge the LiPo, so the battery is left out by default (see the end).

## What replaces each missing part

| Was on the list | Use instead (owned) | What changes |
|---|---|---|
| IP5306 charge + boost board | **Nothing: power from USB.** A USB-C cable into the ESP32 board's own port, from a 5 V 2 A phone charger | No battery, so it lives on the desk plugged in. 5 V for radar + amp comes from the board's **5V pin** |
| Schottky diode | Not needed | Only one 5 V source now, nothing to back-feed |
| 6 × 6 tact button (power key) | Not needed | Plug in = on. Unplug = off |
| 1k resistor (radar TX) | Not needed | Radar TX moves from GPIO43 to **GPIO1**, which never drives at boot. No resistor |
| 2 × 100k (battery divider) | Not needed | No battery to measure. GPIO1 goes to the radar instead |
| 10k camera reset pull-up | Not needed | Only for a bare OV5640 module. The CAM board has it |
| 30 AWG silicone wire | **Dupont jumpers** (40 × 10 cm kit) and the **PH 2.0 / JST 1.25 pigtails** | Cut off the plugs, strip, solder. Stiffer than silicone: leave bigger loops. 7 Dupont wires fit the 12 mm neck easily |
| Right-angle USB-C cable | Any straight USB-C cable | Plugs into the head's right side (the flashing port), not the stand's back |
| 470 µF capacitor (amp) | Volume cap in firmware | Keep `vol` ≤ 0.3 in `playTone()` and future audio code. Loud 3 W peaks are what reset boards on USB |
| Kapton tape / heat-shrink | Electrical tape or a dab of hot glue | Only to insulate joints |

## The 2 real gaps (said plainly)

1. **LiPo charging.** None of the owned parts is known to charge a LiPo. The 5 × "5 V 2 A Type-C boost converter" boards are *probably* boost-only, but some boards sold under that name are charge + boost power-bank boards. **Check one:** read the chip marking (IP5306, FM5324, TP5400, HT4928 = charges too) and look for B+ / B− pads plus a Type-C **input**. If it charges, say so and the plan switches to the battery build below. Until then, **don't wire a LiPo to anything**.
2. **Filament.** Any filament you already have works. PLA is fine for a desk pet that stays indoors; print `pebble_snaptest.stl` first, because PLA snaps are more brittle than PETG. If you have no filament at all, that's the one thing to buy, and everything else still works on a breadboard meanwhile.

## Optional battery build (only if a boost board turns out to charge)

- That board goes where the IP5306 was (stand, USB-C out the back). Measure it and set `IPM` / `IPM_USB_Z` in `case/pebble_case.scad`.
- Its 5 V out feeds the radar, the amp and the ESP32's 5V pin directly. **No diode, so never plug USB into the ESP32 while the battery is connected.** Flash over OTA, or unplug the battery JST first.
- Power key (if the board has a KEY pad): use a spare **TTP223** (owned) in the rails on the stand's back wall: VCC to battery +, OUT to KEY, bridge its **A** pad so it pulls LOW when touched. Tap the dimple through the plastic: once = on, twice = off. Or tap KEY to GND with a wire, or put an SS12F15 slide switch between KEY and GND and flick it on and back off. KEY carries almost no current, so the 0.3 A rating is fine there. It is *not* fine on the battery line.
- No battery %, because there's no divider. The board's LEDs show the charge level.

## Nice to have later (not needed)
Right-angle USB-C cable (neater), 30 AWG silicone wire (easier harness), an IP5306 board (proper battery build), copper tape (more touch pads).
