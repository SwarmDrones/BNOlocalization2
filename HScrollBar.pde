class HScrollbar {
  int swidth, sheight;    // width and height of bar
  double xpos, ypos;       // x and y position of bar
  double spos, newspos;    // x position of slider
  double sposMin, sposMax; // max and min values of slider
  double[] gainMin, gainMax;
  double[] gains;
  int loose;    // how loose/heavy
  boolean over;           // is the mouse over the slider?
  boolean locked;
  double ratio;
  
  boolean changed;
  String name;
  int activeAxis;
  HScrollbar (double xp, double yp, int sw, int sh, int l, double[] gainMins, double[] gainMaxs, String name) {
    this.swidth = sw;
    this.sheight = sh;
    int widthtoheight = sw - sh;
    this.ratio = (double)sw / (double)widthtoheight;
    this.xpos = xp;
    this.ypos = yp-sheight/2;
    this.spos = xpos + swidth/2 - sheight/2;
    this.newspos = spos;
    this.sposMin = xpos;
    this.sposMax = xpos + swidth - sheight;
    this.loose = l;
    this.changed = false;
    this.gains = new double[3];
    this.gainMin = new double[3];
    this.gainMax = new double[3];
    this.activeAxis = 0;
    
    for(int i = 0; i < gains.length; i++)
    {
      this.gainMin[i] = gainMins[i];
      this.gainMax[i] = gainMaxs[i];
      
    }
    this.name = name;
    updateGains();
  }
  
  void update() {
    if (overEvent()) {
      over = true;
    } else {
      over = false;
    }
    if (mousePressed && over) {
      locked = true;
    }
    if (!mousePressed) {
      locked = false;
    }
    if (locked) {
      newspos = constrain(mouseX-sheight/2, sposMin, sposMax);
    }
    if (abs((float)(newspos - spos)) > 1) {
      spos = spos + (newspos-spos)/loose;
      updateGains();
    }
  }

  double constrain(double val, double minv, double maxv) {
    return min(max((float)val, (float)minv), (float)maxv);
  }

  boolean overEvent() {
    if (mouseX > xpos && mouseX < xpos+swidth &&
       mouseY > ypos && mouseY < ypos+sheight) {
      return true;
    } else {
      return false;
    }
  }

  void display() {
    noStroke();
    fill(200);
    rect((float)xpos, (float)ypos, swidth, sheight);
    if (over || locked) {
      fill(56, 215, 229);
    } else {
      fill(113, 223, 183);
    }
    rect((float)spos, (float)ypos, sheight, sheight);
    String s = this.name + gains[activeAxis];
    //fill(250, 40,50);
    textSize(18);
    text(s, (float)(this.xpos+10.0), (float)this.ypos);
    
  }

  double getPos() 
  {
    // Convert spos to be values between
    // 0 and the total width of the scrollbar
    return spos * ratio;
  }
  void updateGains()
  {
    /*for(int i = 0; i < gains.length; i++)
    {
      gains[i] = map(getPos(), sposMin, sposMax, gainMin[i], gainMax[i]);
      
    }*/
    gains[this.activeAxis] = map((float)getPos(), (float)sposMin, (float)sposMax, (float)gainMin[this.activeAxis], (float)gainMax[this.activeAxis]);
    println("gain changed " + this.activeAxis + " : "+ gains[this.activeAxis]);
    changed = true;
  }
  
  double getGain(int n)
  {
    return gains[n];
  }
  
  void resetChange()
  {
    changed = false;
  }
  
  boolean isChanged()
  {
    return changed;
  }
  
  void setActiveAxis(int newAxis)
  {
    this.activeAxis = newAxis;
  }
}