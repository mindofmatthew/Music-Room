import SimpleOpenNI.*;
import arb.soundcipher.*;

SimpleOpenNI  context;

int[] blobIndex;
int numBlobs = 1;

float[][] pitchSet = {{48, 50, 52, 53, 55}, {57, 59, 60,62,64},{65,67, 69, 71,72}, {74, 76, 79,81,83}, {57, 59, 60,62,64}};
int[] pixelsPerBlob;
int[] minimumZPerBlob;
boolean[][] activeNote;

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
  
  int maxArea = 0;
  
  for(int i = 0; i < minimumZPerBlob.length; ++i) {
    minimumZPerBlob[i] = 3500;
  }
  
  for(int i = 0; i < blobIndex.length; ++i) {
    if(blobIndex[i] > 0) {
      pixelsPerBlob[blobIndex[i]] += 1;
      maxArea = max(maxArea, pixelsPerBlob[blobIndex[i]]);
      
      minimumZPerBlob[blobIndex[i]] = min(minimumZPerBlob[blobIndex[i]], round(depthPoints[i].z));
    }
  }
  
  println(maxArea);
  
  
  for(int i = 0; i < blobIndex.length; ++i) {
    if(blobIndex[i] > 0) {
      rgbImage.pixels[i] = color(map(minimumZPerBlob[blobIndex[i]], 1000, 3000, 0, 255), 255, 255);
      //rgbImage.pixels[i] = color(map(minimumZPerBlob[blobIndex[i]], 0, maxArea, 0, 255), 255, 255);
    }
  }
  
  rgbImage.updatePixels();
  image(rgbImage, 0, 0);
  
  /*for(int i = 0; i < pixelsPerCell.length; ++i) {
    for(int j = 0; j < pixelsPerCell[i].length; ++j) {
      if(pixelsPerCell[i][j] > 300) {
        noFill();
        stroke(255);
        rect(i * width / 5, j * height / 5, width / 5, height / 5);
        
        if(!activeNote[i][j]) {
          int octave = round(map(minimumZ[i][j], 3000, 1000, -1, 2));
          
          //ciphers[cipherIndex].playNote(pitchSet[i][j] + octave * 12, 127, 10);
          //cipherIndex = (cipherIndex + 1) % ciphers.length;
          //activeNote[i][j] = true;
        }
      } else {
        if(activeNote[i][j]) {
          activeNote[i][j] = false;
        }
      }
    }
  }*/
}

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
