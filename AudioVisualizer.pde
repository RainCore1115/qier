import processing.sound.*;

AudioIn input;
Amplitude analyzer;
FFT fft;

int bands = 64;
float[] spectrum = new float[bands];

float smoothFactor = 0.2;
float[] sum = new float[bands];

ArrayList<Particle> particles;

void setup() {
  size(800, 600);
  background(0);
  
  input = new AudioIn(this, 0);
  input.start();
  
  analyzer = new Amplitude(this);
  analyzer.input(input);
  
  fft = new FFT(this, bands);
  fft.input(input);
  
  particles = new ArrayList<Particle>();
  for (int i = 0; i < 100; i++) {
    particles.add(new Particle());
  }
}

void draw() {
  fill(0, 30);
  noStroke();
  rect(0, 0, width, height);
  
  fft.analyze(spectrum);
  
  float volume = analyzer.analyze();
  
  translate(width / 2, height / 2);
  
  for (int i = 0; i < bands; i++) {
    sum[i] += (spectrum[i] - sum[i]) * smoothFactor;
  }
  
  strokeWeight(2);
  noFill();
  
  for (int ring = 1; ring <= 3; ring++) {
    float baseRadius = 80 * ring;
    
    beginShape();
    for (int i = 0; i < bands; i++) {
      float angle = map(i, 0, bands, 0, TWO_PI);
      
      float amp = sum[i] * 200 * ring;
      float r = baseRadius + amp;
      
      float hue = map(i, 0, bands, 200, 340);
      float sat = map(sum[i], 0, 0.5, 50, 100);
      float bri = map(sum[i], 0, 0.5, 60, 100);
      
      colorMode(HSB, 360, 100, 100);
      stroke(hue, sat, bri, 150);
      
      float x = r * cos(angle);
      float y = r * sin(angle);
      
      vertex(x, y);
    }
    endShape(CLOSE);
  }
  
  colorMode(RGB, 255);
  
  for (Particle p : particles) {
    p.update(volume);
    p.display();
  }
  
  float pulseSize = 50 + volume * 300;
  noFill();
  stroke(255, 100);
  strokeWeight(1);
  ellipse(0, 0, pulseSize, pulseSize);
}

class Particle {
  float x, y;
  float vx, vy;
  float size;
  float alpha;
  
  Particle() {
    x = random(-width/2, width/2);
    y = random(-height/2, height/2);
    vx = random(-1, 1);
    vy = random(-1, 1);
    size = random(2, 6);
    alpha = random(100, 200);
  }
  
  void update(float volume) {
    x += vx + volume * 10;
    y += vy + volume * 10;
    
    if (x < -width/2) x = width/2;
    if (x > width/2) x = -width/2;
    if (y < -height/2) y = height/2;
    if (y > height/2) y = -height/2;
    
    size = map(volume, 0, 0.5, 2, 15);
  }
  
  void display() {
    noStroke();
    fill(255, alpha);
    ellipse(x, y, size, size);
  }
}
