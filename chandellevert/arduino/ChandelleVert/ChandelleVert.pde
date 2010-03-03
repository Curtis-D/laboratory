/*
 * ChandelleVert test program
 */

#include <stdlib.h>

const int pin0 = 0;    // RX
const int pin1 = 1;    // TX
const int pin2 = 2;    // digital 
const int pin3 = 3;    // digital (PWM)
const int pin4 = 4;    // digital
const int pin5 = 5;    // digital (PWM)
const int pin6 = 6;    // digital (PWM)
const int pin7 = 7;    // digital
const int pin8 = 8;    // digital (PWM)
const int pin9 = 9;    // digital (PWM)
const int pin10= 10;   // digital (PWM)
const int pin11 = 11;  // digital
const int pin12 = 12;  // digital
const int pin13 = 13;  // digital
const int pin14 = 14;  // analog in 0
const int pin15 = 15;  // analog in 1
const int pin16 = 16;  // analog in 2
const int pin17 = 17;  // analog in 3
const int pin18 = 18;  // analog in 4
const int pin19 = 19;  // analog in 5

const int outPin =  pin13;

const int sensorPin = pin15;
//const int sensorPin = 6;

//const int muxSelectPins1[] = {pin16, pin17, pin18, pin19};
const int firstMuxSelectPin = pin16;
//const int muxSelectPins1[] = {pin2, pin3, pin4, pin5};

const unsigned int REVERSE = false;
//const unsigned int REVERSE = true;

int lineno = 0;

////////////////////////////////////////

#define MUX_LEVELS 1
#if MUX_LEVELS == 1
  #define SELECT_PINS 4
  #define BITS_PER_SAMPLE 16
#elif MUX_LEVELS == 2
  #define SELECT_PINS 8
  #define BITS_PER_SAMPLE 256
#elif MUX_LEVELS == 3
  #define SELECT_PINS 12
  #define BITS_PER_SAMPLE 4096
#endif

#define SAMPLES_PER_CYCLE 1
#define SENSOR_MULTIPLIER 16 // 16 MUXes for 256 sensors
//#define SENSOR_MULTIPLIER 64 // 64 MUXes for 1024 sensors

unsigned char sampleData[BITS_PER_SAMPLE / 8]; 
unsigned char prevSampleData[BITS_PER_SAMPLE / 8];

#define PRETTY_MODE

////////////////////////////////////////

unsigned char muxSelectPins1State[SELECT_PINS];

inline void sampleSensor(unsigned int i)
{
  // Oddly enough, when I took this unnecessaqry assigment out, the sampling
  // rate dropped slightly.
  unsigned int x = !digitalRead(sensorPin);
  // TODO
  sampleData[i / 8] |= (x << (i % 8));
  //if (x) Serial.println("\tGot one!");
  //if (x) { Serial.println((unsigned int) sampleData[i/8]); }
}

int hasChanged;

void advanceSampleData()
{
  hasChanged = false;
  
  unsigned char *cur = sampleData;
  unsigned char *prev = prevSampleData;
  
  while (cur < sampleData + BITS_PER_SAMPLE / 8)
  {
    if (*cur != *prev)
    {
      hasChanged = true;
    }
    
    *prev = *cur;
    *cur = 0;
    
    cur++;
    prev++;
  }
}

inline void setMuxSelectPin(unsigned int j, unsigned int val)
{
  digitalWrite(firstMuxSelectPin + j, REVERSE ? !val : val); 
  muxSelectPins1State[j] = val;
}

void sampleSensors()
{
  for (unsigned int s = 0; s < SAMPLES_PER_CYCLE * SENSOR_MULTIPLIER; s++)
  {
    for (unsigned int k = 0; k < SELECT_PINS; k++)
    {
      setMuxSelectPin(k, false);
    }
  
    unsigned int i = 0;
    //Serial.println("Sampling...");
    while (i < BITS_PER_SAMPLE)
    {
      /*
      Serial.print("\t\t");
      for (int k = 0; k < SELECT_PINS; k++)
      {
        Serial.print(muxSelectPins1State[k]);
      }
      Serial.println("");*/
      
      if (i > 0)
      {
        unsigned int j = 0;
        while (muxSelectPins1State[j])
        {
          setMuxSelectPin(j, false);
          j++;
        } 
        setMuxSelectPin(j, true);
      }
      
      sampleSensor(i);
      i++;
      setMuxSelectPin(0, true);
      sampleSensor(i);
      i++;
    }
  }
}

/*
unsigned int muxSelectPins1StateNew;

inline void setMuxSelectPinNew(unsigned int j)
{
  digitalWrite(muxSelectPins1[j], !REVERSE); 
  muxSelectPins1StateNew |= 1 << j;
}

inline void unsetMuxSelectPinNew(unsigned int j)
{
  digitalWrite(muxSelectPins1[j], REVERSE);
  muxSelectPins1StateNew &= ~(1 << j);
}

void sampleSensorsNew()
{
  for (unsigned int s = 0; s < SAMPLES_PER_CYCLE * SENSOR_MULTIPLIER; s++)
  {
    for (unsigned int k = 0; k < SELECT_PINS; k++)
    {
      unsetMuxSelectPinNew(k);
    }
  
    unsigned int i = 0;
    //Serial.println("Sampling...");
    while (i < BITS_PER_SAMPLE)
    {      
      if (i > 0)
      {
        unsigned int j = 0;
        while ((muxSelectPins1StateNew >> j) & 1)
        {
          unsetMuxSelectPinNew(j);
          j++;
        } 
        setMuxSelectPinNew(j);
      }
      
      sampleSensor(i);
      i++;
      setMuxSelectPinNew(0);
      sampleSensor(i);
      i++;
    }
  }
}
*/

void outputSampleData()
{
#ifdef PRETTY_MODE
  lineno++;

  Serial.print(lineno);
  Serial.print(") ");
  for (unsigned int i = 0; i < BITS_PER_SAMPLE; i++)
  {
    unsigned int b = prevSampleData[i / 8] & (1 << (i % 8));
    Serial.print(b ? 'o' : ' ');
  }
#else
  for (int l = 0; l < BITS_PER_SAMPLE / 8; l++)
  {
    Serial.print(prevSampleData[l]);      
  }
#endif

  Serial.println("");
}

void setup()
{
  Serial.begin(9600);           // set up Serial library at 9600 bps
  pinMode(sensorPin, INPUT);
  pinMode(outPin, OUTPUT);
  
  for (unsigned int j = 0; j < SELECT_PINS; j++)
  {
    pinMode(firstMuxSelectPin + j, OUTPUT);
  }
  
  // Trick to force outputting of an artificial blank sensor map.
  prevSampleData[0] = 1;
}

//#define TIMING_TEST

void loop()
{  
// Current results: around 3500 Hz (at 1 iteration over a single
// 16-pin mux)
#ifdef TIMING_TEST
  unsigned int iters = 100;
  unsigned long before, after;
  before = millis();
  for (unsigned int i = 0; i < iters; i++) {
    advanceSampleData();
    sampleSensors();  
  }
  after = millis();
  Serial.print((1000 * (double) iters) / (double) (after - before));
  Serial.println(" samples per second");
#else
  advanceSampleData();
  
  if (hasChanged)
  {
    outputSampleData();
  }

  sampleSensors();
#endif
}