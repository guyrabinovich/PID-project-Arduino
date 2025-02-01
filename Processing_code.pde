import processing.serial.*;

Serial myPort;  // משתנה לתקשורת עם הארדואינו

// משתנים למד SetPoint
int sliderValue = 0; // ערך המד SetPoint
boolean isDraggingSetPoint = false; // מצב גרירה למד SetPoint

// משתנים למד Disturbance
int disturbanceValue = 0; // ערך המד Disturbance
boolean isDraggingDisturbance = false; // מצב גרירה למד Disturbance

// משתנים ל-PID
String kpText = "0"; // טקסט שמוזן עבור Kp
String kiText = "10"; // טקסט שמוזן עבור Ki
String kdText = "0"; // טקסט שמוזן עבור Kd
boolean isEditingKp = false; // מעקב אחר תיבת Kp
boolean isEditingKi = false; // מעקב אחר תיבת Ki
boolean isEditingKd = false; // מעקב אחר תיבת Kd

// משתנים לגרף
float[] currentLightValues = new float[500]; // ערכים של Current Light (Input)
float[] setPointValues = new float[500];    // ערכים של SetPoint
int graphIndex = 0; // אינדקס לגרף

int currentLightValue = 0; // ערך Input המתקבל מארדואינו

void setup() {
  size(800, 600); // גודל החלון
  myPort = new Serial(this, Serial.list()[0], 115200); // פתיחת תקשורת סריאלית
}

void draw() {
  background(230, 230, 255); // צבע רקע בהיר

  // ---- חלונית CONTROL PANEL ----
  fill(200, 200, 240);
  noStroke();
  rect(50, 30, width - 100, 200, 10); // חלונית מעוגלת

  fill(0);
  textSize(20);
  textAlign(CENTER, CENTER);
  text("Control Panel", width / 2, 50); // כותרת
  // ---- מד SetPoint ----
  drawMeter(width / 4, 100, sliderValue, "SetPoint");

  // ---- מד Disturbance ----
  drawMeter(2 * width / 4, 100, disturbanceValue, "Disturbance");

  // ---- גרף ביצועים ----
  drawPerformanceGraph(50, 250, width - 100, 300);

  // ---- תיבות טקסט ל-PID ----
  drawPidInputs(600, 100);

  // ---- מקרא (Legend) ----
  drawLegend(600, 400);
  if (sliderValue < disturbanceValue) {
    drawErrorMessageOverlay(); // ציור הודעת השגיאה
  }
}

void drawMeter(int x, int y, int value, String label) {
  int meterWidth = 60;
  int meterHeight = 100;

  // מסגרת המד
  fill(150);
  rect(x - meterWidth / 2, y, meterWidth, meterHeight);

  // מילוי המד
  fill(0, 255, 0);
  int fillHeight = int(map(value, 0, 255, 0, meterHeight));
  rect(x - meterWidth / 2, y + meterHeight - fillHeight, meterWidth, fillHeight);

  // כיתוב
  fill(0);
  textSize(14);
  textAlign(CENTER, CENTER);
  text(label + ": " + value + " (" + int(map(value, 0, 255, 0, 100)) + "%)", x, y + meterHeight + 20);
}

void drawPidInputs(int x, int y) {
  textSize(14);
  textAlign(LEFT, CENTER);

  // תיבת Kp
  text("Kp:", x, y);
  drawTextBox(x + 30, y - 10, kpText, isEditingKp);

  // תיבת Ki
  text("Ki:", x, y + 40);
  drawTextBox(x + 30, y + 30, kiText, isEditingKi);

  // תיבת Kd
  text("Kd:", x, y + 80);
  drawTextBox(x + 30, y + 70, kdText, isEditingKd);
}

void drawTextBox(int x, int y, String textValue, boolean isActive) {
  fill(isActive ? 255 : 200); // שינוי צבע לפי מצב פעיל
  stroke(0);
  rect(x, y, 60, 25);
  fill(0);
  noStroke();
  text(textValue, x + 5, y + 15);
}

void drawPerformanceGraph(int x, int y, int w, int h) {
  // רקע החלונית
  fill(220, 255, 220);
  stroke(0);
  rect(x, y, w, h, 10);

  // רשת (Grid) וערכים בציר Y
  stroke(200);
  fill(0);
  textSize(10);
  textAlign(RIGHT, CENTER);
  for (int i = 0; i <= 255; i += 50) {
    float yPos = map(i, 0, 255, y + h, y);
    line(x, yPos, x + w, yPos); // קווים אופקיים
    text(i, x - 5, yPos); // ערכים בציר Y
  }
  for (int i = 0; i <= 10; i++) {
    line(x + i * w / 10, y, x + i * w / 10, y + h); // קווים אנכיים
  }

  // נתוני SetPoint
  stroke(255, 0, 0);
  noFill();
  beginShape();
  for (int i = 0; i < graphIndex; i++) {
    float xPos = map(i, 0, currentLightValues.length, x, x + w);
    float yPos = map(setPointValues[i], 0, 255, y + h, y);
    vertex(xPos, yPos);
  }
  endShape();

  // נתוני Current Light
  stroke(0, 0, 255);
  noFill();
  beginShape();
  for (int i = 0; i < graphIndex; i++) {
    float xPos = map(i, 0, currentLightValues.length, x, x + w);
    float yPos = map(currentLightValues[i], 0, 255, y + h, y);
    vertex(xPos, yPos);
  }
  endShape();
}

void drawLegend(int x, int y) {
  fill(0);
  textSize(12);
  textAlign(LEFT, CENTER);
  text("Legend:", x, y);

  fill(0, 0, 255);
  rect(x, y + 15, 10, 10);
  fill(0);
  text("Input (Blue)", x + 20, y + 20);

  fill(255, 0, 0);
  rect(x, y + 35, 10, 10);
  fill(0);
  text("SetPoint (Red)", x + 20, y + 40);
}

void mousePressed() {
  if (mouseOverMeter(width / 4, 100, sliderValue)) {
    isDraggingSetPoint = true;
  }
  if (mouseOverMeter(2 * width / 4, 100, disturbanceValue)) {
    isDraggingDisturbance = true;
  }

  // בדיקה אם לחץ על תיבות הטקסט
  if (mouseOverTextBox(600 + 30, 100 - 10)) {
    isEditingKp = true;
    isEditingKi = false;
    isEditingKd = false;
  } else if (mouseOverTextBox(600 + 30, 140 - 10)) {
    isEditingKi = true;
    isEditingKp = false;
    isEditingKd = false;
  } else if (mouseOverTextBox(600 + 30, 180 - 10)) {
    isEditingKd = true;
    isEditingKp = false;
    isEditingKi = false;
  } else {
    isEditingKp = isEditingKi = isEditingKd = false;
  }
}

void mouseDragged() {
  if (isDraggingSetPoint) {
    sliderValue = calculateValueFromMouse(100, 200);
    myPort.write("S" + sliderValue + "\n");
  }
  if (isDraggingDisturbance) {
    disturbanceValue = calculateValueFromMouse(100, 200);
    myPort.write("D" + disturbanceValue + "\n");
  }
}

void mouseReleased() {
  isDraggingSetPoint = false;
  isDraggingDisturbance = false;
}

boolean mouseOverMeter(int x, int y, int value) {
  int meterWidth = 60;
  int meterHeight = 100;
  return mouseX > x - meterWidth / 2 && mouseX < x + meterWidth / 2 &&
         mouseY > y && mouseY < y + meterHeight;
}

boolean mouseOverTextBox(int x, int y) {
  return mouseX > x && mouseX < x + 60 && mouseY > y && mouseY < y + 20;
}

int calculateValueFromMouse(int yStart, int yEnd) {
  int mouseValue = constrain(mouseY, yStart, yEnd);
  return int(map(mouseValue, yEnd, yStart, 0, 255));
}

void keyPressed() {
  if (isEditingKp) {
    kpText = handleTextInput(kpText);
    if (key == ENTER || key == RETURN) {
      myPort.write("P" + kpText + "\n"); // שליחת Kp
      isEditingKp = false;
    }
  } else if (isEditingKi) {
    kiText = handleTextInput(kiText);
    if (key == ENTER || key == RETURN) {
      myPort.write("I" + kiText + "\n"); // שליחת Ki
      isEditingKi = false;
    }
  } else if (isEditingKd) {
    kdText = handleTextInput(kdText);
    if (key == ENTER || key == RETURN) {
      myPort.write("d" + kdText + "\n"); // שליחת Kd
      isEditingKd = false;
    }
  }
}

String handleTextInput(String currentText) {
  if (key == BACKSPACE && currentText.length() > 0) {
    return currentText.substring(0, currentText.length() - 1);
  } else if ((key >= '0' && key <= '9') || key == '.') {
    return currentText + key;
  }
  return currentText;
}

void serialEvent(Serial myPort) {
  if (myPort.available() > 0) {
    String data = myPort.readStringUntil('\n');
    if (data != null && data.trim().length() > 0) {
      currentLightValue = int(data.trim());
      updateGraph(currentLightValue, sliderValue);
    }
  }
}

void updateGraph(float currentLight, float setPoint) {
  if (graphIndex < currentLightValues.length) {
    currentLightValues[graphIndex] = currentLight;
    setPointValues[graphIndex] = setPoint;
    graphIndex++;
  } else {
    arrayCopy(currentLightValues, 1, currentLightValues, 0, currentLightValues.length - 1);
    arrayCopy(setPointValues, 1, setPointValues, 0, setPointValues.length - 1);
    currentLightValues[currentLightValues.length - 1] = currentLight;
    setPointValues[setPointValues.length - 1] = setPoint;
  }
}
void drawErrorMessageOverlay() {
  pushStyle(); // שמירת סגנונות קודמים
  fill(255, 255, 255, 200); // רקע חצי שקוף לבן
  rectMode(CENTER);
  noStroke();
  rect(width / 2, height / 2, 300, 100); // מלבן במרכז המסך

  fill(255, 0, 0); // טקסט אדום
  textSize(24);
  textAlign(CENTER, CENTER);
  text("ERROR: Invalid State", width / 2, height / 2); // כיתוב הודעת השגיאה
  popStyle(); // שחזור הסגנונות
}
