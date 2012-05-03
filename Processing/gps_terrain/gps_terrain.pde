/*
  gps_terrain by Becky Stewart
 May 2012
 
 Reads in GPS data and changes a landscape
 accordingly.
 */

import processing.dxf.*;
import processing.serial.*;


Serial myPort;                   // The serial port
GpsParser gpsParser;

ToxiclibsSupport gfx;
TerrainGenerator terrain;

int[] sats = {
  0, 1, 2
};
int[] hdops = {
  0, 1, 2
};



PFont myFont;

// landscape parameters
float s = 0.0; // stability
float j = 0.1; // jaggedness
int longT = 0;
int latT = 0; // translate values for camera
float camRotate = 0.0; // Y rotation of camera

boolean record = false; // record for DXF

int framesPassed = 0;

//--------------------------------------------------
// setup and draw
//--------------------------------------------------
void setup() {
  size(1440, 900, OPENGL);
  // create terrain & generate elevation data
  terrain = new TerrainGenerator(j, s);

  // slow down the frame rate
  frameRate(20);

  // attach drawing utils
  gfx = new ToxiclibsSupport(this);


  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 9600);
  gpsParser = new GpsParser(myPort);

  // set up the font
  myFont = loadFont("AndaleMono-36.vlw"); 
  textFont(myFont, 30);
}

//--------------------------------------------------
void draw() {
  framesPassed++;
  if (framesPassed > 20) {
    updateGpsValues();
    framesPassed = 0;
  }
  if (record) {
    beginRaw(DXF, "output.dxf");
  }

  background(128, 128, 128);

  // setup lights
  updateLights(h, 0);

  fill(168, 168, 168);
  noStroke();

  beginCamera();
  camera();
  rotateX(camRotate);
  translate(longT, 1000, latT);
  endCamera();


  // draw mesh
  terrain.display();


  pushMatrix();

  translate(longT, -1000, latT);
  rotateX(-camRotate);
  // raw data feeds

  // label boxes
  fill(255);
  int rh = 40;
  for (int i=0; i<4; i++) {
    rect(47, 69 + i*50, 242, rh); // sat
    rect(297, 69 + i*50, 135, rh); //hdop
    rect(447, 69 + i*50, 210, rh); // lat
    rect(677, 69 + i*50, 225, rh); //long
    rect(927, 69 + i*50, 210, rh); //alt
    rect(1147, 69 + i* 50, 190, rh); // fix
  }
  rect(47, 670, 390, rh*2.3); // date and time




  fill(0);
  text("SATELLITES //", 50, 100);
  text("HDOP //", 300, 100);
  text("LATITUDE //", 450, 100);
  text("LONGITUDE //", 680, 100);
  text("ALTITUDE //", 930, 100);
  text("FIX AGE //", 1150, 100);

  for (int i=0; i<3; i++) {
    text(sats[i], 50, 150 + i*50);
    text(hdops[i], 300, 150 + i*50);
  }

  text("DATE //", 50, 700);
  text("TIME //", 50, 750);

  popMatrix();


  if (record) {
    endRaw();
    record = false;
  }
}

//--------------------------------------------------
// function for reading gps data
//--------------------------------------------------
void serialEvent(Serial myPort) {
  gpsParser.serialEvent();
}

void updateGpsValues() {
  for (int i=1; i<3; i++) {
    sats[i] = sats[i-1];
  }
  //sats[0] = gpsParser.getSatellites();
  sats[0] = 5;
}

//--------------------------------------------------
// function for lighting
//--------------------------------------------------
void updateLights(int currHour, int currMin) {
  // June sunrise 5:00
  // June sunset 9:30
  int ambLevel;
  float spotX;
  if (currHour<14) {
    ambLevel = 10 + currHour*10;
    spotX = -100 + currHour*100.0;
  }
  else {
    ambLevel = 10 + (23-currHour)*10;
    spotX = -100 + (23-currHour)*100.0;
  }

  ambientLight(ambLevel, ambLevel/2, ambLevel);
  spotLight(223, 0, 255, -spotX, 5000.0, 1000.0, -1, 1, 0, PI/2, 2);
}

//--------------------------------------------------
// functions for moving the camera
//--------------------------------------------------
void moveCameraLeft(int amount) {
  longT += amount;
}
//--------------------------------------------------
void moveCameraRight(int amount) {
  longT -= amount;
}
//--------------------------------------------------
void moveCameraForward(int amount) {
  latT += amount;
}
//--------------------------------------------------
void moveCameraBackward(int amount) {
  latT -= amount;
}

//--------------------------------------------------
// interactive tests
//--------------------------------------------------
void mouseDragged() {
  if (mouseY > pmouseY) {
    camRotate = (camRotate + radians(5))%(2*PI);
  } 
  else {
    camRotate = (camRotate - radians(5))%(2*PI);
  }
}

//--------------------------------------------------
void keyPressed() {
  switch(key) {
    // change the jaggedness
  case 'y':
    terrain.updateJaggedness(j -= 0.02);
    break;
  case 't':
    terrain.updateJaggedness(j += 0.02);
    break;
    // change the stability
  case 'f':
    terrain.updateStability(s -= 10.0);
    break;
  case 'g':
    terrain.updateStability(s += 10.0);
    break;
    // move right
  case 'k':
    moveCameraRight(10);
    break;
    //move left
  case 'j':
    moveCameraLeft(10);
    break;
    //move forward
  case 'i':
    moveCameraForward(10);
    break;
    //move backward
  case 'm':
    moveCameraBackward(10);
    break;
    // record for DXF
  case 'r':
    record = true;
    break;
  }
}

//--------------------------------------------------
int h = 0;
void mouseReleased() {
  h+=1; 
  h = h%24;
}

