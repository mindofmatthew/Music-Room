import java.util.LinkedList;
import arb.soundcipher.*;

class Person {
  private LinkedList<PVector> containedPixels;
  PVector centerOfMass;
  
  PVector velocity = new PVector();
  
  boolean updateFlag = true;
  
  color personColor;
  
  float[][] pitchSet = {{48, 50, 52, 53, 55}, {57, 59, 60,62,64}, {65,67, 69, 71,72}, {74, 76, 79,81,83}, {57, 59, 60,62,64}};
  
  SoundCipher cipher;
  
  Person(PApplet parent, PVector centerOfMass, LinkedList<PVector> containedPixels) {
    this.containedPixels = containedPixels;
    this.centerOfMass = centerOfMass;
    
    cipher = new SoundCipher(parent);
    
    colorMode(HSB);
    personColor = color(round(random(255)), 255, 255);
  }
  
  void playNote() {
    if(velocity.magSq() > 100) {
      cipher.playNote(pitchSet[floor(centerOfMass.x / 128)][floor(centerOfMass.y / 96)], 127, 10);
    }
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
}
