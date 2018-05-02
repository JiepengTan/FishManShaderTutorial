---
layout: post
title:  "中级Shader教程00 总纲"
date:   2018-03-26 16:09:03
author: Jiepeng Tan
categories: 
 - shader tutorial
tags: shader_tutorial
img_path: /assets/img/blog/ShaderTutorial2D/Snow
mathjax: true
---



# FishMan Shader Tutorial

### **0.说在前面**
如果你觉得本教程有用，就去[github][1]中给我颗星星⭐吧.

- [本教程配套blog ][1]  
- [本教程配套项目源码 ][2]  
- [教程中抽取的RayMarching框架][3]  
- [本人shadertoy地址 ][25]  
- [第一时间更新blog地址][26]  
- 如果想学习哪种类型的shader，可以在[这里][1]留言,我优先出留言中的shader的教程  


**shader技术交流qq群:299080901**

### **1.内容**：
>1. 教程中会讲解在编写shader的常用技巧，以及在项目中如何使用这些shader
>2. 大量的实例如水，火，粒子，海洋，山脉，闪电等
>3. 一些shader实现的理论知识
>因为本人也会点特效制作，所以本教程会有比较多的描绘自然现象的shader，如熔岩，雪花，冰，水，火，粒子，海洋，山脉，闪电等.
>4. 已经抽取一个[RayMarching框架][13],更加方便编写raymarching shader

### **2.目录**

#### 1.**理论知识** 
 - [基本数学函数][4]
 - [shader技巧总纲][5]
 - [2D shader框架][6]
 - [3D raymarching框架][11]
 - [基本建模SDF][12]
 - [多层透明叠加渲染][21]
 - [优化:用shader分摊CPU压力][24]

----------


#### 2.**实例**
 1. **2D Shader基础**
    - [2D海洋][7]
    - [雪花][8]
    - [火焰粒子][9]
    - [熔岩][10]
    - [下雨][28]
 2. **3D Shader**
    - [Unity 和 Raymarch 整合][11]
    - [星空][16]
    - [天空][17]
    - [地形][18]
    - [湖泊][19]
    - [大海][20]
    - [雾][22]
    - [云][23]
 3. **shader技术整合**
    - [GameUI 血瓶][21]
    - 荒原湖泊
    - 西湖
    
#### 4.**专题**  
1. **水**  
    - [下雨][28]
    - [涟漪][29]
    - [水底焦散][30]
    - [窗前雨滴][31]



----------

### **6.部分效果图：**
<p align="center"><img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial2D/BaseMath/head.gif?raw=true" width="256"></p> 
<p align="center"><img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial2D/Sea/head.gif?raw=true" width="256"></p>
<p align="center"><img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial2D/Snow/head.gif?raw=true" width="256"></p> 
<p align="center"><img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial2D/FireParticle/head.gif?raw=true" width="256"></p> 
<p align="center">
<img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial3D/SDF/head.gif?raw=true" width="256"></p> 

<p align="center"><img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial3D/Stars/head.gif?raw=true" width="256"></p> 
<p align="center"><img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial3D/Sky/head.gif?raw=true" width="256"></p>
<p align="center">
<img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial3D/Mountain/head.gif?raw=true" width="256"></p> 


<p align="center"><img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial3D/Lake/head.gif?raw=true" width="256"></p>
<p align="center">
<img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial3D/Sea/head.gif?raw=true" width="256"></p> 

<p align="center"><img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial3D/Fog/head.gif?raw=true" width="256"></p> 
<p align="center">
<img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial3D/Cloud/head.gif?raw=true" width="256"></p>   

<p align="center"><img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/JobSys/head.gif?raw=true" width="256"></p> 

<p align="center"><img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial3D/GameHPUI/head.gif?raw=true" width="256"></p>

<p align="center"><img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial2D/Rain/head.gif?raw=true" width="256"></p> 

<p align="center"><img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial3D/Rain/head.gif?raw=true" width="256"></p> 
<p align="center"><img src="https://github.com/JiepengTan/JiepengTan.github.io/blob/master/assets/img/blog/ShaderTutorial3D/Caustic/head.gif?raw=true" width="768"></p>
----------

### **3.链接：**
- [本教程配套blog ][1]
- [本教程配套项目源码 ][2]
- [教程中抽取的RayMarching框架][3]
- 如果想学习哪种类型的shader，可以在[这里][1]留言,我优先出留言中的shader的教程



  [1]: https://blog.csdn.net/tjw02241035621611/article/details/80038608
  [2]: https://github.com/JiepengTan/FishManShaderTutorial
  [3]: https://github.com/JiepengTan/Unity-Raymarching-Framework
  [4]: https://blog.csdn.net/tjw02241035621611/article/details/80041397
  [5]: https://blog.csdn.net/tjw02241035621611/article/details/80043469
  [6]: https://blog.csdn.net/tjw02241035621611/article/details/80042647
  [7]: https://blog.csdn.net/tjw02241035621611/article/details/80042736
  [8]: https://blog.csdn.net/tjw02241035621611/article/details/80047566
  [9]: https://blog.csdn.net/tjw02241035621611/article/details/80045381
  [10]: https://blog.csdn.net/tjw02241035621611/article/details/80048713
  [11]: https://blog.csdn.net/tjw02241035621611/article/details/80057928
  [12]: https://blog.csdn.net/tjw02241035621611/article/details/80061750
  [13]: https://blog.csdn.net/tjw02241035621611/article/details/80061750
  [14]: https://blog.csdn.net/tjw02241035621611/article/details/80089786
  [15]: https://blog.csdn.net/tjw02241035621611/article/details/80089804
  [16]: https://blog.csdn.net/tjw02241035621611/article/details/80089822
  [17]: https://blog.csdn.net/tjw02241035621611/article/details/80089850
  [18]: https://blog.csdn.net/tjw02241035621611/article/details/80106320
  [19]: https://blog.csdn.net/tjw02241035621611/article/details/80108319
  [20]: https://blog.csdn.net/tjw02241035621611/article/details/80106327
  [21]: https://blog.csdn.net/tjw02241035621611/article/details/80089882
  [22]: https://blog.csdn.net/tjw02241035621611/article/details/80108619
  [23]: https://blog.csdn.net/tjw02241035621611/article/details/80112668
  [24]: https://blog.csdn.net/tjw02241035621611/article/details/80090204
  [25]: https://www.shadertoy.com/user/FishMan
  [26]: https://jiepengtan.github.io/
  [27]: https://blog.csdn.net/tjw02241035621611/article/details/80137615
  [28]: https://blog.csdn.net/tjw02241035621611/article/details/80135576
  [29]: https://blog.csdn.net/tjw02241035621611/article/details/80135597
  [30]: https://blog.csdn.net/tjw02241035621611/article/details/80135626
  [31]: https://blog.csdn.net/tjw02241035621611/article/details/80135648
  [32]: https://blog.csdn.net/tjw02241035621611/article/details/80137622
