# Portals

对 [SebLague/Portals](https://github.com/SebLague/Portals/) 项目的升级，使其再 URP 中可以正常显示和使用

核心部分代码在 [PortalCore](Assets/PortalCore) 文件夹中，理论上可以直接迁移使用

请一定去观看[原作者的视频](https://www.youtube.com/watch?v=cWpFZbjtSQg)，这是很棒的教程

> 测试中，使用安装 Blender4.3 的设备无法启动项目，进度会卡在加载 Blander 模型。但 Blender4.4 可以。

# 使用方法

## 传送门

创建一个空组件作为传送门时，他有一些必要配置，以确保传送门可以正常运行：

添加组件：

1. [Portal](Assets/PortalCore/Scripts/Portal.cs) 脚本：获取传送门渲染能力，指定**链接对象**和**传送门显示区域**
2. Box Collider：【传送物体】或者其他碰撞体：勾选 **是触发体**，以正常传送物体。
3. Rigidbody：取消重力

添加子对象：

1. 摄像机对象：直接添加即可，会自动使用。
2. 平面模型：用作屏幕，需要使用 [Portal](Assets/PortalCore/Shader/Portal.shader) 材质（作为示例，可以直接使用  [M_PortalScreen](Assets/PortalCore/Material/M_PortalScreen.mat) ）

# 原始 Readme
Little test of portals in Unity.

Note: in the two worlds scene, you'll need to have Blender installed to view some of the models.

在Unity中对传送门进行的小型测试。

注：在双世界场景中，你需要安装Blender才能查看部分模型。

[Watch video](https://www.youtube.com/watch?v=cWpFZbjtSQg)

![Portals](https://raw.githubusercontent.com/SebLague/Images/master/Portals.png)
