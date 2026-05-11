/**
 * ============================================================
 *  墨韵敦煌 · 飞天  —  Ink Rhythm of Dunhuang · Flying Celestial
 * ============================================================
 *
 * 【创作说明 / Creative Statement】
 *   以敦煌飞天为灵感，水墨晕染为底，矿物色点缀。
 *   鼠标引导飞天飘带流转，点击绽放莲花，
 *   体验传统美学与数字艺术的交融。
 *
 * 【技术要素 / Technical Elements】
 *   - setup / draw 结构
 *   - HSB 色彩模式 (色相 Hue 0~360, 饱和度 Saturation 0~100,
 *                     亮度 Brightness 0~100, 透明度 Alpha 0~100)
 *   - 基本图形: 矩形(边框回纹)、椭圆(莲花瓣/涟漪)、
 *               线条(飞天飘带)、弧线(曼陀罗环)
 *   - 变量驱动动画: time 控制全局律动, breathPhase 呼吸感缩放,
 *                   mandalaRotation 旋转角度跟随鼠标
 *   - 鼠标输入: 位置影响曼陀罗旋转与飘带偏移,
 *               点击产生涟漪与墨花, 拖拽产生墨滴轨迹
 *   - 坐标系变换: translate() 平移至画面中心,
 *                 rotate() 旋转曼陀罗, scale() 呼吸缩放
 *   - 传统文化主题: 敦煌莫高窟飞天、莲花曼陀罗、回纹边框、
 *                   水墨晕染、朱砂/石青/佛金矿物颜料色系
 *   - 时长: 循环运行, 交互可持续任意时长 (10~20 秒体验充分)
 */

// ==================== 全局变量 ====================
float   time           = 0;       // 全局动画时间 (驱动所有动态元素)
float   breathPhase    = 0;       // "呼吸"相位 (0.7~1.0, 模拟画面呼吸感)
float[] ribbonPhases;             // 每条飘带的初始相位偏移
int     ribbonCount    = 5;       // 飘带数量
color[] dunhuangColors;           // 敦煌矿物色系 (HSB 存储)

float   mandalaRotation = 0;      // 曼陀罗当前旋转角度
float   targetRotation  = 0;      // 旋转目标值 (由鼠标 X 坐标映射)

boolean isDragging      = false;  // 是否正在拖拽
PVector dragStart;                // 拖拽起始点
float   dragInfluence   = 0;      // 拖拽影响力 (0~1, 松开后衰减)

ArrayList<Ripple>  ripples;       // 涟漪列表 (鼠标点击产生)
ArrayList<InkDrop> inkDrops;      // 墨滴粒子列表 (拖拽/点击产生)


// ==================== 初始化 ====================
void setup() {
  // ---- 画布 ----
  size(800, 800);

  // ---- HSB 色彩模式 (H:0-360, S:0-100, B:0-100, A:0-100) ----
  // 使用 HSB 而非 RGB, 便于实现自然的色相渐变与过渡
  colorMode(HSB, 360, 100, 100, 100);

  // ---- 8 倍抗锯齿 ----
  smooth(8);

  // ---- 初始化飘带相位 (每条不同, 形成错落流动感) ----
  ribbonPhases = new float[ribbonCount];
  for (int i = 0; i < ribbonCount; i++) {
    ribbonPhases[i] = random(TWO_PI);
  }

  // ---- 敦煌色系 (HSB 值) ----
  // 参考莫高窟壁画颜料: 朱砂红、石青蓝、佛金色、墨色、沙土色、松石绿
  dunhuangColors = new color[6];
  dunhuangColors[0] = color(5,   85, 90);   // 朱砂红 (Cinnabar Red)
  dunhuangColors[1] = color(200, 80, 70);   // 石青蓝 (Mineral Blue)
  dunhuangColors[2] = color(45,  90, 90);   // 佛金色 (Buddha Gold)
  dunhuangColors[3] = color(30,  10, 25);   // 墨色   (Ink Black)
  dunhuangColors[4] = color(35,  40, 80);   // 沙土色 (Sand)
  dunhuangColors[5] = color(160, 50, 85);   // 松石绿 (Turquoise)

  // ---- 动态列表 ----
  ripples  = new ArrayList<Ripple>();
  inkDrops = new ArrayList<InkDrop>();
  dragStart = new PVector(0, 0);

  // ---- 墨色初始背景 ----
  background(30, 10, 25);
}


// ==================== 主循环 ====================
void draw() {
  // ---- 半透明背景覆盖 (营造水墨拖影/晕染效果) ----
  // 不彻底清除画布, 而是叠加一层半透明墨色矩形,
  // 使前一帧的图形逐渐隐去, 产生水墨在宣纸上自然晕开的拖尾感
  fill(30, 10, 25, 12);
  noStroke();
  rect(0, 0, width, height);

  // ---- 更新全局时间 ----
  // 约 60fps 下的帧增量, 使动画速度不依赖帧率波动
  time += 0.016;

  // ---- 更新呼吸相位 (sin 在 -1..1 间缓动, 映射到 0.7..1.0) ----
  breathPhase = sin(time * 0.5) * 0.15 + 0.85;

  // ---- 鼠标 X 坐标映射为目标旋转角度 (-PI/6 到 +PI/6) ----
  // 鼠标位置是主要交互手段之一: 左右移动控制曼陀罗倾斜旋转
  targetRotation = map(mouseX, 0, width, -PI / 6, PI / 6);

  // ---- 缓动跟随 (指数衰减逼近, 产生惯性感) ----
  mandalaRotation += (targetRotation - mandalaRotation) * 0.05;

  // ---- 拖拽影响力衰减 (松开鼠标后逐渐归零) ----
  if (!isDragging && dragInfluence > 0) {
    dragInfluence *= 0.97;
    if (dragInfluence < 0.005) dragInfluence = 0;
  }

  // ============ 第 1 层: 水墨晕染背景 ============
  drawInkWashBackground();

  // ============ 第 2 层: 飞天飘带 (线条动画) ============
  drawFlyingRibbons();

  // ============ 第 3 层: 中心莲花曼陀罗 (translate + rotate + scale) ============
  pushMatrix();
  translate(width / 2, height / 2);   // ★ 平移: 将坐标系原点移至画布中心
  drawLotusMandala();
  popMatrix();

  // ============ 第 4 层: 边框装饰 (矩形 + 回纹) ============
  drawBorderDecoration();

  // ============ 第 5 层: 涟漪 (鼠标点击产生) ============
  updateAndDrawRipples();

  // ============ 第 6 层: 墨滴粒子 (拖拽/点击产生) ============
  updateAndDrawInkDrops();

  // ============ 第 7 层: 鼠标光标光晕 ============
  drawMouseGlow();
}


// ================================================================
//  第 1 层: 水墨晕染背景
//  使用多层半透明椭圆模拟水墨在宣纸上扩散渗透的纹理
// ================================================================
void drawInkWashBackground() {
  noStroke();

  // 三层交错椭圆, 每层位置随时间缓慢漂移
  for (int i = 0; i < 3; i++) {
    // 偏移量由 sin/cos 驱动, 互成 120° 相位差
    float offX = sin(time * 0.3 + i * TWO_PI / 3) * 60 * breathPhase;
    float offY = cos(time * 0.4 + i * TWO_PI / 3) * 45 * breathPhase;
    // 透明度也随时间波动, 模拟墨色浓淡变化
    float alp = map(sin(time * 0.6 + i), -1, 1, 2, 8);

    // 不同色相的蓝灰色调, 模拟青墨层层渲染
    fill(200 + i * 25, 12, 40 + i * 6, alp);
    ellipse(width / 2 + offX, height / 2 + offY,
            320 + sin(time + i) * 60, 380 + cos(time + i) * 50);
  }

  // 四角墨韵, 增强画面层次
  fill(25, 5, 20, 5);
  ellipse(100 + sin(time * 0.2) * 20, 100 + cos(time * 0.3) * 15, 180, 170);
  ellipse(width - 100 + cos(time * 0.25) * 20,
         height - 100 + sin(time * 0.35) * 15, 190, 175);
}


// ================================================================
//  第 2 层: 飞天飘带 (线条)
//  使用 curveVertex 绘制闭合的 Catmull-Rom 样条曲线,
//  通过多层不同透明度的线圈叠加, 表现飞天飘带的轻盈流动
// ================================================================
void drawFlyingRibbons() {
  noFill();

  // 每条飘带独立绘制
  for (int r = 0; r < ribbonCount; r++) {
    float basePhase = ribbonPhases[r] + time * (0.7 + r * 0.12);

    // 鼠标距离画面中心的远近影响飘带波动幅度
    float mouseDist = dist(mouseX, mouseY, width / 2, height / 2);
    float mouseInfluence = constrain(mouseDist / (width * 0.45), 0, 1);

    // 拖拽时飘带更活跃
    float activity = 1 + dragInfluence * 2.5;

    // 当前飘带基础颜色 (取自敦煌色系)
    color baseColor = dunhuangColors[r % dunhuangColors.length];

    // ---- 预计算飘带顶点 ----
    int   ptCount = 150;          // 采样点数 (越多越平滑)
    float[] xs    = new float[ptCount];
    float[] ys    = new float[ptCount];

    for (int i = 0; i < ptCount; i++) {
      float t = map(i, 0, ptCount, 0, TWO_PI);

      // 飘带半径: 基础半径 + 多重正弦扰动
      float radius = 170 + r * 38;
      radius += sin(t * 3 + basePhase) * 65 * activity;
      radius += sin(t * 5 + basePhase * 1.4) * 28;
      radius += cos(t * 7 + basePhase * 0.7) * 15 * mouseInfluence;

      // 鼠标位置对飘带产生引力偏移
      float pullX = (mouseX - width / 2) * 0.18 * sin(t + basePhase);
      float pullY = (mouseY - height / 2) * 0.18 * cos(t + basePhase);

      xs[i] = cos(t + basePhase * 0.25) * radius + pullX;
      ys[i] = sin(t + basePhase * 0.25) * radius + pullY;
    }

    // ---- 三层叠加 (由外向内, 透明度递增, 线宽递减) ----
    for (int layer = 0; layer < 3; layer++) {
      float layerAlpha = map(layer, 0, 2, 55, 18);
      float layerWidth = map(layer, 0, 2, 3.5, 0.8) * breathPhase * activity;

      strokeWeight(layerWidth);
      // 色相沿路径缓慢旋转
      float ribbonHue = (hue(baseColor) + time * 15 + r * 40) % 360;
      stroke(ribbonHue,
             saturation(baseColor) * (0.7 + layer * 0.15),
             brightness(baseColor) * (0.6 + layer * 0.2),
             layerAlpha);

      // ★ 使用 curveVertex 绘制平滑闭合曲线
      beginShape();
      // 控制点: 倒数第二点 (使曲线闭合处平滑)
      curveVertex(xs[ptCount - 2], ys[ptCount - 2]);
      for (int i = 0; i < ptCount; i++) {
        curveVertex(xs[i] + width / 2, ys[i] + height / 2);
      }
      // 控制点: 第一、二点 (使曲线闭合处平滑)
      curveVertex(xs[0]          + width / 2, ys[0]          + height / 2);
      curveVertex(xs[1]          + width / 2, ys[1]          + height / 2);
      endShape();
    }
  }
}


// ================================================================
//  第 3 层: 莲花曼陀罗
//  综合运用 translate / rotate / scale 三种坐标系变换
//  以画布中心为原点, 旋转角度由鼠标 X 位置控制
// ================================================================
void drawLotusMandala() {
  // ★ scale: 呼吸缩放, 使曼陀罗有"心跳"般的生命感
  float scl = breathPhase * (1 + dragInfluence * 0.25);
  scale(scl);

  // ★ rotate: 旋转跟随鼠标 (mandalaRotation 由鼠标 X 坐标驱动)
  rotate(mandalaRotation);

  int petalCount = 8;              // 八瓣莲花 (佛教八正道象征)

  // -------- 外层: 莲花瓣 (椭圆旋转阵列) --------
  for (int i = 0; i < petalCount; i++) {
    float angle = i * TWO_PI / petalCount;
    pushMatrix();
    rotate(angle);
    translate(0, -80);

    // 花瓣颜色: 在朱砂红与佛金色之间随时间渐变
    float petalHue = lerp(hue(dunhuangColors[0]),     // 朱砂红
                          hue(dunhuangColors[2]),     // 佛金色
                          map(sin(time + i * 1.2), -1, 1, 0, 1));
    float petalSat = 75 + sin(time * 1.5 + i) * 15;
    float petalBri = 68 + cos(time * 2 + i) * 18;

    // 多层椭圆嵌套, 透明度递减 → 模拟矿物颜料由浓到淡的渐变
    for (int g = 0; g < 5; g++) {
      float gAlpha = map(g, 0, 4, 75, 15);
      fill(petalHue, petalSat, petalBri + g * 4, gAlpha);
      noStroke();
      ellipse(0, 0, 26 - g * 3.5, 58 - g * 6);
    }
    popMatrix();
  }

  // -------- 中层: 装饰圆环 (虚线弧) --------
  noFill();
  for (int ring = 0; ring < 3; ring++) {
    float ringR   = 47 + ring * 18;              // 环半径递增
    float ringHue = (hue(dunhuangColors[1])      // 石青蓝为底
                     + ring * 25 + time * 6) % 360;
    strokeWeight(1.6 - ring * 0.35);
    stroke(ringHue, 55, 82, 65 - ring * 18);

    // 虚线效果: 每隔 dashLen 弧度画一段弧
    float dashLen = 0.14 + ring * 0.04;
    float rotationSpeed = time * 0.4 * (ring + 1); // 不同环速度不同
    for (float a = 0; a < TWO_PI; a += dashLen * 2) {
      arc(0, 0, ringR * 2, ringR * 2,
          a + rotationSpeed, a + rotationSpeed + dashLen);
    }
  }

  // -------- 内层: 莲心 (金色小圆点旋转阵列) --------
  float innerR = 18;
  for (int i = 0; i < 12; i++) {
    float a    = i * TWO_PI / 12 + time * 0.25; // 缓慢自转
    float dotX = cos(a) * innerR;
    float dotY = sin(a) * innerR;
    fill(45, 85, 92, 78);        // 佛金色, 半透明
    noStroke();
    ellipse(dotX, dotY, 6.5, 6.5);
  }

  // -------- 中心光点 --------
  fill(45, 80, 98);
  noStroke();
  ellipse(0, 0, 10 * breathPhase, 10 * breathPhase);
}


// ================================================================
//  第 4 层: 边框装饰 (矩形)
//  外框 + 内框 + 四角回纹, 模拟传统卷轴画的装裱形式
// ================================================================
void drawBorderDecoration() {
  noFill();
  float borderAlpha = 28 + sin(time) * 10;

  // ---- 外边框 (石青色) ----
  stroke(198, 55, 72, borderAlpha);
  strokeWeight(2.2);
  rect(18, 18, width - 36, height - 36);

  // ---- 内边框 (沙土色, 更细更淡) ----
  stroke(32, 28, 72, borderAlpha * 0.65);
  strokeWeight(1);
  rect(28, 28, width - 56, height - 56);

  // ---- 四角回纹装饰 (矩形阵列) ----
  // 回纹是中国传统纹样, 寓意"富贵不断头"
  float cornerAlpha = 22 + sin(time * 1.5) * 8;
  for (int corner = 0; corner < 4; corner++) {
    // 确定角点位置与方向
    float cx   = (corner % 2 == 0) ? 32 : width - 32;
    float cy   = (corner < 2) ? 32 : height - 32;
    int   dirX = (corner % 2 == 0) ? 1 : -1;
    int   dirY = (corner < 2) ? 1 : -1;

    stroke(44, 65, 82, cornerAlpha);
    strokeWeight(1.5);

    // 每个角画 3 个叠进的小矩形 (回纹单元)
    for (int j = 0; j < 3; j++) {
      float off = j * 11;
      rect(cx + dirX * off, cy + dirY * off, 7, 7);
    }
  }
}


// ================================================================
//  第 5 层: 涟漪 (鼠标点击产生)
//  点击位置扩散出双层同心圆, 模拟水面涟漪 / 佛光扩散
// ================================================================
class Ripple {
  float x, y;          // 中心坐标
  float radius;        // 当前半径
  float maxRadius;     // 最大扩散半径
  float alphaVal;      // 当前透明度
  float hueVal;        // 色相 (创建时确定, 随时间微调)

  Ripple(float px, float py) {
    x = px;
    y = py;
    radius    = 0;
    maxRadius = 160;
    alphaVal  = 55;
    hueVal    = (hue(dunhuangColors[2]) + random(-20, 20)) % 360; // 金色系
  }

  void update() {
    radius   += 2.8;      // 向外扩散
    alphaVal -= 0.75;     // 渐隐
  }

  boolean isDead() {
    return alphaVal <= 0 || radius > maxRadius;
  }

  void draw() {
    // 外层大圆
    noFill();
    strokeWeight(2.2 - radius / maxRadius * 1.6);
    stroke(hueVal, 45, 88, alphaVal);
    ellipse(x, y, radius * 2, radius * 2);

    // 内层装饰圆 (稍小, 更淡)
    if (radius > 15) {
      strokeWeight(0.6);
      stroke(hueVal, 28, 92, alphaVal * 0.45);
      ellipse(x, y, radius * 1.45, radius * 1.45);
    }
  }
}

void updateAndDrawRipples() {
  // 倒序遍历, 方便安全删除
  for (int i = ripples.size() - 1; i >= 0; i--) {
    Ripple r = ripples.get(i);
    r.update();
    r.draw();
    if (r.isDead()) {
      ripples.remove(i);
    }
  }
}


// ================================================================
//  第 6 层: 墨滴粒子 (拖拽 / 点击产生)
//  模拟毛笔蘸墨后自然飞溅的墨点, 受重力下落
// ================================================================
class InkDrop {
  float x, y;           // 位置
  float vx, vy;         // 速度
  float size;           // 大小
  float alphaVal;       // 透明度
  float hueVal;         // 色相 (墨色范围)

  InkDrop(float px, float py, float pvx, float pvy) {
    x = px;
    y = py;
    vx = pvx;
    vy = pvy;
    size    = random(3, 14);
    alphaVal = random(25, 65);
    hueVal   = random(22, 38);   // 墨色色相范围 (深褐到蓝黑)
  }

  void update() {
    x += vx;
    y += vy;
    vy    += 0.08;       // 重力加速度
    alphaVal -= 0.45;     // 渐隐
    size   *= 1.003;     // 墨迹在宣纸上微微扩散
  }

  boolean isDead() {
    return alphaVal <= 0 || x < -20 || x > width + 20
           || y < -20 || y > height + 20;
  }

  void draw() {
    noStroke();
    fill(hueVal, 6, 32, alphaVal);
    // 略扁的椭圆模拟墨滴落在纸上的自然形状
    ellipse(x, y, size, size * 0.65);
  }
}

void updateAndDrawInkDrops() {
  for (int i = inkDrops.size() - 1; i >= 0; i--) {
    InkDrop d = inkDrops.get(i);
    d.update();
    d.draw();
    if (d.isDead()) {
      inkDrops.remove(i);
    }
  }
}


// ================================================================
//  第 7 层: 鼠标光标光晕
//  鼠标周围的金色光晕, 象征佛光指引, 也作为视觉引导
// ================================================================
void drawMouseGlow() {
  float glowR = 14 + sin(time * 3) * 5;       // 光晕半径呼吸
  float glowA = 20 + sin(time * 2.5) * 7;     // 透明度波动

  noStroke();
  // 三层半径递增、透明度递减的光环
  for (int i = 3; i > 0; i--) {
    float r = glowR + i * 7;
    float a = glowA / (i + 0.8);
    fill(44, 55, 92, a);     // 金色光晕
    ellipse(mouseX, mouseY, r * 2, r * 2);
  }

  // 中心亮点
  fill(44, 30, 98, glowA * 1.2);
  ellipse(mouseX, mouseY, glowR * 0.7, glowR * 0.7);
}


// ================================================================
//  鼠标事件处理
//  三种交互方式:
//    1. 鼠标位置 — 始终影响曼陀罗旋转与飘带偏移
//    2. 点击 (press) — 产生涟漪 + 墨花
//    3. 拖拽 (drag) — 产生墨滴轨迹 + 增强视觉活跃度
// ================================================================
void mousePressed() {
  // 点击产生涟漪
  ripples.add(new Ripple(mouseX, mouseY));

  // 同时迸发墨滴 (模拟毛笔落纸瞬间的墨花飞溅)
  for (int i = 0; i < 6; i++) {
    float a = random(TWO_PI);
    float s = random(0.6, 3.5);
    inkDrops.add(new InkDrop(mouseX, mouseY,
                             cos(a) * s, sin(a) * s));
  }

  dragStart.set(mouseX, mouseY);
  isDragging = true;
}

void mouseDragged() {
  if (!isDragging) return;

  // 根据鼠标移动速度决定墨滴生成密度
  float spd   = dist(mouseX, mouseY, pmouseX, pmouseY);
  int   count = int(spd / 4) + 1;

  for (int i = 0; i < count; i++) {
    float t  = i / (float) count;
    float px = lerp(pmouseX, mouseX, t);
    float py = lerp(pmouseY, mouseY, t);
    inkDrops.add(new InkDrop(px, py,
                             random(-0.4, 0.4),
                             random(-0.4, 0.4)));
  }

  // 累积拖拽影响力 (上限 1.0, 使飘带更活跃)
  dragInfluence = constrain(dragInfluence + 0.018, 0, 1);
}

void mouseReleased() {
  isDragging = false;

  // 松开时再产生一波涟漪 + 墨滴 (收笔回锋效果)
  ripples.add(new Ripple(mouseX, mouseY));
  for (int i = 0; i < 10; i++) {
    float a = random(TWO_PI);
    float s = random(1, 4.5);
    inkDrops.add(new InkDrop(mouseX, mouseY,
                             cos(a) * s, sin(a) * s));
  }
}
