# 6. Firmware plan

Three stages, each one usable on its own.

## Stage 1: bring-up (done, in this folder)
[`firmware/bringup`](../firmware/bringup): PlatformIO + Arduino-ESP32. Tests every part from a serial menu and shows blinking eyes that wake on presence or touch. Pins in `include/pins.h`.

> Not compiled yet: the cloud machine that wrote it couldn't reach the PlatformIO registry. First build on your PC may need a small fix or two; send me the error if so.

## Stage 2: the pet (PlatformIO, Arduino) — about 2 to 3 weekends

Grow the bring-up code into `firmware/pet`:

```
src/
  main.cpp          setup + task start
  face/             eye renderer (sprites in PSRAM, 30 fps), expressions, transitions
  mood.cpp          state machine (below)
  sensors.cpp       task: AHT20/BMP280/BH1750 every 10 s, radar every 100 ms, touch
  sound.cpp         WAV clips from LittleFS through I2S (purr, beep, yawn)
  net.cpp           Wi-Fi manager (captive portal setup), NTP clock, OTA, MQTT
data/               sounds and images for LittleFS
```

**Mood state machine**

| State | Enters when | Face / sound |
|---|---|---|
| Sleeping | radar: nobody for 2 min | Screen dim, slow "zzz", Wi-Fi light sleep |
| Waking | radar: someone arrives | Yawn, eyes open, "welcome back" chirp |
| Idle | someone present | Blink, look around, clock under the eyes |
| Happy | head pat (touch) | Squint eyes, purr sound, LED warm |
| Hot / Cold | AHT20 > 28 °C or < 17 °C | Sweat drop / shiver |
| Sleepy | BH1750 < 30 lx while present | Droopy eyes, "too dark to read" hint |
| Nagging | radar: sitting > 50 min | Points at you, "stretch!" every 5 min until you leave |

Libraries: LovyanGFX (display), [RoboEyes](https://github.com/FluxGarage/RoboEyes) as a reference for eye shapes, ld2410, Adafruit AHTX0/BMP280, BH1750, PubSubClient (MQTT), ArduinoOTA.

**Home Assistant (optional):** publish presence, temperature, humidity, pressure, lux over MQTT with HA discovery topics, so the pet also becomes a room sensor.

## Stage 3: AI voice (ESP-IDF, XiaoZhi) — about 1 to 2 weekends

The best open-source voice stack for this chip is [XiaoZhi ESP32](https://github.com/78/xiaozhi-esp32): on-device wake word (ESP-SR), streaming to a server that runs speech-to-text, an LLM and text-to-speech, an LVGL face, MCP tools so the LLM can call device functions, and camera support for "what do you see?".

Plan:
1. Clone XiaoZhi, add a **new** board folder `main/boards/deskpet-s3/` (never edit an existing board: OTA could overwrite you), following their [custom board guide](https://raw.githubusercontent.com/78/xiaozhi-esp32/main/docs/custom-board.md).
2. Start from their breadboard board (INMP441 + MAX98357A + ST7789 SPI LCD), then set our pins in `config.h`. Use their duplex no-codec I2S class because mic and amp share BCLK/WS here (check the class name in their `audio_codecs` folder, it has changed between versions).
3. Add the OV5640 with our camera pins.
4. Register MCP tools: `get_room_climate` (AHT20/BMP280), `get_light_level`, `is_someone_here` (radar), `set_face_mood`, `take_photo`. Then "is it warm in here?" just works.
5. Server: start with the free public XiaoZhi server to test. For privacy, self-host their open-source server later and point it at an LLM of your choice (Claude works through it).
6. Build with ESP-IDF (`idf.py build`) or their `scripts/build.py`. This stage is ESP-IDF rather than PlatformIO because XiaoZhi is an ESP-IDF project.

**Merging stage 2 and 3:** either port the mood state machine into XiaoZhi (it already has a display and emotions, so this is the less work path), or keep two firmwares and switch with OTA. Recommendation: port, so one firmware does everything.

## Power-saving rules (all stages)
- Camera off (`esp_camera_deinit` or PWDN) unless asked for a photo.
- Backlight follows presence: 0 when nobody is there.
- Wi-Fi modem sleep while idle; wake word keeps the mic and ESP-SR running only when someone is present (radar gates it, which also means fewer false wake-ups).

## Privacy rules
- Camera and mic indicators: draw a small red dot on screen whenever the camera or mic stream is active.
- No photos leave the device unless you asked for one.
