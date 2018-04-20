# Intermediate-Shader-Tutoriali

# Shader 中级教程

### **0.说在前面**

如果你觉得本教程有用，就去[github][1]中给我颗星星⭐吧，这是对我最大的鼓励，谢谢。

### **1.出发点**：
>简单的shader的教程网上很多，(如溶解，扭曲，描边等)，但是进阶的shader教程比较少，而且也不全面，都是零星碎点的。
导致在学完简单shader教程后写shader的时候总感觉少了点掌控感，好像懂，又好像不懂。
这教程是将我之前踩过的坑，以及收集到的一些资源进行整合，方便大家系统的学习，直观的感受shader的外在表现。同时，我也尽可能的将我对一些现象的理解写入当中，一些数学函数的尽量以图的方式展示。方便大家理解shader。 

### **2.目标受众**：

有一点shader基础的同学或者是搞特效而且想知道实现原理的的同学

### **3.目标是**:
>1. 提升对一些数学函数的直观理解
>2. 提升对一些自然现象的直观理解
>3. 掌握shader实现中常用的的一些套路

学完之后应该在看shadertoy中的复杂shader过程中会比较轻松,自己写起shader来也会比较的顺手

### **4.内容**：
>1. 教程中会讲解在编写shader的常用技巧，以及在项目中如何使用这些shader
>2. 大量的实例如水，火，粒子，海洋，山脉，闪电等
>3. 一些shader实现的理论知识
>因为本人也会点特效制作，所以本教程会有比较多的描绘自然现象的shader，如熔岩，雪花，冰，水，火，粒子，海洋，山脉，闪电，泡泡等。

### **5.目录**

####1.**理论知识** 
 - 基本数学函数 
 - 基本图形2D 
 - 基本图形3D(raymarch) 
 - 基本建模SDF
 - shader技巧 空间划分 
 - shader技巧 Noise 和 FBM 
 - shader技巧 颜色空间
 - shader技巧 优化：用shader分摊CPU压力 
 - shader技巧 特效中shader的运用

----------


####2.**实例**
 1. **2D Shader基础**
    - 雪花
    - 火焰粒子
    - 下雨
    - 火焰
    - 2D海洋
 2. **3D Shader**
    - Unity 和 Raymarch 整合
    - 天空
    - 地形
    - 大海
 3. **shader技术整合**
    - GameUI 血瓶
    - 荒漠湖泊
    - 池塘

----------

### **6.部分效果图：**


<img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial2D/Snow/head.gif?raw=true" width="256"> <img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial3D/GameHPUI/head.gif?raw=true" width="256">

<img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial2D/Sea/head.gif?raw=true" width="256"> <img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial2D/FireParticle/head.gif?raw=true" width="256"> 

<img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial2D/Rain/head.gif?raw=true" width="256"> <img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial3D/Sky/head.gif?raw=true" width="256">

<img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial3D/Stars/head.gif?raw=true" width="256"> <img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial3D/Lake/head.gif?raw=true" width="256">

<img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial3D/Fog/head.gif?raw=true" width="256"> <img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/JobSys/head.gif?raw=true" width="256"> 

<img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial3D/Caustic/head.gif?raw=true" width="768">
 
----------

### **7.链接：**
- [本教程配套项目源码 ][1]
- [本人shadertoy地址 ][2]
- [第一时间更新blog地址][3]

  [1]: https://github.com/JiepengTan/FishManShaderTutorial
  [2]: https://www.shadertoy.com/user/FishMan
  [3]: https://jiepengtan.github.io/