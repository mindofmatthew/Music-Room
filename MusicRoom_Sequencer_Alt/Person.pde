import java.util.LinkedList;
import themidibus.*;
import java.util.Timer;
import java.util.TimerTask;

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

  int channel;

  int flagMinSizeThreshold = 60;
  
  Timer timer;

  Person(MidiBus midiOut, PVector centerOfMass, LinkedList<PVector> containedPixels, int hasFlag, int minX, int minY, int maxX, int maxY) {
    this.containedPixels = containedPixels;
    this.centerOfMass = centerOfMass;
    this.hasFlag = hasFlag > flagMinSizeThreshold;
    this.minCorner = new PVector(minX, minY);
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
    
    timer = new Timer();
  }

  void destroy() {
    //instrument.destroy();
    //midiOut.sendNoteOff(channel, currentPitch, 127);
  }
  
  int shortestNote = 82;
  int longestNote = 600;
  
  void playNote() {
    
    // pitchSet is global in MusicRoom_UpdatedBlobAlgorithm
    Frequency freq = freqSet[floor(centerOfMass.x / (camWidth / notesX))][floor(centerOfMass.y / (camHeight / notesY))];
    int duration = round(constrain(map(boundBoxSides.x,100,400,shortestNote,longestNote), shortestNote, longestNote)); //round(map(boundBoxArea, 10000, 100000, 300, 2000));
    int dynamic = min(round(map(minZ,3100,500,0,127)),127);
    //int numNotes = min(round(map(boundBoxSides.y,20,400,1,5)),5);
    int numNotes = 1;

    Note[] notes = new Note[numNotes];
    for (int i=0; i<numNotes; i++) {
      //float freqMultiplier = (boundBoxSides.y<120)?1:2^(round(map(boundBoxSides.y,100,400,1,6))/12);
      //float freqHz = freq.asHz()*freqMultiplier;
      //freq = Frequency.ofHertz(freqHz);
      //println(freqHz+" = "+round(freq.asMidiNote()));
      int pitch = round(map(boundBoxSides.y, 100, 400, 48, 72));
      notes[i] = new Note(1, pitch, dynamic, duration); 
    }
    
    midiOut.sendNoteOn(notes[0]);
    timer.schedule(new OffBeat(notes), duration);
  }

  class OffBeat extends TimerTask {
    Note[] sentNotes;
    
    public OffBeat(Note[] sentNotes) {
      this.sentNotes = sentNotes;
    }
    
    public void run() {
      for(int i = 0; i < sentNotes.length; ++i) {
        midiOut.sendNoteOff(sentNotes[i]);
      }
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

  void setHighestPoint(int minZ, PVector highpoint) {
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
    
 //   print(boundBoxSides.x + ", " + boundBoxSides.y);
  }

  void setHasFlag(int hasFlag, int x, int y) {
    this.hasFlag = hasFlag > flagMinSizeThreshold;
    this.flagVector = new PVector(x, y);
    //    this.flagVector = PVector.sub(flagCenter,centerOfMass);
  }

  PImage drawPerson(PImage image) {
    image.loadPixels();

    for (PVector pixel : containedPixels) {
      image.pixels[round(pixel.x) + round(pixel.y) * image.width] = personColor;
    }

    image.updatePixels();
    return image;
  }
}

