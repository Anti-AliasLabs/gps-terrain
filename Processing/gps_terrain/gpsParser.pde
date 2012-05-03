

class GpsParser {
  int sats;
  int hdop;
  float lat, lon;
  int fix;
  int currMon, currDay, currYear;
  int currHour, currMin, currSec;
  float altitude;

  Serial myPort;

  GpsParser(Serial port) {

    // read bytes into a buffer until you get a carriage
    // return (ASCII 13):
    myPort = port;
    myPort.bufferUntil(',');


    int sats = 0;
    int hdop = 0;
    float lat = 0.0;
    float lon = 0.0;
    int fix = 0;
    int currMon = 0;
    int currDay = 0;
    int currYear = 0;
    int currHour = 0;
    int currMin = 0;
    int currSec = 0;
    float altitude = 0.0;
  }

  void serialEvent() {
    // read the serial buffer:
    String myString = myPort.readStringUntil(',');
    // if you got any bytes other than the linefeed, parse it:
    if (myString != null) {
      //print(myString);
      parseString(myString);
    }
  }

  void parseString (String serialString) {
    // split the string at the commas:
    String items[] = (split(serialString, ':'));
    // number of sats
    if (items.length > 1) {
      String label = trim(items[0]);
      String val = split(items[1], ',')[0];
      //print(label  + ' ');
      if (label.equals("LAT")) {
        setLatitude(val);
      }
      if (label.equals("LON")) {
        setLongitude(val);
      }
      if (label.equals("ALT")) {
        setAltitude(val);
      }
      if (label.equals("SAT")) {
        setSatellites(val);
        print("PSats: " + val + ' ');
      }
      if (label.equals("HDO")) {
        setHDOP(val);
      }
      if (label.equals("AGE")) {
        setFixAge(val);
      }
      if (label.equals("DAT")) {
        setDateTime(val);
      }
    }
  }

  void setLatitude(String newLat) {
    lat = float(newLat);
    print("Lat: " + lat + ' ');
  }

  float getLatitude() {
    return lat;
  }

  void setLongitude(String newLon) {
    lon = float(newLon);
    print("Lon: " + lon + ' ');
  }

  float getLongitude() {
    return lon;
  }

  void setAltitude(String newAlt) {
    altitude = float(newAlt);
    print("Altitude: " + altitude + ' ');
  }

  float getAltitude() {
    return altitude;
  }

  void setSatellites(String newSats) {
    String trimSats = trim(newSats);
    sats = int(trimSats);
    print("Sats: " + newSats + sats + ' ');
  }

  int getSatellites() {
    return sats;
  }

  void setHDOP(String newHdop) {
    String trimHdop = trim(newHdop);
    hdop = int(trimHdop);
    print("HDOP: " + hdop + ' ');
  }

  int getHDOP() {
    return hdop;
  }

  void setFixAge(String newFix) {
    String trimFix = trim(newFix);
    fix = int(trimFix);
    print("Fix: " + fix + ' ');
  }

  int getFixAge() {
    return fix;
  }

  void setDateTime(String data) {
    String dt = trim(data);
    String items[] = (split(dt, ' '));
    String dateItems[] = (split(items[0], '/'));
    String timeItems[] = (split(items[1], '_'));
   
    println(dateItems[2] + " " + timeItems[0]);
    // move the items from the string into the variables:
    currMon = int(dateItems[0]);
    currDay = int(dateItems[1]);
    currYear = int(dateItems[2]);
    
    currHour = int(timeItems[0]);
    currMin = int(timeItems[1]);
    currSec = int(timeItems[2]);
    
  }
  int getMonth() {
    return currMon;
  }
  int getDay() {
    return currDay;
  }
  int getYear() {
    return currYear;
  }
  int getHour() {
    return currHour;
  }
  int getMinute() {
    return currMin;
  }
  int getSeconds() {
    return currSec;
  }
  
}

