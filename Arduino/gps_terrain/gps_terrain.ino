#include <SoftwareSerial.h>

#include <TinyGPS.h>

/* This sample code demonstrates the normal use of a TinyGPS object.
   It requires the use of SoftwareSerial, and assumes that you have a
   4800-baud serial GPS device hooked up on pins 3(rx) and 4(tx).
*/

TinyGPS gps;
SoftwareSerial nss(3, 2);

static void gpsdump(TinyGPS &gps);
static bool feedgps();
static void print_float(const char *label, float val, float invalid, int len, int prec);
static void print_int(const char *label, unsigned long val, unsigned long invalid, int len);
static void print_date(const char *label, TinyGPS &gps);
static void print_str(const char *str, int len);

void setup()
{
  Serial.begin(9600);
  nss.begin(9600);
  /*
  Serial.print("Testing TinyGPS library v. "); Serial.println(TinyGPS::library_version());
  Serial.println("by Mikal Hart");
  Serial.println();
  Serial.print("Sizeof(gpsobject) = "); Serial.println(sizeof(TinyGPS));
  Serial.println();
  Serial.println("Sats HDOP Latitude Longitude Fix  Date       Time       Date Alt     Course Speed Card  Distance Course Card  Chars Sentences Checksum");
  Serial.println("          (deg)    (deg)     Age                        Age  (m)     --- from GPS ----  ---- to London  ----  RX    RX        Fail");
  Serial.println("--------------------------------------------------------------------------------------------------------------------------------------");
*/
}

void loop()
{
  bool newdata = false;
  unsigned long start = millis();
  
  // Every second we print an update
  while (millis() - start < 1000)
  {
    if (feedgps())
      newdata = true;
  }
  
  gpsdump(gps);
}

static void gpsdump(TinyGPS &gps)
{
  float flat, flon;
  unsigned long age, date, time, chars = 0;
  unsigned short sentences = 0, failed = 0;
  static const float LONDON_LAT = 51.508131, LONDON_LON = -0.128002;
  
  print_int("SAT: ", gps.satellites(), TinyGPS::GPS_INVALID_SATELLITES, 5);
  print_int("HDO: ", gps.hdop(), TinyGPS::GPS_INVALID_HDOP, 5);
  gps.f_get_position(&flat, &flon, &age);
  print_float("LAT:", flat, TinyGPS::GPS_INVALID_F_ANGLE, 9, 5);
  print_float("LON:", flon, TinyGPS::GPS_INVALID_F_ANGLE, 10, 5);
  print_int("AGE:", age, TinyGPS::GPS_INVALID_AGE, 5);

  print_date("DAT:", gps);

  print_float("ALT:", gps.f_altitude(), TinyGPS::GPS_INVALID_F_ALTITUDE, 8, 2);
  print_float("CRS:", gps.f_course(), TinyGPS::GPS_INVALID_F_ANGLE, 7, 2);
  print_float("SPD:", gps.f_speed_kmph(), TinyGPS::GPS_INVALID_F_SPEED, 7, 2);
  print_str(gps.f_course() == TinyGPS::GPS_INVALID_F_ANGLE ? "*** " : TinyGPS::cardinal(gps.f_course()), 4);
  print_int("ANG:", flat == TinyGPS::GPS_INVALID_F_ANGLE ? 0UL : (unsigned long)TinyGPS::distance_between(flat, flon, LONDON_LAT, LONDON_LON) / 1000, 0xFFFFFFFF, 9);
  print_float("DIS:", flat == TinyGPS::GPS_INVALID_F_ANGLE ? 0.0 : TinyGPS::course_to(flat, flon, 51.508131, -0.128002), TinyGPS::GPS_INVALID_F_ANGLE, 7, 2);
  print_str(flat == TinyGPS::GPS_INVALID_F_ANGLE ? "*** " : TinyGPS::cardinal(TinyGPS::course_to(flat, flon, LONDON_LAT, LONDON_LON)), 4);

  gps.stats(&chars, &sentences, &failed);
  print_int("CHA:", chars, 0xFFFFFFFF, 6);
  print_int("SEN:", sentences, 0xFFFFFFFF, 10);
  print_int("CHK:", failed, 0xFFFFFFFF, 9);
  Serial.println();
}

static void print_int(const char * label, unsigned long val, unsigned long invalid, int len)
{
  char sz[32];
  Serial.print(label);
  if (val == invalid)
    strcpy(sz, "*******");
  else
    sprintf(sz, "%ld,", val);
  sz[len] = 0;
  for (int i=strlen(sz); i<len; ++i)
    sz[i] = ' ';
  if (len > 0) 
    sz[len-1] = ' ';
  Serial.print(sz);
  feedgps();
}

static void print_float(const char * label, float val, float invalid, int len, int prec)
{
  char sz[32];
  Serial.print(label);
  if (val == invalid)
  {
    strcpy(sz, "*******,");
    sz[len] = 0;
        if (len > 0) 
          sz[len-1] = ' ';
    for (int i=7; i<len; ++i)
        sz[i] = ' ';
    Serial.print(sz);
  }
  else
  {
    Serial.print(val, prec);
    Serial.print(",");
    int vi = abs((int)val);
    int flen = prec + (val < 0.0 ? 2 : 1);
    flen += vi >= 1000 ? 4 : vi >= 100 ? 3 : vi >= 10 ? 2 : 1;
    for (int i=flen; i<len; ++i)
      Serial.print(" ");
  }
  feedgps();
}

static void print_date(const char *label, TinyGPS &gps)
{
  int year;
  byte month, day, hour, minute, second, hundredths;
  unsigned long age;
  Serial.print(label);
  gps.crack_datetime(&year, &month, &day, &hour, &minute, &second, &hundredths, &age);
  if (age == TinyGPS::GPS_INVALID_AGE)
    Serial.print("*******    *******,    ");
  else
  {
    char sz[32];
    sprintf(sz, "%02d/%02d/%02d %02d_%02d_%02d,   ",
        month, day, year, hour, minute, second);
    Serial.print(sz);
  }
  print_int("AGE: ", age, TinyGPS::GPS_INVALID_AGE, 5);
  feedgps();
}

static void print_str(const char *str, int len)
{
  int slen = strlen(str);
  for (int i=0; i<len; ++i)
    Serial.print(i<slen ? str[i] : ' ');
  Serial.print(',');
  feedgps();
}

static bool feedgps()
{
  while (nss.available())
  {
    if (gps.encode(nss.read()))
      return true;
  }
  return false;
}
