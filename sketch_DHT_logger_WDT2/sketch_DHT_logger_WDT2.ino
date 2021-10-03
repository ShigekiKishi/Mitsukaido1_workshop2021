/* 水海道一高　データロガー　ワークショップ用スケッチ
 * Arduino Uno(r3) + 
 * DHT11 module + 
 * DS3231 + 
 * microSDcard slot with level shifter +
 * delayWatchDogTimer 2
 */

// DHT11
#include <Adafruit_Sensor.h>
#include <DHT.h>
#include <DHT_U.h>

#define DHTPIN 2     // DHT11 module serial trans.
#define DHTTYPE    DHT11     // DHT 11
DHT_Unified dht(DHTPIN, DHTTYPE);
sensor_t sensor; //
sensors_event_t event_T;
sensors_event_t event_H;
uint32_t delayMS;

// microSD card slot
#include <SPI.h>
#include <SD.h>
File dfile;

// RTC DS3231
#include <Wire.h>
#include "RTClib.h"
RTC_DS3231 rtc;

// delay WatchDogTimer 2 省エネタイマー
#include <avr/sleep.h> 
#include <avr/wdt.h>  
#include <avr/power.h>


void setup() {
  Serial.begin(9600);
  // Initialize device.
  Wire.begin();
  rtc.begin();
  dht.begin();
  SD.begin(10); //No. of chip select
  dfile = SD.open("test.txt", FILE_WRITE);
  if (dfile) {
    Serial.println("file in microSD can be opened");
    dfile.close();
  } else {
    Serial.println("error opening file in microSD");
  }
  
  // Set delay between sensor readings based on sensor details.

  dht.temperature().getSensor(&sensor);
  dht.humidity().getSensor(&sensor);
  delayMS = sensor.min_delay / 1000;
}

void loop() {
  // Delay between measurements.
  delay(delayMS);
  // Get current time from DS3231
  DateTime now = rtc.now();
   
  // Get temperature from DHT11
  dht.temperature().getEvent(&event_T);
  // Get humidity 
  dht.humidity().getEvent(&event_H);

  //show data on serial window
  Serial.print(now.hour(), DEC);
  Serial.print(':');
  Serial.print(now.minute(), DEC);
  Serial.print(':');
  Serial.print(now.second(), DEC);
  Serial.print("\t"); 
  Serial.print(F("Temp: ")); // F() F macro, don't use SRAM
  Serial.print(event_T.temperature);
  Serial.print(F("°C"));
  Serial.print("\t");
  Serial.print(F("Humidity: "));
  Serial.print(event_H.relative_humidity);
  Serial.print(F("%"));
  Serial.print("\n");

  // recording data on microSD card
  dfile = SD.open("test.txt", FILE_WRITE);
  dfile.print(now.hour(), DEC);
  dfile.print(':');
  dfile.print(now.minute(), DEC);
  dfile.print(':');
  dfile.print(now.second(), DEC);
  dfile.print("\t");    
  dfile.print(F("Temp: "));
  dfile.print(event_T.temperature);
  dfile.print(F(" °C"));
  dfile.print("\t");
  dfile.print(F("Humid: "));
  dfile.print(event_H.relative_humidity);
  dfile.print(F(" %"));
  dfile.print("\n");
  dfile.close();

  delayWDT2(8);

//  もっと長い間隔でスリープさせる。
//  for (int i=0; i <= 200; i++){
//      delayWDT2(9);
//   }
  
}

  // 引数はWDTCSRにセットするWDP0-WDP3の値。設定値と動作時間は概略下記
  // 0=16ms, 1=32ms, 2=64ms, 3=128ms, 4=250ms, 5=500ms
  // 6=1sec, 7=2sec, 8=4sec, 9=8sec
void delayWDT2(unsigned long t) {       // パワーダウンモードでdelayを実行
  // 引数はWDTCSRにセットするWDP0-WDP3の値。設定値と動作時間は概略下記
  // 0=16ms, 1=32ms, 2=64ms, 3=128ms, 4=250ms, 5=500ms
  // 6=1sec, 7=2sec, 8=4sec, 9=8sec  
  Serial.flush();                       // シリアルバッファが空になるまで待つ
  delayWDT_setup(t);                    // ウォッチドッグタイマー割り込み条件設定
 
  // ADCを停止（消費電流 147→27μA）
  ADCSRA &= ~(1 << ADEN);
 
  set_sleep_mode(SLEEP_MODE_PWR_DOWN);  // パワーダウンモード指定
  sleep_enable();
 
  // BODを停止（消費電流 27→6.5μA）
  MCUCR |= (1 << BODSE) | (1 << BODS);   // MCUCRのBODSとBODSEに1をセット
  MCUCR = (MCUCR & ~(1 << BODSE)) | (1 << BODS);  // すぐに（4クロック以内）BODSSEを0, BODSを1に設定
 
  asm("sleep");                         // 3クロック以内にスリープ sleep_mode();では間に合わなかった
 
  sleep_disable();                      // WDTがタイムアップでここから動作再開
  ADCSRA |= (1 << ADEN);                // ADCの電源をON（BODはハードウエアで自動再開される）
}
 
void delayWDT_setup(unsigned int ii) {  // ウォッチドッグタイマーをセット。

  byte bb;
  if (ii > 9 ) {                        // 変な値を排除
    ii = 9;
  }
  bb = ii & 7;                          // 下位3ビットをbbに
  if (ii > 7) {                         // 7以上（7.8,9）なら
    bb |= (1 << 5);                     // bbの5ビット目(WDP3)を1にする
  }
  bb |= ( 1 << WDCE );
 
  MCUSR &= ~(1 << WDRF);                // MCU Status Reg. Watchdog Reset Flag ->0
  // start timed sequence
  WDTCSR |= (1 << WDCE) | (1 << WDE);   // ウォッチドッグ変更許可（WDCEは4サイクルで自動リセット）
  // set new watchdog timeout value
  WDTCSR = bb;                          // 制御レジスタを設定
  WDTCSR |= _BV(WDIE);
}
 
ISR(WDT_vect) {                         // WDTがタイムアップした時に実行される処理
  //  wdt_cycle++;                      // 必要ならコメントアウトを外す
}
