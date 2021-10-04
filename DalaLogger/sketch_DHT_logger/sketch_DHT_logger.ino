/* 水海道一高　データロガー　ワークショップ用スケッチ
 * Arduino Uno(r3) + 
 * DHT11 module + 
 * DS3231 + 
 * microSDcard slot with level shifter
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

  delay(3000);
  
}
