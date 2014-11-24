import SimpleOpenNI.*;

SimpleOpenNI  context;

int camWidth = 640;
int camHeight = 480;

int[] blobIndex;  // all pixels in image, with a number indicating which blob they belong to (or 0 if not part of blob)
int numBlobs = 1;

LinkedList<PVector>[] blobPixels;  // Array of linkedlists, each containing all pixels for a given blob
PVector[] blobCenterOfMass;    // All of vectors with the x,y of center of mass for each blob
boolean[] blobHasFlag;     // true for each blob which contains IR reflector token/flag/marker

LinkedList<Person> people;

int minimumBlobSize = 5000;
float maxDistance = 200;

int[][] neighborLocation = {{0, -1}, {-1, 0}, {1, 0}, {0, 1}};

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
  
//  context.enableRGB();
//println("width = "+context.rgbWidth()+ " height="+context.rgbHeight());
  context.setMirror(true);
  
  people = new LinkedList<Person>();
  
  background(0);
 
  size(camWidth,camHeight);
  
  colorMode(HSB);
}

void draw() {
  background(0);
  updatePeople();
  
  for(Person person : people) {
    person.playNote();
    
    stroke(255);
    PVector offset = new PVector();
    offset = offset.sub(person.centerOfMass, person.velocity);
    line(person.centerOfMass.x, person.centerOfMass.y, offset.x, offset.y);
    noStroke();
    fill(person.personColor);
    ellipse(person.centerOfMass.x, person.centerOfMass.y, 10, 10);
    if (person.hasFlag) { 
      textSize(24);
      text("hasFlag", person.centerOfMass.x, person.centerOfMass.y);
    }
  }
}

void updatePeople() {
  // Reset blobIndex array
  blobIndex = new int[camWidth * camHeight];
  numBlobs = 1;
  
  context.update();
  
  PVector[] depthPoints = context.depthMapRealWorld();
    PImage irImage = context.irImage();
        color[] irPixels = irImage.pixels;
  
  for(int i = 0; i < depthPoints.length; i++) {
    if((depthPoints[i].z > 0 && depthPoints[i].z < 3300) ||  // if depth is within min and max threshhold
        (brightness(irPixels[i])>80))  {  // OR we don't know depth but we have a bright IR reflection (because IR reflecting flag screws with depth data)
      int x = i % camWidth;
      int y = i / camWidth;
      
      setBlobIndex(x, y);   // mark this point as being inside a blob
      
    }
  }
  
  // Set up our per-blob variables
  blobPixels = new LinkedList[numBlobs];
  blobCenterOfMass = new PVector[numBlobs];
  blobHasFlag = new boolean[numBlobs];
  
  for(int i = 0; i < numBlobs; ++i) {
    blobPixels[i] = new LinkedList<PVector>();
    blobCenterOfMass[i] = new PVector();
  }
  
  // Now that the dust has settled, go through and count how
  // many pixels are in each blob
  for(int i = 0; i < blobIndex.length; ++i) {
    
    // Ignore the floor
    if(blobIndex[i] > 0) {
      int x = i % camWidth;
      int y = i / camWidth;
      
      blobPixels[blobIndex[i]].push(new PVector(x, y, depthPoints[i].z));
      if (brightness(irPixels[i])>80) { // this pixel is probably an IR reflecting flag
        blobHasFlag[blobIndex[i]] = true;
      }
      
      blobCenterOfMass[blobIndex[i]].x += x;
      blobCenterOfMass[blobIndex[i]].y += y;
    }
  }
  
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
        people.push(new Person(this, blobCenterOfMass[i], blobPixels[i], blobHasFlag[i]));
      } else {
        closestPerson.setCenterOfMass(blobCenterOfMass[i]);
        closestPerson.setPixels(blobPixels[i]);
      }
    }
  }
  
  for(Person person : people) { // Fix concurrency error
    if(!person.updateFlag) {
      people.remove(person);
    }
  }
}

// Figure out what the blob index should be for a single pixel
void setBlobIndex(int x, int y) {
  int index = coordsToIndex(x, y);
  
  int min = numBlobs;
  
  int[] neighbors = {(y == 0) ? 0 : blobIndex[coordsToIndex(x, y - 1)],
                     (x == 0) ? 0 : blobIndex[coordsToIndex(x - 1, y)],
                     (x == camWidth - 1) ? 0 : blobIndex[coordsToIndex(x + 1, y)],
                     (y == camHeight - 1) ? 0 : blobIndex[coordsToIndex(x, y + 1)]};
  
  for(int i = 0; i < neighbors.length; ++i) {
    if(neighbors[i] != 0) {
      min = min(min, neighbors[i]);
    }
  }

  blobIndex[index] = min;
  
  if(min == numBlobs) {
    numBlobs += 1;
  }
  
  for(int i = 0; i < neighbors.length; ++i) {
    if(neighbors[i] > blobIndex[index]) {
      setBlobIndex(x + neighborLocation[i][0], y + neighborLocation[i][1]);
    }
  }
}

int coordsToIndex(int x, int y) {
  return x + y * camWidth;
}
