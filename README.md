# Dealism Dashboard

静态单页 dashboard，用来记录 Dealism 带来的：

- 成交额
- 订单量
- 线索量
- 成交客户数
- 转化率与趋势图

## 打开方式

- 本地直接打开 [index.html](/Users/sager/Documents/New%20project/index.html)
- 或打开 [dashboard.html](/Users/sager/Documents/New%20project/dashboard.html)

## 发布方式

这是一个纯静态页面，不需要后端，适合直接发布到：

- GitHub Pages
- Netlify
- Vercel
- 任何支持静态 HTML 的服务器或对象存储

建议把 `index.html` 作为站点首页发布。

## 当前功能

- 多语言：中文、英文、巴西葡萄牙语、西班牙语
- 主题切换：深色模式、浅色模式
- 货币按语言切换
- 单日录入
- CSV 批量导入
- 趋势图、周期表现、转化漏斗

## 重要说明

- 当前数据保存在每个用户自己的浏览器 `localStorage` 中。
- 这意味着不同用户之间的数据不会自动同步。
- 如果这周末发布的目标是“每个人各自记录和查看自己的数据”，当前版本可以直接用。
- 如果目标是“团队共用同一份实时数据”，下一步需要接后端或在线数据库。
