import toxi.geom.mesh.*;
import toxi.processing.*;
import processing.opengl.*;

class TerrainGenerator {
  float jaggedness;
  float stability;
  float[] el;
  int terrainWidth;
  int terrainHeight;
  Terrain terrain;
  Mesh3D mesh;
  int framesPassed;

  // Constructor (creates and sets up the object)
  TerrainGenerator(float jag, float stab) {
    // peakiness of terrain
    jaggedness = jag;
    stability = stab;

    // width and height of terrain
    terrainWidth = 100; 
    terrainHeight = 100;

    // raw elevation values of terrain
    el = new float[terrainWidth*terrainHeight];

    framesPassed = 0;

    createTerrain();
  }

  // generates a brand new terrain
  void createTerrain() { 
    terrain = new Terrain(terrainWidth, terrainHeight, 200);

    noiseSeed(500);
    for (int z = 0, i = 0; z < terrainHeight; z++) {
      for (int x = 0; x < terrainWidth; x++) {
        el[i++] = noise(x * jaggedness, z * jaggedness) * 2000;
      }
    }
    terrain.setElevation(el);
    // create mesh
    mesh = terrain.toMesh();
  }

  // introduce some noise
  void destabilise() {
    for (int i=0; i<terrainWidth*terrainHeight; i++) {
      el[i] = el[i] + random(stability*-1.0, stability);
    }
    terrain.setElevation(el);
    // create mesh
    mesh = terrain.toMesh();
  }

  // change the stability
  void updateStability(float s) {
    // stability can't be negative
    abs(s);
    stability = s;
  }
  
  // change the jaggedness
  void updateJaggedness(float j) {
     jaggedness = j;
    createTerrain(); 
  }

  // draws the terrain
  void display() {
    fill(223, 0, 255);
    destabilise();
    if (framesPassed > 10) {
      createTerrain();
      framesPassed = 0;
    }
    gfx.mesh(mesh, false);
    framesPassed++;
  }
}

