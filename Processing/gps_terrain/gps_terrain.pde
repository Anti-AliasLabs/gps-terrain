/*
  gps_terrain by Becky Stewart
 May 2012
 
 Reads in GPS data and changes a landscape
 accordingly.
 */

import processing.dxf.*;
import processing.serial.*;
import peasy.*;

PeasyCam cam;

Serial myPort;                   // The serial port
GpsParser gpsParser;

ToxiclibsSupport gfx;
TerrainGenerator terrain;

int[] sats;
int[] hdops;
float[] lats;
float[] longs;
int[] fixes;
float[] altitudes;

int secs;
int mins;
int hours;
int days;
int months;
int years;

PFont myFont;

// landscape parameters
float s = 0.0; // stability
float prev_s = 0.0;
float j = 0.1; // jaggedness
float moveLR = 0;
float prev_moveLR = 0;
float moveFB = 0;
float prev_moveFB = 0;



float longT = 0;
float latT = 0; // translate values for camera
float camRotate = 0.0; // Y rotation of camera

boolean record = false; // record for DXF

int framesPassed = 0;

//--------------------------------------------------
// setup and draw
//--------------------------------------------------
void setup() {
  size(1440, 900, OPENGL);

  // set up camera
  cam = new PeasyCam(this, 100);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(500);

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
  textFont(myFont, 18);


  // initialise arrays
  sats = new int[3];
  hdops = new int[3];
  lats = new float[3];
  longs = new float[3];
  fixes = new int[3];
  altitudes = new float[3];
  secs = 0;
  mins = 0;
  hours = 0;
  days = 0;
  months = 0;
  years = 0;
  
  for ( int i=0; i<3; i++) {
    sats[i] = 0;
    hdops[i] = 0;
    lats[i] = 0.0;
    longs[i] = 0.0;
    fixes[i] = 0;
    altitudes[i] = 0.0;
  }
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

  fill(168, 168, 168);
  noStroke();
  
  // setup lights
  updateLights(12, 0);

  beginCamera();
  camera();
  rotateX(camRotate);
  translate(longT, 1000, latT);
  endCamera();


  // draw mesh
  updateTerrain();
  terrain.display();

  // HUD
  cam.beginHUD();
  
  // setup lights
  updateHUDLights();
  
  // raw data feeds

  // label boxes
  fill(255);
  int rh = 20;
  for (int i=0; i<4; i++) {
    rect(47, 53 + i*30, 150, rh); // sat
    rect(217, 53 + i*30, 85, rh); //hdop
    rect(377, 53 + i*30, 130, rh); // lat
    rect(527, 53 + i*30, 140, rh); //long
    rect(747, 53 + i*30, 130, rh); //alt
    rect(897, 53 + i*30, 120, rh); // fix
  }
  rect(1197, 53, 185, rh); // date and time
  rect(1197, 83, 185, rh);

  rect(47, 764, 250, rh); // title
  rect(47, 794, 360, rh);

  fill(0);
  text("SATELLITES //", 50, 70);
  text("HDOP //", 220, 70);
  text("LATITUDE //", 380, 70);
  text("LONGITUDE //", 530, 70);
  text("ALTITUDE //", 750, 70);
  text("FIX AGE //", 900, 70);

  text("UNSTABLE LANDSCAPES //", 50, 780);
  text("GPS MODULE // POLSTAR PMB-648 //", 50, 810);

  for (int i=0; i<3; i++) {
    text(sats[i], 50, 100 + i*30);
    text(hdops[i], 220, 100 + i*30);
    
    String lt = nfs(lats[i], 2, 5);
    String ln = nfs(longs[i], 1, 5);
    
    text(lt, 371, 100 + i*30);
    text(ln, 530, 100 + i*30);
    text(altitudes[i], 750, 100 + i*30);
    text(fixes[i], 900, 100 + i*30);
  }

  text("DATE //", 1200, 70);
  String d = days + "/" + months + "/" + years;
  text(d, 1290, 70);
  
  String h, m, s;
  if( hours < 10) {
    h = "0" + hours + ":";
  } else h = hours + ":";
  if( mins < 10) {
    m = "0" + mins + ":";
  } else m = mins + ":";
  if( secs < 10) {
    s = "0" + secs;
  } else s = secs + " ";
  
  String t = h + m  + s;
  text(t, 1290, 100);
  text("TIME //", 1200, 100);

  cam.endHUD();


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
    hdops[i] = hdops[i-1];
    fixes[i] = fixes[i-1];
    lats[i] = lats[i-1];
    longs[i] = longs[i-1];
    altitudes[i] = altitudes[i-1];
  }
  
  sats[0] = gpsParser.getSatellites();
  hdops[0] = gpsParser.getHDOP();
  fixes[0] = gpsParser.getFixAge();
  
  lats[0] = gpsParser.getLatitude();
  longs[0] = gpsParser.getLongitude();
  altitudes[0] = gpsParser.getAltitude();
  
  hours = (gpsParser.getHour() + 1)%24;
  mins = gpsParser.getMinute();
  secs = gpsParser.getSeconds();
  
  days = gpsParser.getDay();
  months = gpsParser.getMonth();
  years = gpsParser.getYear();
}

void updateTerrain() {
  // jaggedness affected by HDOP
  // 100-150 almost flat terrain 0.01
  j = map(hdops[0], 100, 5000, 0.01, 0.9);
  if(hdops[0] == 0)
    j = 1.0;
  terrain.updateJaggedness(j);
  
  // stability affected by satellites
  if( sats[0] > 0 ){
    s = 50/sats[0];
  }
  else {
    s = 100.0;
  }
  if( s != prev_s ) {
    terrain.updateStability(s); 
  }
  prev_s = s;
  
  // lat and long affect camera view
  /*
  moveLR =  0.0 - longs[0] - prev_moveLR;
  moveCameraLeft(moveLR*10000);
  println("------moveLR: " + moveLR*100000.0);
  prev_moveLR = moveLR;
  
  moveFB =  (51.0 - lats[0] - prev_moveFB)*100000.;
  moveCameraForward( moveFB);
  println("------moveFB: " + moveFB);
  prev_moveFB = moveFB;
  */
}

//--------------------------------------------------
// function for lighting
//--------------------------------------------------
void updateHUDLights() {
  //spotLight(20, 20, 20, 1000.0, 1000.0, 1000.0, 0, 1, 0, PI/2, 2);
  directionalLight(100, 100, 100, 0.5f, 500.19f, 0.5f);
}

void updateLights(int currHour, int currMin) {
  // June sunrise 5:00
  // June sunset 9:30
  int ambLevel = 150;
  float spotX;
  if (currHour<14) {
    //ambLevel = 10 + currHour*10;
    spotX = -100 + currHour*100.0;
  }
  else {
    //ambLevel = 10 + (23-currHour)*10;
    spotX = -100 + (23-currHour)*100.0;
  }

  //ambientLight(ambLevel, ambLevel/2, ambLevel);
  //spotLight(123, 0, 155, -spotX, 500.0, 1000.0, -1, 1, 0, PI/4, 2);
  directionalLight(200, 200, 200, 0.5f, -0.1f, 0.5f);
}

//--------------------------------------------------
// functions for moving the camera
//--------------------------------------------------
void moveCameraLeft(float amount) {
  if(abs(amount) < 10)
    longT += amount;
}
//--------------------------------------------------
void moveCameraRight(float amount) {
  if(abs(amount) < 10)
    longT -= amount;
}
//--------------------------------------------------
void moveCameraForward(float amount) {
  if(abs(amount) < 10)
    latT += amount;
}
//--------------------------------------------------
void moveCameraBackward(float amount) {
  if(abs(amount) < 10)
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

