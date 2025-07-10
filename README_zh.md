# realsync 数据同步 LuCI 应用

## 项目简介

**realsync** 是一款基于 OpenWrt 的数据实时同步与自动备份工具，配套 LuCI Web 界面，支持多任务、定时同步、日志查看、权限控制等功能，适用于路由器、NAS、边缘网关等多种场景。

---

## 主要功能

- 多任务数据同步配置
- 支持 rsync + inotifywait 实时/定时同步
- LuCI 界面可视化管理、状态监控、日志查看
- 一键清空日志、强制重启服务
- 权限控制（ACL）安全可靠
- 支持中英文界面

---

## 安装方法

1. 上传本项目所有文件到 OpenWrt 路由器（推荐 `/root` 或 `/tmp` 目录）。
2. 赋予安装脚本执行权限：
   ```sh
   git clone https://github.com/xfghvgnfyjssjgte/Luci-app-Realsync.git
   cd realsync
   chmod +x install_realsync.sh
   ```
3. 执行安装：
   ```sh
   ./install_realsync.sh install
   ```
4. 安装过程中会自动检查并安装依赖（rsync、inotify-tools），复制所有文件，设置权限，启用并启动服务。
5. 安装完成后，登录 LuCI，进入“服务”->“realsync”进行配置和管理。

---

## 使用说明

- 在 LuCI 界面添加/编辑同步任务，填写源目录、目标目录、同步间隔等参数。
- 可随时启用/停用任务，查看任务运行状态和详细日志。
- 支持一键清空日志、强制重启服务。
- 日志文件位于 `/var/log/realsync.log`。

---

## 常见问题

- **Q: 安装后界面无显示？**
  - 请清理浏览器缓存，或重启 uhttpd。
- **Q: 日志无法清空？**
  - 请确认有写权限，或重启服务后再试。
- **Q: 任务未自动启动？**
  - 可手动点击“强制重启”或检查依赖是否安装。

---

## 支持环境

- OpenWrt 19.07/21.02/22.03 及以上
- 路由器、x86、ARM、NAS、虚拟机等
- 需预装 rsync、inotify-tools

---

## 联系方式

Author: [望天追风や ]

Email: [xfghvgnfyjssjgte@gmail.com]



