import java.util.LinkedList;

class Person {
  private LinkedList<PVector> containedPixels;
  PVector centerOfMass;
  
  boolean updateFlag = true;
  
  color personColor;
  
  Person(PVector centerOfMass, LinkedList<PVector> containedPixels) {
    this.containedPixels = containedPixels;
    this.centerOfMass = centerOfMass;
    
    colorMode(HSB);
    personColor = color(round(random(255)), 255, 255);
  }
  
  void setPixels(LinkedList<PVector> containedPixels) {
    this.containedPixels = containedPixels;
    updateFlag = true;
  }
  
  /*
  minimumZPerBlob = new int[numBlobs];
  minimumZLocation = new PVector[numBlobs];
  
    int maxArea = 0;
  
  for(int i = 0; i < minimumZPerBlob.length; ++i) {
    minimumZPerBlob[i] = 3500;
    
    
    maxArea = max(maxArea, pixelsPerBlob[blobIndex[i]]);
  
  
  
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
  
  */
}
