import java.awt.Robot;
import java.awt.AWTException;
import processing.opengl.*;
import java.util.ArrayList;
import java.util.List;

Player player;
float camYaw = 0;
float camPitch = 0;
float sensitivity = 0.003;
Robot robot;

PShape chairModel;
PImage groundTex;

// WASD 鍵狀態
boolean wPressed, aPressed, sPressed, dPressed;

// 椅子在 3D 世界的定位
PVector chairPos = new PVector(100, -20, 100);

// 玩家與椅子距離多少才可坐下`
float sitDistance = 80;

// 碰撞檢測額外乘數，可調整碰撞範圍（>1 會擴大碰撞範圍）
float collisionMargin = 2.2;

//========= BVH (空間分割) 相關 =========
BVHNode bvhRoot;  // 主根節點(包住整個椅子)

//-----------------------------------------------------------------
// 幫助函式：根據 axis=0/1/2 取得 PVector 的 x / y / z
//-----------------------------------------------------------------
float getAxisValue(PVector v, int axis) {
  switch(axis) {
    case 0: return v.x;
    case 1: return v.y;
    case 2: return v.z;
  }
  return 0;
}

//-----------------------------------------------------------------
// Processing: settings, setup, draw
//-----------------------------------------------------------------
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

  // 將椅子模型轉成三角形並放大/旋轉/平移到世界座標
  List<Triangle> chairTriangles = extractMeshTriangles(chairModel, chairPos, 100, PI);

  // 建立 BVH，提高 Mesh 碰撞的效率
  bvhRoot = new BVHNode(chairTriangles);

  // 建立玩家
  player = new Player(new PVector(0, 0, 0));

  noCursor();
  camYaw = 0;
  camPitch = 2;
  centerMouse();
}

void draw() {
  background(135, 206, 235);
  lights();

  // 1. 滑鼠視角
  float dx = mouseX - width/2;
  float dy = mouseY - height/2;
  camYaw   -= dx * sensitivity;
  camPitch += dy * sensitivity;
  camPitch = constrain(camPitch, -radians(80), radians(80));
  centerMouse();

  // 2. 更新玩家(含碰撞判斷)
  player.update();

  // 3. 設定第一人稱攝影機
  PVector eye = player.pos.copy();
  eye.y -= 135;  // 相機高度
  PVector center = new PVector(
    eye.x + cos(camPitch) * sin(camYaw),
    eye.y + sin(camPitch),
    eye.z + cos(camPitch) * cos(camYaw)
  );
  camera(eye.x, eye.y, eye.z, center.x, center.y, center.z, 0, 1, 0);

  // 4. 繪製地面
  drawGround();

  // 5. 繪製椅子 (純視覺)
  pushMatrix();
    translate(chairPos.x, chairPos.y, chairPos.z);
    scale(100);
    rotateX(PI);
    shape(chairModel);
  popMatrix();
}

//-----------------------------------------------------------------
// Ground
//-----------------------------------------------------------------
void drawGround() {
  pushMatrix();
  noStroke();
  textureMode(NORMAL);
  
  beginShape(QUADS);
    texture(groundTex);
    vertex(-2750, 0, -2062.5, 0, 0);
    vertex( 2750, 0, -2062.5, 1, 0);
    vertex( 2750, 0,  2062.5, 1, 1);
    vertex(-2750, 0,  2062.5, 0, 1);
  endShape();
  
  popMatrix();
}

//-----------------------------------------------------------------
// Player 類別：含移動 + 碰撞偵測
//-----------------------------------------------------------------
class Player {
  PVector pos, vel;
  float speed = 5;
  boolean onGround;
  boolean isSeated = false;

  float playerRadius = 30; // 玩家以球體做碰撞

  Player(PVector startPos) {
    pos = startPos.copy();
    vel = new PVector(0, 0, 0);
    onGround = true;
  }

  void update() {
    if (isSeated) {
      return;
    }

    // 1) 移動 (W/A/S/D)
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
    // 重力
    vel.y += 0.5;
    pos.add(vel);

    // 2) 地面碰撞 (y=0)
    if (pos.y > 0) {
      pos.y = 0;
      vel.y = 0;
      onGround = true;
    } else {
      onGround = false;
    }

    // 3) Mesh 碰撞 (椅子)
    meshCollision();
  }

  // 以 BVH 先找候選三角形，再做球-三角形最近點檢查
  void meshCollision() {
    if (bvhRoot == null) return;

    float effectiveRadius = playerRadius * collisionMargin;
    List<Triangle> candidates = new ArrayList<Triangle>();
    bvhRoot.collectPotentialCollisions(pos, effectiveRadius, candidates);

    for (Triangle tri : candidates) {
      PVector cp = closestPointOnTriangle(pos, tri);
      float dist = PVector.dist(pos, cp);
      if (dist < effectiveRadius) {
        float pen = effectiveRadius - dist;
        PVector pushDir = PVector.sub(pos, cp).normalize();
        pos.add(PVector.mult(pushDir, pen));
      }
    }
  }

  void jump() {
    if (onGround) {
      vel.y = -10;
      onGround = false;
    }
  }

  void sitOnChair(PVector cPos) {
    // 坐下時的位置微調
    PVector offset = new PVector(0, 40, 80);
    pos.set(PVector.add(cPos, offset));
    vel.set(0, 0, 0);
    isSeated = true;
    onGround = true;
  }

  void exitChair() {
    isSeated = false;
  }
}

//-----------------------------------------------------------------
// Triangle：儲存 3D 座標 v0,v1,v2
//-----------------------------------------------------------------
class Triangle {
  PVector v0, v1, v2;

  Triangle(PVector a, PVector b, PVector c) {
    v0 = a; 
    v1 = b; 
    v2 = c;
  }

  // 取得最小/最大 xyz (AABB)
  void getMinMax(PVector outMin, PVector outMax) {
    outMin.x = min(v0.x, min(v1.x, v2.x));
    outMin.y = min(v0.y, min(v1.y, v2.y));
    outMin.z = min(v0.z, min(v1.z, v2.z));
    outMax.x = max(v0.x, max(v1.x, v2.x));
    outMax.y = max(v0.y, max(v1.y, v2.y));
    outMax.z = max(v0.z, max(v1.z, v2.z));
  }
}

//-----------------------------------------------------------------
// BVHNode：用軸對齊包圍盒 (AABB) 做空間分割
//-----------------------------------------------------------------
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

    // 1) 計算本節點 AABB
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

    // 2) 若數量 <= MAX_TRI -> 葉子
    if (tris.size() <= MAX_TRI) {
      triangles.addAll(tris);
      return;
    }

    // 3) 否則，依「最長軸」切分
    PVector size = PVector.sub(maxBound, minBound);
    int axis;
    if (size.x > size.y && size.x > size.z) {
      axis = 0;
    } else if (size.y > size.z) {
      axis = 1;
    } else {
      axis = 2;
    }
    float midVal = (getAxisValue(minBound, axis) + getAxisValue(maxBound, axis)) * 0.5;

    List<Triangle> leftList = new ArrayList<Triangle>();
    List<Triangle> rightList = new ArrayList<Triangle>();

    // 以三角形中心在哪邊做切分
    for (Triangle t : tris) {
      float cx = ( getAxisValue(t.v0, axis)
                 + getAxisValue(t.v1, axis)
                 + getAxisValue(t.v2, axis) ) / 3.0;
      if (cx < midVal) leftList.add(t);
      else rightList.add(t);
    }

    // 若某一邊空 -> 強制平分
    if (leftList.size() == 0 && rightList.size() > 0) {
      int half = rightList.size()/2;
      leftList.addAll(rightList.subList(0, half));
      rightList = rightList.subList(half, rightList.size());
    }
    else if (rightList.size() == 0 && leftList.size() > 0) {
      int half = leftList.size()/2;
      rightList.addAll(leftList.subList(0, half));
      leftList = leftList.subList(half, leftList.size());
    }

    // 若依然無法切分 -> 葉子
    if (leftList.size() == 0 || rightList.size() == 0) {
      triangles.addAll(tris);
      return;
    }

    // 建立子節點
    leftChild = new BVHNode(leftList);
    rightChild = new BVHNode(rightList);
  }

  // 收集「可能與球 (center, radius) 相撞」的三角形
  void collectPotentialCollisions(PVector center, float radius, List<Triangle> outList) {
    // 若球跟本節點的 AABB 無碰撞 -> 不檢查
    if (!sphereIntersectsAABB(center, radius, minBound, maxBound)) {
      return;
    }

    // 若是葉子 -> 全部三角形
    if (leftChild == null && rightChild == null) {
      outList.addAll(triangles);
      return;
    }
    // 否則遞迴
    if (leftChild != null) leftChild.collectPotentialCollisions(center, radius, outList);
    if (rightChild != null) rightChild.collectPotentialCollisions(center, radius, outList);
  }
}

//-----------------------------------------------------------------
// 判斷「球 vs. AABB」是否相交
//-----------------------------------------------------------------
boolean sphereIntersectsAABB(PVector c, float r, PVector minB, PVector maxB) {
  float nx = constrain(c.x, minB.x, maxB.x);
  float ny = constrain(c.y, minB.y, maxB.y);
  float nz = constrain(c.z, minB.z, maxB.z);

  float dx = c.x - nx;
  float dy = c.y - ny;
  float dz = c.z - nz;
  float distSq = dx*dx + dy*dy + dz*dz;
  return (distSq <= r*r);
}

//-----------------------------------------------------------------
// 從 PShape 中提取三角形：套用 (translate, scale, rotateX)
//-----------------------------------------------------------------
List<Triangle> extractMeshTriangles(PShape shp, PVector pos, float s, float rotX) {
  List<Triangle> result = new ArrayList<Triangle>();

  // 先組個 3D 矩陣
  PMatrix3D mat = new PMatrix3D();
  mat.translate(pos.x, pos.y, pos.z);
  mat.scale(s);
  mat.rotateX(rotX);

  extractTrianglesRecursive(shp, mat, result);
  return result;
}

//-----------------------------------------------------------------
//  遞迴讀取 PShape 及其子 shape -> 擷取三角形頂點
//-----------------------------------------------------------------
void extractTrianglesRecursive(PShape shape, PMatrix3D parentMatrix, List<Triangle> outList) {
  // 1) 複製父矩陣
  PMatrix3D curMatrix = parentMatrix.get();
  
  // 2) Processing 3.x 中已移除 getMatrix() 方法，
  // 因此此處預設 shape 本身無局部轉換，或需自行管理轉換矩陣
  
  // 3) 若此 shape 本身有頂點 (且沒有子 shape)，則把頂點抓出來
  int vc = shape.getVertexCount();
  if (vc >= 3 && shape.getChildCount() == 0) {
    // 修改迴圈條件，避免存取不存在的索引
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
  
  // 4) 如果有子 shape，繼續遞迴
  for (int i = 0; i < shape.getChildCount(); i++) {
    PShape child = shape.getChild(i);
    if (child != null) {
      extractTrianglesRecursive(child, curMatrix, outList);
    }
  }
}

//-----------------------------------------------------------------
// 幫頂點 (x,y,z) 套用 3D 矩陣
//-----------------------------------------------------------------
PVector applyMatrix(PVector v, PMatrix3D mat) {
  float[] in = { v.x, v.y, v.z, 1 };
  float[] out = new float[4];
  mat.mult(in, out);
  return new PVector(out[0], out[1], out[2]);
}

//-----------------------------------------------------------------
// 計算球心 c 到三角形 (v0,v1,v2) 的最近點
//-----------------------------------------------------------------
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
  if (abs(denom) < 0.000001) {
    // 幾乎退化 -> 當成邊線即可
    // (雖然正常不該發生，但以防三角形無面積)
    // 直接回到最後的 "最近邊" 判斷
  } else {
    float invDenom = 1.0 / denom;
    float u = (dot11 * dot02 - dot01 * dot12) * invDenom;
    float w = (dot00 * dot12 - dot01 * dot02) * invDenom;

    if (u >= 0 && w >= 0 && (u + w) <= 1) {
      // 在三角形內
      PVector proj = v0.copy();
      proj.add(PVector.mult(edge0, u));
      proj.add(PVector.mult(edge1, w));
      return proj;
    }
  }

  // 否則找最近的邊或頂點
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

//-----------------------------------------------------------------
// 幫助函式：點 p 到線段 ab 的最近點
//-----------------------------------------------------------------
PVector closestPointOnSegment(PVector p, PVector a, PVector b) {
  PVector ab = PVector.sub(b, a);
  float t = PVector.sub(p, a).dot(ab) / ab.dot(ab);
  t = constrain(t, 0, 1);
  return PVector.add(a, PVector.mult(ab, t));
}

//-----------------------------------------------------------------
// 鍵盤事件
//-----------------------------------------------------------------
void keyPressed() {
  if (key == 'w' || key == 'W') wPressed = true;
  if (key == 'a' || key == 'A') aPressed = true;
  if (key == 's' || key == 'S') sPressed = true;
  if (key == 'd' || key == 'D') dPressed = true;

  if (key == ' ') {
    if (!player.isSeated) {
      player.jump();
    }
  }

  if (key == 'f' || key == 'F') {
    if (player.isSeated) {
      player.exitChair();
    } else {
      float distToChair = PVector.dist(player.pos, chairPos);
      if (distToChair < sitDistance) {
        player.sitOnChair(chairPos);
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

//-----------------------------------------------------------------
// 置中滑鼠
//-----------------------------------------------------------------
void centerMouse() {
  if (robot != null) {
    robot.mouseMove(displayWidth/2, displayHeight/2);
  }
}
