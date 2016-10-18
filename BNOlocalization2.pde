import processing.serial.*;
import java.awt.datatransfer.*;
import java.awt.Toolkit;
import processing.opengl.*;
//import saito.objloader.*;
import g4p_controls.*;

 
/* great gains
* X: 42,  15,  15
*/

double roll  = 0.0F;
double pitch = 0.0F;
double yaw   = 0.0F;
double temp  = 0.0F;
double deltaT = 0.0F;
double[] q = {0.0F, 0.0F, 0.0F, 0.0F};

//velocity
double[] velocity = {0.0F, 0.0F, 0.0F};
double[] angularVelocity = {0.0F, 0.0F, 0.0F};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                   Jerking drift compensation                                                   //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// the box variables
double xPos;
double yPos;

HScrollbar hs1, hs2, hs3;  // Two scrollbars
double[][] gainMins = {{1.0F, 1.0F, 1.0F}, {1.0F, 1.0F, 1.0F}, {1.0F, 1.0F, 1.0F}};// x1, y1, z1; x2, y2,z2; x3, y3,z3
double[][] gainMaxs = {{100.0F, 1.0F, 1.0F}, {100.0F, 0.0F, 0.0F}, {100.0F, 0.0F, 0.0F}};// x1, y1, z1; x2, y2,z2; x3, y3,z3
double[][] disGain = {{1.0F, 1.0F, 1.0F}, {1.0F, 1.0F, 1.0F}, {1.0F, 1.0F, 1.0F}}; // x1, y1, z1;   x2, y2, z2;   x3, y3, z3
// different derivatives of acceleration //
///////////////////////////////////////////
double[] cAccel = {0.0F, 0.0F, 0.0F}; // @ t
double[] pAccel = {0.0F, 0.0F, 0.0F}; // @ t-1
double[] dAccel = {0.0F, 0.0F, 0.0F}; // a(t) - a(t-1)
double[] accelDeriv = {0.0F, 0.0F, 0.0F}; // a(t) - a(t-1)/(deltaT) 

double[] cJerk = {0.0F, 0.0F, 0.0F}; // delta accel/ delta time -> 1st derivative of accel: jerk
double[] pJerk = {0.0F, 0.0F, 0.0F}; // @ t-1
double[] dJerk = {0.0F, 0.0F, 0.0F}; // j(t) - j(t-1)
double[] jerkDeriv = {0.0F, 0.0F, 0.0F}; // j(t) - j(t-1)/(deltaT)

double[] cSnap = {0.0F, 0.0F, 0.0F}; // delta jerk/ delta time -> 2nd derivative of accel: snap
double[] pSnap = {0.0F, 0.0F, 0.0F}; // @ t-1
double[] dSnap = {0.0F, 0.0F, 0.0F}; // s(t) - s(t-1)
double[] snapDeriv = {0.0F, 0.0F, 0.0F}; // s(t) - s(t-1)/(deltaT) : crackle

double[] cCrackle = {0.0F, 0.0F, 0.0F}; // delta snap/ delta time -> 3rd derivative of accel: snap
double[] pCrackle = {0.0F, 0.0F, 0.0F}; // @ t-1
double[] dCrackle = {0.0F, 0.0F, 0.0F}; // c(t) - c(t-1)
double[] crackleDeriv = {0.0F, 0.0F, 0.0F}; // c(t) - c(t-1)/(deltaT) : pop

double[] cPop = {0.0F, 0.0F, 0.0F}; // delta snap/ delta time -> 4rth derivative of accel: snap
double[] pPop = {0.0F, 0.0F, 0.0F}; // @ t-1
double[] dPop = {0.0F, 0.0F, 0.0F}; // p(t) - p(t-1)
double[] popDeriv = {0.0F, 0.0F, 0.0F}; // p(t) - p(t-1)/(deltaT) : 


// integrals of acceleration //
///////////////////////////////
double[] sumAccelD = {0.0F, 0.0F, 0.0F};// first integral of acceleration -> velocity

double[] cVel = {0.0F, 0.0F, 0.0F};
double[] pVel = {0.0F, 0.0F, 0.0F};
double[] dVel = {0.0F, 0.0F, 0.0F};
double[] sumVelD = {0.0F, 0.0F, 0.0F}; // second integral of acceleration -> position

double[] dis = {0.0F, 0.0F, 0.0F};
double[] input = {0.0F, 0.0F, 0.0F};
double[] unfiltDistance = {0.0F, 0.0F, 0.0F};
double[] filteredDistance = {0.0F, 0.0F, 0.0F};
double[] sumD = {0.0F, 0.0F, 0.0F};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



//OBJModel model;
Serial myPort; //creates a software serial port
// Serial port state.
Serial port;
final String serialConfigFile = "serialconfig.txt";
boolean      printSerial = false;
String fileName;

RegressionQueue regressQ = new RegressionQueue(0,255,222,1000);
AllButtons buttons; 
void setup()
{
  // setting up the box initial position
  xPos = width/2;
  yPos = height/2;
  
  // Setting up scrollbars
  hs1 = new HScrollbar(0, height - 68, width, 16, 1, gainMins[0], gainMaxs[0], "hs1 :");
  hs2 = new HScrollbar(0, height - 42, width, 16, 1, gainMins[1], gainMaxs[1], "hs2 :");
  hs3 = new HScrollbar(0, height - 16, width, 16, 1, gainMins[2], gainMaxs[2], "hs3 :");
  buttons = new AllButtons(width, height);
  size(900, 800, OPENGL);
  frameRate(30);
  String portName = Serial.list()[3]; 
  myPort = new Serial(this, portName,  115200); //set up your port to listen to the serial port
  // don't generate a serialEvent() unless you get a newline character:
  myPort.bufferUntil('\n');
  
  
  
}

void draw()
{
  background(255,255,255);

  // Set a new co-ordinate space
  pushMatrix();

  lights();
  // Move bunny from 0,0 in upper left corner to roughly center of screen.
  //xPos = width/2 + dis[0];
  //xPos += dis[0];
  xPos += (filteredDistance[0]);
  translate((float)xPos, (float)yPos, 0);//translate(300, 200, 0);//
  
  // Rotate shapes around the X/Y/Z axis (values in radians, 0..Pi*2)
  rotateZ(radians((float)roll));
  rotateX(radians((float)pitch));
  rotateY(radians((float)yaw));
  //rotateZ(radians(yaw));
  //rotateX(radians(roll));
  //rotateY(radians(pitch));
  sphere(20);
  
  fill(255,0,0);
  box(5,50,5);    
  pushMatrix();
  //translate(0, 50, 0);
  
  sphere(10);
  popMatrix();
 
  fill(0,255,0);
  box(100,10,10);
  pushMatrix();
  //translate(50, 0, 0); 
  rotateX(PI/2);
  ellipse(50, 0, 30, 30);
  ellipse(-50, 0, 30, 30);
  sphere(10);
  
  popMatrix();
 
  fill(0,0,255);
  box(10,10,100);
  pushMatrix();
  //translate(0, 0, 50); 
  rotateX(PI/2);
  ellipse(0, 50, 30, 30);
  ellipse(0, -50, 30, 30);
  sphere(10);
  popMatrix();
  
  popMatrix();
  
  hs1.update();
  hs2.update();
  hs3.update();
  hs1.display();
  hs2.display();
  hs3.display();
  
  if(hs1.isChanged()) 
  {
    updateGains();
    hs1.resetChange();
    resetBox();
    
  }
  if(hs2.isChanged()) 
  {
    updateGains();
    hs2.resetChange();
    resetBox();
  }
  if(hs3.isChanged()) 
  {
    updateGains();
    hs3.resetChange();
    resetBox();
  }
  buttons.updateButtons();
  buttons.display();
}


void serialEvent(Serial p) 
{
  
  String incoming = p.readString();
  if (printSerial) {
    println(incoming);
  }
  
  if ((incoming.length() > 8))
  {
    String[] list = split(incoming, " ");
    if((list.length > 0) && (list[0].equals("DeltaTime:")))
    {
      //println("inside deltaTime");
      deltaT = Double.parseDouble(list[1])/1000.0;
    }
    
    if ( (list.length > 0) && (list[0].equals("Orientation:")) ) 
    {
      roll  = Double.parseDouble(list[3]); // Roll = Z
      pitch = Double.parseDouble(list[2]); // Pitch = Y 
      yaw   = Double.parseDouble(list[1]); // Yaw/Heading = X;
    }
    
    
   
   
    if((list.length > 0) && (list[0].equals("LinearAccel:")))
    {
      
      //println("inside linear: ");
      input[0] = Double.parseDouble(list[1]);
      input[1] = Double.parseDouble(list[2]);
      input[2] = Double.parseDouble(list[3]);
      //getDisplacement();
      ///getDisplacement2();
      if(deltaT != 0.0F)
      {
        setSumsAndDerivatives(input);
        setDistanceTraveled2();
        //printSD();
        //printPosition();
      }
    }
    
    
  }
}
void printPosition()
{
  println(unfiltDistance[0]);
}
void printSD()
{
   //println("Position: " + sumVelD[0]  + "\t" + "Vel: " + sumAccelD[0] + "\t" +"Accel: " + cAccel[0] + "\t" 
           //+ "Jerk: " + cJerk[0] + "\t" + "Snap: " + cSnap[0] + "\t" + "Crackle: " + cCrackle[0] +  "\t" + "Pop: " + cPop[0] +  "\t" + "dPop/dt: " + popDeriv[0] );
           
           
   //      position              velocity             accel             jerk             snap             Crackle              Pop              PopDeriv
   println(sumVelD[0]  + "," + sumAccelD[0] + "," + cAccel[0] + "," + cJerk[0] + "," + cSnap[0] + "," + cCrackle[0] +  "," + cPop[0] +  "," + popDeriv[0] + "," + filteredDistance[0] + ",");
}
void setSumsAndDerivatives(double[] accel)
{
  setDerivatives(accel);
  setSums(accel);
}

void setSums(double[] accel)
{
  // integrals will be used differently for position
  for(int i = 0; i < accel.length; i++)
  {
    sumAccelD[i] += dAccel[i] * deltaT/2;// first integral of acceleration -> velocity
    pVel[i] = cVel[i];
    cVel[i] = sumAccelD[i];
    dVel[i] = cVel[i] - pVel[i];
    sumVelD[i] += dVel[i] * deltaT/2;
  }
}

void setDerivatives(double[] accel)
{
  /*
  cAccel[0] = linAccel[0];
  cJerk[0] = (cAccel[0] - pAccel[0]) / deltaT;
  pAccel[0] = cAccel[0];
  accelNew[0] = ((cJerk[0] - pJerk[0]) / 2) * deltaT;
  pJerk[0] = cJerk[0];
  vel[0] += accelNew[0] * deltaT;
  double driftComp = disGain[0][0]*(vel[0] * deltaT) + disGain[1][0];
  dis[0] = driftComp;
  */ 
  // derivatives will be used differently for position
  for(int i = 0; i < accel.length; i++)
  {
    // set the accels
    pAccel[i] = cAccel[i];
    cAccel[i] = accel[i];
    dAccel[i] = cAccel[i] - pAccel[i];
    accelDeriv[i] = dAccel[i] / deltaT;  //(dAccel[i] / 2) * deltaT;
    
    // set the jerks
    pJerk[i] = cJerk[i];
    cJerk[i] = accelDeriv[i];
    dJerk[i] = cJerk[i] - pJerk[i]; 
    jerkDeriv[i] = dJerk[i] / deltaT; //(dJerk[i]/6) * deltaT
    
    // set the Snaps
    pSnap[i] = cSnap[i];
    cSnap[i] = jerkDeriv[i];
    dSnap[i] = cSnap[i] - pSnap[i]; 
    snapDeriv[i] = dSnap[i] / deltaT; // (dSnap[i] / 24) * deltaT   
    
    // set the Crackle
    pCrackle[i] = cCrackle[i];
    cCrackle[i] = snapDeriv[i];
    dCrackle[i] = cCrackle[i] - pCrackle[i]; 
    crackleDeriv[i] = dCrackle[i] / deltaT; // (dCrackle[i] / 120) * deltaT 
    
    //set the pop
    pPop[i] = cPop[i];
    cPop[i] = crackleDeriv[i];
    dPop[i] = cPop[i] - pPop[i]; 
    popDeriv[i] = dPop[i] / deltaT; // (dPop[i] / 720) * deltaT 
    

  }
}

// setting the distances traveled using integrals and derivatives

void setDistanceTraveled()
{
  for(int i = 0; i < unfiltDistance.length; i++)
  {
    unfiltDistance[i] += disGain[0][0]* ((sumVelD[i]*deltaT/2) + (cVel[i]*deltaT/2) + (cAccel[i]*deltaT/2) + (cJerk[i]*deltaT/2) + (cSnap[i]*deltaT/2) + (cCrackle[i]*deltaT/2) + (cPop[i]*deltaT/2));//;
  }
}
void setDistanceTraveled2()
{
  for(int i = 0; i < unfiltDistance.length; i++)
  {
    unfiltDistance[i] =  ((disGain[i][0]*(sumVelD[i]*deltaT/2)) + (disGain[i][1]*(cVel[i]*deltaT/2)) + (disGain[i][1]*(cAccel[i]*deltaT/2)) + 
                          (cJerk[i]*deltaT/6) + (cSnap[i]*deltaT/24) + (cCrackle[i]*deltaT/120) + (cPop[i]*deltaT/722));//;snap/6, cracle/36, pip /1295
    
  }
  
  regressQ.theilSenRegression(cAccel[0], cAccel[1], cAccel[2], unfiltDistance[0], unfiltDistance[1], unfiltDistance[2]); //<>//
  
  for(int i = 0; i < unfiltDistance.length; i++)
  {
    filteredDistance[i] =  unfiltDistance[i] - regressQ.regressionFunc(cAccel[i], 0);
  }
}

//updateing the gains
void updateGains()
{
  for(int i = 0; i < disGain[0].length; i++)
  {
    disGain[0][i] = hs1.getGain(i);
    disGain[1][i] = hs2.getGain(i);
    disGain[2][i] = hs3.getGain(i);
  }
  
}

// resetting the location of the box
void resetBox()
{
  for(int i = 0; i < cAccel.length; i++)
  {
    cAccel[i] = 0.0F;
    pAccel[i] = 0.0F;
    cJerk[i] = 0.0F;
    pJerk[i] = 0.0F;
    dis[i] = 0.0F;
    xPos = width/2;
    yPos = height/2;
    
    // set the accels
    pAccel[i] = 0.0F;
    cAccel[i] = 0.0F;
    dAccel[i] = 0.0F;
    accelDeriv[i] = 0.0F;  
    
    // set the jerks
    pJerk[i] = 0.0F;
    cJerk[i] = 0.0F;
    dJerk[i] = 0.0F; 
    jerkDeriv[i] = 0.0F;
    
    // set the Snaps
    pSnap[i] =0.0F;
    cSnap[i] = 0.0F;
    dSnap[i] = 0.0F; 
    snapDeriv[i] = 0.0F; 
    
    // set the 
    sumAccelD[i] = 0.0F;
    pVel[i] = 0.0F;
    cVel[i] = 0.0F;
    dVel[i] = 0.0F;
    sumVelD[i] = 0.0F;
    
    pCrackle[i] = 0.0F;
    cCrackle[i] = 0.0F;
    dCrackle[i] = 0.0F; 
    crackleDeriv[i] = 0.0F;
    
    //set the pop
    pPop[i] = 0.0F;
    cPop[i] = 0.0F;
    dPop[i] = 0.0F; 
    popDeriv[i] = 0.0F; 
    
    unfiltDistance[i] = 0.0F;
    filteredDistance[i] = 0.0F;
    
    
  }
  regressQ = new RegressionQueue(0,255,222,10);
  deltaT = 0.0F;
  /*if (port != null) {
    port.stop();
  }*/
  if (myPort != null) {
    myPort.stop();
  }
  String portName = Serial.list()[3]; 
  myPort = new Serial(this, portName,  115200); //set up your port to listen to the serial port
  // don't generate a serialEvent() unless you get a newline character:
  myPort.bufferUntil('\n');
}
void mousePressed() 
{
  if (overCircle(buttons.buttons[0].xPos, buttons.buttons[0].yPos, 20) )
  {
    buttons.buttons[0].setOn();
    buttons.buttons[1].setOff();
    buttons.buttons[2].setOff();
    hs1.setActiveAxis(0);
    hs2.setActiveAxis(0);
    hs3.setActiveAxis(0);
    
  }
  else if (overCircle(buttons.buttons[1].xPos, buttons.buttons[1].yPos, 20) )
  {
    buttons.buttons[1].setOn();
    buttons.buttons[0].setOff();
    buttons.buttons[2].setOff();
    hs1.setActiveAxis(1);
    hs2.setActiveAxis(1);
    hs3.setActiveAxis(1);
  }
  else if (overCircle(buttons.buttons[2].xPos, buttons.buttons[2].yPos, 20) )
  {
    buttons.buttons[2].setOn();
    buttons.buttons[0].setOff();
    buttons.buttons[1].setOff();
    hs1.setActiveAxis(2);
    hs2.setActiveAxis(2);
    hs3.setActiveAxis(2);
  }
  
}
boolean overCircle(double x, double y, int diameter) {
  double disX = x - mouseX;
  double disY = y - mouseY;
  if (sqrt(sq((float)disX) + sq((float)disY)) < diameter/2 ) {
    return true;
  } else {
    return false;
  }
}
// Set serial port to desired value.
void setSerialPort(String portName) {
  // Close the port if it's currently open.
  if (port != null) {
    port.stop();
  }
  try {
    // Open port.
    port = new Serial(this, portName, 115200);
    port.bufferUntil('\n');
    // Persist port in configuration.
    saveStrings(serialConfigFile, new String[] { portName });
  }
  catch (RuntimeException ex) {
    // Swallow error if port can't be opened, keep port closed.
    port = null; 
  }
}