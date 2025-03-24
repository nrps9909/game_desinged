import processing.sound.*; // For audio playback
import processing.video.*; // For video playback

SoundFile audioFile; // The audio file (WAV or MP3)
Movie videoFile; // The video file (MP4)
FFT fft; // For frequency analysis
String studentInfo = "41171214H 陳廷安 播放器"; // Your student ID and name
String personalTag = "TingAn CyberDeck"; // Personalized tag/logo

// File type detection
boolean isVideo = false; // Flag to check if the file is an MP4
String filePath = "rickroll.mp3"; // Default to WAV; change to your MP4 file if needed (e.g., "test.mp4")

// Font
PFont chineseFont;
PFont cyberFont;

// Button positions and sizes
int buttonSize = 60;
int buttonY;
int loopButtonX;
int muteButtonX;
int stopButtonX;
int playButtonX;
int replayButtonX;

// Button states
boolean isPlaying = false;
boolean isMuted = false;
boolean isLooping = false;
boolean loopPressed = false;
boolean mutePressed = false;
boolean stopPressed = false;
boolean playPressed = false;
boolean replayPressed = false;

// Volume slider
float volume = 1.0; // Volume level (0 to 1)
int sliderX;
int sliderY;
int sliderWidth;
int sliderHeight = 10;
boolean sliderDragging = false;

// For dynamic waveform and visualization
int bands = 512; // Number of frequency bands for FFT
float[] spectrum = new float[bands];

// Particle system for visual effects
ArrayList<Particle> particles = new ArrayList<Particle>();

// 3D wireframe cube
float cubeAngle = 0;

void setup() {
  fullScreen(P3D); // Use P3D renderer for 3D effects
  
  // Load a font that supports Chinese characters
  chineseFont = createFont("Microsoft YaHei", 32);
  if (chineseFont == null) {
    chineseFont = createFont("SimSun", 32);
  }
  if (chineseFont == null) {
    chineseFont = createFont("Arial", 32);
  }
  
  // Load a Cyberpunk font (replace with a font like "Orbitron" if available)
  cyberFont = createFont("Arial", 16); // Fallback to Arial; ideally use a font like "Orbitron"
  
  // Check file type and load accordingly
  if (filePath.toLowerCase().endsWith(".mp4")) {
    isVideo = true;
    try {
      videoFile = new Movie(this, filePath);
      videoFile.loop(); // Start the video in a paused state
      videoFile.pause();
    } catch (Exception e) {
      println("Error loading video file: " + e.getMessage());
      isVideo = false; // Fallback to audio mode if video fails
      filePath = "npc_voice.wav"; // Fallback to a default audio file
    }
  }
  
  // Load audio file if not a video or if video loading failed
  if (!isVideo) {
    audioFile = new SoundFile(this, filePath);
    // Set up FFT for audio file
    fft = new FFT(this, bands);
    fft.input(audioFile);
  }
  
  // Calculate button positions (centered)
  buttonY = height - 100;
  loopButtonX = width/2 - 200;
  muteButtonX = width/2 - 100;
  stopButtonX = width/2;
  playButtonX = width/2 + 100;
  replayButtonX = width/2 + 200;
  
  // Volume slider position
  sliderWidth = width/4;
  sliderX = width/2 - sliderWidth/2;
  sliderY = buttonY - 60;
  
  textAlign(CENTER);
}

// Callback for video frame availability
void movieEvent(Movie m) {
  m.read();
}

void draw() {
  // Cyberpunk background
  background(10, 20, 30);
  
  // Draw scanlines for Cyberpunk effect
  stroke(255, 255, 255, 20);
  for (int i = 0; i < height; i += 10) {
    line(0, i, width, i);
  }
  
  // Analyze the audio with FFT (only for audio files)
  float avgAmp = 0;
  if (!isVideo) {
    fft.analyze(spectrum);
    // Calculate average amplitude for animations
    for (int i = 0; i < bands/4; i++) {
      avgAmp += spectrum[i];
    }
    avgAmp /= (bands/4);
  } else {
    // For videos, use a fake amplitude to keep particles and cube moving
    avgAmp = random(0.01, 0.05); // Simulated amplitude
  }
  
  // Draw spectrum analyzer with glitch effect
  for (int i = 0; i < bands/4; i++) {
    float x = map(i, 0, bands/4, 0, width);
    float h = -spectrum[i] * height * 3;
    stroke(lerpColor(color(255, 0, 255), color(0, 255, 255), i/(float)(bands/4)));
    strokeWeight(3 + random(-1, 1)); // Glitchy flicker
    if (random(1) < 0.05) stroke(255, 255, 255, 150); // Random white flicker
    line(x, height, x, height + h);
  }
  
  // Draw video in the center if it's an MP4
  if (isVideo && videoFile != null) {
    imageMode(CENTER);
    float videoScale = min(width * 0.6 / videoFile.width, height * 0.6 / videoFile.height);
    image(videoFile, width/2, height/2, videoFile.width * videoScale, videoFile.height * videoScale);
  }
  
  // Draw particles with trails
  if (random(1) < avgAmp * 50) {
    particles.add(new Particle(random(width), random(height)));
  }
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update(avgAmp);
    p.display();
    if (p.isDead()) {
      particles.remove(i);
    }
  }
  
  // Draw rotating 3D wireframe cube
  pushMatrix();
  translate(width/2, height/2, -200);
  rotateX(cubeAngle);
  rotateY(cubeAngle);
  stroke(255, 0, 255, 150);
  strokeWeight(2);
  noFill();
  box(100 + avgAmp * 500);
  popMatrix();
  cubeAngle += avgAmp * 0.5;
  
  // Draw personalized holographic tag
  fill(0, 255, 255, 150);
  textFont(cyberFont);
  textSize(24);
  text(personalTag, width/2 + random(-3, 3), height/4 + random(-3, 3));
  fill(255, 0, 255, 100);
  text(personalTag, width/2 + random(-3, 3), height/4 + random(-3, 3));
  
  // Draw student info with Cyberpunk glitch effect (moved up)
  fill(255, 105, 180);
  textFont(chineseFont);
  textSize(32);
  text(studentInfo, width/2 + random(-2, 2), height/2 - 100 + random(-2, 2)); // Moved up by 60 pixels
  fill(0, 255, 255, 150);
  text(studentInfo, width/2 + random(-2, 2), height/2 - 100 + random(-2, 2));
  
  // Draw volume slider with neon glow
  drawSlider();
  
  // Draw buttons with Cyberpunk style
  drawButtons();
}

void drawSlider() {
  stroke(0, 255, 255);
  strokeWeight(2);
  fill(50, 50, 50);
  rect(sliderX, sliderY, sliderWidth, sliderHeight);
  
  float handleX = map(volume, 0, 1, sliderX, sliderX + sliderWidth - 10);
  noStroke();
  fill(255, 0, 255);
  rect(handleX, sliderY - 5, 10, sliderHeight + 10);
  for (int i = 0; i < 10; i++) {
    stroke(255, 0, 255, 100 - i * 10);
    strokeWeight(2 + i);
    line(handleX, sliderY - 5, handleX + 10, sliderY - 5);
    line(handleX, sliderY + 15, handleX + 10, sliderY + 15);
  }
  
  if (sliderDragging) {
    volume = constrain(map(mouseX, sliderX, sliderX + sliderWidth, 0, 1), 0, 1);
    if (!isMuted) {
      if (isVideo && videoFile != null) {
        videoFile.volume(volume);
      } else {
        audioFile.amp(volume);
      }
    }
  }
}

void drawButtons() {
  // Loop button
  fill(loopPressed ? 50 : 0, loopPressed ? 150 : 120, loopPressed ? 255 : 255);
  stroke(0, 255, 255);
  strokeWeight(2);
  if (random(1) < 0.1) stroke(255, 255, 255, 150);
  rect(loopButtonX, buttonY, buttonSize, buttonSize);
  drawLoopIcon(loopButtonX + buttonSize/2, buttonY + buttonSize/2);
  textFont(cyberFont);
  fill(255, 0, 255);
  textSize(16);
  text("Loop", loopButtonX + buttonSize/2, buttonY + buttonSize + 20);
  
  // Mute button
  fill(mutePressed ? 50 : 0, mutePressed ? 150 : 120, mutePressed ? 255 : 255);
  stroke(0, 255, 255);
  strokeWeight(2);
  if (random(1) < 0.1) stroke(255, 255, 255, 150);
  rect(muteButtonX, buttonY, buttonSize, buttonSize);
  drawMuteIcon(muteButtonX + buttonSize/2, buttonY + buttonSize/2);
  textFont(cyberFont);
  fill(255, 0, 255);
  textSize(16);
  text("Mute", muteButtonX + buttonSize/2, buttonY + buttonSize + 20);
  
  // Stop button
  fill(stopPressed ? 50 : 0, stopPressed ? 150 : 120, stopPressed ? 255 : 255);
  stroke(0, 255, 255);
  strokeWeight(2);
  if (random(1) < 0.1) stroke(255, 255, 255, 150);
  rect(stopButtonX, buttonY, buttonSize, buttonSize);
  drawStopIcon(stopButtonX + buttonSize/2, buttonY + buttonSize/2);
  textFont(cyberFont);
  fill(255, 0, 255);
  textSize(16);
  text("Stop", stopButtonX + buttonSize/2, buttonY + buttonSize + 20);
  
  // Play/Pause button
  fill(playPressed ? 50 : 0, playPressed ? 150 : 120, playPressed ? 255 : 255);
  stroke(0, 255, 255);
  strokeWeight(2);
  if (random(1) < 0.1) stroke(255, 255, 255, 150);
  rect(playButtonX, buttonY, buttonSize, buttonSize);
  if (isPlaying) {
    drawPauseIcon(playButtonX + buttonSize/2, buttonY + buttonSize/2);
    textFont(cyberFont);
    fill(255, 0, 255);
    textSize(16);
    text("Pause", playButtonX + buttonSize/2, buttonY + buttonSize + 20);
  } else {
    drawPlayIcon(playButtonX + buttonSize/2, buttonY + buttonSize/2);
    textFont(cyberFont);
    fill(255, 0, 255);
    textSize(16);
    text("Play", playButtonX + buttonSize/2, buttonY + buttonSize + 20);
  }
  
  // Replay button
  fill(replayPressed ? 50 : 0, replayPressed ? 150 : 120, replayPressed ? 255 : 255);
  stroke(0, 255, 255);
  strokeWeight(2);
  if (random(1) < 0.1) stroke(255, 255, 255, 150);
  rect(replayButtonX, buttonY, buttonSize, buttonSize);
  drawReplayIcon(replayButtonX + buttonSize/2, buttonY + buttonSize/2);
  textFont(cyberFont);
  fill(255, 0, 255);
  textSize(16);
  text("Replay", replayButtonX + buttonSize/2, buttonY + buttonSize + 20);
}

// Custom icon drawing functions
void drawLoopIcon(float x, float y) {
  stroke(255, 0, 255);
  strokeWeight(2);
  noFill();
  arc(x - 5, y, 20, 20, PI/2, TWO_PI);
  arc(x + 5, y, 20, 20, -PI/2, PI);
  triangle(x - 5, y - 10, x - 10, y - 15, x, y - 15);
  triangle(x + 5, y + 10, x + 10, y + 15, x, y + 15);
}

void drawMuteIcon(float x, float y) {
  stroke(255, 0, 255);
  strokeWeight(2);
  noFill();
  triangle(x - 10, y - 10, x - 10, y + 10, x + 5, y);
  line(x + 5, y - 5, x + 10, y - 5);
  line(x + 5, y + 5, x + 10, y + 5);
  line(x - 5, y - 15, x + 15, y + 15);
}

void drawStopIcon(float x, float y) {
  fill(0, 255, 255);
  noStroke();
  rect(x - 10, y - 10, 20, 20);
}

void drawPlayIcon(float x, float y) {
  fill(0, 255, 255);
  noStroke();
  triangle(x - 10, y - 10, x - 10, y + 10, x + 15, y);
}

void drawPauseIcon(float x, float y) {
  fill(0, 255, 255);
  noStroke();
  rect(x - 10, y - 10, 5, 20);
  rect(x + 5, y - 10, 5, 20);
}

void drawReplayIcon(float x, float y) {
  stroke(255, 0, 255);
  strokeWeight(2);
  noFill();
  arc(x, y, 20, 20, 0, PI + HALF_PI);
  triangle(x + 10, y - 5, x + 15, y - 10, x + 15, y);
}

// Particle class for visual effects
class Particle {
  float x, y;
  float vx, vy;
  float lifespan;
  float size;
  int shapeType;
  ArrayList<PVector> trail = new ArrayList<PVector>();
  
  Particle(float x, float y) {
    this.x = x;
    this.y = y;
    this.vx = random(-2, 2);
    this.vy = random(-2, 2);
    this.lifespan = 255;
    this.size = random(5, 15);
    this.shapeType = int(random(3));
  }
  
  void update(float amp) {
    x += vx + amp * 10;
    y += vy + amp * 10;
    lifespan -= 2;
    trail.add(new PVector(x, y));
    if (trail.size() > 10) trail.remove(0);
  }
  
  void display() {
    noFill();
    for (int i = 0; i < trail.size() - 1; i++) {
      stroke(lerpColor(color(255, 0, 255), color(0, 255, 255), i/(float)trail.size()), map(i, 0, trail.size(), 0, lifespan));
      strokeWeight(1);
      line(trail.get(i).x, trail.get(i).y, trail.get(i+1).x, trail.get(i+1).y);
    }
    
    noStroke();
    fill(lerpColor(color(255, 0, 255), color(0, 255, 255), lifespan/255.0), lifespan);
    if (shapeType == 0) {
      ellipse(x, y, size, size);
    } else if (shapeType == 1) {
      triangle(x, y - size, x - size, y + size, x + size, y + size);
    } else {
      rect(x - size/2, y - size/2, size, size);
    }
  }
  
  boolean isDead() {
    return lifespan <= 0;
  }
}

void mousePressed() {
  // Check for slider interaction
  float handleX = map(volume, 0, 1, sliderX, sliderX + sliderWidth - 10);
  if (mouseX >= handleX && mouseX <= handleX + 10 && mouseY >= sliderY - 5 && mouseY <= sliderY + sliderHeight + 5) {
    sliderDragging = true;
  }
  
  // Loop button
  if (mouseX > loopButtonX && mouseX < loopButtonX + buttonSize && mouseY > buttonY && mouseY < buttonY + buttonSize) {
    loopPressed = true;
    isLooping = !isLooping;
    if (isVideo && videoFile != null) {
      if (isLooping) {
        videoFile.loop();
      } else {
        videoFile.play();
      }
    } else {
      if (isLooping) {
        audioFile.loop();
      } else {
        audioFile.play();
      }
    }
  }
  
  // Mute button
  if (mouseX > muteButtonX && mouseX < muteButtonX + buttonSize && mouseY > buttonY && mouseY < buttonY + buttonSize) {
    mutePressed = true;
    isMuted = !isMuted;
    if (isMuted) {
      if (isVideo && videoFile != null) {
        videoFile.volume(0);
      } else {
        audioFile.amp(0);
      }
    } else {
      if (isVideo && videoFile != null) {
        videoFile.volume(volume);
      } else {
        audioFile.amp(volume);
      }
    }
  }
  
  // Stop button
  if (mouseX > stopButtonX && mouseX < stopButtonX + buttonSize && mouseY > buttonY && mouseY < buttonY + buttonSize) {
    stopPressed = true;
    if (isVideo && videoFile != null) {
      videoFile.stop();
    } else {
      audioFile.stop();
    }
    isPlaying = false;
  }
  
  // Play/Pause button
  if (mouseX > playButtonX && mouseX < playButtonX + buttonSize && mouseY > buttonY && mouseY < buttonY + buttonSize) {
    playPressed = true;
    if (isPlaying) {
      if (isVideo && videoFile != null) {
        videoFile.pause();
      } else {
        audioFile.pause();
      }
    } else {
      if (isVideo && videoFile != null) {
        if (isLooping) {
          videoFile.loop();
        } else {
          videoFile.play();
        }
      } else {
        if (isLooping) {
          audioFile.loop();
        } else {
          audioFile.play();
        }
      }
    }
    isPlaying = !isPlaying;
  }
  
  // Replay button
  if (mouseX > replayButtonX && mouseX < replayButtonX + buttonSize && mouseY > buttonY && mouseY < buttonY + buttonSize) {
    replayPressed = true;
    if (isVideo && videoFile != null) {
      videoFile.stop();
      if (isLooping) {
        videoFile.loop();
      } else {
        videoFile.play();
      }
    } else {
      audioFile.stop();
      if (isLooping) {
        audioFile.loop();
      } else {
        audioFile.play();
      }
    }
    isPlaying = true;
  }
}

void mouseReleased() {
  // Reset button pressed states
  loopPressed = false;
  mutePressed = false;
  stopPressed = false;
  playPressed = false;
  replayPressed = false;
  
  // Stop slider dragging
  sliderDragging = false;
}
