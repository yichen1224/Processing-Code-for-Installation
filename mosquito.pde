ArrayList<Germ> germs;
ArrayList<BigGerm> bigGerms;
PGraphics gfx;
PGraphics shadowPG;
PGraphics overAllTexture;
ArrayList<PVector> candidatePoints;
float rateY = 0.999;
float speedY = 0.008;
int growthRate = 120;

void setup() {
  size(540, 960);
  rectMode(CENTER);
  fullScreen();
  smooth();
  germs= new ArrayList<Germ>();
  bigGerms = new ArrayList<BigGerm>();
  germs.add(new Germ(width/2, height/2));
  initPG();
  shadowPG = createGraphics(width, height);

  for (int i = 0; i < random(4, 12); i++) {
    tryCreateGerm(2);
  }

  for (int i = 0; i < germs.size(); i++) {
    Germ g = germs.get(i);
    if (g.r>=30) {
      bigGerms.add(new BigGerm(g.x, g.y, g.r));
    }
  }
  germs.remove(0);
}

void draw() {
  if (rateY > 0) {
    rateY-=speedY;
  } else {
    rateY=0;
  }

  for (int i = 0; i < growthRate*(1-rateY); i++) {
    tryCreateGerm(1);
  }

  shadowPG.beginDraw();
  shadowPG.background(255, 100);

  for (int i = 0; i < bigGerms.size(); i++) {
    BigGerm g = bigGerms.get(i);
    g.update();
  }

  for (int i = 0; i < germs.size(); i++) {
    Germ g = germs.get(i);
    for (int j = 0; j < germs.size(); j++) {
      Germ og = germs.get(j);
      if (i != j && overlap(g, og)) {
        g.growing = false;
      }
    }
    g.display(shadowPG);
    g.update();
  }
  shadowPG.filter(BLUR, 4);
  shadowPG.endDraw();
  image(shadowPG, 0, 0);
  for (int i = 0; i < germs.size(); i++) {
    Germ g = germs.get(i);
    g.display();
    g.update();
  }

  for (int i = 0; i < bigGerms.size(); i++) {
    BigGerm g = bigGerms.get(i);
    g.show();
  }
  
  filter(BLUR, 1);
}

void initPG() {
  candidatePoints = new ArrayList<PVector>();
  PImage bgImg = loadImage("data/bg.jpg");

  gfx = createGraphics(width, height);
  gfx.beginDraw();
  gfx.image(bgImg, 0, 0, width, height);
  gfx.endDraw();

  gfx.loadPixels();
  for (int y = 0; y < gfx.height; y++) {
    for (int x = 0; x < gfx.width; x++) {
      if (red(gfx.get(x, y)) < 240) {
        candidatePoints.add(new PVector(x, y));
      }
    }
  }
}

void tryCreateGerm(int type) {
  int idx;
  float x, y;
  Germ g;

  if (type==1) {
    idx = floor(random(rateY*candidatePoints.size(), candidatePoints.size()));
    x = candidatePoints.get(idx).x;
    y = candidatePoints.get(idx).y;
    g = new Germ(x, y);
  } else {
    idx = floor(random(0, candidatePoints.size()));
    x = candidatePoints.get(idx).x;
    y = candidatePoints.get(idx).y;
    g = new Germ(x, y);
    g.r = random(60, 150);
    g.growing = false;
  }
  candidatePoints.remove(idx);
  boolean addGerm = true;
  for (int i = 0; i < germs.size(); i++) {
    Germ other = germs.get(i);

    if (overlap(g, other)) {
      addGerm = false;
    }
  }

  if (addGerm) {
    germs.add(g);
  }
}

boolean overlap(Germ g1, Germ g2) {
  float distance = dist(g1.x, g1.y, g2.x, g2.y);
  if (distance < g1.r + g2.r + 2) {
    return true;
  }
  return false;
}

class Germ {
  float x, y, r;
  boolean growing;

  Germ(float _x, float _y) {
    this.x = _x;
    this.y = _y;
    this.r = 2;
    this.growing = true;
  }
  
  boolean touchesEdge() {
    return x+r > width || x-r < 0 || y+r > height || y-r < 0;
  }

  void update() {
    if (growing) {
      r*=1.05;
    }

    if (growing && this.touchesEdge() || r >= 15) {
      growing = false;
    }
  }

  void display() {
    color from = color(#bababa);
    color to = color(#1a1f1b);
    color currCol = lerpColor(from, to, r/15);
    if (r > 2 && r<=20) {
      fill(currCol);
      ellipse(x, y, r*2, r*2);
    }
  }

  void display(PGraphics pg) {
    if (r > 2 && r<=20) {
      pg.fill(#dad9d5);
      pg.ellipse(x, y, r*2, r*2);
    }
  }
}

class BigGerm {
  float x, y, r;
  ArrayList<Germ> smallGerms;

  BigGerm(float _x, float _y, float _r) {
    this.x = _x;
    this.y = _y;
    this.r = _r;
    this.smallGerms = new ArrayList<Germ>();
    this.smallGerms.add(new Germ(x, y));
  }

  void update() {
    for (int i = 0; i < 5; i++) {
      this.addSmallGerm();
    }
    for (int i = 0; i < smallGerms.size(); i++) {
      Germ g = smallGerms.get(i);
      if (g.r>= map(dist(x, y, g.x, g.y), 0, r, 20, 4)) {
        g.growing = false;
      }

      for (int j = 0; j < smallGerms.size(); j++) {
        Germ og = smallGerms.get(j);
        if (i != j && overlap(g, og)) {
          g.growing = false;
        }
      }
      if (g.y>rateY*height) {
        g.display(shadowPG);
      }
      g.update();
    }
  }

  void show() {
    for (int i = 0; i < smallGerms.size(); i++) {
      Germ g = smallGerms.get(i);
      if (g.y>rateY*height) {
        g.display();
      }
    }
  }


  void addSmallGerm() {
    float nx = x+random(-r, r);
    float ny = y+random(-r, r);
    while (dist(x, y, nx, ny)> r -2) {
      nx = x+random(-r, r);
      ny = y+random(-r, r);
    }
    Germ g = new Germ(nx, ny);

    boolean addGerm = true;
    for (int i = 0; i < smallGerms.size(); i++) {
      Germ other = smallGerms.get(i);

      if (overlap(g, other)) {
        addGerm = false;
      }
    }

    if (addGerm) {
      smallGerms.add(g);
    }
  }
}
