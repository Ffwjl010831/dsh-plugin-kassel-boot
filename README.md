# dsh-kassel-boot

卡塞尔学院风格的 **DeepSeek Harness 启动动画**。DSH 启动（页面加载）时，在 `shell.overlay`
框架级浮层上铺一块全屏画面，播放六屏授权序列，结尾以暗金「欢迎来到卡塞尔」交还宿主。

| # | 代号 | 内容 |
|---|---|---|
| 01 | AUTHORIZATION | 等待用户授权 |
| 02 | IDENTITY | 核对身份资料（RICARDO M. LU / A.D.0013 / S 级） |
| 03 | REQUEST | 请求终端权限 |
| 04 | READ | 读取血统档案 |
| 05 | VERIFY | 核验通过 → 即将接入卡塞尔学院 |
| 06 | WELCOME | WELCOME TO KASSEL ·【接入终端】 |

每一屏都要**点一下**（或按 `Enter` / `空格`）才进下一屏，不自动播放。右上角 `SKIP` 直接跳到第 06 屏。
点「接入终端」→ 金色大字逐字浮现 → 自动淡出 → 插件自行卸载，把界面交还给 DSH。

---

## 安装

### 方式一：一行命令（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/__GITHUB_USER__/dsh-kassel-boot/main/install.sh | bash
```

装完 **⌘Q 完全退出 DeepSeek Harness**，再打开就能看到动画。

### 方式二：下载单文件双击

下载 [`install.command`](./install.command)，右键 →「打开」→ 再点一次「打开」。

### 方式三：标准 npm 包

```bash
dsh plugin --profile desktop add https://raw.githubusercontent.com/__GITHUB_USER__/dsh-kassel-boot/main/dsh-kassel-boot-0.1.0.tgz
```

> 需要先把 DSH 的命令行工具装进 PATH（DSH 设置里的「安装命令行工具」）。

### 手动装

把本目录放进 `~/.dsh/plugins/dsh-kassel-boot`，然后：

```bash
ln -sfn ../../plugins/dsh-kassel-boot ~/.dsh/profiles/desktop/node_modules/dsh-kassel-boot
```

并在 `~/.dsh/profiles/desktop/package.json` 里加两处：

```jsonc
{
  "dependencies": { "dsh-kassel-boot": "link:../../plugins/dsh-kassel-boot" },
  "dsh": { "profile": { "bundles": ["...", "dsh-kassel-boot"] } }
}
```

---

## 卸载

```bash
curl -fsSL https://raw.githubusercontent.com/__GITHUB_USER__/dsh-kassel-boot/main/install.sh | bash -s -- --uninstall
```

或者本地跑 `sh install.sh --uninstall`。

---

## 结构

```
dsh-kassel-boot/
├── package.json          # dsh.bundle.patch + dsh.client 声明
├── cordis.patch.yml      # 把插件行插入 Cordis 配置树
├── lib/
│   ├── index.js          # 宿主半（Node）：空实现，能力全在浏览器半
│   ├── client.js         # 浏览器半：往 shell.overlay 注册全屏组件
│   └── boot.html         # 六屏动画本体（被 base64 内联进 client.js）
├── assets/icon.png       # 插件图标（校徽）
├── install.sh            # 安装 / 卸载脚本（唯一真源）
└── build-share.js        # 把 install.sh + tgz 合并成自解压 install.command
```

浏览器半把 `boot.html` 以 base64 内联，运行时解码塞进 `iframe.srcdoc` —— 样式与 DSH 完全隔离，
也不依赖宿主静态路由或文件协议。动画与宿主只靠一条消息通信：

```js
// iframe 内（金色弹窗播完）
window.parent.postMessage({ type: 'kassel-boot-go' }, '*')

// 宿主组件收到后淡出并卸载
```

---

## 改动画内容

改 `lib/boot.html`，重新内联：

```bash
node build.js
```

## 打包分享

```bash
./build-share.sh 你的GitHub用户名
```

产出 `dist/卡塞尔启动动画/`、`卡塞尔启动动画-分享包.zip`、`install.command`。

## License

MIT
