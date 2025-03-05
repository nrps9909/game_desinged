import java.awt.Robot;
import java.awt.AWTException;
import processing.opengl.*;

Player player;
float camYaw = 0;
float camPitch = 0;
float sensitivity = 0.003;
Robot robot;
PShape chairModel;

PImage groundTex;



// WASD 鍵狀態
boolean wPressed, aPressed, sPressed, dPressed;

void settings() {
  fullScreen(P3D);
  
}

void setup() {
  chairModel = loadShape("chair.obj");
  textFont(createFont("Arial", 16));
  groundTex = loadImage("floor.jpg");  // 放在 data/ 資料夾
  try {
    robot = new Robot();
  } catch (AWTException e) {
    e.printStackTrace();
  }
  
  // 玩家初始位置
  player = new Player(new PVector(0, 0, 0));
  
  noCursor();
  camYaw = 0;
  camPitch = 2;
  centerMouse();
}

void draw() {
  background(135, 206, 235);
  lights();
  
  // 更新滑鼠移動後的攝影機角度
  float dx = mouseX - width/2;
  float dy = mouseY - height/2;
  // 改為減掉 dx，使左右視角移動符合直覺
  camYaw   -= dx * sensitivity;
  camPitch += dy * sensitivity;
  camPitch = constrain(camPitch, -radians(80), radians(80));
  centerMouse();
  
  // 更新玩家移動
  player.update();
  
  // 設定第一人稱視角：攝影機位置設在玩家眼位，並根據 camYaw 與 camPitch 調整觀看方向
  PVector eye = player.pos.copy();
  eye.y -= 135;  // 可依需求調整視角高度
  PVector center = new PVector(
    eye.x + cos(camPitch) * sin(camYaw),
    eye.y + sin(camPitch),
    eye.z + cos(camPitch) * cos(camYaw)
  );
  camera(eye.x, eye.y, eye.z, center.x, center.y, center.z, 0, 1, 0);
  
  // 繪製平地
  drawGround();
  // 繪製椅子
  pushMatrix();
    // 舉例：把椅子放在 x=100, y=0, z=100 的地面上
    translate(100, -20, 100);
    // 若模型本身很大或很小，可用 scale() 進行縮放
    scale(100);
    rotateX(PI);
    shape(chairModel);
  popMatrix();
}

void centerMouse() {
  if (robot != null) {
    robot.mouseMove(displayWidth/2, displayHeight/2);
  }
}

void drawGround() {
  pushMatrix();
  noStroke();
  textureMode(NORMAL);
  
  beginShape(QUADS);
    texture(groundTex);
    // 以 (0,0,0) 為中心，可以對稱分布
    // ½(5500) = 2750，½(4125) = 2062.5
    vertex(-2750, 0, -2062.5, 0, 0);  // 左前角 (u,v)=(0,0)
    vertex( 2750, 0, -2062.5, 1, 0);  // 右前角 (u,v)=(1,0)
    vertex( 2750, 0,  2062.5, 1, 1);  // 右後角 (u,v)=(1,1)
    vertex(-2750, 0,  2062.5, 0, 1);  // 左後角 (u,v)=(0,1)
  endShape();
  
  popMatrix();
}

void keyPressed() {
  if (key == 'w' || key == 'W') {
    wPressed = true;
  }
  if (key == 'a' || key == 'A') {
    aPressed = true;
  }
  if (key == 's' || key == 'S') {
    sPressed = true;
  }
  if (key == 'd' || key == 'D') {
    dPressed = true;
  }
  if (key == ' ') {
    player.jump();
  }
}

void keyReleased() {
  if (key == 'w' || key == 'W') {
    wPressed = false;
  }
  if (key == 'a' || key == 'A') {
    aPressed = false;
  }
  if (key == 's' || key == 'S') {
    sPressed = false;
  }
  if (key == 'd' || key == 'D') {
    dPressed = false;
  }
}

//====================================
// Player 類別：僅包含移動與跳躍邏輯
//====================================
class Player {
  PVector pos, vel;
  float speed = 5;
  boolean onGround;
  
  Player(PVector pos) {
    this.pos = pos.copy();
    this.vel = new PVector(0, 0, 0);
    onGround = true;
  }
  
  void update() {
    PVector move = new PVector(0, 0, 0);
    // 依據 camYaw 計算前後左右的移動方向（第一人稱模式）
    if (wPressed) {
      move.add(new PVector(sin(camYaw), 0, cos(camYaw)));
    }
    if (sPressed) {
      move.sub(new PVector(sin(camYaw), 0, cos(camYaw)));
    }
    if (aPressed) {
      move.add(new PVector(sin(camYaw + HALF_PI), 0, cos(camYaw + HALF_PI)));
    }
    if (dPressed) {
      move.add(new PVector(sin(camYaw - HALF_PI), 0, cos(camYaw - HALF_PI)));
    }
    
    if (move.mag() > 0) {
      move.normalize();
      move.mult(speed);
      vel.x = move.x;
      vel.z = move.z;
    } else {
      vel.x *= 0.9;
      vel.z *= 0.9;
    }
    
    // 模擬重力
    vel.y += 0.5;
    pos.add(vel);
    
    // 簡單地面碰撞檢測
    if (pos.y > 0) {
      pos.y = 0;
      vel.y = 0;
      onGround = true;
    } else {
      onGround = false;
    }
  }
  
  void jump() {
    if (onGround) {
      vel.y = -10;
      onGround = false;
    }
  }
}
