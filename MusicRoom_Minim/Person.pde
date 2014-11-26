import java.util.LinkedList;

import ddf.minim.*;
import ddf.minim.ugens.*;

class Person {
  private LinkedList<PVector> containedPixels;
  PVector centerOfMass;
  
  PVector velocity = new PVector();
  
  PVector minCorner = new PVector();
  PVector maxCorner = new PVector();
  PVector boundBoxSides = new PVector();
  float boundBoxRatio = 0;
  float boundBoxArea = 0;
  float lastBoundBoxRatio = 0;
  float lastBoundBoxArea = 0;  
  
  
  boolean updateFlag = true;

  boolean hasFlag = false; // Person has IR reflecting token/flag/armband/whatever it is.
  
  color personColor;
  
  float[][] pitchSet = {{48, 50, 52, 53, 55}, {57, 59, 60,62,64}, {65,67, 69, 71,72}, {74, 76, 79,81,83}, {57, 59, 60,62,64}};
  
  Oscil waveform;
  AudioOutput output;
  ADSR envelope;
  
  boolean currentNote = false;
  
  Person(AudioOutput output, PVector centerOfMass, LinkedList<PVector> containedPixels, int hasFlag, int minX, int minY, int maxX, int maxY) {
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
    
    this.output = output;
    waveform = new Oscil(220, 0.5f, Waves.SINE);
    envelope = new ADSR();
    waveform.patch(envelope);
    envelope.patch(output);
    
    colorMode(HSB);
    personColor = color(round(random(255)), 255, 255);
  }
  
  void destroy() {
    envelope.unpatch(output);
  }
  
  /* Here's where the magic happens; at least until we decide to make this event driven, or use minim */
  void playNote() {
    if((velocity.magSq() > 50) && !currentNote) {
      println("Note On");
      println("Area: " + boundBoxArea);
      envelope.setParameters(1, 0.1, 0.1, 0.6, constrain(map(boundBoxArea, 20000, 100000, 0.1, 2), 5, 10), 0, 0);
      envelope.noteOn();
      currentNote = true;
    } else if((velocity.magSq() < 5) && currentNote) {
      println("Note Off");
      //envelope.noteOff();
      currentNote = false;
    }
    
    float pitch = pitchSet[floor(centerOfMass.x / 128)][floor(centerOfMass.y / 96)];
    
    waveform.setFrequency(pow(2, (pitch - 69) / 12) * 440);
    
    //waveform.setFrequency(map(velocity.magSq(), 0, 100, 220, 880));
    //waveform.setAmplitude(constrain(map(containedPixels.size(), 5000, 20000, 0, 1), 0, 1));
    /*double boxRatioChange = abs(boundBoxRatio-lastBoundBoxRatio);
    float boxAreaChange = abs(boundBoxArea-lastBoundBoxArea);
   double boxChange = max(boxAreaChange/2,velocity.magSq());
    if(boxChange > 25) {  // what's the right threshhold here?
      
      
    
    
      //double startBeat = 0;
      //double channel = 0;
//      double instrument = map(containedPixels.size(), minimumBlobSize, 20000, 0, 127); 
      //double pitch = pitchSet[floor(centerOfMass.x / 128)][floor(centerOfMass.y / 96)];
      //double dynamic = min(map(boundBoxArea,0,480*480, 40,127),127);  //map(velocity.magSq(), 0, 320, 80, 127);  
      //double duration = 4;
      //double articulation = boundBoxRatio; // 0.8;
      //double pan = map(centerOfMass.x,0,camWidth,0,127);
      /*cipher.playNote(startBeat,
                     channel,
                      instrument,
                      pitch,
                      dynamic,
                      duration,
                      articulation,
                      pan);
     // cipher.playNote(pitchSet[floor(centerOfMass.x / 128)][floor(centerOfMass.y / 96)], 127, 10);
    }*/
  }
  
  void setCenterOfMass(PVector centerOfMass) {
    velocity = velocity.sub(centerOfMass, this.centerOfMass);
    this.centerOfMass = centerOfMass;
  }
  
  void setPixels(LinkedList<PVector> containedPixels) {
    this.containedPixels = containedPixels;
    updateFlag = true;
    
    // update bounding box
    // update height
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
