# 7. Buy list (missing parts)

Checked against the parts inventory (AliExpress orders, Nov 2 to 10, 2026). Rough AliExpress prices.

## Needed before the build

| # | Part | Qty | ~Price | Why |
|---|---|---|---|---|
| 1 | **IP5306 Type-C charge + 5 V boost module** (2.1 A charge, 2.4 A out) | 2 | $3 | Charges the LiPo and runs the device at the same time. Your 5 V boost boards can't charge. Buy 2: one spare |
| 2 | **Matte black PETG**, 1 kg | 1 | $15 | Case. A few meters of a second color for ears/details is nice |
| 3 | **30 AWG silicone wire** kit (6 colors) | 1 | $5 | Internal harness |
| 4 | **M2 self-tapping screws** kit (M2 × 5/6/8) | 1 | $3 | Lid, sled, board. Magnets work until these arrive |
| 5 | **Resistor kit** (1/4 W, includes 1k, 10k, 100k) | 1 | $3 | Battery divider (2 × 100k), radar series resistor (1k), camera reset pull-up (10k) |
| 6 | **SS34 or 1N5819 Schottky diodes** | 10 | $1 | Stops USB back-feed into the ESP32 5 V pin |
| 7 | **6 × 6 mm tact switches** | 10 | $1 | IP5306 on/off key (your SS12F15 slide switches are only 0.3 A) |
| 8 | **Right-angle USB-C cable** | 2 | $4 | Plugs into the bottom through the stand's channel |

**Subtotal ≈ $35.**

## Nice to have

| Part | Why |
|---|---|
| 470 µF 10 V electrolytic capacitors | Across the amp's 5 V if loud sounds reset the board |
| Kapton tape | Insulating solder joints and the battery |
| Hot glue gun (mini) | Holding display, camera, sensors in place (reversible) |
| Copper tape | Extra touch pads later (TTP223 pads also work through 2 mm plastic) |
| Clear PETG | See-through back lid |

## Already covered, don't buy
- Display, camera, speaker, amp, mic, radar, sensors, touch pads (owned or in transit).
- Battery: the PL103665 3000 mAh fits the case as designed.
- JST 1.25 and PH 2.0 pigtails, magnets, glue, soldering iron, flux (owned).

## Still in transit (needed for full bring-up)
ESP32-S3 N16R8 CAM board, MAX98357A, mic module, LD2410C, AHT20+BMP280, BH1750, TTP223. You can start with the display and case while they arrive.
