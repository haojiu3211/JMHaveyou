# 茶色 App 接口文档

## 一、基础配置

### 1.1 服务器地址

| 环境 | API 地址 | Assets 地址 | 协议地址 |
|------|----------|-------------|----------|
| 正式环境 | `https://apipro.szyuany.com/api` | `https://asset.szyuany.com/` | `https://h5web.szyuany.com/` |
| 测试环境 | `https://apipro.szyuany.com/api` | `https://asset.szyuany.com/` | `https://h5web.szyuany.com/` |

> 注意：正式环境与测试环境使用相同的API地址

### 1.2 密钥配置

| 密钥名称 | 值 | 用途 |
|----------|-----|------|
| **AES密钥** | `LTeMFNXEfwzKPzrr` | 加密解密 |
| **微信AppID** | `wx32e945c3c2b305f6` | 微信登录/分享 |
| **微信AppSecret** | `b955690290b909e417ad90e65d2915d1` | 微信API调用 |
| **一键登录Key** | `8279c54bcca0465c90c8e577e4a47d67` | 运营商一键登录 |
| **网易易盾Key** | `YD00196119061484` | 验证码/安全验证 |
| **网易易盾支付业务ID** | `c33381dbb95496a24c6292db294586fe` | 支付安全验证 |
| **网易易盾登录业务ID** | `a74904493b63e346b7be3aee34344432` | 登录安全验证 |
| **高德地图iOS Key** | `5e4aef6e4e8738050977ce15ff61d601` | 地图SDK |
| **高德地图Web iOS Key** | `37b8613cad7660e6144e5160609623cd` | Web地图 |

### 1.3 请求头配置

所有接口请求必须携带以下请求头：

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `source-id` | String | 否 | 来源ID |
| `oaid` | String | 否 | Android设备标识符 |
| `uuid` | String | 是 | 设备唯一标识 |
| `channel` | String | 否 | 渠道ID |
| `token` | String | 是(登录后) | 用户令牌 |
| `idfa` | String | 否 | iOS广告标识符 |
| `phone-brand` | String | 否 | 手机品牌 |
| `package-name` | String | 是 | 包名：`com.yuanyu.chase` |
| `version` | String | 是 | 版本号：`1.0.8` |
| `ver-code` | String | 是 | 版本代码：`108` |
| `theme` | String | 是 | 主题：`fdqn-white` |

### 1.4 响应格式

接口响应采用统一格式：

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | int | 0=成功，非0=失败 |
| `message` | String | 提示信息 |
| `data` | Object | 响应数据 |

### 1.5 错误码说明

| 错误码 | 说明 | 处理方式 |
|--------|------|----------|
| 1001 | Token失效 | 跳转登录页 |
| 1003 | 余额不足 | 提示充值 |
| 1007 | 需要真人认证 | 提示去认证 |
| 1008 | 需要实名认证 | 提示去认证 |
| 1009 | VIP权益次数用完 | 提示充值钻石 |
| 1010 | 需要人脸核验 | 提示人脸认证 |
| 1014 | 仅VIP会员开放 | 提示开通VIP |
| 1015 | 真人审核中 | 提示催审 |

---

## 二、登录认证接口

### 2.1 手机号登录

**请求**
- **URL**: `/login/verifyLogin`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `agreement` | String | 是 | 协议同意标识 |
| `mobile` | String | 是 | 手机号 |
| `phone_code` | String | 是 | 验证码 |
| `yidunToken` | String | 是 | 网易易盾token |

**响应**

| 字段 | 类型 | 说明 |
|------|------|------|
| `userinfo` | UserInfo | 用户信息 |

**UserInfo结构**

| 字段 | 类型 | 说明 |
|------|------|------|
| `usercode` | String | 用户编码 |
| `nickname` | String | 昵称 |
| `mobile` | String | 手机号 |
| `avatar` | String | 头像URL |
| `gender` | int | 性别：1=女，2=男 |
| `age` | int | 年龄 |
| `birthday` | String | 生日 |
| `finishStatus` | int | 资料完成状态：0=未完成，1=完成 |
| `regist_step` | int | 注册步骤 |
| `im_token` | String | IM令牌 |
| `token` | String | 用户令牌 |
| `user_id` | int | 用户ID |
| `vip` | int | VIP状态：0=非VIP，1=VIP |
| `expire_time` | String | VIP过期时间 |
| `is_auth` | int | 实名认证状态 |
| `is_rp_auth` | int | 真人认证状态 |

---

### 2.2 一键登录

**请求**
- **URL**: `/login/quickLogin`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `token` | String | 是 | 运营商token |
| `operator` | String | 是 | 运营商类型 |

**响应**: 同手机号登录

---

### 2.3 发送验证码

**请求**
- **URL**: `/login/sendVerify`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `type` | String | 是 | 类型 |
| `mobile` | String | 是 | 手机号 |

---

### 2.4 获取昵称库

**请求**
- **URL**: `/login/getNick`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `gender` | int | 是 | 性别：1=女，2=男 |

**响应**

| 字段 | 类型 | 说明 |
|------|------|------|
| `nicknames` | List<String> | 昵称列表 |

---

### 2.5 注册补充资料

**请求**
- **URL**: `/login/appendUserData`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `usercode` | String | 是 | 用户编码 |
| `nickname` | String | 是 | 昵称 |
| `gender` | int | 是 | 性别 |
| `birthday` | String | 是 | 生日 |
| `city` | String | 否 | 城市 |
| `height` | int | 否 | 身高 |
| `weight` | int | 否 | 体重 |

---

### 2.6 第三方登录

**请求**
- **URL**: `/login/third`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `type` | String | 是 | 类型：wechat/apple |
| `code` | String | 是 | 第三方授权码 |

---

### 2.7 绑定手机

**请求**
- **URL**: `/login/bindMobile`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `mobile` | String | 是 | 手机号 |
| `phone_code` | String | 是 | 验证码 |

---

## 三、首页接口

### 3.1 首页推荐数据

**请求**
- **URL**: `/homePage.home/index`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `type` | int | 否 | 类型：0=全部，1=推荐，2=同城，3=新人 |
| `area` | int | 否 | 地区 |
| `is_online` | int | 否 | 是否在线 |
| `video_status` | int | 否 | 视频状态 |
| `ageBegin` | int | 否 | 最小年龄 |
| `ageEnd` | int | 否 | 最大年龄 |
| `is_auth` | int | 否 | 是否真人：0=否，1=是 |
| `is_goddess` | int | 否 | 是否女神：0=否，1=是 |
| `page` | int | 否 | 页码 |
| `limit` | int | 否 | 每页数量 |

---

### 3.2 心动推荐

**请求**
- **URL**: `/homePage.heartBeat/index`
- **Method**: POST

---

### 3.3 人气会员排行榜

**请求**
- **URL**: `/homePage.heartBeat/popularity`
- **Method**: POST

---

### 3.4 搜索用户

**请求**
- **URL**: `/homePage.home/search`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `keyword` | String | 是 | 搜索关键词 |
| `page` | int | 否 | 页码 |
| `limit` | int | 否 | 每页数量 |

---

### 3.5 获取首页状态

**请求**
- **URL**: `/homePage.home/getHomeStyle`
- **Method**: POST

---

### 3.6 获取今日缘分列表

**请求**
- **URL**: `/homePage.heartBeat/todayLove`
- **Method**: POST

---

## 四、用户相关接口

### 4.1 获取用户数据

**请求**
- **URL**: `/getInformation`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `user_id` | int | 否 | 用户ID，不传则获取当前用户 |

---

### 4.2 保存资料

**请求**
- **URL**: `/editInformationSave`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `nickname` | String | 否 | 昵称 |
| `birthday` | String | 否 | 生日 |
| `city` | String | 否 | 城市 |
| `height` | int | 否 | 身高 |
| `weight` | int | 否 | 体重 |
| `occupation` | String | 否 | 职业 |
| `bio` | String | 否 | 个人介绍 |
| `favoritePeople` | List<String> | 否 | 喜欢的类型 |
| `expectedRelationship` | String | 否 | 期待关系 |
| `myTags` | List<String> | 否 | 我的标签 |
| `playCity` | List<String> | 否 | 约玩城市 |
| `willGoSoon` | String | 否 | 近期想去城市 |

---

### 4.3 个人主页

**请求**
- **URL**: `/personalHomepage`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `user_id` | int | 是 | 用户ID |

---

### 4.4 AI个人主页

**请求**
- **URL**: `/homePage.Home/AIUserInfo`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `user_id` | int | 是 | 用户ID |

---

### 4.5 个人中心页

**请求**
- **URL**: `/personalCenter`
- **Method**: POST

---

### 4.6 获取职业数据

**请求**
- **URL**: `/getUserExtData`
- **Method**: POST

---

### 4.7 获取个人介绍

**请求**
- **URL**: `/getUserIntroduction`
- **Method**: POST

---

## 五、社交关系接口

### 5.1 关注/取消关注

**请求**
- **URL**: `/focusOn`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `user_id` | int | 是 | 目标用户ID |

---

### 5.2 拉黑用户

**请求**
- **URL**: `/addBlack`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `user_id` | int | 是 | 目标用户ID |

---

### 5.3 获取拉黑列表

**请求**
- **URL**: `/blackList`
- **Method**: POST

---

### 5.4 获取关注列表

**请求**
- **URL**: `/watchList`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `page` | int | 否 | 页码 |
| `limit` | int | 否 | 每页数量 |

---

### 5.5 获取粉丝列表

**请求**
- **URL**: `/fansList`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `page` | int | 否 | 页码 |
| `limit` | int | 否 | 每页数量 |

---

### 5.6 设置备注

**请求**
- **URL**: `/setRemark`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `user_id` | int | 是 | 目标用户ID |
| `remark` | String | 是 | 备注名 |

---

## 六、动态相关接口

### 6.1 动态列表

**请求**
- **URL**: `/circle.getLists`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `page` | int | 否 | 页码 |
| `limit` | int | 否 | 每页数量 |

---

### 6.2 个人动态列表

**请求**
- **URL**: `/personalDynamicList`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `user_id` | int | 否 | 用户ID，不传则获取当前用户 |
| `page` | int | 否 | 页码 |
| `limit` | int | 否 | 每页数量 |

---

### 6.3 动态详情

**请求**
- **URL**: `/circle.item`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | int | 是 | 动态ID |

---

### 6.4 发布动态（视频）

**请求**
- **URL**: `/circle.release`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `content` | String | 是 | 内容 |
| `video_url` | String | 是 | 视频URL |
| `images` | List<String> | 否 | 图片列表 |
| `location` | String | 否 | 位置 |

---

### 6.5 发布动态（图片）

**请求**
- **URL**: `/dynamic/publish_image`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `content` | String | 是 | 内容 |
| `images` | List<String> | 是 | 图片URL列表 |
| `location` | String | 否 | 位置 |

---

### 6.6 删除动态

**请求**
- **URL**: `/dynamic/delete`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | int | 是 | 动态ID |

---

### 6.7 点赞

**请求**
- **URL**: `/circle.like`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | int | 是 | 动态ID |

---

### 6.8 评论

**请求**
- **URL**: `/circle.comment`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | int | 是 | 动态ID |
| `content` | String | 是 | 评论内容 |
| `reply_id` | int | 否 | 回复评论ID |

---

### 6.9 评论列表

**请求**
- **URL**: `/circle.comment.lists`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | int | 是 | 动态ID |
| `page` | int | 否 | 页码 |
| `limit` | int | 否 | 每页数量 |

---

### 6.10 删除评论

**请求**
- **URL**: `/circle.comment.remove`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | int | 是 | 评论ID |

---

## 七、钱包相关接口

### 7.1 获取钱包

**请求**
- **URL**: `/wallet/index`
- **Method**: POST

**响应**

| 字段 | 类型 | 说明 |
|------|------|------|
| `diamond` | int | 钻石数量 |
| `balance` | int | 余额 |

---

### 7.2 钻石充值

**请求**
- **URL**: `/wallet/recharge`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `channel` | String | 是 | 支付渠道：alipay/wechat/apple |
| `goods_id` | String | 是 | 商品ID |
| `pooling` | int | 是 | 是否拼团 |
| `rechargeScene` | int | 是 | 充值场景 |

---

### 7.3 获取钻石商品列表

**请求**
- **URL**: `/diamondList`
- **Method**: POST

---

### 7.4 消费记录

**请求**
- **URL**: `/consumptionRecords`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `type` | int | 否 | 类型 |
| `page` | int | 否 | 页码 |
| `limit` | int | 否 | 每页数量 |

---

### 7.5 Apple Pay订单

**请求**
- **URL**: `/applePayOrder`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `goods_id` | String | 是 | 商品ID |

---

### 7.6 Apple Pay校验

**请求**
- **URL**: `/applePayVerification`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `order_id` | String | 是 | 订单ID |
| `transaction_id` | String | 是 | Apple交易ID |
| `receipt` | String | 是 | 收据数据 |

---

## 八、VIP相关接口

### 8.1 获取VIP配置

**请求**
- **URL**: `/memberCenter`
- **Method**: POST

---

### 8.2 获取VIP购买记录

**请求**
- **URL**: `/vipRecord`
- **Method**: POST

---

### 8.3 VIP充值

**请求**
- **URL**: `/vipOrder/payNobleOrder`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `channel` | String | 是 | 支付渠道 |
| `goods_id` | String | 是 | 商品ID |

---

## 九、礼物相关接口

### 9.1 获取礼物分类

**请求**
- **URL**: `/gift/getGiftCate`
- **Method**: POST

---

### 9.2 获取礼物列表

**请求**
- **URL**: `/giftList`
- **Method**: POST

---

### 9.3 发送礼物

**请求**
- **URL**: `/sendGift`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `user_id` | int | 是 | 接收用户ID |
| `gift_id` | int | 是 | 礼物ID |
| `num` | int | 是 | 数量 |

---

## 十、相册相关接口

### 10.1 获取相册列表

**请求**
- **URL**: `/myAlbumList`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `user_id` | int | 否 | 用户ID |

---

### 10.2 查看相册

**请求**
- **URL**: `/readAlbum`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | int | 是 | 相册ID |

---

### 10.3 添加相册

**请求**
- **URL**: `/addAlbum`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `images` | List<String> | 是 | 图片URL列表 |
| `type` | int | 是 | 类型：0=普通，1=红包，2=阅后即焚 |
| `price` | int | 否 | 价格（红包照片） |

---

### 10.4 删除相册

**请求**
- **URL**: `/deleteAlbum`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | int | 是 | 相册ID |

---

### 10.5 解锁红包照片

**请求**
- **URL**: `/unlockImg`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | int | 是 | 相册ID |

---

## 十一、搭讪相关接口

### 11.1 一键搭讪

**请求**
- **URL**: `/oneClickChat`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `num` | int | 否 | 搭讪人数 |

---

### 11.2 单独搭讪

**请求**
- **URL**: `/chatAlone`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `user_id` | int | 是 | 目标用户ID |

---

### 11.3 钻石解锁私聊

**请求**
- **URL**: `/diamondUnlock`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `user_id` | int | 是 | 目标用户ID |

---

### 11.4 查询私聊解锁状态

**请求**
- **URL**: `/unlockPrivateStatus`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `user_id` | int | 是 | 目标用户ID |

---

## 十二、气球相关接口

### 12.1 获取气球次数

**请求**
- **URL**: `/balloonNum`
- **Method**: POST

---

### 12.2 抓气球

**请求**
- **URL**: `/balloonGrab`
- **Method**: POST

---

### 12.3 回复气球

**请求**
- **URL**: `/balloonReply`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | int | 是 | 气球消息ID |
| `content` | String | 是 | 回复内容 |

---

### 12.4 放气球

**请求**
- **URL**: `/balloonFly`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `content` | String | 是 | 内容 |

---

### 12.5 气球消息列表

**请求**
- **URL**: `/balloonNotice`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `page` | int | 否 | 页码 |
| `limit` | int | 否 | 每页数量 |

---

### 12.6 气球未读消息

**请求**
- **URL**: `/balloonIsRead`
- **Method**: POST

---

## 十三、心情相关接口

### 13.1 获取心情记录列表

**请求**
- **URL**: `/userMoodList`
- **Method**: POST

---

### 13.2 保存心情记录

**请求**
- **URL**: `/userMoodAdd`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `mood` | int | 是 | 心情值 |
| `content` | String | 否 | 心情描述 |

---

### 13.3 获取心情记录详情

**请求**
- **URL**: `/userMoodShow`
- **Method**: POST

---

## 十四、AI相关接口

### 14.1 AI聊天

**请求**
- **URL**: `/tongYiChat`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `content` | String | 是 | 聊天内容 |
| `type` | int | 否 | 类型 |

---

## 十五、举报相关接口

### 15.1 举报

**请求**
- **URL**: `/report`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `type` | int | 是 | 类型：1=用户，2=动态 |
| `cate_id` | int | 是 | 分类ID |
| `report_uid` | int | 是 | 被举报人ID |
| `content` | String | 是 | 举报内容 |
| `images` | String | 否 | 图片（逗号分隔） |

---

### 15.2 获取举报分类

**请求**
- **URL**: `/reportReason`
- **Method**: POST

---

### 15.3 获取举报列表

**请求**
- **URL**: `/reportRecords`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `page` | int | 否 | 页码 |
| `limit` | int | 否 | 每页数量 |

---

### 15.4 获取举报详情

**请求**
- **URL**: `/reportRecordDetails`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | int | 是 | 举报ID |

---

### 15.5 撤回举报

**请求**
- **URL**: `/withdrawReport`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | int | 是 | 举报ID |

---

## 十六、系统配置接口

### 16.1 获取系统配置

**请求**
- **URL**: `/system/init`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `device_id` | String | 是 | 设备ID |
| `channel` | String | 否 | 渠道 |

---

### 16.2 获取首页Banner

**请求**
- **URL**: `/homeBanner`
- **Method**: POST

---

### 16.3 获取城市列表

**请求**
- **URL**: `/provinceCityLocation`
- **Method**: POST

---

### 16.4 获取活动配置

**请求**
- **URL**: `/system/activeConfig`
- **Method**: POST

---

### 16.5 获取IM Banner

**请求**
- **URL**: `/imBanner`
- **Method**: POST

---

### 16.6 获取隐私设置

**请求**
- **URL**: `/privacyGet`
- **Method**: POST

---

### 16.7 设置隐私

**请求**
- **URL**: `/privacySettings`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | int | 是 | 设置项ID |
| `value` | int | 是 | 值：0=关闭，1=开启 |

---

### 16.8 获取认证状态

**请求**
- **URL**: `/certificationCenter`
- **Method**: POST

---

### 16.9 获取OSS上传信息

**请求**
- **URL**: `/sts/index`
- **Method**: POST

---

### 16.10 激活设备（iOS）

**请求**
- **URL**: `/system/activateIos`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `idfa` | String | 是 | IDFA |

---

## 十七、访客相关接口

### 17.1 谁看过我

**请求**
- **URL**: `/visitorsList`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `page` | int | 否 | 页码 |
| `limit` | int | 否 | 每页数量 |

---

### 17.2 我看过谁

**请求**
- **URL**: `/footprint`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `page` | int | 否 | 页码 |
| `limit` | int | 否 | 每页数量 |

---

### 17.3 谁解锁我

**请求**
- **URL**: `/whoUnlockedMe`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `page` | int | 否 | 页码 |
| `limit` | int | 否 | 每页数量 |

---

## 十八、其他接口

### 18.1 更新定位

**请求**
- **URL**: `/updateLngLat`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `lng` | double | 是 | 经度 |
| `lat` | double | 是 | 纬度 |

---

### 18.2 查询在线状态和距离

**请求**
- **URL**: `/onlineAndDistance`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `user_id` | int | 是 | 用户ID |

---

### 18.3 获取支付类型

**请求**
- **URL**: `/pay/pay_type`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `scene` | int | 是 | 场景 |

---

### 18.4 真人认证支付获取商品

**请求**
- **URL**: `/getRealGoods`
- **Method**: POST

---

### 18.5 真人认证Apple Pay

**请求**
- **URL**: `/realApplePay`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `goods_id` | String | 是 | 商品ID |

---

### 18.6 真人认证Apple Pay校验

**请求**
- **URL**: `/realApplePayVerification`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `order_id` | String | 是 | 订单ID |
| `transaction_id` | String | 是 | Apple交易ID |
| `receipt` | String | 是 | 收据数据 |

---

### 18.7 注销账号

**请求**
- **URL**: `/deregisterAccount`
- **Method**: POST

---

### 18.8 编辑资料任务完成

**请求**
- **URL**: `/editProfileTask`
- **Method**: POST

---

### 18.9 前后台切换

**请求**
- **URL**: `/updateAppBackAndFront`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `type` | int | 是 | 0=后台，1=前台 |

---

### 18.10 发送IM消息校验

**请求**
- **URL**: `/sendMessage`
- **Method**: POST

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `to_id` | int | 是 | 接收用户ID |
| `content` | String | 是 | 消息内容 |
| `type` | int | 是 | 消息类型 |

---

## 附录：常量配置

### 性别常量

| 值 | 含义 |
|----|------|
| 1 | 女 |
| 2 | 男 |

### VIP常量

| 值 | 含义 |
|----|------|
| 0 | 非VIP |
| 1 | VIP |

### 支付类型

| 值 | 含义 |
|----|------|
| `alipay` | 支付宝 |
| `wechat` | 微信 |
| `apple` | Apple Pay |
