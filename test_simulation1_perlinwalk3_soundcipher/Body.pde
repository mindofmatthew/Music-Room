// Body, with some code borrowed from Dan Shiffman's "Mover" class
import arb.soundcipher.*;

class Body {

  // The Mover tracks location, velocity, and acceleration 
  PVector location;
  PVector velocity;
  PVector acceleration;
  // The Mover's maximum speed
  float topspeed;
  
  // for perlin noise
  float tx,ty;
  
  String name;

  
  Body(String name) {
    // Start in the center
    location = new PVector(random(width),random(height));
    velocity = new PVector(0,0);
    acceleration = new PVector(0,0);
    topspeed = 6;
    tx = int(random(50000));
    ty = int(random(50000));
    this.name = name;
  } 
 
 void update() {
       // Velocity changes according to acceleration
    velocity.add(acceleration);
    // Limit the velocity by topspeed
    velocity.limit(topspeed);
    // Location changes by velocity
    location.add(velocity);
    
        // Stay on the screen
    location.x = constrain(location.x, 0, width-1);
    location.y = constrain(location.y, 0, height-1);
    
 }
 
 void setAcceleration(PVector newAccel) {
   acceleration  = newAccel;
 }
 
 
 
 void perlinWalk() {

   
   float negX = -1;
   float posX = +1;
   float negY = -1;
   float posY = +1;
   
     // walker tends to stay away from sides
   // this doesn't quite work, because perlin noise tends to push in the same direction, so when we hit the
   // side threshhold we reverse the acceleration but the next iteration will still try to push off the edge
   // so we end up oscillating on the edge for a while, til the noise moves us away again.
   // probably a better way to do this, but the point is not to build a perfect random walker.
   int sideThresh = 150; // how close to sides before we start turning away
   
   // as body approaches sides, increase probability of turning around (how?)
   if (location.x < sideThresh && velocity.x<0) {
      // too far left, bounce back
      negX = map(location.x, 0, sideThresh, 0, -1);
   }
   if (location.x >(width-sideThresh) && velocity.x>0) {
      // too far right, bounce back
      posX = map(location.x, width-sideThresh, width,1 , 0);
   }
   if (location.y < sideThresh && velocity.y<0) {
      negY = map(location.y, 0,sideThresh,0,-1);
   }
   if (location.y >(height-sideThresh) && velocity.y>0) {
      posY = map(location.y,(height-sideThresh),height,1,0);
   }
   
   
       float x = map(noise(tx), 0, 1, negX, posX);
    float y = map(noise(ty), 0, 1, negY, posY);
 
   acceleration = new PVector(x,y);
   acceleration.normalize();
   
//   // walker tends to stay away from sides
//   // this doesn't quite work, because perlin noise tends to push in the same direction, so when we hit the
//   // side threshhold we reverse the acceleration but the next iteration will still try to push off the edge
//   // so we end up oscillating on the edge for a while, til the noise moves us away again.
//   // probably a better way to do this, but the point is not to build a perfect random walker.
//   int sideThresh = 100; // how close to sides before we start turning away
//   
//   // as body approaches sides, increase probability of turning around (how?)
//   if (location.x < sideThresh && velocity.x<0) {
//     // set acceleration to positive x
//     acceleration.x = 0; //abs(acceleration.x);  // just setting to 0 doesn't work -- they all get stuck in corners?
//   }
//   if (location.x >(width-sideThresh) && velocity.x>0) {
//     // set acceleration to negative x
//          acceleration.x = 0; //-1 * abs(acceleration.x);
//
//   }
//   if (location.y < sideThresh && velocity.y<0) {
//     // set acceleration to positive y
//     acceleration.y = 0; // abs(acceleration.y);
//   }
//   if (location.y >(height-sideThresh) && velocity.y>0) {
//     // set acceleration to negative y
//     acceleration.y = 0; //-1*abs(acceleration.y);
//
//   }
   
   
   println (x+", "+y+" : "+acceleration.x+", "+acceleration.y);

   
    tx += 0.01;
    ty += 0.01;
   
 }
 
 
 
 void perlinWalk2() {

   // want to avoid edges.  as we move away from center in any direction, decrease acceleration in that direction
   
  PVector center = new PVector(width/2, height/2);
  PVector delta = PVector.sub(center, location);
  // delta points from location to center
  float length = delta.mag();
  delta.div(1000);
  
  

     float negX = -1;
   float posX = +1;
   float negY = -1;
   float posY = +1; 
   
      int sideThresh = 150; // how close to sides before we start turning away
   
   // as body approaches sides closer than threshhold, limit possible acceleration to push away from sides
   if (location.x < sideThresh && velocity.x<0) {
      // too far left, bounce back
      negX = map(location.x, 0, sideThresh, 0, -1);
   }
   if (location.x >(width-sideThresh) && velocity.x>0) {
      // too far right, bounce back
      posX = map(location.x, width-sideThresh, width,1 , 0);
   }
   if (location.y < sideThresh && velocity.y<0) {
      negY = map(location.y, 0,sideThresh,0,-1);
   }
   if (location.y >(height-sideThresh) && velocity.y>0) {
      posY = map(location.y,(height-sideThresh),height,1,0);
   }
   
       float x = map(noise(tx), 0, 1, negX, posX);
    float y = map(noise(ty), 0, 1, negY, posY);
 
   acceleration = new PVector(x,y);
   acceleration.add(delta); // try pushing back towards center
   acceleration.normalize();
 
   
   println (x+", "+y+" : "+acceleration.x+", "+acceleration.y);

   
    tx += 0.01;
    ty += 0.01;
   
 }
 
 void randomWalk() {
   // generate random acceleration
   
   acceleration = new PVector(random(-1,1),random(-1,1));
    acceleration.normalize();
 }
   
 void display() {
    stroke(0);
    strokeWeight(2);
    fill(127);
    pushMatrix();
   translate(location.x,location.y);
  // rotate according to current heading
  //   add a half turn to the rotation 
  //    (otherwise will always head towards starboard shoulder)
    rotate(velocity.heading()+(PI/2));  
    // body (from top)
    ellipse(0,0,100,40);
    
    // head
    fill(0);
    ellipse(0,0,30,30);
    
    // label the person
    
    // starboard and port shoulder patches
    rectMode(CENTER);
    fill(200,0,0);
    rect(-50,0,10,10);
    fill(0,200,0);
    rect(50,0,10,10);
    
    fill(255);
    text(name, 0,0);
    
    popMatrix();
    
  } 
  
  int lastIdx = 0;
    int lastIdy = 0;
  void play(SoundCipher sc, float[][] pitchSet, float keyRoot) {
    int setSize = pitchSet.length;
    // need to divide floor into sectors, each corresponding to a note in the set,
    // so there are setSize quadrants.  
    // how to calculate which quadrant we are in based on x and y and width and height?
    int idxX = int(map(location.x, 0, width, 0, 4));   // note: hardcoding x and y dimensions of 2d pitchset -- cheating
        int idxY = int(map(location.x, 0, width, 0, 5));
//    // for now, use velocity...
//    lastIdx = lastIdx + int(velocity.mag());
//    if (lastIdx >= setSize) lastIdx=0;
    lastIdx = idxX;
    lastIdy = idxY;
    
        sc.playNote(pitchSet[lastIdx][lastIdy]+keyRoot, random(90)+30, random(20)/10 + 0.2);
  }
}
