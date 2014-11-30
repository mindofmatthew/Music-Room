import java.util.LinkedList;

import ddf.minim.*;

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
  
  color personColor;
    
  Instrument instrument;
  
  Person(AudioOutput output, PVector centerOfMass, LinkedList<PVector> containedPixels, int hasFlag, int minX, int minY, int maxX, int maxY) {
    this.containedPixels = containedPixels;
    this.centerOfMass = centerOfMass;
    this.hasFlag = hasFlag > 60;
    this.minCorner = new PVector(minX, minY);
    this.maxCorner = new PVector(maxX, maxY);
    int xside = maxX-minX;
    int yside = maxY-minY;
    this.boundBoxSides = new PVector(xside, yside);
    this.boundBoxArea = xside*yside;
    this.boundBoxRatio = xside/yside;
    
    instrument = new Instrument(output);
    
    colorMode(HSB);
    personColor = color(round(random(255)), 255, 255);
  }
  
  void destroy() {
    instrument.destroy();
  }
  
  void playNote() {
    playNotePosition();
  }
  

  boolean currentNote = false;
  int timeOfAttack = 0;
  
  void playNotePosition() {
    // pitchSet is global in MusicRoom_UpdatedBlobAlgorithm
    int pitch = pitchSet[floor(centerOfMass.x / (camWidth / notesX))][floor(centerOfMass.y / (camHeight / notesY))];
    
    if(minZ < 1300) {
      pitch += 7;
    } else if(minZ > 1900) {
      pitch -= 5;
    }
    
    boolean onCondition = (velocity.magSq() > 20) || (boundBoxArea - lastBoundBoxArea > 2000);
    boolean offCondition = millis() - timeOfAttack > 500;
    
    instrument.setVolume(constrain(map(boundBoxArea, 15000, 100000, 0, 3), 0, 3));
    
    if(onCondition && !currentNote) {
      instrument.noteOn(pitch);
      currentNote = true;
      
      println("new pitch: " + pitch);
      
      /*if(bend != null) {
        bend.setEndAmp(frequency);
        bend.activate();
      }*/
      
      timeOfAttack = millis();
    } else if(offCondition && currentNote) {
      instrument.noteOff();
      currentNote = false;
    }
  }
  
  // Direction/movement-based note triggering
  
  int currPitch = 69;
  int pitchDirection = 1;
  PVector lastCenter = new PVector(0, 0);
  PVector lastDisplacement = new PVector(0, 0);
  
  void playNoteDirection() {
    PVector displacement = new PVector();
    displacement = displacement.sub(centerOfMass, lastCenter);
    
    if(displacement.magSq() > 250) {
      float changeInAngle = displacement.angleBetween(displacement, lastDisplacement);
      
      if(abs(changeInAngle) > 1.5) {
        pitchDirection *= -1;
      }
      
      println("pitch change: " + currPitch);
      
      currPitch += pitchDirection;
      instrument.noteOn(currPitch);
      lastCenter = centerOfMass;
      lastDisplacement = displacement;
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
 
  void setHasFlag(int hasFlag) {
    this.hasFlag = (hasFlag>60);
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
