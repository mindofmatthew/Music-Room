import java.util.LinkedList;
import ddf.minim.*;
import themidibus.*;

class Person {
  private LinkedList<PVector> containedPixels;
  PVector centerOfMass;
  
  PVector velocity = new PVector();
  
  PVector highestPoint = new PVector();
  int minZ = 0;
  
  PVector minCorner = new PVector();
  PVector maxCorner = new PVector();
  PVector boundBoxSides = new PVector();
  float boundBoxRatio = 0;
  float boundBoxArea = 0;
  float lastBoundBoxRatio = 0;
  float lastBoundBoxArea = 0;
  
  boolean updateFlag = true;

  boolean hasFlag = false; // Person has IR reflecting token/flag/armband/whatever it is.
  PVector flagCenter = new PVector();
  PVector flagVector = new PVector(); // points from cetner of mass to flag center
  
  color personColor;
    
  MidiBus midiOut;
    
  Instrument instrument;
  
  int channel;
  
  int flagMinSizeThreshold = 60;
  
  Person(Audi5oOutput output, MidiBus midiOut, PVector centerOfMass, LinkedList<PVector> containedPixels, int hasFlag, int minX, int minY, int maxX, int maxY) {
    this.containedPixels = containedPixels;
    this.centerOfMass = centerOfMass;
    this.hasFlag = hasFlag > flagMinSizeThreshol60r = new PVector(minX, minY);
    this.maxCorner = new PVector(maxX, maxY);
    int xside = maxX-minX;
    int yside = maxY-minY;
    this.boundBoxSides = new PVector(xside, yside);
    this.boundBoxArea = xside*yside;
    this.boundBoxRatio = xside/yside;
    
    this.midiOut = midiOut;
    
    channel = globalChannel;
    globalChannel = (globalChannel + 1) % 3;
    
    //instrument = new Instrument(output);
    
    colorMode(HSB);
    personColor = color(round(random(255)), 255, 180);
  }
  
  void destroy() {
    //instrument.destroy();
    midiOut.sendNoteOff(channel, currentPitch, 127);
  }
  
  void playNote() {
    playNotePosition();
  }
  

  boolean currentNote = false;
  int currentPitch;
  int timeOfAttack = 0;
  
  void playNotePosition() {
    // pitchSet is global in MusicRoom_UpdatedBlobAlgorithm
    Frequency freq = freqSet[floor(centerOfMass.x / (camWidth / notesX))][floor(centerOfMass.y / (camHeight / notesY))];
    
    if(minZ < 1300) {
      float pitch = freq.asMidiNote();
      pitch += 7;
      freq = Frequency.ofMidiNote(pitch);
    } else if(minZ > 2100) {
      float pitch = freq.asMidiNote();
      pitch -= 5;
      freq = Frequency.ofMidiNote(pitch);
    }
    
    //boolean onCondition = (velocity.magSq() > 20) || (boundBoxArea - lastBoundBoxArea > lastBoundBoxArea * 0.1);
    boolean onCondition = (boundBoxArea - lastBoundBoxArea > lastBoundBoxArea * 0.1);
    boolean offCondition = millis() - timeOfAttack > 500 && boundBoxArea < 30000;
    
    //instrument.setVolume(constrain(map(boundBoxArea, 15000, 100000, 0, 3), 0, 3));
    midiOut.sendControllerChange(channel, 7, round(constrain(map(boundBoxArea, 15000, 80000, 80, 127), 40, 127)));
    
    if(onCondition && !currentNote) {
      midiOut.sendNoteOff(channel, currentPitch, 127);
      currentPitch = round(freq.asMidiNote());
      midiOut.sendNoteOn(channel, currentPitch, 127);
      //instrument.noteOn(freq);
      currentNote = true;
      
      println("new pitch: " + freq.asMidiNote());
      
      /*if(bend != null) {
        bend.setEndAmp(frequency);
        bend.activate();
      }*/
      
      timeOfAttack = millis();
    } else if(offCondition && currentNote) {
      midiOut.sendNoteOff(channel, currentPitch, 127);
      //instrument.noteOff();
      currentNote = false;
    }
    
    if(currentNote) {
      if(currentPitch != freq.asMidiNote()) {
        midiOut.sendNoteOff(channel, currentPitch, 127);
        currentPitch = round(freq.asMidiNote());
        midiOut.sendNoteOn(channel, currentPitch, 127);
      }
    }
  }
  
  // Direction/movement-based note triggering
  
  int currPitch = 69;
  int pitchDirection = 1;
  PVector lastCenter = new PVector(0, 0);
  PVector lastDisplacement = new PVector(0, 0);
  int lastNoteTime = 0;
  
  void playNoteDirection() {
    PVector displacement = new PVector();
    displacement = displacement.sub(centerOfMass, lastCenter);
    
    if(displacement.magSq() > 250) {
      float changeInAngle = displacement.angleBetween(displacement, lastDisplacement);
      
      if(abs(changeInAngle) > 1.5) {
        pitchDirection *= -1;
      }
      
      println("pitch change: " + currPitch);
      
      midiOut.sendNoteOff(channel, currPitch, 127);
      midiOut.sendControllerChange(channel, 7, floor(random(128)));
      
      currPitch += pitchDirection * round(constrain(map(millis() - lastNoteTime, 200, 0, 1, 5), 1, 5));
      float currFrequency = pow(2, (currPitch - 69) / 12.0) * 440;
      //instrument.noteOn(Frequency.ofHertz(currFrequency));
      
      midiOut.sendNoteOn(channel, currPitch, 127);
      
      lastCenter = centerOfMass;
      lastDisplacement = displacement;
      lastNoteTime = millis();
    }
  }
  
  void setCenterOfMass(PVector centerOfMass) {
    velocity = velocity.sub(centerOfMass, this.centerOfMass);
    this.centerOfMass = centerOfMass;
  }
  
  void setPixels(LinkedList<PVector> containedPixels) {
    this.containedPixels = containedPixels;
    updateFlag = true;
  }
  
  void setHighestPoint(int minZ,PVector highpoint) {
    this.highestPoint = highpoint;
    this.minZ = minZ;
  }
  
  void setBoundingBox(int minX, int minY, int maxX, int maxY) {
    this.lastBoundBoxArea = this.boundBoxArea;
    this.lastBoundBoxRatio = this.boundBoxRatio;
    
    this.minCorner = new PVector(minX, minY);
    this.maxCorner = new PVector(maxX, maxY);
    int xside = maxX - minX;
    int yside = maxY - minY;
    this.boundBoxSides = new PVector(xside, yside);
    this.boundBoxArea = xside*yside;
    this.boundBoxRatio = xside/yside;
  }
 
  void setHasFlag(int hasFlag, int x, int y) {
    this.hasFlag = (hasFlag>flagMinSizeThreshol60ter = new PVector(x, y);
//    this.flagVector = PVector.sub(flagCenter,centerOfMass);
  }
  
  PImage drawPerson(PImage image) {
    image.loadPixels();
    
    for(PVector pixel : containedPixels) {
      image.pixels[round(pixel.x) + round(pixel.y) * image.width] = personColor;
    }
    
    image.updatePixels();
    return image;
  }
}
