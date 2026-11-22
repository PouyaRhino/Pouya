// Desk pet bring-up firmware: tests every part one by one.
// Open the serial monitor (115200) and type a letter:
//   s = scan I2C     d = display test   c = camera mirror (any key stops)
//   t = speaker tone m = mic level      r = radar        e = env sensors
//   b = battery      k = touch/button   l = RGB LED      a = run all quick tests
// With nothing typed, the screen shows idle "eyes" that blink and wake
// on presence or touch, which is the start of the pet face.

#include <Arduino.h>
#include <Wire.h>
#include <driver/i2s.h>
#include <esp_camera.h>
#define LGFX_USE_V1
#include <LovyanGFX.hpp>
#include <ld2410.h>
#include <Adafruit_AHTX0.h>
#include <Adafruit_BMP280.h>
#include <BH1750.h>
#include <Adafruit_NeoPixel.h>
#include "pins.h"

// ---------------- display ----------------
// MEASURE: if the picture is shifted or has a noise strip, adjust offsets.
static constexpr int LCD_W = 240, LCD_H = 296, LCD_OFFSET_X = 0, LCD_OFFSET_Y = 12;

class LGFX : public lgfx::LGFX_Device {
  lgfx::Panel_ST7789 panel;
  lgfx::Bus_SPI bus;
  lgfx::Light_PWM light;
 public:
  LGFX() {
    auto b = bus.config();
    b.spi_host = SPI2_HOST; b.spi_mode = 0; b.freq_write = 40000000;
    b.pin_sclk = LCD_SCLK; b.pin_mosi = LCD_MOSI; b.pin_miso = -1; b.pin_dc = LCD_DC;
    b.dma_channel = SPI_DMA_CH_AUTO;
    bus.config(b); panel.setBus(&bus);
    auto p = panel.config();
    p.pin_cs = LCD_CS; p.pin_rst = LCD_RST; p.pin_busy = -1;
    p.panel_width = LCD_W; p.panel_height = LCD_H;
    p.offset_x = LCD_OFFSET_X; p.offset_y = LCD_OFFSET_Y;
    p.invert = true; p.rgb_order = false; p.readable = false;
    panel.config(p);
    auto l = light.config();
    l.pin_bl = LCD_BL; l.freq = 12000; l.pwm_channel = 7;
    light.config(l); panel.setLight(&light);
    setPanel(&panel);
  }
};
static LGFX lcd;

// ---------------- other parts ----------------
static ld2410 radar;
static Adafruit_AHTX0 aht;
static Adafruit_BMP280 bmp;
static BH1750 lux;
static Adafruit_NeoPixel led(1, RGB_LED, NEO_GRB + NEO_KHZ800);
static bool haveAht = false, haveBmp = false, haveLux = false, haveCam = false;

static const int SAMPLE_RATE = 16000;

static void i2sInit() {
  i2s_config_t cfg = {};
  cfg.mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_TX | I2S_MODE_RX);
  cfg.sample_rate = SAMPLE_RATE;
  cfg.bits_per_sample = I2S_BITS_PER_SAMPLE_32BIT;     // INMP441 sends 24 bits in a 32-bit slot
  cfg.channel_format = I2S_CHANNEL_FMT_ONLY_LEFT;      // mic L/R pin tied to GND
  cfg.communication_format = I2S_COMM_FORMAT_STAND_I2S;
  cfg.dma_buf_count = 6; cfg.dma_buf_len = 256;
  cfg.tx_desc_auto_clear = true;
  i2s_driver_install(I2S_NUM_0, &cfg, 0, nullptr);
  i2s_pin_config_t pins = {};
  pins.mck_io_num = I2S_PIN_NO_CHANGE;
  pins.bck_io_num = I2S_BCLK; pins.ws_io_num = I2S_WS;
  pins.data_out_num = I2S_DOUT; pins.data_in_num = I2S_DIN;
  i2s_set_pin(I2S_NUM_0, &pins);
}

static bool camInit() {
  camera_config_t c = {};
  c.pin_pwdn = CAM_PIN_PWDN; c.pin_reset = CAM_PIN_RESET; c.pin_xclk = CAM_PIN_XCLK;
  c.pin_sccb_sda = -1;            // reuse the Wire bus already running on GPIO4/5
  c.pin_sccb_scl = -1;
  c.sccb_i2c_port = 0;
  c.pin_d0 = CAM_PIN_D0; c.pin_d1 = CAM_PIN_D1; c.pin_d2 = CAM_PIN_D2; c.pin_d3 = CAM_PIN_D3;
  c.pin_d4 = CAM_PIN_D4; c.pin_d5 = CAM_PIN_D5; c.pin_d6 = CAM_PIN_D6; c.pin_d7 = CAM_PIN_D7;
  c.pin_vsync = CAM_PIN_VSYNC; c.pin_href = CAM_PIN_HREF; c.pin_pclk = CAM_PIN_PCLK;
  c.xclk_freq_hz = 20000000;
  c.ledc_timer = LEDC_TIMER_1; c.ledc_channel = LEDC_CHANNEL_1;
  c.pixel_format = PIXFORMAT_RGB565;
  c.frame_size = FRAMESIZE_240X240;
  c.fb_count = 2; c.fb_location = CAMERA_FB_IN_PSRAM;
  c.grab_mode = CAMERA_GRAB_LATEST;
  esp_err_t err = esp_camera_init(&c);
  if (err != ESP_OK) { Serial.printf("camera init failed: 0x%x\n", err); return false; }
  sensor_t *s = esp_camera_sensor_get();
  Serial.printf("camera OK, sensor PID 0x%x (OV5640 = 0x5640)\n", s->id.PID);
  return true;
}

// ---------------- tests ----------------
static void i2cScan() {
  Serial.println("I2C scan (expect 0x23 BH1750, 0x38 AHT20, 0x3C OV5640, 0x76/0x77 BMP280):");
  for (uint8_t a = 1; a < 127; a++) {
    Wire.beginTransmission(a);
    if (Wire.endTransmission() == 0) Serial.printf("  found 0x%02X\n", a);
  }
}

static void displayTest() {
  const uint16_t cols[] = {TFT_RED, TFT_GREEN, TFT_BLUE, TFT_WHITE, TFT_BLACK};
  for (auto c : cols) { lcd.fillScreen(c); delay(300); }
  lcd.drawRect(0, 0, lcd.width(), lcd.height(), TFT_YELLOW);   // all 4 edges must be visible
  lcd.setTextColor(TFT_WHITE); lcd.setTextSize(2);
  lcd.setCursor(20, 130); lcd.printf("%dx%d OK", lcd.width(), lcd.height());
  Serial.println("display: yellow frame must touch all 4 edges, else fix LCD_OFFSET_X/Y");
}

static void cameraMirror() {
  if (!haveCam) { Serial.println("camera not available"); return; }
  Serial.println("camera mirror running, send any key to stop");
  lcd.fillScreen(TFT_BLACK);
  uint32_t frames = 0, t0 = millis();
  while (!Serial.available()) {
    camera_fb_t *fb = esp_camera_fb_get();
    if (!fb) continue;
    lcd.pushImage(0, (lcd.height() - 240) / 2, 240, 240, (const lgfx::swap565_t *)fb->buf);
    esp_camera_fb_return(fb);
    frames++;
  }
  Serial.read();
  Serial.printf("%.1f fps\n", frames * 1000.0f / (millis() - t0));
}

// USB-only build: keep vol <= 0.3 so loud peaks stay inside what a USB port can give.
static void playTone(float hz, int ms, float vol = 0.2f) {
  const int n = 256; int32_t buf[n]; size_t w;
  int total = SAMPLE_RATE * ms / 1000; float ph = 0;
  for (int i = 0; i < total; i += n) {
    for (int j = 0; j < n; j++) { buf[j] = (int32_t)(sinf(ph) * vol * 2147483647.0f); ph += 2 * PI * hz / SAMPLE_RATE; }
    i2s_write(I2S_NUM_0, buf, sizeof(buf), &w, portMAX_DELAY);
  }
  i2s_zero_dma_buffer(I2S_NUM_0);
}

static void speakerTest() { Serial.println("speaker: 3 rising beeps"); playTone(440, 200); playTone(660, 200); playTone(880, 300); }

static void micTest() {
  Serial.println("mic: speak or clap for 5 s (bars should move)");
  int32_t buf[256]; size_t r;
  uint32_t t0 = millis();
  while (millis() - t0 < 5000) {
    i2s_read(I2S_NUM_0, buf, sizeof(buf), &r, portMAX_DELAY);
    int64_t sum = 0; int n = r / 4;
    for (int i = 0; i < n; i++) { int32_t s = buf[i] >> 14; sum += (int64_t)s * s; }
    float rms = sqrtf((float)sum / max(n, 1));
    int bars = constrain((int)(20 * log10f(rms + 1)), 0, 60);
    Serial.printf("%6.0f |%.*s\n", rms, bars, "############################################################");
    delay(100);
  }
}

static void radarTest() {
  Serial.println("radar: 5 s of readings");
  uint32_t t0 = millis();
  while (millis() - t0 < 5000) {
    radar.read();
    Serial.printf("OUT=%d  ", digitalRead(RADAR_OUT));
    if (radar.isConnected())
      Serial.printf("moving %d cm (%d)  still %d cm (%d)\n", radar.movingTargetDistance(), radar.movingTargetEnergy(),
                    radar.stationaryTargetDistance(), radar.stationaryTargetEnergy());
    else Serial.println("no UART frames yet (check radar TX->GPIO1 wire, 5 V supply)");
    delay(500);
  }
}

static void envTest() {
  if (haveAht) { sensors_event_t h, t; aht.getEvent(&h, &t); Serial.printf("AHT20 %.1f C  %.0f %%RH\n", t.temperature, h.relative_humidity); }
  else Serial.println("AHT20 missing");
  if (haveBmp) Serial.printf("BMP280 %.1f C  %.1f hPa\n", bmp.readTemperature(), bmp.readPressure() / 100.0f);
  else Serial.println("BMP280 missing");
  if (haveLux) Serial.printf("BH1750 %.0f lx\n", lux.readLightLevel());
  else Serial.println("BH1750 missing");
}

static float batteryVolts() {
  if (VBAT_ADC < 0) return 0;           // USB-only build: no divider fitted
  uint32_t mv = 0;
  for (int i = 0; i < 16; i++) mv += analogReadMilliVolts(VBAT_ADC);
  return mv / 16.0f * 2.0f / 1000.0f;   // 100k/100k divider
}

static void batteryTest() {
  if (VBAT_ADC < 0) { Serial.println("battery: not fitted (USB-powered build)"); return; }
  Serial.printf("battery %.2f V (full 4.2, empty ~3.4)\n", batteryVolts());
}

static void touchTest() {
  Serial.println("touch/button: 5 s, touch the pad and press BOOT");
  uint32_t t0 = millis();
  while (millis() - t0 < 5000) { Serial.printf("touch=%d boot=%d\n", digitalRead(TOUCH_HEAD), !digitalRead(BTN_BOOT)); delay(250); }
}

static void ledTest() {
  const uint32_t c[] = {0x200000, 0x002000, 0x000020, 0};
  for (auto x : c) { led.setPixelColor(0, x); led.show(); delay(400); }
}

// ---------------- idle eyes (first pet face) ----------------
static void drawEyes(int lookX, bool open) {
  static LGFX_Sprite spr(&lcd);
  if (!spr.getBuffer()) { spr.setPsram(true); spr.createSprite(lcd.width(), 160); }
  spr.fillScreen(TFT_BLACK);
  int cy = 80, h = open ? 70 : 8;
  for (int side = -1; side <= 1; side += 2) {
    int cx = lcd.width() / 2 + side * 55 + lookX;
    spr.fillRoundRect(cx - 32, cy - h / 2, 64, h, open ? 18 : 4, TFT_CYAN);
  }
  spr.pushSprite(0, (lcd.height() - 160) / 2);
}

static void idleFace() {
  static uint32_t nextBlink = 0, lastSeen = 0; static int look = 0, target = 0;
  bool present = digitalRead(RADAR_OUT) || digitalRead(TOUCH_HEAD);
  if (present) lastSeen = millis();
  bool awake = millis() - lastSeen < 30000;
  lcd.setBrightness(awake ? 200 : 10);
  if (random(60) == 0) target = random(-20, 21);
  look += (target - look) / 4;
  bool blink = millis() > nextBlink;
  drawEyes(look, !blink);
  if (blink) { delay(120); nextBlink = millis() + random(2000, 6000); }
}

void setup() {
  Serial.begin(115200);
  delay(1500);
  Serial.printf("\nDesk pet bring-up. PSRAM %u bytes, flash %u bytes\n", ESP.getPsramSize(), ESP.getFlashChipSize());
  pinMode(RADAR_OUT, INPUT); pinMode(TOUCH_HEAD, INPUT); pinMode(BTN_BOOT, INPUT_PULLUP);
  if (VBAT_ADC >= 0) analogSetPinAttenuation(VBAT_ADC, ADC_11db);
  led.begin(); led.clear(); led.show();
  lcd.init(); lcd.setBrightness(200); lcd.fillScreen(TFT_BLACK);
  Wire.begin(I2C_SDA, I2C_SCL, 100000);
  haveAht = aht.begin();
  haveBmp = bmp.begin(0x77) || bmp.begin(0x76);
  haveLux = lux.begin(BH1750::CONTINUOUS_HIGH_RES_MODE, 0x23, &Wire);
  haveCam = camInit();
  Serial1.begin(256000, SERIAL_8N1, RADAR_RX, RADAR_TX);
  radar.begin(Serial1, false);
  i2sInit();
  i2cScan();
  Serial.println("type s d c t m r e b k l a");
}

void loop() {
  if (Serial.available()) {
    char ch = Serial.read();
    switch (ch) {
      case 's': i2cScan(); break;
      case 'd': displayTest(); delay(2000); break;
      case 'c': cameraMirror(); break;
      case 't': speakerTest(); break;
      case 'm': micTest(); break;
      case 'r': radarTest(); break;
      case 'e': envTest(); break;
      case 'b': batteryTest(); break;
      case 'k': touchTest(); break;
      case 'l': ledTest(); break;
      case 'a': i2cScan(); envTest(); batteryTest(); displayTest(); speakerTest(); ledTest(); break;
      default: break;
    }
  }
  radar.read();
  idleFace();
  delay(30);
}
