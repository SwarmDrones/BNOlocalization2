/*
  *TODO:
  *  somewere a NAN is being set ( look at fill arr)
  *  implement on all axis
*/
import java.util.Iterator;
/*
 * Used to remove drift
 * function will take in an (x,y,z) accel reading, and the estimated unfiltered displacement(x,y,z)
 * RegressionQueue q = new RegressionQueue(r, g, b, 10)
 * q.(ax, ay, az, fx, fy, fz)
 * q.
 *
*/
public class RegressionQueue
{
    private Node head;
    private Node tail;
    private int length;
    private double[][] ms;
    private double[][] vals; // holds all vals
    int maxLength;
    int R;
    int G;
    int B;
    
    double m;
    double my;
    double mz;
    double b;
    double by;
    double bz;
    

    public RegressionQueue(int r, int g, int b, int capacity)
    {
        this.length = 0;
        this.maxLength = capacity;
        this.head = null;
        this.tail = null;
        this.R = r;
        this.G = g;
        this.B = b;
        this.ms = new double[capacity][3]; // ((aX-ax)/(fX-fx))//, ay, az, fx, fy, fz
        this.vals = new double[capacity][6]; //ax, ay, az, fx, fy, fz
        this.m = 0.0F;
        this.b = 0.0F;
        for(int i = 0; i < this.ms.length; i++)
        {
          for(int j = 0; j < this.ms[0].length; j++)
          {
            this.ms[i][j] = 0.0F;
          }
        }
        for(int i = 0; i < this.ms.length; i++)
        {
          for(int j = 0; j < this.ms[0].length; j++)
          {
            this.vals[i][j] = 0.0F;
          }
        }
        
    }

    public int length()
    {
        return this.length;
    }

    void push(double x, double y, double z, double fx, double fy, double fz)
    {
      if(this.length < this.maxLength)
      {
        if(length()==0)
        {
          Node node = new Node();
          node.ax = x;
          node.ay = y;
          node.az = z;
          node.fx = fx;
          node.fy = fy;
          node.fz = fz;
          node.ahead = null;
          node.back = null;
          this.head = node;
          this.tail = node;
          this.length++;
        }
        else
        {
          Node node = new Node();
          node.ax = x;
          node.ay = y;
          node.az = z;
          node.fx = fx;
          node.fy = fy;
          node.fz = fz;
          node.ahead = this.tail;
          this.tail.back = node;
          this.tail = node;
          this.length++;
        }
      }
      else
      {
        this.pop();
        this.push(x, y, z, fx, fy, fz);
      }
    }
    void pop()
    {
      if(this.length >= this.maxLength)
      {
        if(length()!=0)
        {
          this.head = this.head.back;
          this.head.ahead.back = null;
          this.head.ahead = null;
          this.length--;
        }
        else
        {
          println("Queue is empty");
        }
      }
    }
    void display()
    {
      double x1 = 0.0F;
      double x2 = 0.0F;
      double y1 = 0.0F;
      double y2 = 0.0F;
      double z1 = 0.0F;
      double z2 = 0.0F;
      Node temp = this.head;
      while(temp.back != null)
      {
        x1 = temp.ax;
        y1 = temp.ay;
        x2 = temp.back.ax;
        y2 = temp.back.ay;
        stroke( this.R, this.G, this.B, 50);
        strokeWeight(10);
        line((float)x1, (float)y1, (float)x2, (float)y2);
        temp = temp.back;
      }
    }
    
    boolean isFull()
    {
      if(this.maxLength == this.length)
      {
        return true;
      }
      return false;
    }
    
    void fillArr(double aX, double aY, double aZ, double fX, double fY, double fZ)
    {
      Node temp = this.head; //<>//
      int i = 0;
      while(temp != null && i < this.length-1)
      {
        if(fX != temp.fx || fY != temp.fy || fZ != temp.fz)
        {
          this.ms[i][0] = (aX - temp.ax) / (fX - temp.fx);
          this.ms[i][1] = (aY - temp.ay) / (fY - temp.fy);
          this.ms[i][2] = (aZ - temp.az) / (fZ - temp.fz);
          
          //i++;
        }
        else
        {
          this.ms[i][0] = 0.0F;
          this.ms[i][1] = 0.0F;
          this.ms[i][2] = 0.0F;
        }
        this.vals[i][0] = temp.ax;
        this.vals[i][1] = temp.ay;
        this.vals[i][2] = temp.az;
        this.vals[i][3] = temp.fx;
        this.vals[i][4] = temp.fy;
        this.vals[i][5] = temp.fz;
        temp = temp.back;
        i++;
      }
    }
    public void sortArr()
    {
      quickSortArr(0, this.length-1, 0); //fx
      //quickSortArr(0, this.arrayForm.length, 4); //fy
      //quickSortArr(0, this.arrayForm.length, 5); //fz
    }
    
    private void quickSortArr(int l, int r, int axis)
    {
      int pivIdx = (l + r) / 2;
      double pivot = this.ms[pivIdx][axis];
      
      int lIdx = l;
      int rIdx = r;
      
      while(lIdx <= rIdx)
      {
        // moving left idx untill it finds value where it is greater than pivot value
        while(this.ms[lIdx][axis] < pivot)
        {
          lIdx++;
        }
        // moving right idx until it finds value where it is less than pivot value
        while(this.ms[rIdx][axis] > pivot)
        {
          rIdx--;
        }
        
        // switch left and right side
        if(lIdx <= rIdx)
        {
          double t = this.ms[lIdx][axis]; //<>//
          this.ms[lIdx][axis] = this.ms[rIdx][axis];
          this.ms[rIdx][axis] = t;
          // also change the vals;
          double []t2 = {this.vals[lIdx][0], this.vals[lIdx][1], this.vals[lIdx][2], this.vals[lIdx][3], this.vals[lIdx][4], this.vals[lIdx][5]}; 
          for(int i = 0; i < t2.length; i++)
          {
            this.vals[lIdx][i] = this.vals[rIdx][i];
            this.vals[rIdx][i] = t2[i];
          }
          
          lIdx++;
          rIdx--; //<>//
        }
      }
      
      // should both meet in the same place
      if(l < lIdx-1)
      {
        this.quickSortArr(l, lIdx-1, axis);//quickSortArr(this.ms, l, lIdx-1, axis);
        
      }
      if(r > lIdx)
      {
        //quickSortArr(this.ms, lIdx, r, axis);
        this.quickSortArr(lIdx, r, axis);
      }
    }
    
    public double linearRegression()
    {
      return 1.0;
    }
    public void theilSenRegression(double aX, double aY, double aZ, double fX, double fY, double fZ)
    {
      push(aX, aY, aZ, fX, fY, fZ); //<>//
       //<>// //<>//
      if(isFull())
      {
        fillArr(aX, aY, aZ, fX, fY, fZ);
        sortArr();
        int idx = this.ms.length/2;
        int sizeIdx = int(this.maxLength * 0.1);
        //for(int i = 0; i < 
        double msSum = 0.0;
        double msAvg = 0.0;
        // average median
        for(int i = idx-sizeIdx; i <= idx+sizeIdx; i++)
        {
          msSum += this.ms[i][0];
        }
        msAvg = msSum/((2*sizeIdx)+1);
        
        this.m = (this.m*0.9)+ (msAvg* 0.1);//this.ms[idx][0];
        this.b = this.vals[idx][3] - (this.m*this.vals[idx][0]); // yi-mxi
      }
    }
    
    public void maxLikeEst(double aX, double aY, double aZ, double fX, double fY, double fZ)
    {
      push(aX, aY, aZ, fX, fY, fZ);
      if(isFull())
      {
        fillArr(aX, aY, aZ, fX, fY, fZ);
        
      }
    }
    public void weightedMid(double aX, double aY, double aZ, double fX, double fY, double fZ)
    {
      push(aX, aY, aZ, fX, fY, fZ);
      if(isFull())
      {
        fillArr(aX, aY, aZ, fX, fY, fZ);
        
      }
    }
    
    public double regressionFunc(double a,int axis)
    {
      return ((this.m*a)+this.b);
    }
    
}

class Node
{
    public double ax; //
    public double ay;
    public double az;
    public double fx;
    public double fy;
    public double fz;
    public Node back;
    public Node ahead;
}