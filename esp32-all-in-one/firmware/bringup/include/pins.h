// Single source of truth for the desk pet pin map.
// Keep in sync with docs/03-pinmap-power.md. Board: ESP32-S3 N16R8.
//
// NEVER use: GPIO19/20 (native USB), GPIO26-32 (flash), GPIO35-37 (octal PSRAM),
//            GPIO45 (VDD_SPI strap, must be LOW at boot), GPIO44 (fed by the USB-UART chip).
#pragma once

// ---- Camera, OV5640 over DVP (same map as ESP32-S3-EYE / S3-CAM boards) ----
#define CAM_PIN_PWDN   -1   // tie PWDN to GND on a bare module
#define CAM_PIN_RESET  -1   // tie RESET to 3V3 via 10k on a bare module
#define CAM_PIN_XCLK   15
#define CAM_PIN_SIOD    4   // shared with the sensor I2C bus
#define CAM_PIN_SIOC    5   // shared with the sensor I2C bus
#define CAM_PIN_D0     11   // Y2
#define CAM_PIN_D1      9   // Y3
#define CAM_PIN_D2      8   // Y4
#define CAM_PIN_D3     10   // Y5
#define CAM_PIN_D4     12   // Y6
#define CAM_PIN_D5     18   // Y7
#define CAM_PIN_D6     17   // Y8
#define CAM_PIN_D7     16   // Y9
#define CAM_PIN_VSYNC   6
#define CAM_PIN_HREF    7
#define CAM_PIN_PCLK   13

// ---- I2C sensors (shared bus with the camera SCCB) ----
// OV5640 0x3C, AHT20 0x38, BMP280 0x77 (or 0x76), BH1750 0x23
#define I2C_SDA         4
#define I2C_SCL         5

// ---- Display, ST7789 SPI ----
#define LCD_SCLK       21
#define LCD_MOSI       47
#define LCD_CS         14
#define LCD_DC         38
#define LCD_BL         39   // PWM backlight
#define LCD_RST        -1   // wire LCD RST to the board's EN/RST pin

// ---- Audio, one I2S port in full duplex ----
#define I2S_BCLK       40   // to MAX98357A BCLK and INMP441 SCK
#define I2S_WS         41   // to MAX98357A LRC  and INMP441 WS
#define I2S_DOUT       42   // to MAX98357A DIN
#define I2S_DIN         2   // from INMP441 SD

// ---- Presence radar, HLK-LD2410C ----
#define RADAR_RX        1   // ESP RX <- LD2410C TX (direct, no resistor needed), UART1, 256000 baud
                            // (was 43 + 1k; 43 is the boot-log TX pin, now left free)
#define RADAR_TX       -1   // not wired: configure the radar with the HLKRadarTool app over BLE
#define RADAR_OUT      46   // presence output, HIGH = someone there

// ---- Inputs / misc ----
#define TOUCH_HEAD      3   // TTP223 OUT (idles LOW, safe for the GPIO3 strap)
#define BTN_BOOT        0   // onboard BOOT button, usable as a user button after boot
#define VBAT_ADC       -1   // no battery sense in the owned-parts build (GPIO1 is the radar RX now)
#define RGB_LED        48   // onboard WS2812 on most N16R8 boards (some use 38: check yours!)
