import SimpleOpenNI.*;
import java.util.Stack;
import ddf.minim.ugens.Frequency;
import themidibus.*;
import java.util.Timer;
import java.util.TimerTask;

SimpleOpenNI  context;

int camWidth = 640;
int camHeight = 480;

Stack<Integer> blobIndexStack;
int[] blobIndex;  // all pixels in image, with a number indicating which blob they belong to (or 0 if not part of blob)
PVector[] depthPoints;
color[] irPixels;
int numBlobs = 1;

LinkedList<PVector>[] blobPixels;  // Array of linkedlists, each containing all pixels for a given blob
PVector[] blobCenterOfMass;    // All of vectors with the x,y of center of mass for each blob
int[] blobHasFlag;     // count of IR reflecting pixels -- for each blob which contains IR reflector token/flag/marker
int[] blobFlagCtrX;  // center point of reflector for each blob (note: used as accumulator first)
int[] blobFlagCtrY;
int irFlagThreshold = 150; // brightness of IR reflector

int[] blobMinX;  
int[] blobMinY;  
int[] blobMaxX;  
int[] blobMaxY;  // used to compute bounding box corners
int[] minimumZPerBlob;  // highest point in blob
PVector[] minimumZLocation;  // 3d location of highest point in blob

LinkedList<Person> people;
LinkedList<Person> keep_people;

int minimumBlobSize = 3000;
float maxDistance = 50;
int bgZThreshhold = 3100; // ignore floor by ignoring any pixels past this Z value
int overlapThreshold = 355;

MidiBus midiOut;

Timer timer;
int personIndex = 0;

int globalChannel = 0;

// Position-based note triggering

//int[][] pitchSet = {{48, 50, 52, 53},{55, 57, 59,60},{62,64,65,67},{69,71,72,74},{76, 79,81,83}};
//int[][] pitchSet = {{48, 50, 52, 55},{50, 52, 55,57},{52,55,57,60},{55,57,60,62},{57, 60,62,64}}; // pentatonic, one step each way
//int[][] pitchSet = {{48, 52, 57, 62},{50, 55, 60,64},{52,57,62,67},{55,60,64,69},{57, 62,67,72}}; // pentatonic, third on x axis
//int[][] pitchSet = {{48, 52, 55},{52, 55, 59},{55,60,64},{59,62,65}}; // diatonic, up by 3rd each way
String[][] noteSet = {{"C4", "E4", "G4"},
                      {"D4", "F4", "A4"},
                      {"E4", "G4", "B4"},
                      {"F4", "A4", "C5"}}; // diatonic, up by 3rd yaxis,by 1 on xaxis


int notesX = noteSet.length;
int notesY = noteSet[0].length;
Frequency[][] freqSet = new Frequency[notesX][notesY];
int[][] pitchSet = new int[notesX][notesY];
int sectorSizeX, sectorSizeY;

void setup()
{
  context = new SimpleOpenNI(this);

  // enable depthMap generation 
  context.enableDepth();
  camWidth=context.depthWidth();
  camHeight = context.depthHeight();
  println("width = "+context.depthWidth()+ " height="+context.depthHeight());

  // enable ir generation
  context.enableIR();
  println("width = "+context.irWidth()+ " height="+context.irHeight());
  //context.alternativeViewPointDepthToImage();

  people = new LinkedList<Person>();
  keep_people = new LinkedList<Person>();

  //MidiBus.list();
  midiOut = new MidiBus(this, -1, "Pd to Logic");

  background(0);

  size(camWidth, camHeight);
  sectorSizeX = int(camWidth/notesX);
  sectorSizeY=int(camHeight/notesY);
  
  for (int x=0; x<notesX; x++) {
    for (int y=0; y<notesY; y++) {
       freqSet[x][y] = Frequency.ofPitch(noteSet[x][y]);
       println(noteSet[x][y] +" = "+ freqSet[x][y]);//+" = "+pitchSet[x][y]);
    }
  }
  
  colorMode(HSB);
  rectMode(CORNERS);
  
  timer = new Timer();
}

class PlayBeat extends TimerTask {
  public void run() {
    if(people.size() > 0) {
      personIndex = personIndex % people.size();
      Note[] sentNotes = people.get(personIndex).playNote();
      midiOut.sendNoteOn(sentNotes[0]);
      timer.schedule(new WaitBeat(sentNotes[0]), sentNotes[0].ticks() - 20);
      personIndex += 1;
    }
  }
}

class WaitBeat extends TimerTask {
  Note sentNote;
  
  public WaitBeat(Note sentNote) {
    this.sentNote = sentNote;
  }
  
  public void run() {
    midiOut.sendNoteOff(sentNote);
    timer.schedule(new PlayBeat(), 20);
  }
}

void draw() {
  background(0);

  updatePeople();

  PImage personImage = new PImage(camWidth, camHeight);

  for (Person person : people) {
    personImage = person.drawPerson(personImage);
  }

  image(personImage, 0, 0);

  // draw boxes for notes
  stroke(240, 200, 200);

  for (int w =sectorSizeX; w<camWidth; w+=sectorSizeX) {
    line(w, 0, w, camHeight);
  }
  for (int h=sectorSizeY; h<camHeight; h+=sectorSizeY) {
    line(0, h, camWidth, h);
  }

  // draw persons
  for (Person person : people) {
    stroke(255);
    PVector offset = new PVector();
    offset = offset.sub(person.centerOfMass, person.velocity);
    line(person.centerOfMass.x, person.centerOfMass.y, offset.x, offset.y);    // draw velocity vector
    noFill();
    rect(person.minCorner.x, person.minCorner.y, person.maxCorner.x, person.maxCorner.y); // draw bounding box
    noStroke();
    fill(255);
    ellipse(person.centerOfMass.x, person.centerOfMass.y, 10, 10);
    if (person.hasFlag) { 
      //      textSize(24);
      //      text(person.minZ+" : "+person.boundBoxArea, person.centerOfMass.x, person.centerOfMass.y);
      fill(150, 255, 255);
      ellipse(person.flagCenter.x, person.flagCenter.y, 5, 5);
      stroke(255);
      line(person.centerOfMass.x, person.centerOfMass.y, person.flagCenter.x, person.flagCenter.y);
    }
  }
}

void updatePeople() {
  // Reset blobIndex array
  blobIndex = new int[camWidth * camHeight];
  blobIndexStack = new Stack<Integer>();
  numBlobs = 1;

  context.update();

  depthPoints = context.depthMapRealWorld();
  PImage irImage = context.irImage();
  irPixels = irImage.pixels;

  for (int i = 0; i < depthPoints.length; i++) {
    if (isFreeBlobPixel(i)) {  // Check if this pixel is good
      blobIndexStack.push(i);

      while (blobIndexStack.size () > 0) {
        int newIndex = blobIndexStack.pop().intValue();

        setBlobIndex(newIndex, numBlobs);
      }

      numBlobs += 1;
    }
  }

  // Set up our per-blob variables
  blobPixels = new LinkedList[numBlobs];
  blobCenterOfMass = new PVector[numBlobs];
  blobHasFlag = new int[numBlobs];
  blobFlagCtrX = new int[numBlobs];
  blobFlagCtrY = new int[numBlobs];
  blobMinX = new int[numBlobs];          // used to compute bounding box corners
  blobMinY = new int[numBlobs];
  blobMaxX = new int[numBlobs];
  blobMaxY = new int[numBlobs];
  minimumZPerBlob = new int[numBlobs];
  minimumZLocation = new PVector[numBlobs];

  for (int i = 0; i < numBlobs; ++i) {
    blobPixels[i] = new LinkedList<PVector>();
    blobCenterOfMass[i] = new PVector();
    minimumZLocation[i] = new PVector();
    blobMinX[i] = 10000; 
    blobMinY[i]=10000;
    //    blobMaxX[i] = 0; blobMaxY[i]=0;  // not necessary because int arrays initialize to all zeros
    minimumZPerBlob[i] = 3500;
  }

  // Now that the dust has settled, go through and count how
  // many pixels are in each blob
  for (int i = 0; i < blobIndex.length; ++i) {


    // Ignore the floor
    if (blobIndex[i] > 0) {
      int x = i % camWidth;
      int y = i / camWidth;

      // update bounding box corner coordinates
      if (x < blobMinX[blobIndex[i]]) { 
        blobMinX[blobIndex[i]]=x;
      }
      if (x > blobMaxX[blobIndex[i]]) { 
        blobMaxX[blobIndex[i]]=x;
      }
      if (y < blobMinY[blobIndex[i]]) { 
        blobMinY[blobIndex[i]]=y;
      }
      if (y > blobMaxY[blobIndex[i]]) { 
        blobMaxY[blobIndex[i]]=y;
      }

      blobPixels[blobIndex[i]].push(new PVector(x, y, depthPoints[i].z));
      if (brightness(irPixels[i])>irFlagThreshold) { // this pixel is probably an IR reflecting flag
        blobHasFlag[blobIndex[i]] += 1;
        blobFlagCtrX[blobIndex[i]] += x;
        blobFlagCtrY[blobIndex[i]] += y;
      }

      // sum x and y of all points, to computer center of mass
      blobCenterOfMass[blobIndex[i]].x += x;   
      blobCenterOfMass[blobIndex[i]].y += y;

      // look at depth of pixel, and set as min Z for the blob if this is lower than min 
      int z = round(depthPoints[i].z);
      if (z>10 && z < minimumZPerBlob[blobIndex[i]]) {
        minimumZPerBlob[blobIndex[i]] = z;
        minimumZLocation[blobIndex[i]] = new PVector(x, y, z);
      }
    }
  }

  // find center of mass as average x and y of all points in blob
  for (int i = 0; i < numBlobs; ++i) {
    blobCenterOfMass[i].x /= blobPixels[i].size();
    blobCenterOfMass[i].y /= blobPixels[i].size();
    if (blobHasFlag[i] > 0) {
      blobFlagCtrX[i] /= blobHasFlag[i];
      blobFlagCtrY[i] /= blobHasFlag[i];
    }
  }

  // Now, figure out which people are close to which blobs
  for (Person person : people) {
    person.updateFlag = false;
  }
  
  // Keep track of how many people we're starting with
  int oldNumberOfPeople = people.size();

  for (int i = 0; i < numBlobs; ++i) {
    if (blobPixels[i].size() > minimumBlobSize) {
      Person closestPerson = null;
      float distance = 1000000;

      for (Person person : people) {
        float newDistance = blobCenterOfMass[i].dist(person.centerOfMass);

        if (newDistance < distance && newDistance < maxDistance) {
          distance = newDistance;
          closestPerson = person;
        }
      }

      if (closestPerson == null) {
        //        people.push(new Person(out, blobCenterOfMass[i], blobPixels[i], blobHasFlag[i], blobMinX[i], blobMinY[i], blobMaxX[i], blobMaxY[i]));
        Person p = new Person(midiOut, blobCenterOfMass[i], blobPixels[i], blobHasFlag[i], blobMinX[i], blobMinY[i], blobMaxX[i], blobMaxY[i]);
        p.setHasFlag(blobHasFlag[i], blobFlagCtrX[i], blobFlagCtrY[i]);
        p.setHighestPoint(minimumZPerBlob[i], minimumZLocation[i]);
        people.add(p);
      } else {
        closestPerson.setCenterOfMass(blobCenterOfMass[i]);
        closestPerson.setPixels(blobPixels[i]);
        closestPerson.setBoundingBox(blobMinX[i], blobMinY[i], blobMaxX[i], blobMaxY[i]);
        closestPerson.setHasFlag(blobHasFlag[i], blobFlagCtrX[i], blobFlagCtrY[i]);
        closestPerson.setHighestPoint(minimumZPerBlob[i], minimumZLocation[i]);
      }
    }
  }
  
  // remove people who no longer exist, by making copy of list with only people who still exist
  int tempPersonIndex = 0;
  for (Person person : people) { 
    if (person.updateFlag) {
      keep_people.add(person);
      tempPersonIndex += 1;
    } else {
      person.destroy();
      if(personIndex > tempPersonIndex) {
        personIndex -= 1;
      }
    }
  }  
  people = keep_people;
  keep_people = new LinkedList<Person>();
  
  if((oldNumberOfPeople == 0) && (people.size() > 0)) {
    personIndex = 0;
    timer.schedule(new PlayBeat(), 0);
    println("first!");
  }
}

// Set the blob index for a single pixel
void setBlobIndex(int index, int blobID) {
  blobIndex[index] = blobID;

  if (index % camWidth > 0) { //We have a left neighbor
    if (isFreeBlobPixel(index - 1, index)) {
      blobIndexStack.push(new Integer(index - 1));
    }
  }

  if (index % camWidth < camWidth - 1) {
    if (isFreeBlobPixel(index + 1, index)) {
      blobIndexStack.push(new Integer(index + 1));
    }
  }

  if (index - camWidth >= 0) {
    if (isFreeBlobPixel(index - camWidth, index)) {
      blobIndexStack.push(new Integer(index - camWidth));
    }
  }

  if (index + camWidth < blobIndex.length) {
    if (isFreeBlobPixel(index + camWidth, index)) {
      blobIndexStack.push(new Integer(index + camWidth));
    }
  }
}

boolean isFreeBlobPixel(int index) {
  if (blobIndex[index] > 0) {
    return false;
  }

  if ((depthPoints[index].z > 0 && depthPoints[index].z < bgZThreshhold) || (brightness(irPixels[index])>80)) {
    return true;
  } else {
    return false;
  }
}

boolean isFreeBlobPixel(int destIndex, int sourceIndex) {
  if (!isFreeBlobPixel(destIndex)) {
    return false;
  }

  if (abs(depthPoints[sourceIndex].z - depthPoints[destIndex].z) < overlapThreshold) {
    return true;
  } else {
    return false;
  }
}

