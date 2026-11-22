# 1. Research: similar builds and the best ideas

Searched Nov 18, 2026 across GitHub, Hackster/Instructables, Hackaday, MakerWorld, Circuit Digest, Espressif docs and forums, and the Home Assistant community.

## Similar projects worth studying

| Project | What it is | Why it matters for us |
|---|---|---|
| [XiaoZhi ESP32 (78/xiaozhi-esp32)](https://github.com/78/xiaozhi-esp32) | Open-source ESP32-S3 AI voice chatbot: offline wake word, cloud LLM, MCP tools, LVGL "emoji" face, camera support on some boards | The fastest way to a real voice assistant on our exact chip. Has a [custom board guide](https://raw.githubusercontent.com/78/xiaozhi-esp32/main/docs/custom-board.md). Huge community, many breadboard kits use INMP441 + MAX98357A like ours |
| [Keyestudio KS5028 XiaoZhi camera kit](https://docs.keyestudio.com/projects/KS5028/en/latest/s3cam.html) | Commercial DIY kit: S3 + camera + XiaoZhi | Proves the S3-CAM + XiaoZhi + "what do you see?" combo works |
| [DhamuVkl/ESP32S3-AI-Voice-Assistant](https://github.com/DhamuVkl/ESP32S3-AI-Voice-Assistant) | DIY S3 voice assistant | Simple reference wiring for I2S mic + amp |
| [Exposed-hardware S3 AI assistant (Hackster)](https://www.hackster.io/news/an-ai-assistant-that-wants-you-to-see-what-makes-it-tick-3ecab6e1ea38) | XiaoZhi build in a see-through case | Case idea: a clear back lid looks great |
| [StackChan (M5Stack)](https://docs.m5stack.com/en/StackChan) and [dotty-stackchan](https://brettkinny.github.io/dotty-stackchan/1.3/hardware-support/) | The classic "face on a screen" desk companion | Best reference for a cute, simple face that feels alive |
| [Sentio on ESP32-S3-Box-3](https://circuitdigest.com/microcontroller-projects/sentio-a-cute-companion-robot-esp32-s3-box-3) ([code](https://github.com/Akram1966/Sentio)) | S3-Box companion with moods | Mood state machine to copy |
| [TN-24 V2.0 desktop companion](https://www.instructables.com/TN-24-V20-Cute-Desktop-Companion-Robot) | 3D-printed companion with full instructions | Good enclosure and assembly photos |
| [Deskimon](https://circuitdigest.com/news/deskimon-the-interactive-3d-printed-desk-robot-with-esp32-s3) | 3D-printed S3 desk robot | Interaction ideas |
| [DiGi Hami on MakerWorld](https://makerworld.com/en/models/3096322) | Printable "desk hamster" | Printable cute shell inspiration |
| [XIAO S3 tiny desk pet](https://www.hackster.io/pradeeplogu0/building-a-tiny-desktop-toy-pet-with-xiao-esp32-s3-justway-518845) | Very small pet on the XIAO Sense (which you also own) | A pocket version later |
| [element14 multi-function desk pet](https://community.element14.com/challenges-projects/element14-presents/project-videos/w/documents/72069/creating-a-multi-function-esp32-desk-pet-with-custom-pcb-and-audio-processing) | Desk pet with audio processing and a custom PCB | Where this build can go in v2 (custom PCB) |
| [Will Cogley's Coglet](https://www.hackster.io/news/will-cogley-s-coglet-is-a-3d-printable-expressive-twin-camera-companion-bot-5cc02a04b718) | Expressive twin-camera bot | Expression design |
| [LD2410 + ESPHome tips (HA community)](https://community.home-assistant.io/t/ld2410-esphome-tips/477058/614), [atomic14 LD2410 notes](https://www.atomic14.com/esp32/sensors/hlk-ld2410/) | mmWave presence in practice | Tuning gates, mounting behind plastic |

Libraries/frameworks used by these builds (well known, not re-checked today): Espressif [esp32-camera](https://github.com/espressif/esp32-camera), [ESP-SR](https://github.com/espressif/esp-sr) (wake word, offline commands), [ESP-WHO](https://github.com/espressif/esp-who) (face detection), [LVGL](https://lvgl.io), [LovyanGFX](https://github.com/lovyan03/LovyanGFX), [FluxGarage RoboEyes](https://github.com/FluxGarage/RoboEyes) (animated eyes).

## Ranked shortlist of features

Ranked by "fun per hour of work" with the parts you own. ✅ = in the v1 plan.

| # | Feature | Parts | Effort | Notes |
|---|---|---|---|---|
| 1 ✅ | **Animated eyes face** that blinks, looks around and has moods | display | Easy | The heart of a desk pet. Already in the bring-up firmware as a starting point |
| 2 ✅ | **Wakes up when you sit down, sleeps when you leave** | LD2410C | Easy | Greets you, dims the screen, saves battery. Radar sees through the PETG face |
| 3 ✅ | **Head-pat touch** → happy face + purr sound | TTP223, speaker | Easy | Single most "alive" feeling interaction |
| 4 ✅ | **Room mood**: hot → sweating, dark → sleepy, humid → foggy eyes | AHT20, BMP280, BH1750 | Easy | Turns boring sensors into personality |
| 5 ✅ | **Desk health coach**: "you've sat 50 min, stretch!", too-dark-for-reading warning | LD2410C, BH1750 | Easy | Practical and uses the radar's still-person detection |
| 6 ✅ | **AI voice chat** with wake word (XiaoZhi) | mic, amp, Wi-Fi | Medium | Biggest wow. On-device wake word, LLM in the cloud |
| 7 | **"What do you see?"** camera question to a vision LLM | OV5640 | Medium | XiaoZhi already supports camera on some boards |
| 8 | **Eyes follow your face** (ESP-WHO face detection) | OV5640 | Medium-hard | Very cute; run at low fps to save power |
| 9 | **Home Assistant sensor** (presence, temp, light) over MQTT/ESPHome | Wi-Fi | Medium | Makes the pet useful for room automation |
| 10 | Clock, weather, Pomodoro focus timer on the face | display, Wi-Fi | Easy | Good "idle" screens |
| 11 | Away-mode snapshot to your phone when someone appears | camera, radar | Medium | Privacy: off by default, only with a clear on-screen indicator |

Skipped for now: moving parts (no servos owned), CO2 sensing (no sensor owned).

## Key findings that shaped the design

- **Use the "S3 N16R8 CAM" board you have on order as the main board.** A bare OV5640 module needs 2.8 V and 1.5 V rails besides 3.3 V. The CAM dev board already has them; the 24-pin FPC adapter may not. Both use the same standard camera pins, so the pin map works either way.
- **N16R8 pins 35, 36, 37 belong to the octal PSRAM** ([esp32.com](https://esp32.com/viewtopic.php?p=133867), [pinouts](https://github.com/mcuw/esp32-s3-pinouts)), and the camera takes 14 pins. That leaves very few spare GPIOs, so audio shares one I2S port (mic and amp) and the sensors share the camera's I2C bus.
- **IP5306 is the right charger here** ([done.land notes](https://done.land/components/power/powersupplies/battery/chargers/charge-discharge/ip5306/)): charges at up to 2.1 A, gives 5 V out at up to 2.4 A and powers the device while charging. One board replaces "TP4056 + boost". Gotcha: it switches its 5 V off when the load is under about 45 to 50 mA for ~32 s. Our device draws more than that while awake, and the auto-off conveniently acts as "power off" in deep sleep.
- **LD2410C** needs 5 V, outputs 3.3 V logic, 256000 baud UART, 16 x 22 mm ([espboards](https://www.espboards.dev/sensors/ld2410c/)). It works through thin plastic; keep metal and the speaker magnet out of its front.
- **Camera FOV 120°** needs a cone-shaped window or the case edge shows in the picture. The case has one.
