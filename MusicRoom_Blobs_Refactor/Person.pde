import java.util.LinkedList;
import arb.soundcipher.*;

class Person {
  private LinkedList<PVector> containedPixels;
  PVector centerOfMass;
  
  PVector velocity = new PVector();
  
  PVector highestPoint = new PVector();
  
  PVector minCorner = new PVector();
  PVector maxCorner = new PVector();
   PVector boundBoxSides = new PVector();
  float boundBoxRatio = 0;
  float boundBoxArea = 0;
  float lastBoundBoxRatio = 0;
  float lastBoundBoxArea = 0;  
  
  // used to calculate moving averages
  float bbRatioAvg = 0;
  float bbAreaAvg = 0;
  float centerXAvg=0;
  float centerYAvg = 0;
  float velocitySqAvg = 0;
  float heightAvg = 0;
  float smoothingFactor = 0.01; // dunno what this should be

  float movingAverage(float workingAverage, float newValue) {
    if (workingAverage == 0) return newValue;
//    if (abs(newValue - workingAverage) > 50) { 
//        newValue = workingAverage;
//    }
    return ((newValue*smoothingFactor) + ( workingAverage * ( 1.0 - smoothingFactor) ));
  } 
  boolean updateFlag = true;

  boolean hasFlag = false; // Person has IR reflecting token/flag/armband/whatever it is.
  
  color personColor;
  
  //float[][] pitchSet = {{48, 50, 52, 53, 55}, {57, 59, 60,62,64}, {65,67, 69, 71,72}, {74, 76, 79,81,83}, {57, 59, 60,62,64}};
  float[][] pitchSet = {{48, 50, 52, 53},{55, 57, 59,60},{62,64,65,67},{69,71,72,74},{76, 79,81,83}};
  
  SoundCipher cipher;
  double instrument;
  
  Person(PApplet parent, PVector centerOfMass, LinkedList<PVector> containedPixels, int hasFlag, int minX, int minY, int maxX, int maxY) {
    this.containedPixels = containedPixels;
    this.centerOfMass = centerOfMass;
    this.hasFlag = hasFlag>60;
    this.minCorner = new PVector(minX, minY);
    this.maxCorner = new PVector(maxX, maxY);
    int xside = maxX-minX;
    int yside = maxY-minY;
    this.boundBoxSides = new PVector(xside, yside);
    this.boundBoxArea = xside*yside;
    this.boundBoxRatio = xside/yside;
    this.cipher = new SoundCipher(parent);
    cipher.tempo(120);  // this should be able to change or something
    this.instrument = floor(map(minCorner.x, 0, camWidth,0,127));
    
    colorMode(HSB);
    personColor = color(round(random(255)), 255, 255);
  }
  
  /* Here's where the magic happens; at least until we decide to make this event driven, or use minim */
  int playTimer = 0;
  void playNote() {
//    double boxRatioChange = abs(boundBoxRatio-lastBoundBoxRatio);
//    float boxAreaChange = abs(boundBoxArea-lastBoundBoxArea);
//   double boxChange = max(boxAreaChange/2,velocity.magSq());

    if((velocity.magSq() > 25) && // start if we've moved; what's the right threshhold here?
       (millis()-playTimer > 1000))  {  // but only if last time note started was more than a second ago
      playTimer=millis();
      double startBeat = 0;
      double channel = 0;
//      double instrument = map(containedPixels.size(), minimumBlobSize, 20000, 0, 127); 
      double pitch = pitchSet[floor(centerOfMass.x / (camWidth/5))][floor(centerOfMass.y / (camWidth/4))];
      double dynamic = min(map(boundBoxArea,0,480*480, 0,127),127);  //map(velocity.magSq(), 0, 320, 80, 127);  
      double duration = int(velocity.mag());
      double articulation = boundBoxRatio; // 0.8;
      double pan = map(centerOfMass.x,0,camWidth,0,127);
      cipher.playNote(startBeat,
                     channel,
                      instrument,
                      pitch,
                      dynamic,
                      duration,
                      articulation,
                      pan);
     // cipher.playNote(pitchSet[floor(centerOfMass.x / 128)][floor(centerOfMass.y / 96)], 127, 10);
    }
  }
  
  int centerChangeTimer = millis();  // used to know if we're still for a certain period of time
  void setCenterOfMass(PVector centerOfMass) {
    velocity = velocity.sub(centerOfMass, this.centerOfMass);
    if (velocity.magSq() > 10) { // don't know what threshold should be
      centerChangeTimer = millis();  // record time of last significant change in location
    }
    this.centerOfMass = centerOfMass;
    centerXAvg = (centerOfMass.x*smoothingFactor) + ( centerXAvg * ( 1.0 - smoothingFactor) );
    centerYAvg = movingAverage(centerYAvg, centerOfMass.y);
    velocitySqAvg = movingAverage(velocitySqAvg, velocity.magSq());
  }
  
  void setPixels(LinkedList<PVector> containedPixels) {
    this.containedPixels = containedPixels;
    updateFlag = true;
    
    // update bounding box
    // update height
  }
  
  int minZ = 0;
  
  void setHighestPoint(int minZ,PVector highpoint) {
    this.highestPoint = highpoint;
    this.minZ = minZ;
    this.heightAvg = (minZ*smoothingFactor) + ( heightAvg * ( 1.0 - smoothingFactor) );
    
  }
  
  void setBoundingBox(int minX, int minY, int maxX, int maxY) {
    this.lastBoundBoxArea = this.boundBoxArea;
    this.lastBoundBoxRatio = this.boundBoxRatio;
    
    this.minCorner = new PVector(minX, minY);
    this.maxCorner = new PVector(maxX, maxY);
    int xside = maxX-minX;
    int yside = maxY-minY;
    this.boundBoxSides = new PVector(xside, yside);
    this.boundBoxArea = xside*yside;
    bbAreaAvg = movingAverage(bbAreaAvg, boundBoxArea);
    this.boundBoxRatio = xside/yside;
  }
  
  void setHasFlag(int hasFlag) {
    this.hasFlag = (hasFlag>60);
  }
  
  PImage drawPerson(PImage image) {
    image.loadPixels();
    
    for(PVector pixel : containedPixels) {
      image.pixels[round(pixel.x) + round(pixel.y) * image.width] = color(128);
    }
    
    image.updatePixels();
    return image;
  }
  
 
}
