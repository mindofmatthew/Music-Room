import SimpleOpenNI.*;
import ddf.minim.*;
import java.util.Stack;

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
int[] blobHasFlag;     // true for each blob which contains IR reflector token/flag/marker
int[] blobMinX;  int[] blobMinY;  int[] blobMaxX;  int[] blobMaxY;  // used to compute bounding box corners
int[] minimumZPerBlob;  // highest point in blob
PVector[] minimumZLocation;  // 3d location of highest point in blob

LinkedList<Person> people;
LinkedList<Person> keep_people;

int minimumBlobSize = 3000;
float maxDistance = 50;

Minim minim;
AudioOutput out;

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
  
  minim = new Minim(this);
  out = minim.getLineOut();
  
  background(0);
 
  size(camWidth,camHeight);
  
  colorMode(HSB);
  rectMode(CORNERS);
}

void draw() {
  background(0);
  updatePeople();
  
  PImage personImage = new PImage(camWidth, camHeight);
  
  for(Person person : people) {
    personImage = person.drawPerson(personImage);
  }
  
  image(personImage, 0, 0);
  
  for(Person person : people) {
    person.playNote();
    
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
      textSize(24);
      text(person.minZ+" : "+person.boundBoxArea, person.centerOfMass.x, person.centerOfMass.y);
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
  
  for(int i = 0; i < depthPoints.length; i++) {
    if(isFreeBlobPixel(i)) {  // Check if this pixel is good
      blobIndexStack.push(i);
      
      while(blobIndexStack.size() > 0) {
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
  blobMinX = new int[numBlobs];          // used to compute bounding box corners
  blobMinY = new int[numBlobs];
  blobMaxX = new int[numBlobs];
  blobMaxY = new int[numBlobs];
  minimumZPerBlob = new int[numBlobs];
  minimumZLocation = new PVector[numBlobs];
  
  for(int i = 0; i < numBlobs; ++i) {
    blobPixels[i] = new LinkedList<PVector>();
    blobCenterOfMass[i] = new PVector();
    minimumZLocation[i] = new PVector();
    blobMinX[i] = 10000; blobMinY[i]=10000;
//    blobMaxX[i] = 0; blobMaxY[i]=0;  // not necessary because int arrays initialize to all zeros
    minimumZPerBlob[i] = 3500;
  }
  
  // Now that the dust has settled, go through and count how
  // many pixels are in each blob
  for(int i = 0; i < blobIndex.length; ++i) {

    
    // Ignore the floor
    if(blobIndex[i] > 0) {
      int x = i % camWidth;
      int y = i / camWidth;
      
      // update bounding box corner coordinates
      if (x < blobMinX[blobIndex[i]]) { blobMinX[blobIndex[i]]=x; }
      if (x > blobMaxX[blobIndex[i]]) { blobMaxX[blobIndex[i]]=x; }
      if (y < blobMinY[blobIndex[i]]) { blobMinY[blobIndex[i]]=y; }
      if (y > blobMaxY[blobIndex[i]]) { blobMaxY[blobIndex[i]]=y; }
      
      blobPixels[blobIndex[i]].push(new PVector(x, y, depthPoints[i].z));
      if (brightness(irPixels[i])>175) { // this pixel is probably an IR reflecting flag
        blobHasFlag[blobIndex[i]] += 1;
      }
      
      // sum x and y of all points, to computer center of mass
      blobCenterOfMass[blobIndex[i]].x += x;   
      blobCenterOfMass[blobIndex[i]].y += y;
      
      // look at depth of pixel, and set as min Z for the blob if this is lower than min 
      int z = round(depthPoints[i].z);
      if (z>10 && z < minimumZPerBlob[blobIndex[i]]) {
        minimumZPerBlob[blobIndex[i]] = z;
        minimumZLocation[blobIndex[i]] = new PVector(x, y,z);
      }
    }
  }
  
  // find center of mass as average x and y of all points in blob
  for(int i = 0; i < numBlobs; ++i) {
    blobCenterOfMass[i].x /= blobPixels[i].size();
    blobCenterOfMass[i].y /= blobPixels[i].size();
  }
  
  // Now, figure out which people are close to which blobs
  for(Person person : people) {
    person.updateFlag = false;
  }
  
  for(int i = 0; i < numBlobs; ++i) {
    if(blobPixels[i].size() > minimumBlobSize) {
      Person closestPerson = null;
      float distance = 1000000;
      
      for(Person person : people) {
        float newDistance = blobCenterOfMass[i].dist(person.centerOfMass);
        
        if(newDistance < distance && newDistance < maxDistance) {
          distance = newDistance;
          closestPerson = person;
        }
      }
      
      if(closestPerson == null) {
//        people.push(new Person(out, blobCenterOfMass[i], blobPixels[i], blobHasFlag[i], blobMinX[i], blobMinY[i], blobMaxX[i], blobMaxY[i]));
        Person p = new Person(out, blobCenterOfMass[i], blobPixels[i], blobHasFlag[i], blobMinX[i], blobMinY[i], blobMaxX[i], blobMaxY[i]);
        p.setHighestPoint(minimumZPerBlob[i],minimumZLocation[i]);
        people.push(p);
      } else {
        closestPerson.setCenterOfMass(blobCenterOfMass[i]);
        closestPerson.setPixels(blobPixels[i]);
        closestPerson.setBoundingBox(blobMinX[i], blobMinY[i], blobMaxX[i], blobMaxY[i]);
        closestPerson.setHasFlag(blobHasFlag[i]);
        closestPerson.setHighestPoint(minimumZPerBlob[i],minimumZLocation[i]);
      }
    }
  }
  
  // remove people who no longer exist, by making copy of list with only people who still exist
  for(Person person : people) { 
    if(person.updateFlag) {
      keep_people.push(person);
    } else {
      person.destroy();
    }
  }  
  people = keep_people;
  keep_people = new LinkedList<Person>();
}

// Set the blob index for a single pixel
void setBlobIndex(int index, int blobID) {
  blobIndex[index] = blobID;
  
  if(index % camWidth > 0) { //We have a left neighbor
    if(isFreeBlobPixel(index - 1, index)) {
      blobIndexStack.push(new Integer(index - 1));
    }
  }
  
  if(index % camWidth < camWidth - 1) {
    if(isFreeBlobPixel(index + 1, index)) {
      blobIndexStack.push(new Integer(index + 1));
    }
  }
  
  if(index - camWidth >= 0) {
    if(isFreeBlobPixel(index - camWidth, index)) {
      blobIndexStack.push(new Integer(index - camWidth));
    }
  }
  
  if(index + camWidth < blobIndex.length) {
    if(isFreeBlobPixel(index + camWidth, index)) {
      blobIndexStack.push(new Integer(index + camWidth));
    }
  }
}

boolean isFreeBlobPixel(int index) {
  if(blobIndex[index] > 0) {
    return false;
  }
  
  if((depthPoints[index].z > 0 && depthPoints[index].z < 3300) || (brightness(irPixels[index])>80)) {
    return true;
  } else {
    return false;
  }
}

boolean isFreeBlobPixel(int destIndex, int sourceIndex) {
  if(!isFreeBlobPixel(destIndex)) {
    return false;
  }
  
  if(abs(depthPoints[sourceIndex].z - depthPoints[destIndex].z) < 200) {
    return true;
  } else {
    return false;
  }
}