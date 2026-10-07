# Galaxy Maze

Galaxy Maze 是一个面向具有基础天文知识初学者的星系形态识别游戏。玩家根据决策树逐步回答问题，完成星系识别并收集拼图碎片。

## 在线体验

当前在线地址：<http://8.148.20.120:8777/>

直接打开上面的地址即可体验游戏。普通用户和管理员均从该地址进入；管理员可进入标定页面，为数据库中的星系填写标准答案。

## 游戏功能

- 按星系形态决策树生成迷宫问题。
- 每关从数据库读取星系名称、图像和属性答案。
- 所有问题回答正确后才能通过当前星系。
- 答错的星系之后仍可能再次出现，已完成的星系不会重复出现。
- 按答对的问题累计积分，积分可兑换随机拼图碎片。
- 拼图碎片随机落位，集齐后可以查看和下载完整拼图。
- 支持键盘操作：方向键移动或切换，左右键选择，空格键确认；`P` 打开拼图，`H` 打开操作指南，`R` 重新开始当前关卡。
- 管理员可以使用决策树快速标定并保存星系答案。

## 项目结构

```text
src/                  Vue 前端代码
src/assets/images/    星系图、示例图、决策树和拼图素材
server/index.mjs      Express API 与 MySQL 接口
package.json          项目脚本和依赖
.env.example          环境变量示例，不包含真实密码
```

## 本地运行

需要安装 Node.js 20.19 或更高版本。若要在本地使用数据库功能，还需要准备 MySQL，并创建 `.env.server.local`：

```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=your_database_user
DB_PASSWORD=your_database_password
DB_NAME=galaxy_levels
API_PORT=3001
APP_USER_NAME=user
APP_USER_PASSWORD=replace_with_user_password
APP_ADMIN_NAME=admin
APP_ADMIN_PASSWORD=replace_with_admin_password
```

安装依赖并启动开发环境：

```powershell
npm install
npm run dev
```

开发页面地址通常为 `http://localhost:5173/`。

生产构建：

```powershell
npm run build
npm start
```

## 数据库说明

在线版本使用服务器上的 API 和 MySQL 数据库。项目仓库只保存源代码和图片素材，不包含线上数据库密码，也不包含数据库导出文件。需要运行独立的本地版本时，请自行准备数据库并根据 `.env.example` 配置环境变量。

## 安全提示

- 不要提交 `.env.server.local`、数据库密码、服务器密码或 GitHub Token。
- 不要把 MySQL 的 `3306` 端口直接暴露给公网用户。
- 如果只想体验游戏，直接访问在线地址即可；不需要安装 MySQL。
