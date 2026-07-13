# 我的页面设置说明

## 已完成的功能

### 1. UserManager扩展
已为UserManager添加以下新字段：
- `age: Int?` - 年龄
- `city: String?` - 城市
- `bio: String?` - 个人简介
- `tags: [String]` - 标签数组

### 2. 页面布局
已按照设计图完成页面布局，包括：
- 顶部背景图和设置按钮
- 用户头像、昵称、年龄、性别标签
- ID号（支持复制）
- 个人简介
- 标签展示区域
- "我发起的活动"空状态

### 3. 工具类
- 创建了 `AppToast.swift` 用于显示提示信息

## 需要手动添加的图片资源

请在 `Assets.xcassets` 中添加以下图片资源：

1. **placeholder_header** - 顶部背景图
   - 建议尺寸：375 x 280 pt (@2x: 750 x 560 px)
   - 用途：个人主页顶部背景

2. **placeholder_avatar** - 默认头像
   - 建议尺寸：80 x 80 pt (@2x: 160 x 160 px)
   - 用途：用户未设置头像时的占位图

3. **placeholder_empty** - 空状态图片
   - 建议尺寸：80 x 80 pt (@2x: 160 x 160 px)
   - 用途："我发起的活动"为空时的占位图

## 测试数据

为了方便测试，已在UserManager中添加了 `setTestData()` 方法。

在需要测试的地方调用：
```swift
UserManager.shared.setTestData()
```

这会设置以下测试数据：
- 昵称：林妹妹
- 年龄：21
- ID：12345678
- 城市：北京
- 简介：我是一个开朗的人，期待在这里遇到更....
- 标签：["认识新朋友", "找同好伙子", "寻找恋爱/脱单"]

## 待实现的功能

以下功能已预留接口，需要后续实现：

1. **设置按钮** - `settingsTapped()`
   - 打开设置页面

2. **编辑资料按钮** - `editTapped()`
   - 打开编辑资料页面

3. **添加标签按钮** - `addTagTapped()`
   - 打开添加/编辑标签页面

4. **头像加载**
   - 从网络URL加载头像
   - 建议使用 Kingfisher 或 SDWebImage

5. **活动列表**
   - 加载并显示用户发起的活动列表
   - 替换当前的空状态视图

## 使用说明

页面会自动从 `UserManager.shared` 读取用户数据并显示：
- 头像：优先使用 `avatarLocalPath`，其次使用 `avatar`
- 昵称：`nickname`
- 年龄：`age`
- ID：`userId`
- 简介：`bio`
- 标签：`tags`

当数据为空时，会显示默认的占位内容。
