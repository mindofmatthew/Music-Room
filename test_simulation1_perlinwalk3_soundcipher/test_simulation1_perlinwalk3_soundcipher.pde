

import arb.soundcipher.*;

SoundCipher sc = new SoundCipher(this);
SoundCipher sc2 = new SoundCipher(this);
SoundCipher sc3 = new SoundCipher(this);
//float[] pitchSet = {57, 60, 60, 60, 62, 64, 67, 67, 69, 72, 72, 72, 74, 76, 79};
float[][] pitchSet = {{48, 50, 52, 53, 55}, {57, 59, 60,62,64},{65,67, 69, 71,72}, {74, 76, 79,81,83}};
int setSize = pitchSet.length;
float keyRoot = 0;
float density = 0.8;

Body body, body1, body2;
int x = 0;


void setup() {
  size(700,700);
  body = new Body("0");
    body1 = new Body("1");
      body2 = new Body("2");
  
  // for soundcipher    
        frameRate(8);
  sc3.instrument(49);
}

void draw() {
  x = x+1;

    background(255);
  
  // random walk
  body.perlinWalk2();
  
  // Update the location
  body.update();
  // Display the Mover
  body.display(); 
  
    if (random(1) < density) {
  body.play(sc, pitchSet, keyRoot);
    }
    
    // random walk
  body1.perlinWalk2();
  
  // Update the location
  body1.update();
  // Display the Mover
  body1.display(); 
  
    if (frameCount%32 == 0) {
  keyRoot = (random(4)-2)*2;
      density = random(7) / 10 + 0.3;
   body1.play(sc, pitchSet, keyRoot);
    }
    
    // random walk
  body2.perlinWalk2();
  
  // Update the location
  body2.update();
  // Display the Mover
  body2.display(); 
  
    if (frameCount%16 == 0) {
      // how to correlate this to body2??????
//  keyRoot= keyRoot+(random(24)-12);
      float[] pitches = {pitchSet[(int)random(4)][(int)random(5)]+keyRoot-12, pitchSet[(int)random(4)][(int)random(5)]+keyRoot-12};
sc3.playChord(pitches, random(50)+30, 4.0);
// body2.play(sc, pitches, keyRoot);
    }


}
