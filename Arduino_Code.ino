#include <PID_v1.h>

const int photores = A0; 
const int led = 9;  
const int disturbanceLed = 10; 
double lightLevel;   

// Tuning parameters
double Kp = 0;         
double Ki = 10;            
double Kd = 0;              
int Disturbance = 0;     

PID myPID(&Input, &Output, &Setpoint, Kp, Ki, Kd, DIRECT);
const int sampleRate = 1;      

void setup() {
  lightLevel = analogRead(photores);            
  Input = map(lightLevel, 0, 1023, 0, 255);                     
  Serial.begin(115200);                
  myPID.SetMode(AUTOMATIC);                      
  myPID.SetSampleTime(sampleRate);              
}

void loop() {
  lightLevel = analogRead(photores);
  Input = map(lightLevel, 0, 1023, 0, 255);
  
  if (Serial.available() > 0) {
    String data = Serial.readStringUntil('\n');  
    char type = data.charAt(0);               
    String valueString = data.substring(1);     

    if (type == 'S') {
      Setpoint = valueString.toDouble();       
      //Setpoint = map(Setpoint, 0, 255, 0, 200); 
    } else if (type == 'D') {
      Disturbance = valueString.toInt();      
      analogWrite(disturbanceLed, Disturbance);
    } else if (type == 'P') {
      Kp = valueString.toDouble();          
      myPID.SetTunings(Kp, Ki, Kd);             
    } else if (type == 'I') {
      Ki = valueString.toDouble();           
      myPID.SetTunings(Kp, Ki, Kd);            
    } else if (type == 'd') {
      Kd = valueString.toDouble();              
      myPID.SetTunings(Kp, Ki, Kd);           
    }
  }

  // Calculate the PID output
  myPID.Compute();
  analogWrite(led, Output);                  
  Serial.println(Input);
}
