
class AxisButton
{
    double xPos, yPos;
    String axisName;
    boolean selected;
    
    public AxisButton(String name, double x, double y)
    {
      this.xPos = x;
      this.yPos = y;
      this.axisName = name;
      this.selected = false;
      
    }
    public void display()
    {
      if(selected == false)
      {
        fill(255);
      }
      else
      {
        fill(100);
      }
      stroke(0);
      ellipse((float)this.xPos, (float)this.yPos, 20, 20);
      String s = this.axisName;
      //fill(250, 40,50);
      textSize(18);
      text(s, (float)this.xPos, (float)this.yPos);
    }
    void mousePressed() 
    {
      println("button pressed" );
      this.selected = !this.selected;
    }
    void setOff()
    {
       this.selected = false; 
    }
    void setOn()
    {
       this.selected = true; 
    }
}

class AllButtons
{
  AxisButton[] buttons;
  
  AllButtons(double x, double y)
  {
    
    buttons = new AxisButton[3];
    buttons[0] = new AxisButton("X" , ((x/2)-50), y-75);//width/2)-50, height - (height-50));
    buttons[1] = new AxisButton("Y" , x/2, y-75);//width/2, height - (height-50));
    buttons[2] = new AxisButton("Z" , ((x/2)+50), y-75); //(width/2)+50, height - (height-50));
    
  }
  void updateButtons()
  {
    if(buttons[0].selected ==true)
    {
      
      buttons[1].setOff();
      buttons[2].setOff();
    }
    else if(buttons[1].selected==true)
    {
      buttons[0].setOff();
      buttons[2].setOff();
    }
    else if(buttons[2].selected==true)
    {
      buttons[0].setOff();
      buttons[1].setOff();
    }
    
  }
  void display()
  {
    for(int i = 0; i < buttons.length; i++)
    {
      buttons[i].display();
    }
  }
  
  int getAxisOn()
  {
    int axis = 0;
    for(int i = 0; i< buttons.length; i++)
    {
      if(buttons[i].selected)
      {
        axis = i;
      }
    }
    return axis;
  }
}