/*
 * Simulate SYM-1's cassette format, so as to download programs into a SYM-1
 *  via the Arduino
 */

const int outPin = 8;  // Digital pin 8
const byte sync_char = 0x16;
const byte start_char = 0x2A;
const byte end_char = 0x2F;
const byte end_of_tape = 0x04;
const unsigned int start_address = 0x200;
const int delay_period_1 = 255;   // 255 uSecs -- SYM HS cassette timing
const int delay_period_2 = 450;   // 450 uSecs

unsigned int end_address;
byte sizeLo = 0;
int sizeHi = 0;
int datasize = 0;

int checksum = 0;
int dataBytePointer = 0;
int shiftCount = 0;


void setup() {
  // set the digital pin as output:
  pinMode(outPin, OUTPUT);
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.begin(9600);   // open USB port
}

void loop() {
  // Get size bytes
  sizeLo = getSerialByte();  
  sizeHi = getSerialByte();
  datasize = ((int)sizeHi << 8) + sizeLo;
  end_address = start_address + datasize;

  byte dataBlock[datasize];

  // Get the data
  for (int i = 0; i < datasize; i++) {
    dataBlock[i] = getSerialByte();
  }

  // Write 256 sync characters
  for( int i=0; i<256; i++ ) {
    writeByteNoChecksum(sync_char);
  }
  // Write start char
  writeByteNoChecksum(start_char);
  // Write i.d.
  writeByteNoChecksum(1);

  // Write starting address
  writeWord(start_address);
  
  // Write end address
  writeWord(end_address);

  // Write the data block
  for (int i=0; i<datasize; i++) {
    writeByte(dataBlock[i]);
  }

  // Write 'End of data'
  writeByteNoChecksum(end_char);

  // Write checksum word
  writeWordNoChecksum(checksum);
  
  // Write 2 'End of tape' bytes
  writeByteNoChecksum(end_of_tape);
  writeByteNoChecksum(end_of_tape);

  digitalWrite(outPin, LOW);
}

void writeWord(unsigned int word) {
  writeByte(lowByte(word));
  writeByte(highByte(word));
}

void writeWordNoChecksum(int word) {
  writeByteNoChecksum(lowByte(word));
  writeByteNoChecksum(highByte(word));
}

void writeByte(byte inByte) {
  checksum += inByte;
  checksum &= 0xFFFF;   // modulus 16-bits
  writeBoth(inByte);
}

void writeByteNoChecksum(byte inByte) {
  writeBoth(inByte);
}

void writeBoth(byte inByte) {
  // 8 data bits, plus one start bit (equal to 0)
  for (int i=0; i<8; i++ ) {
    writeBit( inByte & B00000001 );
    inByte = inByte >> 1;
  }
  writeBit( 0 );    // Start bit
}

void writeBit( bool notZero ) {
  toggleOutput();
  delayMicroseconds(delay_period_1);
  if (notZero) {
    toggleOutput();
  }
  delayMicroseconds(delay_period_2);
}

void toggleOutput() {
  digitalWrite(outPin, !digitalRead(outPin));
}

byte getSerialByte() {
  while (!Serial.available());
  return Serial.read(); 
}

void signalWithLED() {
  digitalWrite(LED_BUILTIN, HIGH);
  delay(500);
  digitalWrite(LED_BUILTIN, LOW);
  delay(500);
  digitalWrite(LED_BUILTIN, HIGH);
  delay(500);
  digitalWrite(LED_BUILTIN, LOW);
  delay(500);
  digitalWrite(LED_BUILTIN, HIGH);
  delay(250);
  digitalWrite(LED_BUILTIN, LOW);
  delay(250);
  digitalWrite(LED_BUILTIN, HIGH);
  delay(250);
  digitalWrite(LED_BUILTIN, LOW);
  delay(250);
}
