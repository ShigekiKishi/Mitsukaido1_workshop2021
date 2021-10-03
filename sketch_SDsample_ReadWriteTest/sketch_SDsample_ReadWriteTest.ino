/*
   SD card attached to SPI bus as follows:
 ** MOSI - pin 11
 ** MISO - pin 12
 ** CLK - pin 13
 ** CS - pin 10 (for MKRZero SD: SDCARD_SS_PIN)
*/

#include <SPI.h>
#include <SD.h>

File dfile;

void setup() {
  
  // Open serial communications and wait for port to open:
  Serial.begin(9600);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }


  Serial.print("Initializing SD card...");

  if (!SD.begin(10)) { // No. of chipselect
    Serial.println("initialization failed!");
    while (1);
  }
  Serial.println("initialization done.");

  // open the file. note that only one file can be open at a time,
  // so you have to close this one before opening another.
  dfile = SD.open("test.txt", FILE_WRITE);

  // if the file opened okay, write to it:
  if (dfile) {
    Serial.print("Writing to test.txt...");
    dfile.println("testing 1, 2, 3.");
    // close the file:
    dfile.close();
    Serial.println("done.");
  } else {
    // if the file didn't open, print an error:
    Serial.println("error opening test.txt");
  }
    
}

void loop() {
  // write "hello world" on micro SD card every 1 sec.
  dfile = SD.open("test.txt", FILE_WRITE);
  dfile.println("Hello World!");

  // read from the file until there's nothing else in it:
  if (dfile.size() > 0) {
    Serial.println("OK. written on SD!");
   }else {
    //print an error:
    Serial.println("error: opening test.txt");
  }
  // close the file:
  dfile.close();

  delay(1000);
}
