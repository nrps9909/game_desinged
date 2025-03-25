import java.awt.Robot;
import java.awt.AWTException;
import processing.opengl.*;
import processing.sound.*;
import java.util.ArrayList;
import java.util.List;

Player player;
ArrayList<Chair> chairs;
NPC classmate;
float camYaw = 0, camPitch = 2;
float sensitivity = 0.003;
Robot robot;
PShape chairModel;
PImage groundTex;
PGraphics uiLayer;
boolean wPressed, aPressed, sPressed, dPressed;
float sitDistance = 80;
float collisionMargin = 2;

void settings() {
  fullScreen(P3D);
}

void setup() {
  try {
    textFont(createFont("Microsoft YaHei", 16));
  } catch (Exception e) {
    println("字體載入失敗: " + e.getMessage());
    textFont(createFont("Arial", 16));
  }
  try {
    groundTex = loadImage("floor.jpg");
    if (groundTex == null) println("地板紋理未找到！");
  } catch (Exception e) {
    println("地板紋理載入失敗: " + e.getMessage());
  }
  try {
    robot = new Robot();
  } catch (AWTException e) {
    e.printStackTrace();
  }
  try {
    chairModel = loadShape("chair.obj");
    if (chairModel == null) println("椅子模型未找到！");
  } catch (Exception e) {
    println("椅子模型載入失敗: " + e.getMessage());
  }
  
  chairs = new ArrayList<Chair>();
  for (int i = 0; i < 10; i++) {
    PVector pos = new PVector(100 + i * 200, -20, 100);
    float rotation = random(-PI, PI);
    chairs.add(new Chair(pos, rotation, 100));
  }
  
  player = new Player(new PVector(100, 0, 100));
  if (chairs.size() > 0) {
    classmate = new NPC(chairs.get(0).getSeatPosition(), this);
  }
  
  noCursor();
  centerMouse();
  uiLayer = createGraphics(width, height, P2D);
}

void draw() {
  background(135, 206, 235);
  lights();
  
  float dx = mouseX - width/2;
  float dy = mouseY - height/2;
  camYaw -= dx * sensitivity;
  camPitch += dy * sensitivity;
  camPitch = constrain(camPitch, -radians(80), radians(80));
  centerMouse();
  
  player.update();
  
  pushMatrix();
  PVector eye = player.pos.copy();
  eye.y -= 135;
  PVector center = new PVector(
    eye.x + cos(camPitch) * sin(camYaw),
    eye.y + sin(camPitch),
    eye.z + cos(camPitch) * cos(camYaw)
  );
  camera(eye.x, eye.y, eye.z, center.x, center.y, center.z, 0, 1, 0);
  
  drawGround();
  drawAxes();
  for (Chair chair : chairs) {
    chair.draw();
  }
  if (classmate != null) {
    classmate.update();
    classmate.drawNPC();
  }
  popMatrix();
  
  uiLayer.beginDraw();
  uiLayer.clear();
  if (classmate != null && classmate.isTalking) {
    classmate.drawDialogueUI(uiLayer);
  }
  uiLayer.endDraw();
  image(uiLayer, 0, 0);
}

void drawGround() {
  if (groundTex != null) {
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
}

void drawAxes() {
  pushStyle();
  pushMatrix();
  strokeWeight(2);
  int tickInterval = 500;
  float tickLength = 40;
  float labelOffset = 60;

  stroke(255, 0, 0);
  line(-5000, 0, 0, 5000, 0, 0);
  for (int x = -5000; x <= 5000; x += tickInterval) {
    line(x, -200 - tickLength/2, 0, x, -200 + tickLength/2, 0);
    PVector tickPos = new PVector(x, -200 - tickLength/2 - labelOffset, 0);
    pushMatrix();
    translate(tickPos.x, tickPos.y, tickPos.z);
    PVector toCam = PVector.sub(player.pos, tickPos);
    float angle = atan2(toCam.x, toCam.z);
    rotateY(angle);
    fill(255);
    textSize(48);
    textAlign(CENTER, CENTER);
    if (x == 5000) text("X", 0, 0);
    else if (x == -5000) text("-X", 0, 0);
    else text(x, 0, 0);
    popMatrix();
  }
  
  stroke(0, 255, 0);
  line(0, 5000, 0, 0, -5000, 0);
  for (int y = 5000; y >= -5000; y -= tickInterval) {
    line(-tickLength/2, y, 0, tickLength/2, y, 0);
    PVector tickPos = new PVector(tickLength/2 + labelOffset, y, 0);
    pushMatrix();
    translate(tickPos.x, tickPos.y, tickPos.z);
    fill(255);
    textSize(48);
    textAlign(CENTER, CENTER);
    if (y == 5000) text("Y", 0, 0);
    else if (y == -5000) text("-Y", 0, 0);
    else text(-y, 0, 0);
    popMatrix();
  }
  
  stroke(0, 0, 255);
  line(0, 0, -5000, 0, 0, 5000);
  for (int z = -5000; z <= 5000; z += tickInterval) {
    line(0, -200 - tickLength/2, z, 0, -200 + tickLength/2, z);
    PVector tickPos = new PVector(0, -200 - tickLength/2 - labelOffset, z);
    pushMatrix();
    translate(tickPos.x, tickPos.y, tickPos.z);
    PVector toCam = PVector.sub(player.pos, tickPos);
    float angle = atan2(toCam.x, toCam.z);
    rotateY(angle);
    fill(255);
    textSize(48);
    textAlign(CENTER, CENTER);
    if (z == 5000) text("Z", 0, 0);
    else if (z == -5000) text("-Z", 0, 0);
    else text(z, 0, 0);
    popMatrix();
  }
  popMatrix();
  popStyle();
}

void keyPressed() {
  if (key == 'w' || key == 'W') wPressed = true;
  if (key == 'a' || key == 'A') aPressed = true;
  if (key == 's' || key == 'S') sPressed = true;
  if (key == 'd' || key == 'D') dPressed = true;
  
  if (key == ' ' && !player.isSeated) player.jump();
  
  if (key == 'f' || key == 'F') {
    if (classmate != null && PVector.dist(player.pos, classmate.pos) < 150) {
      if (!classmate.isTalking) {
        println("開始對話");
        classmate.startConversation();
      } else if (classmate.canProceed()) {
        println("下一句對話");
        classmate.nextDialogue();
      } else {
        println("等待 NPC 說完...");
      }
    } else if (player.isSeated) {
      player.exitChair();
    } else {
      for (Chair chair : chairs) {
        if (PVector.dist(player.pos, chair.getSeatPosition()) < sitDistance) {
          player.sitOnChair(chair);
          break;
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
  if (robot != null) robot.mouseMove(displayWidth/2, displayHeight/2);
}

class Player {
  PVector pos, vel;
  float speed = 5;
  boolean onGround, isSeated = false;
  float capsuleHeight = 80, capsuleRadius = 30;
  
  Player(PVector startPos) {
    pos = startPos.copy();
    vel = new PVector(0, 0, 0);
    onGround = true;
  }
  
  void update() {
    if (isSeated) return;
    
    PVector move = new PVector(0, 0, 0);
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
    
    vel.y += 0.5;
    
    float displacement = vel.mag();
    int subSteps = max(1, int(ceil(displacement / 5.0)));
    subSteps = min(subSteps, 10);
    PVector subVel = PVector.div(vel, subSteps);
    
    for (int i = 0; i < subSteps; i++) {
      pos.add(subVel);
      
      if (pos.y > 0) {
        pos.y = 0;
        vel.y = 0;
        onGround = true;
      } else {
        onGround = false;
      }
      
      float effectiveRadius = capsuleRadius * collisionMargin;
      PVector capTop = PVector.add(pos, new PVector(0, capsuleHeight/2, 0));
      PVector capBottom = PVector.sub(pos, new PVector(0, capsuleHeight/2, 0));
      
      float maxPen = 0;
      PVector collisionNormal = new PVector(0, 0, 0);
      
      // 檢查與椅子的碰撞
      for (Chair chair : chairs) {
        if (PVector.dist(pos, chair.pos) > 300) continue;
        if (chair.bvh != null) {
          List<Triangle> candidates = new ArrayList<Triangle>();
          chair.bvh.collectPotentialCollisions(pos, effectiveRadius, candidates);
          for (Triangle tri : candidates) {
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
      
      // 檢查與 NPC 的碰撞
      if (classmate != null) {
        float npcRadius = 30; // NPC 的球形碰撞體半徑
        float totalRadius = effectiveRadius + npcRadius;
        PVector npcCenter = PVector.add(classmate.pos, new PVector(0, -50, 0)); // NPC 中心點
        float distToNPC = PVector.dist(pos, npcCenter);
        if (distToNPC < totalRadius) {
          float penetration = totalRadius - distToNPC;
          if (penetration > maxPen) {
            maxPen = penetration;
            collisionNormal = PVector.sub(pos, npcCenter).normalize();
          }
        }
      }
      
      // 碰撞響應
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
  
  void sitOnChair(Chair chair) {
    pos.set(chair.getSeatPosition());
    vel.set(0, 0, 0);
    isSeated = true;
    onGround = true;
    camYaw = chair.getFacingAngle();
  }
  
  void exitChair() {
    isSeated = false;
  }
}

class Chair {
  PVector pos;
  float rotation, scale;
  float baseRotation = PI;
  PVector seatOffsetLocal = new PVector(0, 40, 80);
  BVHNode bvh;
  
  Chair(PVector pos, float rotation, float scale) {
    this.pos = pos.copy();
    this.rotation = rotation;
    this.scale = scale;
    
    if (chairModel != null) {
      PMatrix3D mat = new PMatrix3D();
      mat.translate(pos.x, pos.y, pos.z);
      mat.scale(scale);
      mat.rotateX(baseRotation);
      mat.rotateY(rotation);
      List<Triangle> tris = extractMeshTriangles(chairModel, mat);
      bvh = new BVHNode(tris);
    }
  }
  
  PVector getSeatPosition() {
    float offsetX = seatOffsetLocal.x * cos(rotation) - seatOffsetLocal.z * sin(rotation);
    float offsetZ = seatOffsetLocal.x * sin(rotation) + seatOffsetLocal.z * cos(rotation);
    return PVector.add(pos, new PVector(offsetX, seatOffsetLocal.y, offsetZ));
  }
  
  float getFacingAngle() {
    float offsetX = seatOffsetLocal.x * cos(rotation) - seatOffsetLocal.z * sin(rotation);
    float offsetZ = seatOffsetLocal.x * sin(rotation) + seatOffsetLocal.z * cos(rotation);
    return atan2(offsetX, offsetZ);
  }
  
  void draw() {
    if (chairModel != null) {
      pushMatrix();
      translate(pos.x, pos.y, pos.z);
      scale(scale);
      rotateX(baseRotation);
      rotateY(rotation);
      shape(chairModel);
      popMatrix();
    }
  }
}

class NPC {
  PVector pos;
  boolean isTalking = false;
  String[] dialogueOptions = {"哈囉，你的天如何？", "今天天氣非常好！", "師大圖書館我最喜歡！"};
  int currentDialogue = 0;
  SoundFile voice;
  float talkStartTime = 0;
  float talkDuration = 2.0;
  
  NPC(PVector pos, PApplet parent) {
    this.pos = pos.copy();
    try {
      voice = new SoundFile(parent, "rickroll5.mp3");
      if (voice != null) talkDuration = voice.duration();
    } catch (Exception e) {
      println("語音載入失敗: " + e.getMessage());
    }
  }
  
  void startConversation() {
    isTalking = true;
    currentDialogue = 0;
    talkStartTime = millis() / 1000.0;
    if (voice != null) voice.play();
  }
  
  void nextDialogue() {
    currentDialogue++;
    if (currentDialogue < dialogueOptions.length) {
      talkStartTime = millis() / 1000.0;
      if (voice != null) voice.play();
    } else {
      endConversation();
    }
  }
  
  void endConversation() {
    isTalking = false;
    if (voice != null) voice.stop();
  }
  
  void update() {
    if (isTalking && voice != null && !voice.isPlaying()) {
      endConversation();
    }
  }
  
  boolean canProceed() {
    return (millis() / 1000.0 - talkStartTime >= talkDuration);
  }
  
  void drawNPC() {
    pushStyle();
    pushMatrix();
    translate(pos.x - 20, pos.y - 100, pos.z - 20);
    fill(255, 200, 200);
    noStroke();
    sphere(30);
    popMatrix();
    popStyle();
  }
  
  void drawDialogueUI(PGraphics pg) {
    pg.pushStyle();
    pg.textFont(createFont("Microsoft YaHei", 16));
    pg.fill(0, 200);
    pg.rect(50, pg.height - 200, pg.width - 100, 150, 20);
    
    pg.fill(255, 255, 0);
    pg.textSize(24);
    pg.textAlign(LEFT, TOP);
    pg.text("同学", 70, pg.height - 180);
    
    pg.fill(255);
    pg.textSize(20);
    pg.text(dialogueOptions[currentDialogue], 70, pg.height - 140, pg.width - 140, 100);
    
    pg.textSize(16);
    pg.textAlign(RIGHT, BOTTOM);
    if (canProceed()) {
      pg.fill(0, 255, 0);
      pg.text("按 F 繼續", pg.width - 70, pg.height - 60);
    } else {
      pg.fill(255, 100, 100);
      pg.text("正在說話...", pg.width - 70, pg.height - 60);
    }
    pg.popStyle();
  }
}

// 碰撞檢測相關類別和函數
class Triangle {
  PVector v0, v1, v2;
  Triangle(PVector a, PVector b, PVector c) {
    v0 = a; v1 = b; v2 = c;
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
    int axis = (size.x > size.y && size.x > size.z) ? 0 : (size.y > size.z) ? 1 : 2;
    
    float midVal = (getAxisValue(minBound, axis) + getAxisValue(maxBound, axis)) * 0.5;
    List<Triangle> leftList = new ArrayList<Triangle>();
    List<Triangle> rightList = new ArrayList<Triangle>();
    for (Triangle t : tris) {
      float cx = (getAxisValue(t.v0, axis) + getAxisValue(t.v1, axis) + getAxisValue(t.v2, axis)) / 3.0;
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
  int steps = 3;
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
  if (bestPoint == null) return A.copy();
  return bestPoint;
}
