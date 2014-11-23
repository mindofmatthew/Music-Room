import SimpleOpenNI.*;
import arb.soundcipher.*;

SimpleOpenNI  context;

int[] blobIndex;
int numBlobs = 1;

LinkedList<PVector>[] blobPixels;
PVector[] blobCenterOfMass;

LinkedList<Person> people;

SoundCipher[] ciphers;
int cipherLength = 4;
int cipherIndex = 0;

int minimumBlobSize = 5000;
float maxDistance = 200;

int[][] neighborLocation = {{0, -1}, {-1, 0}, {1, 0}, {0, 1}};

void setup()
{
  context = new SimpleOpenNI(this);
   
  // enable depthMap generation 
  context.enableDepth();
  context.enableRGB();
  //context.alternativeViewPointDepthToImage();
  context.setMirror(true);
  
  people = new LinkedList<Person>();
  
  background(0);
  size(context.rgbWidth(), context.rgbHeight()); 
  
  colorMode(HSB);
  
  ciphers = new SoundCipher[cipherLength];
  for(int i = 0; i < ciphers.length; ++i) {
    ciphers[i] = new SoundCipher(this);
  }
}

void draw() {
  background(0);
  updatePeople();
  
  /*for(Person person : people) {
    fill(person.personColor);
    ellipse(person.centerOfMass.x, person.centerOfMass.y, 10, 10);
  }*/
  
  for(int i = 0; i < numBlobs; ++i) {
    if(blobPixels[i].size() > minimumBlobSize) {
      ellipse(blobCenterOfMass[i].x, blobCenterOfMass[i].y, 10, 10);
    }
  }
}

void updatePeople() {
  blobIndex = new int[context.rgbWidth() * context.rgbHeight()];
  numBlobs = 1;
  
  context.update();
  
  PVector[] depthPoints = context.depthMapRealWorld();
  
  for(int i = 0; i < depthPoints.length; i++) {
    if(depthPoints[i].z > 0 && depthPoints[i].z < 3300) {
      int x = i % 640;
      int y = i / 640;
      
      setBlobIndex(x, y);
    }
  }
  
  // Set up our per-blob variables
  blobPixels = new LinkedList[numBlobs];
  blobCenterOfMass = new PVector[numBlobs];
  
  for(int i = 0; i < numBlobs; ++i) {
    blobPixels[i] = new LinkedList<PVector>();
    blobCenterOfMass[i] = new PVector();
  }
  
  // Now that the dust has settled, go through and count how
  // many pixels are in each blob
  for(int i = 0; i < blobIndex.length; ++i) {
    // Ignore the floor
    if(blobIndex[i] > 0) {
      int x = i % 640;
      int y = i / 640;
      
      blobPixels[blobIndex[i]].push(new PVector(x, y, depthPoints[i].z));
      
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
        people.push(new Person(blobCenterOfMass[i], blobPixels[i]));
      } else {
        closestPerson.setPixels(blobPixels[i]);
      }
    }
  }
}

// Figure out what the blob index should be for a single pixel
void setBlobIndex(int x, int y) {
  int index = coordsToIndex(x, y);
  
  int min = numBlobs;
  
  int[] neighbors = {(y == 0) ? 0 : blobIndex[coordsToIndex(x, y - 1)],
                     (x == 0) ? 0 : blobIndex[coordsToIndex(x - 1, y)],
                     (x == context.rgbWidth() - 1) ? 0 : blobIndex[coordsToIndex(x + 1, y)],
                     (y == context.rgbHeight() - 1) ? 0 : blobIndex[coordsToIndex(x, y + 1)]};
  
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
  return x + y * context.rgbWidth();
}
