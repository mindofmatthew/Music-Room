import java.util.LinkedList;

import ddf.minim.*;
import ddf.minim.ugens.*;

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
  
  boolean updateFlag = true;

  boolean hasFlag = false; // Person has IR reflecting token/flag/armband/whatever it is.
  
  color personColor;
  
  float[][] pitchSet = {{48, 50, 52, 53},{55, 57, 59,60},{62,64,65,67},{69,71,72,74},{76, 79,81,83}};
  
  AudioOutput output;
  Oscil waveform;
  ADSR envelope;
  MoogFilter filter;
  Flanger flanger;
  Line bend;
  
  Constant flangerWet;
  
  boolean currentNote = false;
  int timeOfAttack = 0;
  
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
    
    //if(centerOfMass.y < camHeight / 3) {
      envelope = new ADSR();
      waveform = new Oscil(440, 1, Waves.randomNHarms(5));
      filter = new MoogFilter(8000, 0, MoogFilter.Type.BP);
      //flanger = new Flanger(0.5, 5, 0.1, 0.3, 0.5, 0.1);
      waveform.patch(envelope);
      //filter.patch(envelope);
      envelope.patch(out);
      envelope.setParameters(1, 0.005, 0.005, 0.4, 0.6, 0, 0);
      //flangerWet = new Constant();
      //flangerWet.patch(filter.resonance);
    /*} else if(centerOfMass.y < 2 * camHeight / 3) {
      envelope = new ADSR();
      filter = new MoogFilter(8000, 0, MoogFilter.Type.LP);
      //bend = new Line(0.1, 0, 220);
      waveform = new Oscil(220, 1, Waves.SQUARE);
      waveform.patch(filter);
      filter.patch(envelope);
      //bend.patch(waveform.frequency);
      envelope.patch(out);
      envelope.setParameters(0.2, 0.1, 0.05, 0.6, 0.2, 0, 0);
    } else {
      envelope = new ADSR();
      filter = new MoogFilter(3000, 0.2, MoogFilter.Type.LP);
      waveform = new Oscil(110, 1, Waves.SAW);
      waveform.patch(filter);
      filter.patch(out);
      envelope.patch(out);
      envelope.setParameters(0.3, 0.001, 0.5, 0.2, 0.6, 0, 0);
    }*/
    
    
    colorMode(HSB);
    personColor = color(round(random(255)), 255, 255);
  }
  
  void destroy() {
    envelope.unpatch(output);
  }
  
  /* Here's where the magic happens; at least until we decide to make this event driven, or use minim */
  void playNote() {  
    float pitch = pitchSet[floor(centerOfMass.x / (camWidth / 5))][floor(centerOfMass.y / (camHeight / 4))];
    
    if(minZ < 1300) {
      pitch += 12;
    } else if(minZ > 1900) {
      pitch -= 12;
    }
    
    float frequency = pow(2, (pitch - 69) / 12) * 440;
    waveform.setFrequency(frequency);
    
    waveform.setAmplitude(constrain(map(boundBoxArea, 50000, 100000, 1, 2), 1, 2));
    
    //flangerWet.setConstant(constrain(map(boundBoxRatio, 0, 4, 0, 1), 0, 1));
    
    if(boundBoxArea > 50000) {
      timeOfAttack = millis();
    }
    
    
    
    boolean onCondition = (velocity.magSq() > 10) || (boundBoxArea - lastBoundBoxArea > 2000);
    boolean offCondition = millis() - timeOfAttack > 200;
    
    if(onCondition && !currentNote) {
      println("Note On");
      println("Area: " + boundBoxArea);
      envelope.noteOn();
      currentNote = true;
      
      if(bend != null) {
        bend.setEndAmp(frequency);
        bend.activate();
      }
      
      timeOfAttack = millis();
    } else if(offCondition && currentNote) {
      println("Note Off");
      envelope.noteOff();
      currentNote = false;
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
  
  int minZ = 0;
  
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
