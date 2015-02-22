/* Sweep
 by BARRAGAN <http://barraganstudio.com> 
 This example code is in the public domain.

 modified 8 Nov 2013
 by Scott Fitzgerald
 http://arduino.cc/en/Tutorial/Sweep
*/ 

#include <Servo.h> 
 
//Servo[5] fingers;  // create servo object to control a servo 
                // twelve servo objects can be created on most boards
                
Servo thumb;
Servo index;
Servo middle;
Servo ring;
Servo pinkie;

float thumbMin = 20;  //THUMB
float thumbMax = 160;
float thumbPos = thumbMin;

float indexMin = 20;  //INDEX
float indexMax = 160;
float indexPos = indexMin;

float middleMin = 0;   //MIDDLE
float middleMax = 175;
float middlePos = middleMin;

float ringMin = 30;   //RING
float ringMax = 160;
float ringPos = ringMin;

float pinkieMin = 40;   //PINKIE
float pinkieMax = 160;
float pinkiePos = pinkieMin;

int low = 20;
int high = 160;
int delayy = 10;
 
float pos = 0;    // variable to store the servo position 
 
void setup() 
{ 
  
  thumb.attach(2);
  index.attach(3);
  middle.attach(4);
  ring.attach(5);
  pinkie.attach(6);
  pinMode(9, INPUT);
  Serial.begin(9600);
//  for(int i = 0; i < 5; i++){
//    fingers[i].attach(i+2);  // attaches the servo on pin 9 to the servo object 
//  }
  
} 
 
void loop() 
{ 
//  fadeInFadeOut();
  thumbsUp(thumbPos, indexPos, middlePos, ringPos, pinkiePos);
  delay(1000);
  openHand(thumbPos, indexPos, middlePos, ringPos, pinkiePos);
  delay(1000);
  closeFist(thumbPos, indexPos, middlePos, ringPos, pinkiePos);
  delay(1000);
  flipOff(thumbPos, indexPos, middlePos, ringPos, pinkiePos);
  delay(1000);
  iLoveYou(thumbPos, indexPos, middlePos, ringPos, pinkiePos);
  delay(1000);
  shocker(thumbPos, indexPos, middlePos, ringPos, pinkiePos);
  delay(1000);
  peace(thumbPos, indexPos, middlePos, ringPos, pinkiePos);
  delay(5000);

//  if(digitalRead(9)==HIGH){
//    iLoveYou(thumbPos, indexPos, middlePos, ringPos, pinkiePos);
//  }
//  if(digitalRead(9)==LOW){
//    openHand(thumbPos, indexPos, middlePos, ringPos, pinkiePos);
//  }
} 

//      int Ichan = 4 - 1;
//      float myAverage = 0.0;
//      for(int i = data_forDisplay_uV[Ichan].length - 50; i < data_forDisplay_uV[Ichan].length; i++){
//         myAverage += abs(data_forDisplay_uV[Ichan][i]);
//      }
//      myAverage = myAverage / 50.0; //finishing the average
//      
//      if(myAverage >= 50 && isTriggered == false){
//        isTriggered = true;
//        println("SENDING O!");
//        serial_openBCI.write('o'); 
//      }
//      if(myAverage <= 30 && isTriggered == true){
//        isTriggered = false;
//        println("SENDING G!");
//        serial_openBCI.write('g'); 
//      }   

void thumbsUp(float _thumbStart, float _indexStart, float _middleStart, float _ringStart, float _pinkieStart){
  for(float i = 0; i <= 1.0; i+= .01){
    thumbPos = _thumbStart + (thumbMin - _thumbStart)*(i/1.0);
    indexPos = _indexStart + (indexMax - _indexStart)*(i/1.0);
    middlePos = _middleStart + (middleMax - _middleStart)*(i/1.0); 
    ringPos = _ringStart + (ringMax - _ringStart)*(i/1.0);
    pinkiePos = _pinkieStart + (pinkieMax - _pinkieStart)*(i/1.0);
    
//    Serial.println("---");
//    Serial.println(thumbPos);
//    Serial.println(indexPos);
//    Serial.println(middlePos);
//    Serial.println(ringPos);
//    Serial.println(pinkiePos);
    
    thumb.write(thumbPos);
    index.write(indexPos);
    middle.write(middlePos);
    ring.write(ringPos);
    pinkie.write(pinkiePos);
    
    delay(delayy); 
  }
}

void openHand(float _thumbStart, float _indexStart, float _middleStart, float _ringStart, float _pinkieStart){
  for(float i = 0; i <= 1.0; i+= .01){
    thumbPos = _thumbStart + (thumbMin - _thumbStart)*(i/1.0);
    indexPos = _indexStart + (indexMin - _indexStart)*(i/1.0);
    middlePos = _middleStart + (middleMin - _middleStart)*(i/1.0); 
    ringPos = _ringStart + (ringMin - _ringStart)*(i/1.0);
    pinkiePos = _pinkieStart + (pinkieMin - _pinkieStart)*(i/1.0);
    
    thumb.write(thumbPos);
    index.write(indexPos);
    middle.write(middlePos);
    ring.write(ringPos);
    pinkie.write(pinkiePos);
    
    delay(delayy); 
  }
}

void closeFist(float _thumbStart, float _indexStart, float _middleStart, float _ringStart, float _pinkieStart){
  for(float i = 0; i <= 1.0; i+= .01){
    thumbPos = _thumbStart + (thumbMax - _thumbStart)*(i/1.0);
    indexPos = _indexStart + (indexMax - _indexStart)*(i/1.0);
    middlePos = _middleStart + (middleMax - _middleStart)*(i/1.0); 
    ringPos = _ringStart + (ringMax - _ringStart)*(i/1.0);
    pinkiePos = _pinkieStart + (pinkieMax - _pinkieStart)*(i/1.0);
    
    thumb.write(thumbPos);
    index.write(indexPos);
    middle.write(middlePos);
    ring.write(ringPos);
    pinkie.write(pinkiePos);
    
    delay(delayy); 
  }
}

void flipOff(float _thumbStart, float _indexStart, float _middleStart, float _ringStart, float _pinkieStart){
  for(float i = 0; i <= 1.0; i+= .01){
    thumbPos = _thumbStart + (thumbMin - _thumbStart)*(i/1.0);
    indexPos = _indexStart + (indexMax - _indexStart)*(i/1.0);
    middlePos = _middleStart + (middleMin - _middleStart)*(i/1.0); 
    ringPos = _ringStart + (ringMax - _ringStart)*(i/1.0);
    pinkiePos = _pinkieStart + (pinkieMax - _pinkieStart)*(i/1.0);
    
    thumb.write(thumbPos);
    index.write(indexPos);
    middle.write(middlePos);
    ring.write(ringPos);
    pinkie.write(pinkiePos);
    
    delay(delayy); 
  }
}

void iLoveYou(float _thumbStart, float _indexStart, float _middleStart, float _ringStart, float _pinkieStart){
  for(float i = 0; i <= 1.0; i+= .01){
    thumbPos = _thumbStart + (thumbMin - _thumbStart)*(i/1.0);
    indexPos = _indexStart + (indexMin - _indexStart)*(i/1.0);
    middlePos = _middleStart + (middleMax - _middleStart)*(i/1.0); 
    ringPos = _ringStart + (ringMax - _ringStart)*(i/1.0);
    pinkiePos = _pinkieStart + (pinkieMin - _pinkieStart)*(i/1.0);
    
    thumb.write(thumbPos);
    index.write(indexPos);
    middle.write(middlePos);
    ring.write(ringPos);
    pinkie.write(pinkiePos);
    
    delay(delayy); 
  }
}

void shocker(float _thumbStart, float _indexStart, float _middleStart, float _ringStart, float _pinkieStart){
  for(float i = 0; i <= 1.0; i+= .01){
    thumbPos = _thumbStart + (thumbMin - _thumbStart)*(i/1.0);
    indexPos = _indexStart + (indexMin - _indexStart)*(i/1.0);
    middlePos = _middleStart + (middleMin - _middleStart)*(i/1.0); 
    ringPos = _ringStart + (ringMax - _ringStart)*(i/1.0);
    pinkiePos = _pinkieStart + (pinkieMin - _pinkieStart)*(i/1.0);
    
    thumb.write(thumbPos);
    index.write(indexPos);
    middle.write(middlePos);
    ring.write(ringPos);
    pinkie.write(pinkiePos);
    
    delay(delayy); 
  }
}

void peace(float _thumbStart, float _indexStart, float _middleStart, float _ringStart, float _pinkieStart){
  for(float i = 0; i <= 1.0; i+= .01){
    thumbPos = _thumbStart + (thumbMax - _thumbStart)*(i/1.0);
    indexPos = _indexStart + (indexMin - _indexStart)*(i/1.0);
    middlePos = _middleStart + (middleMin - _middleStart)*(i/1.0); 
    ringPos = _ringStart + (ringMax - _ringStart)*(i/1.0);
    pinkiePos = _pinkieStart + (pinkieMax - _pinkieStart)*(i/1.0);
    
    thumb.write(thumbPos);
    index.write(indexPos);
    middle.write(middlePos);
    ring.write(ringPos);
    pinkie.write(pinkiePos);
    
    delay(delayy); 
  }
}

void fadeInFadeOut(){
  for(pos = 0; pos <= 1.0; pos += .01) // goes from 0 degrees to 180 degrees 
  {                                  // in steps of 1 degree 
    thumb.write(thumbMin + (thumbMax-thumbMin)*(float(pos)/1));              // tell servo to go to position in variable 'pos' 
    index.write(indexMin + (indexMax-indexMin)*(float(pos)/1)); 
    middle.write(middleMin + (middleMax-middleMin)*(float(pos)/1));  
    ring.write(ringMin + (ringMax-ringMin)*(float(pos)/1)); 
    pinkie.write(pinkieMin + (pinkieMax-pinkieMin)*(float(pos)/1)); 
    delay(delayy);                       // waits 15ms for the servo to reach the position 
  } 
  for(pos = 1; pos>=0; pos-=.01)     // goes from 180 degrees to 0 degrees 
  {                                
    thumb.write(thumbMin + (thumbMax-thumbMin)*(float(pos)/1));              // tell servo to go to position in variable 'pos' 
    index.write(indexMin + (indexMax-indexMin)*(float(pos)/1)); 
    middle.write(middleMin + (middleMax-middleMin)*(float(pos)/1));  
    ring.write(ringMin + (ringMax-ringMin)*(float(pos)/1)); 
    pinkie.write(pinkieMin + (pinkieMax-pinkieMin)*(float(pos)/1)); 
    delay(delayy);                       // waits 15ms for the servo to reach the position 
  }   
}

