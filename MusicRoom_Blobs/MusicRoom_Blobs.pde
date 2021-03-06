import SimpleOpenNI.*;
import arb.soundcipher.*;

SimpleOpenNI  context;

int[] blobIndex;
int numBlobs = 1;

int[] pixelsPerBlob;
int[] minimumZPerBlob;
PVector[] minimumZLocation;
PVector[] centerOfMass;

SoundCipher[] ciphers;
int cipherLength = 4;
int cipherIndex = 0;

int[][] neighborLocation = {{0, -1}, {-1, 0}, {1, 0}, {0, 1}};

void setup()
{
  context = new SimpleOpenNI(this);
   
  // enable depthMap generation 
  context.enableDepth();
  context.enableRGB();
  context.alternativeViewPointDepthToImage();
  context.setMirror(true);
 
  background(0);
  size(context.rgbWidth(), context.rgbHeight()); 
  
  colorMode(HSB);
  
  ciphers = new SoundCipher[cipherLength];
  for(int i = 0; i < ciphers.length; ++i) {
    ciphers[i] = new SoundCipher(this);
  }
  
  activeNote = new boolean[5][5];
}

void draw() {
  blobIndex = new int[context.rgbWidth() * context.rgbHeight()];
  numBlobs = 1;
  
  context.update();
  PImage rgbImage = context.rgbImage();
  
  PVector[] depthPoints = context.depthMapRealWorld();
  
  for(int i = 0; i < depthPoints.length; i++) {
    float hue = hue(rgbImage.pixels[i]);
    float saturation = saturation(rgbImage.pixels[i]);
    float brightness = brightness(rgbImage.pixels[i]);
    
    if(depthPoints[i].z > 0 && depthPoints[i].z < 3300) {
      int x = i % 640;
      int y = i / 640;
      
      setBlobIndex(x, y);
      
      //pixelsPerCell[x][y] += 1;
      //pixelsPerCell[x][y] = round(min(pixelsPerCell[x][y], depthPoints[i].z));
    } else {
      //rgbImage.pixels[i] = color(0);
    }
  }
  
  rgbImage.loadPixels();
  
  pixelsPerBlob = new int[numBlobs];
  minimumZPerBlob = new int[numBlobs];
  minimumZLocation = new PVector[numBlobs];
  centerOfMass = new PVector[numBlobs];
  
  int maxArea = 0;
  
  for(int i = 0; i < minimumZPerBlob.length; ++i) {
    minimumZPerBlob[i] = 3500;
    centerOfMass[i] = new PVector();
  }
  
  for(int i = 0; i < blobIndex.length; ++i) {
    if(blobIndex[i] > 0) {
      pixelsPerBlob[blobIndex[i]] += 1;
      maxArea = max(maxArea, pixelsPerBlob[blobIndex[i]]);
      
      float x = i % 640;
      float y = i / 640;
      
      centerOfMass[blobIndex[i]].x += x;
      centerOfMass[blobIndex[i]].y += y;
      
      minimumZPerBlob[blobIndex[i]] = min(minimumZPerBlob[blobIndex[i]], round(depthPoints[i].z));
      if(minimumZPerBlob[blobIndex[i]] == round(depthPoints[i].z)) {
        minimumZLocation[blobIndex[i]] = new PVector(x, y);
      }
    }
  }
  
  println(maxArea);
  
  
  for(int i = 0; i < blobIndex.length; ++i) {
    if(blobIndex[i] > 0) {
      rgbImage.pixels[i] = color(map(pixelsPerBlob[blobIndex[i]], 0, maxArea, 0, 255), 255, 255);
    }
  }
  
  rgbImage.updatePixels();
  image(rgbImage, 0, 0);
  
  stroke(255);
  
  for(int i = 1; i < minimumZLocation.length; ++i) {
    centerOfMass[i].x /= pixelsPerBlob[i];
    centerOfMass[i].y /= pixelsPerBlob[i];
    
    if(pixelsPerBlob[i] > 50) {
      ellipse(centerOfMass[i].x, centerOfMass[i].y, 5, 5);
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
