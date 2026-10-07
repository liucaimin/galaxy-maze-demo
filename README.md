# Galaxy Maze

星系形态识别迷宫游戏，面向具有基础天文知识的初学者。玩家通过观察星系图像，按照决策树回答形态问题，完成分类并收集拼图碎片。

## 在线体验

当前在线版本：

<http://8.148.20.120:8777/>

普通用户和管理员都从这个地址进入。管理员账号用于标定 `galaxy_levels` 中每个星系的标准答案。

## 项目功能

- 按星系形态决策树逐步生成迷宫问题。
- 每一关从数据库读取星系名称、图片和答案属性。
- 答案完全正确后才能通过当前星系。
- 答错的星系之后仍可能再次出现，已完成的星系不会重复出现。
- 根据答对题数累计积分，积分可以兑换随机拼图碎片。
- 拼图碎片随机落位，集齐后可以查看、下载完整拼图。
- 支持键盘操作：方向键移动和选择，空格确认，`P` 打开拼图，`H` 打开操作指南，`R` 重新开始当前关卡。
- 管理员可以在管理页面快速标定并保存数据库答案。

## 项目结构

```text
src/                  Vue前端和图片资源
src/assets/images/    星系图、示例图、决策树和拼图
server/index.mjs      Express API和MySQL判题接口
package.json          项目脚本和依赖
.env.example          环境变量示例，不包含真实密码
```

## 本地运行

需要安装 Node.js 20.19 或更高版本。

```bash
npm install
npm run dev
```

浏览器打开：

```text
http://localhost:5173/
```

本地运行数据库功能时，需要自行准备 MySQL 和 `.env.server.local`。真实数据库密码不能提交到 GitHub。

## 安全提示

- `.env.server.local`、数据库密码、服务器密码和 GitHub Token 不要上传。
- GitHub 仓库保存的是源码和图片；在线版本使用服务器上的 API 和数据库。
- 不要把 MySQL 的 `3306` 端口或数据库账号密码交给普通用户。
- 如果只想体验游戏，直接打开上面的在线地址即可。

## 上传到 GitHub（Windows + Git）

### 1. 在 GitHub 创建空仓库

登录 <https://github.com> 后，按下面的英文按钮操作：

1. 点击页面右上角的 `+`。
2. 在菜单中点击 `New repository`。
3. 在 `Repository name` 输入仓库名称，例如 `galaxy-maze`。
4. 选择 `Public` 或 `Private`。
5. `Add a README file` 不要勾选，因为本项目已经有 README。
6. `Add .gitignore` 选择 `None`，因为本项目已经有 `.gitignore`。
7. `Choose a license` 选择 `None`（除非你需要添加开源协议）。
8. 点击页面底部的 `Create repository`。

### 2. 复制 GitHub 仓库地址

进入刚创建的仓库：

1. 点击绿色的 `<> Code` 按钮。
2. 选择 `HTTPS`。
3. 点击仓库地址右侧的复制图标。

复制的地址类似：

```text
https://github.com/你的用户名/galaxy-maze.git
```

### 3. 在本地项目目录推送

打开 PowerShell：

```powershell
cd D:\WebMaze\web\web
git branch -M main
git remote add origin https://github.com/你的用户名/galaxy-maze.git
git push -u origin main
```

将地址替换为刚才从 `<> Code` 复制的地址。

如果提示：

```text
remote origin already exists
```

执行：

```powershell
git remote set-url origin https://github.com/你的用户名/galaxy-maze.git
git push -u origin main
```

### 4. 检查是否上传成功

回到 GitHub 仓库页面，点击上方的 `Code` 标签。应该能看到：

- `src`
- `server`
- `package.json`
- `package-lock.json`
- `README.md`
- 图片资源

如果要查看提交记录，点击仓库页面的 `commits` 或文件列表上方的提交数量链接。

### 5. 后续更新项目

修改代码后，在 PowerShell执行：

```powershell
cd D:\WebMaze\web\web
npm.cmd run build
git add .
git commit -m "Update galaxy maze"
git push
```

也可以把提交信息改成更具体的内容，例如：

```powershell
git commit -m "Fix keyboard controls"
```

## GitHub 网页上传方式（备用）

如果不使用 Git 命令：

1. 进入 GitHub 仓库页面。
2. 点击 `Add file`。
3. 点击 `Upload files`。
4. 将文件拖入 `Drag files here` 区域。
5. 在页面底部的 `Commit changes` 区域填写提交说明。
6. 点击 `Commit changes`。

由于项目包含很多图片，推荐使用 Git 命令推送，网页上传更容易受到文件数量和大小限制。
