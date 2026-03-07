# MapCapture Web - 旅行路线规划工具

MapCapture的Web版本，支持在浏览器中直接使用，无需安装任何应用。

## 🌐 在线访问

直接在浏览器中打开 `index.html` 即可使用。

## ✨ 主要功能

### 核心功能
- **行程管理**：创建、编辑、删除旅行行程
- **地图集成**：基于高德地图的真实地图显示
- **标记管理**：添加、编辑、删除地点标记
- **路线规划**：可视化路线，支持拖拽排序
- **分组功能**：将相关行程分组管理

### 地图功能
- ✅ 真实地图渲染（高德地图）
- ✅ 地图缩放、拖动
- ✅ 标记点显示（支持序号/圆点两种样式）
- ✅ 路线虚线显示
- ✅ 点击标记查看详情
- ✅ 长按地图添加标记（移动端）

## 📱 支持平台

### Web浏览器
- ✅ Chrome (推荐)
- ✅ Safari
- ✅ Firefox
- ✅ Edge

### 移动设备
- ✅ iPhone Safari
- ✅ Android Chrome
- ✅ iPad Safari

## 🚀 快速开始

### 方法1：直接打开
1. 下载 `index.html` 文件
2. 用浏览器打开即可使用

### 方法2：本地服务器（推荐用于开发）
```bash
# 使用Python启动本地服务器
python -m http.server 8000

# 或使用Node.js
npx serve

# 然后访问
http://localhost:8000
```

### 方法3：部署到Web服务器
将整个 `web/` 文件夹部署到任何Web服务器：
- GitHub Pages
- Vercel
- Netlify
- 阿里云OSS
- 腾讯云COS

## 🎨 界面预览

### 主屏幕
- 行程列表（支持分组显示）
- 搜索功能
- 统计信息面板

### 地图页面
- 高德地图集成
- 缩放控制
- 路线切换
- 添加标记按钮

### 路线规划
- 列表/网格视图切换
- 拖拽排序
- 标记详情编辑

## 🔧 配置说明

### 高德地图API密钥

当前版本已配置以下API密钥：
- **API Key**: `d996d5d90eb3c13a57bcdb5b6501a21e`
- **安全密钥**: `67ea1a96de882de569f92f23a01a1e2c`

**如需更换密钥**，修改 `index.html` 中的以下部分：

```html
<script src="https://webapi.amap.com/maps?v=2.0&key=YOUR_KEY"></script>
<script>
    window._AMapSecurityConfig = {
        securityJsCode: 'YOUR_SECURITY_CODE',
    };
</script>
```

## 📊 数据存储说明

**当前版本**：数据存储在内存中，刷新页面会丢失数据。

**数据持久化方案**（可自行实现）：
1. 使用 `localStorage` 存储简单数据
2. 后端API存储（需要服务器）
3. IndexedDB 存储大量数据

### localStorage 实现示例

```javascript
// 保存数据
localStorage.setItem('mapcapture_trips', JSON.stringify(trips));
localStorage.setItem('mapcapture_markers', JSON.stringify(markers));

// 加载数据
const savedTrips = localStorage.getItem('mapcapture_trips');
if (savedTrips) {
    trips = JSON.parse(savedTrips);
}
```

## 🌍 地图功能说明

### 支持的操作
| 操作 | 说明 |
|------|------|
| 拖动地图 | 鼠标拖动 / 触摸滑动 |
| 缩放 | 鼠标滚轮 / 双指捏合 |
| 点击标记 | 查看标记详情 |
| 长按地图 | 添加标记（移动端） |
| 点击空白 | 关闭弹窗 |

### 标记点样式
- **纳入路线**：彩色圆点 + 白色序号
- **不纳入路线**：彩色圆点 + place图标 + 白色边框

## 🔗 相关链接

- **高德开放平台**: https://lbs.amap.com/
- **高德地图JS API文档**: https://lbs.amap.com/api/javascript-api/summary
- **GitHub仓库**: https://github.com/sunguagua233/mapcapture-demo

## 📝 更新日志

### v3.1 (2024-03-07)
- ✅ 集成高德地图JavaScript API
- ✅ 实现Web端完整功能
- ✅ 支持路线规划和标记管理
- ✅ 响应式设计，支持移动端

## 📄 许可证

MIT License

## 💡 使用建议

1. **测试环境**：直接在浏览器打开 `index.html`
2. **生产环境**：部署到CDN或静态网站托管
3. **数据持久**：根据需要添加 localStorage 或后端存储
4. **移动端体验**：建议添加到主屏幕使用

## ⚠️ 注意事项

1. 需要联网才能加载高德地图
2. API密钥有每日调用限制
3. 当前版本数据不持久化
4. 建议使用 Chrome 或 Safari 获得最佳体验
