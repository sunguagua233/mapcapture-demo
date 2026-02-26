# MapCapture - 旅游路线规划应用

基于 Flutter 开发的旅游路线规划工具，支持高德地图标记、多图上传、离线使用。

## 技术栈

- **框架**: Flutter (Dart)
- **状态管理**: Riverpod
- **数据库**: Drift (SQLite)
- **地图**: 高德地图 (amap_flutter_map)
- **架构**: Clean Architecture + Feature-First

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── core/                     # 核心基础设施
│   ├── constants/           # 常量定义
│   ├── theme/               # 主题配置
│   ├── router/              # 路由配置
│   └── utils/               # 通用工具
├── data/                     # 数据层
│   ├── database/            # Drift数据库
│   ├── repositories/        # 数据仓库
│   └── services/            # 基础服务
└── features/                # 功能模块
    ├── trip/                # 行程模块
    ├── marker/              # 标记点模块
    ├── map/                 # 地图模块
    ├── media/               # 媒体模块
    └── view/                # 视图模块
```

## 开发阶段

- [x] 阶段0: 项目初始化
- [ ] 阶段1: 数据层搭建
- [ ] 阶段2: 地图核心功能
- [ ] 阶段3: 媒体管理功能
- [ ] 阶段4: 行程管理功能
- [ ] 阶段5: 视图切换与排序

## 运行项目

1. 安装 Flutter SDK
2. 运行 `flutter pub get` 安装依赖
3. 运行 `flutter run` 启动应用

## 代码生成

```bash
# 运行代码生成
flutter pub run build_runner build

# 清理生成的文件
flutter pub run build_runner clean
```
