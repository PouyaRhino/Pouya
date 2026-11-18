# 2. Recommended concept: "Desk Buddy"

A palm-sized pet that lives next to your monitor. Its face is the screen: two big animated eyes. It knows when you sit down (radar), notices the room (temperature, humidity, pressure, light), reacts to head pats (touch), talks and listens (speaker + mic, AI voice), and can look (camera).

| | |
|---|---|
| Size | 62 × 96 × 47 mm, plus a 12 mm tilt stand |
| Main board | ESP32-S3 N16R8 CAM board (camera power built in) |
| Face | Estardyn 2.01" 240×296 TFT (1.69" is a drop-in option in the CAD) |
| Senses | OV5640 camera, LD2410C presence radar, INMP441 mic, AHT20+BMP280, BH1750, TTP223 head-pat |
| Voice | MAX98357A + 2535 4 Ω 3 W speaker |
| Power | 3000 mAh LiPo + IP5306 USB-C charger, ~6 h awake on battery, lives on USB at the desk |
| Firmware | Stage 1 bring-up and Stage 2 pet in PlatformIO/Arduino, Stage 3 AI voice on XiaoZhi (ESP-IDF) |

**Why this concept:** every part you bought gets a job, it needs no moving parts, and it can be built in stages where each stage is already fun (face → moods → voice → vision).

**Day in the life:**
- 8:55 you sit down → it yawns, eyes open, "morning!" and shows the time and room temperature.
- 10:00 you've sat for 50 min → it starts pointing at you: "stretch!"
- 13:00 lights dim → droopy eyes: "it's dark, turn a light on?"
- "Hey buddy, what's on my desk?" → it takes a photo and answers.
- 18:30 you leave → eyes close, screen off, it sleeps.
