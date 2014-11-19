import SimpleOpenNI.*;
import arb.soundcipher.*;

SimpleOpenNI  context;

int[] reference;

float[][] pitchSet = {{48, 50, 52, 53, 55}, {57, 59, 60,62,64},{65,67, 69, 71,72}, {74, 76, 79,81,83}, {57, 59, 60,62,64}};
int[][] pixelsPerCell;
int[][] minimumZ;
boolean[][] activeNote;

SoundCipher[] ciphers;
int cipherLength = 4;
int cipherIndex = 0;

void setup()
{
  context = new SimpleOpenNI(this);
   
  // enable depthMap generation 
  context.enableDepth();
  context.enableRGB();
  context.alternativeViewPointDepthToImage();
  context.setMirror(true);
  
  reference = new int[context.rgbWidth()];
 
  background(0);
  size(context.rgbWidth(), context.rgbHeight()); 
  
  colorMode(HSB);
  
  ciphers = new SoundCipher[cipherLength];
  for(int i = 0; i < ciphers.length; ++i) {
    ciphers[i] = new SoundCipher(this);
  }
  
  pixelsPerCell = new int[5][5];
  activeNote = new boolean[5][5];
}

void draw() {
  // update the cam
  context.update();
  PImage rgbImage = context.rgbImage();
  rgbImage.loadPixels();
  
  PVector[] depthPoints = context.depthMapRealWorld();
  
  PVector mousePoint = depthPoints[mouseY * width + mouseX];
  println(mousePoint.z);
  
  for(int i = 0; i < pixelsPerCell.length; ++i) {
    for(int j = 0; j < pixelsPerCell[i].length; ++j) {
      pixelsPerCell[i][j] = 0;
    }
  }
  
  for(int i = 0; i < depthPoints.length; i++) {
    float hue = hue(rgbImage.pixels[i]);
    float saturation = saturation(rgbImage.pixels[i]);
    float brightness = brightness(rgbImage.pixels[i]);
    
    if(depthPoints[i].z > 0 && depthPoints[i].z < 3300) {
    //if(hue >= 37 && hue <= 42 && saturation > 60 && brightness > 60) {
      int x = (i % context.rgbWidth()) / (context.rgbWidth() / 5);
      int y = (i / context.rgbHeight()) / (context.rgbWidth() / 5);
      
      //rgbImage.pixels[i] = color(hue(rgbImage.pixels[i]), 255, 255);
      
      pixelsPerCell[x][y] += 1;
    } else {
      //color source = rgbImage.pixels[i];
      //rgbImage.pixels[i] = color(hue(source), 0, brightness(source));
      rgbImage.pixels[i] = color(0);
    }
  }
  
  rgbImage.updatePixels();
  image(rgbImage, 0, 0);
  
  for(int i = 0; i < pixelsPerCell.length; ++i) {
    for(int j = 0; j < pixelsPerCell[i].length; ++j) {
      if(pixelsPerCell[i][j] > 300) {
        noFill();
        stroke(255);
        rect(i * width / 5, j * height / 5, width / 5, height / 5);
        
        if(!activeNote[i][j]) {
          ciphers[cipherIndex].playNote(pitchSet[i][j], 127, 10);
          cipherIndex = (cipherIndex + 1) % ciphers.length;
          activeNote[i][j] = true;
        }
      } else {
        if(activeNote[i][j]) {
          activeNote[i][j] = false;
        }
      }
    }
  }
}

void fill(int x, int y) {
  int index = coordsToIndex(x, y);
  
  int min = 0;
  
  int[] neighbors = {(y == 0) ? 0 : reference[coordsToIndex(x, y - 1)],
                     (x == 0) ? 0 : reference[coordsToIndex(x - 1, y)],
                     (x == context.rgbWidth() - 1) ? 0 : reference[coordsToIndex(x + 1, y)],
                     (y == context.rgbHeight() - 1) ? 0 : reference[coordsToIndex(x, y + 1)]};
  
  for(int i = 0; i < neighbors.length; ++i) {
    if(neighbors[i] != 0) {
      min = min(min, neighbors[i]);
    }
  }
  
  if(min > 0) {
    reference[index] = min;
    
    for(int i = 0; i < neighbors.length; ++i) {
      if(neighbors[i] != 0) {
        min = min(min, neighbors[i]);
      }
    }
  }
}

int coordsToIndex(int x, int y) {
  return x * context.rgbWidth() + y * context.rgbWidth() * context.rgbHeight();
}
