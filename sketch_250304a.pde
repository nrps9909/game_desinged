import java.awt.Robot;
import java.awt.AWTException;
import processing.opengl.*;
import processing.sound.*;
import java.util.ArrayList;
import java.util.List;

// 全域變數
Player player;
ArrayList<Chair> chairs;
NPC classmate;  // 新增 NPC 同學
float camYaw = 0;
float camPitch = 0;
float sensitivity = 0.003;
Robot robot;
PShape chairModel;
PImage groundTex;

// WASD 鍵狀態
boolean wPressed, aPressed, sPressed, dPressed;

// 玩家與椅子距離多少才可坐下
float sitDistance = 80;

// 碰撞檢測額外乘數（>1 擴大範圍）
float collisionMargin = 2;

void settings() {
  fullScreen(P3D);
}

void setup() {
  textFont(createFont("Arial", 16));
  groundTex = loadImage("floor.jpg");
  try {
    robot = new Robot();
  } catch (AWTException e) {
    e.printStackTrace();
  }
  
  // 載入椅子模型
  chairModel = loadShape("chair.obj");
  
  // 初始化多張椅子，每張椅子都是獨立個體，可調整各自旋轉角度
  chairs = new ArrayList<Chair>();
  int numChairs = 10;
  float spacing = 200;  // 間距
  for (int i = 0; i < numChairs; i++){
    // 以 (100, -20, 100) 為起點，沿 x 軸排列
    PVector pos = new PVector(100 + i * spacing, -20, 100);
    // 每張椅子獨立旋轉（這裡用隨機角度示範）
    float rotation = random(-PI, PI);
    float scale = 100;
    chairs.add(new Chair(pos, rotation, scale));
  }
  
  // 建立玩家
  player = new Player(new PVector(0, 0, 0));
  
  // 放置同學 NPC：將同學放在第一張椅子上，並加上座位偏移（例如 40 單位高度）
  if(chairs.size() > 0) {
    Chair targetChair = chairs.get(0);
    // NPC 位置：以椅子位置為基準，加上適當偏移
    PVector npcPos = PVector.add(targetChair.pos, new PVector(0, 40, 0));
    classmate = new NPC(npcPos, this);
  }
  
  noCursor();
  camYaw = 0;
  camPitch = 2;
  centerMouse();
}

void draw() {
  background(135, 206, 235);
  lights();
  
  // 滑鼠視角控制
  float dx = mouseX - width/2;
  float dy = mouseY - height/2;
  camYaw -= dx * sensitivity;
  camPitch += dy * sensitivity;
  camPitch = constrain(camPitch, -radians(80), radians(80));
  centerMouse();
  
  // 更新玩家（包含碰撞檢查與滑動碰撞回應）
  player.update();
  
  // 設定第一人稱攝影機
  PVector eye = player.pos.copy();
  eye.y -= 135;  // 相機高度
  PVector center = new PVector(
    eye.x + cos(camPitch) * sin(camYaw),
    eye.y + sin(camPitch),
    eye.z + cos(camPitch) * cos(camYaw)
  );
  camera(eye.x, eye.y, eye.z, center.x, center.y, center.z, 0, 1, 0);
  
  // 繪製地面
  drawGround();
  
  // 繪製所有椅子
  for (Chair chair : chairs) {
    chair.draw();
  }
  
  // 繪製 NPC（同學）
  if (classmate != null) {
    classmate.draw();
  }
}

void drawGround() {
  pushMatrix();
    noStroke();
    textureMode(NORMAL);
    beginShape(QUADS);
      texture(groundTex);
      vertex(-2750, 0, -2062.5, 0, 0);
      vertex(2750, 0, -2062.5, 1, 0);
      vertex(2750, 0, 2062.5, 1, 1);
      vertex(-2750, 0, 2062.5, 0, 1);
    endShape();
  popMatrix();
}

void keyPressed() {
  if (key == 'w' || key == 'W') wPressed = true;
  if (key == 'a' || key == 'A') aPressed = true;
  if (key == 's' || key == 'S') sPressed = true;
  if (key == 'd' || key == 'D') dPressed = true;
  
  // 若按空白鍵則跳躍（僅限非對話狀態下）
  if (key == ' ' && (classmate == null || !classmate.isTalking)) {
    if (!player.isSeated) player.jump();
  }
  
  // 按 F 鍵：若玩家靠近 NPC（同學）則開始對話或進入下一段對話，
  // 否則執行原本坐椅子的動作
  if (key == 'f' || key == 'F') {
    if (classmate != null && PVector.dist(player.pos, classmate.pos) < 150) {
      if (!classmate.isTalking) {
        classmate.startConversation();
      } else {
        classmate.nextDialogue();
      }
    } else {
      if (player.isSeated) {
        player.exitChair();
      } else {
        for (Chair chair : chairs) {
          float d = PVector.dist(player.pos, chair.pos);
          if (d < sitDistance) {
            player.sitOnChair(chair.pos);
            break;
          }
        }
      }
    }
  }
}

void keyReleased() {
  if (key == 'w' || key == 'W') wPressed = false;
  if (key == 'a' || key == 'A') aPressed = false;
  if (key == 's' || key == 'S') sPressed = false;
  if (key == 'd' || key == 'D') dPressed = false;
}

void centerMouse() {
  if (robot != null) {
    robot.mouseMove(displayWidth/2, displayHeight/2);
  }
}

//---------------------------------------------------
// Player 類別（與碰撞處理保持不變）
//---------------------------------------------------
class Player {
  PVector pos, vel;
  float speed = 5;
  boolean onGround;
  boolean isSeated = false;
  // 膠囊參數
  float capsuleHeight = 80;
  float capsuleRadius = 30;
  
  Player(PVector startPos) {
    pos = startPos.copy();
    vel = new PVector(0, 0, 0);
    onGround = true;
  }
  
  void update() {
    if (isSeated) return;
    
    // 基本移動計算
    PVector move = new PVector();
    if (wPressed) move.add(new PVector(sin(camYaw), 0, cos(camYaw)));
    if (sPressed) move.sub(new PVector(sin(camYaw), 0, cos(camYaw)));
    if (aPressed) move.add(new PVector(sin(camYaw + HALF_PI), 0, cos(camYaw + HALF_PI)));
    if (dPressed) move.add(new PVector(sin(camYaw - HALF_PI), 0, cos(camYaw - HALF_PI)));
    
    if (move.mag() > 0) {
      move.normalize().mult(speed);
      vel.x = move.x;
      vel.z = move.z;
    } else {
      vel.x *= 0.9;
      vel.z *= 0.9;
    }
    
    // 加上重力
    vel.y += 0.5;
    
    // 根據本幀移動距離決定子步進數量，並限制最大子步進數
    float displacement = vel.mag();
    int subSteps = max(1, int(ceil(displacement / 5.0)));
    subSteps = min(subSteps, 10);
    PVector subVel = PVector.div(vel, subSteps);
    
    // 逐步嘗試移動
    for (int i = 0; i < subSteps; i++) {
      pos.add(subVel);
      
      // 地面碰撞檢查
      if (pos.y > 0) {
        pos.y = 0;
        vel.y = 0;
        onGround = true;
      } else {
        onGround = false;
      }
      
      // 設定膠囊檢查參數
      float effectiveRadius = capsuleRadius * collisionMargin;
      PVector capTop = PVector.add(pos, new PVector(0, capsuleHeight/2, 0));
      PVector capBottom = PVector.sub(pos, new PVector(0, capsuleHeight/2, 0));
      
      float maxPen = 0;
      PVector collisionNormal = new PVector(0, 0, 0);
      
      // 檢查靠近的椅子以降低計算量
      for (Chair chair : chairs) {
        if (PVector.dist(pos, chair.pos) > 300) continue;
        if (chair.bvh != null) {
          List<Triangle> candidates = new ArrayList<Triangle>();
          chair.bvh.collectPotentialCollisions(pos, effectiveRadius, candidates);
          for (Triangle tri : candidates) {
            // 取樣法取得膠囊上最靠近三角形的點
            PVector samplePoint = closestPointOnCapsuleSegmentToTriangle(capTop, capBottom, tri);
            if (samplePoint == null) continue;
            PVector cp = closestPointOnTriangle(samplePoint, tri);
            float d = PVector.dist(samplePoint, cp);
            if (d < effectiveRadius && (effectiveRadius - d) > maxPen) {
              maxPen = effectiveRadius - d;
              PVector pushDir = PVector.sub(samplePoint, cp);
              if (pushDir.mag() > 0) {
                pushDir.normalize();
                collisionNormal = pushDir;
              }
            }
          }
        }
      }
      
      // 若檢測到穿透，則將玩家調整出物體，並移除速度中進入物體的分量
      if (maxPen > 0.1) {
        pos.add(PVector.mult(collisionNormal, maxPen));
        float vn = vel.dot(collisionNormal);
        if (vn < 0) {
          vel.sub(PVector.mult(collisionNormal, vn));
        }
      }
    }
  }
  
  void jump() {
    if (onGround) {
      vel.y = -10;
      onGround = false;
    }
  }
  
  void sitOnChair(PVector chairPos) {
    PVector offset = new PVector(0, 40, 80);
    pos.set(PVector.add(chairPos, offset));
    vel.set(0, 0, 0);
    isSeated = true;
    onGround = true;
  }
  
  void exitChair() {
    isSeated = false;
  }
}

//---------------------------------------------------
// Chair 類別（保持原有結構）
//---------------------------------------------------
class Chair {
  PVector pos;
  float rotation; // Y 軸旋轉
  float scale;
  float baseRotation = PI; // 模型初始需要旋轉的角度
  BVHNode bvh;
  
  Chair(PVector pos, float rotation, float scale) {
    this.pos = pos.copy();
    this.rotation = rotation;
    this.scale = scale;
    
    // 建立轉換矩陣
    PMatrix3D mat = new PMatrix3D();
    mat.translate(pos.x, pos.y, pos.z);
    mat.scale(scale);
    mat.rotateX(baseRotation);
    mat.rotateY(rotation);
    // 從模型中提取三角形建立 BVH
    List<Triangle> tris = extractMeshTriangles(chairModel, mat);
    bvh = new BVHNode(tris);
  }
  
  void draw() {
    pushMatrix();
      translate(pos.x, pos.y, pos.z);
      scale(scale);
      rotateX(baseRotation);
      rotateY(rotation);
      shape(chairModel);
    popMatrix();
  }
}

//---------------------------------------------------
// NPC 同學類別：放置在椅子上，並可進行對話
//---------------------------------------------------
class NPC {
  PVector pos;
  boolean isTalking = false;
  String[] dialogueOptions;
  int currentDialogue = 0;
  SoundFile voice;
  
  NPC(PVector pos, PApplet parent) {
    this.pos = pos.copy();
    // 範例對話內容
    dialogueOptions = new String[] {
      "哈囉，你好嗎？",
      "今天天氣真好呢！",
      "下次一起去圖書館吧！"
    };
    // 請將 "npc_voice.wav" 放在 data 資料夾中
    voice = new SoundFile(parent, "npc_voice.wav");
  }
  
  // 開始對話
  void startConversation() {
    isTalking = true;
    currentDialogue = 0;
    playVoice();
  }
  
  // 撥放語音
  void playVoice() {
    if (voice != null) {
      voice.play();
    }
  }
  
  // 進入下一段對話，若對話結束則關閉對話介面
  void nextDialogue() {
    currentDialogue++;
    if (currentDialogue < dialogueOptions.length) {
      playVoice();
    } else {
      endConversation();
    }
  }
  
  void endConversation() {
    isTalking = false;
  }
  
  // 畫出 NPC 與對話 UI
  void draw() {
    // 畫出 NPC 代表（用球體表示）
    pushMatrix();
      translate(pos.x, pos.y - 40, pos.z);
      fill(255, 200, 200);
      noStroke();
      sphere(30);
    popMatrix();
    
    // 若正在對話，畫出對話介面
    if (isTalking) {
      drawDialogueUI();
    }
  }
  
  // 畫出螢幕底下的對話選項
  void drawDialogueUI() {
    fill(0, 150);
    rect(0, height - 100, width, 100);
    fill(255);
    textSize(20);
    textAlign(LEFT, CENTER);
    text(dialogueOptions[currentDialogue], 20, height - 50);
  }
}

//---------------------------------------------------
// Triangle、BVHNode 與輔助函式（保持原有邏輯）
//---------------------------------------------------
class Triangle {
  PVector v0, v1, v2;
  Triangle(PVector a, PVector b, PVector c) {
    v0 = a; 
    v1 = b; 
    v2 = c;
  }
  
  void getMinMax(PVector outMin, PVector outMax) {
    outMin.x = min(v0.x, min(v1.x, v2.x));
    outMin.y = min(v0.y, min(v1.y, v2.y));
    outMin.z = min(v0.z, min(v1.z, v2.z));
    outMax.x = max(v0.x, max(v1.x, v2.x));
    outMax.y = max(v0.y, max(v1.y, v2.y));
    outMax.z = max(v0.z, max(v1.z, v2.z));
  }
}

class BVHNode {
  PVector minBound = new PVector();
  PVector maxBound = new PVector();
  List<Triangle> triangles = new ArrayList<Triangle>();
  BVHNode leftChild = null;
  BVHNode rightChild = null;
  static final int MAX_TRI = 20;
  
  BVHNode(List<Triangle> tris) {
    buildNode(tris);
  }
  
  void buildNode(List<Triangle> tris) {
    if (tris == null || tris.isEmpty()) return;
    
    minBound.set(999999, 999999, 999999);
    maxBound.set(-999999, -999999, -999999);
    for (Triangle t : tris) {
      PVector tMin = new PVector();
      PVector tMax = new PVector();
      t.getMinMax(tMin, tMax);
      if (tMin.x < minBound.x) minBound.x = tMin.x;
      if (tMin.y < minBound.y) minBound.y = tMin.y;
      if (tMin.z < minBound.z) minBound.z = tMin.z;
      if (tMax.x > maxBound.x) maxBound.x = tMax.x;
      if (tMax.y > maxBound.y) maxBound.y = tMax.y;
      if (tMax.z > maxBound.z) maxBound.z = tMax.z;
    }
    
    if (tris.size() <= MAX_TRI) {
      triangles.addAll(tris);
      return;
    }
    
    PVector size = PVector.sub(maxBound, minBound);
    int axis;
    if (size.x > size.y && size.x > size.z) axis = 0;
    else if (size.y > size.z) axis = 1;
    else axis = 2;
    
    float midVal = (getAxisValue(minBound, axis) + getAxisValue(maxBound, axis)) * 0.5;
    List<Triangle> leftList = new ArrayList<Triangle>();
    List<Triangle> rightList = new ArrayList<Triangle>();
    for (Triangle t : tris) {
      float cx = ( getAxisValue(t.v0, axis) +
                   getAxisValue(t.v1, axis) +
                   getAxisValue(t.v2, axis) ) / 3.0;
      if (cx < midVal) leftList.add(t);
      else rightList.add(t);
    }
    if (leftList.size() == 0 || rightList.size() == 0) {
      triangles.addAll(tris);
      return;
    }
    leftChild = new BVHNode(leftList);
    rightChild = new BVHNode(rightList);
  }
  
  void collectPotentialCollisions(PVector center, float radius, List<Triangle> outList) {
    if (!sphereIntersectsAABB(center, radius, minBound, maxBound)) return;
    if (leftChild == null && rightChild == null) {
      outList.addAll(triangles);
      return;
    }
    if (leftChild != null) leftChild.collectPotentialCollisions(center, radius, outList);
    if (rightChild != null) rightChild.collectPotentialCollisions(center, radius, outList);
  }
}

float getAxisValue(PVector v, int axis) {
  switch(axis) {
    case 0: return v.x;
    case 1: return v.y;
    case 2: return v.z;
  }
  return 0;
}

boolean sphereIntersectsAABB(PVector c, float r, PVector minB, PVector maxB) {
  float nx = constrain(c.x, minB.x, maxB.x);
  float ny = constrain(c.y, minB.y, maxB.y);
  float nz = constrain(c.z, minB.z, maxB.z);
  float dx = c.x - nx;
  float dy = c.y - ny;
  float dz = c.z - nz;
  return (dx*dx + dy*dy + dz*dz) <= r*r;
}

List<Triangle> extractMeshTriangles(PShape shp, PMatrix3D mat) {
  List<Triangle> result = new ArrayList<Triangle>();
  extractTrianglesRecursive(shp, mat, result);
  return result;
}

void extractTrianglesRecursive(PShape shape, PMatrix3D parentMatrix, List<Triangle> outList) {
  PMatrix3D curMatrix = parentMatrix.get();
  int vc = shape.getVertexCount();
  if (vc >= 3 && shape.getChildCount() == 0) {
    for (int i = 0; i <= vc - 3; i += 3) {
      PVector v0 = shape.getVertex(i);
      PVector v1 = shape.getVertex(i+1);
      PVector v2 = shape.getVertex(i+2);
      PVector w0 = applyMatrix(v0, curMatrix);
      PVector w1 = applyMatrix(v1, curMatrix);
      PVector w2 = applyMatrix(v2, curMatrix);
      outList.add(new Triangle(w0, w1, w2));
    }
  }
  for (int i = 0; i < shape.getChildCount(); i++) {
    PShape child = shape.getChild(i);
    if (child != null) {
      extractTrianglesRecursive(child, curMatrix, outList);
    }
  }
}

PVector applyMatrix(PVector v, PMatrix3D mat) {
  float[] in = { v.x, v.y, v.z, 1 };
  float[] out = new float[4];
  mat.mult(in, out);
  return new PVector(out[0], out[1], out[2]);
}

PVector closestPointOnTriangle(PVector c, Triangle tri) {
  PVector v0 = tri.v0;
  PVector v1 = tri.v1;
  PVector v2 = tri.v2;
  PVector edge0 = PVector.sub(v1, v0);
  PVector edge1 = PVector.sub(v2, v0);
  PVector vv = PVector.sub(c, v0);
  float dot00 = edge0.dot(edge0);
  float dot01 = edge0.dot(edge1);
  float dot02 = edge0.dot(vv);
  float dot11 = edge1.dot(edge1);
  float dot12 = edge1.dot(vv);
  float denom = (dot00 * dot11 - dot01 * dot01);
  if (abs(denom) >= 0.000001) {
    float invDenom = 1.0 / denom;
    float u = (dot11 * dot02 - dot01 * dot12) * invDenom;
    float w = (dot00 * dot12 - dot01 * dot02) * invDenom;
    if (u >= 0 && w >= 0 && (u + w) <= 1) {
      PVector proj = v0.copy();
      proj.add(PVector.mult(edge0, u));
      proj.add(PVector.mult(edge1, w));
      return proj;
    }
  }
  PVector c0 = closestPointOnSegment(c, v0, v1);
  PVector c1 = closestPointOnSegment(c, v1, v2);
  PVector c2 = closestPointOnSegment(c, v2, v0);
  float dist0 = PVector.dist(c, c0);
  float dist1 = PVector.dist(c, c1);
  float dist2 = PVector.dist(c, c2);
  if (dist0 < dist1 && dist0 < dist2) return c0;
  else if (dist1 < dist2) return c1;
  else return c2;
}

PVector closestPointOnSegment(PVector p, PVector a, PVector b) {
  PVector ab = PVector.sub(b, a);
  float t = PVector.sub(p, a).dot(ab) / ab.dot(ab);
  t = constrain(t, 0, 1);
  return PVector.add(a, PVector.mult(ab, t));
}

PVector closestPointOnCapsuleSegmentToTriangle(PVector A, PVector B, Triangle tri) {
  int steps = 3;  // 降低取樣點數
  float bestDist = Float.MAX_VALUE;
  PVector bestPoint = null;
  for (int i = 0; i <= steps; i++) {
    float t = i / float(steps);
    PVector candidate = PVector.lerp(A, B, t);
    PVector cp = closestPointOnTriangle(candidate, tri);
    float d = PVector.dist(candidate, cp);
    if (d < bestDist) {
      bestDist = d;
      bestPoint = candidate.copy();
    }
  }
  if (bestPoint == null) {
    return A.copy();
  }
  return bestPoint;
}
