#!/bin/bash
# ---------------------------------------------------------------------------
# 卡塞尔启动动画 · DeepSeek Harness 插件（安装 / 卸载）
#
#   sh install.sh                      同目录下有 .tgz 包，直接装
#   sh install.sh /path/to/xxx.tgz     指定包
#   sh install.sh https://xxx.tgz      从网址下载后装
#   sh install.sh --uninstall          卸载
# ---------------------------------------------------------------------------
set -e

PKG="dsh-kassel-boot"
VER="0.1.0"
DSH_HOME="${DSH_HOME:-$HOME/.dsh}"
SELF_DIR=$(cd "$(dirname "$0")" && pwd)

# 没有本地包时，从这个地址下载
PKG_URL="${KASSEL_PKG_URL:-https://raw.githubusercontent.com/Ffwjl010831/dsh-kassel-boot/main/dsh-kassel-boot-0.1.0.tgz}"
# 占位符还没换成真用户名时，视为未配置（字符串拼开写，避免被 build-share 的 sed 一起替换）
PLACEHOLDER="__GITHUB""_USER__"
case "$PKG_URL" in *"$PLACEHOLDER"*) PKG_URL="" ;; esac

blue()  { printf "\033[1;34m%s\033[0m\n" "$1"; }
ok()    { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn()  { printf "  \033[33m!\033[0m %s\n" "$1"; }
die()   { printf "  \033[31m✗\033[0m %s\n" "$1"; exit 1; }

# 双击运行时留住窗口
pause() {
  if [ -t 0 ] && [ -t 1 ]; then
    printf "\n按回车关闭窗口…"
    read -r _ || true
  fi
}

# 优先系统 node；没有就把 DSH 自带的 Electron 当 node 用
find_node() {
  if command -v node >/dev/null 2>&1; then
    command -v node
    return 0
  fi
  for APP in "/Applications/DeepSeek Harness.app" "$HOME/Applications/DeepSeek Harness.app"; do
    if [ -x "$APP/Contents/MacOS/DeepSeek Harness" ]; then
      export ELECTRON_RUN_AS_NODE=1
      printf "%s" "$APP/Contents/MacOS/DeepSeek Harness"
      return 0
    fi
  done
  return 1
}

find_profile() {
  for p in desktop default mac local; do
    if [ -f "$DSH_HOME/profiles/$p/package.json" ]; then printf "%s" "$p"; return 0; fi
  done
  for d in "$DSH_HOME"/profiles/*/; do
    if [ -f "$d/package.json" ]; then basename "$d"; return 0; fi
  done
  return 1
}

[ "$(uname)" = "Darwin" ] || die "这个安装器只支持 macOS。"
[ -d "$DSH_HOME" ] || die "没找到 $DSH_HOME —— 请先装好 DeepSeek Harness 并至少启动过一次。"

PROFILE=$(find_profile) || die "没找到任何 DSH profile，请先启动一次 DeepSeek Harness。"
PROFILE_DIR="$DSH_HOME/profiles/$PROFILE"
NM="$PROFILE_DIR/node_modules"
NODE_BIN=$(find_node) || die "找不到可用的 node，无法更新配置。"

EDITS="${TMPDIR:-/tmp}/kassel-edit-$$.js"
cat > "$EDITS" <<'JS'
const fs = require("fs");
const [file, name, action] = process.argv.slice(2);
const pkg = JSON.parse(fs.readFileSync(file, "utf8"));
if (action === "remove") {
  if (pkg.dependencies) delete pkg.dependencies[name];
  if (pkg.dsh && pkg.dsh.profile && Array.isArray(pkg.dsh.profile.bundles)) {
    pkg.dsh.profile.bundles = pkg.dsh.profile.bundles.filter((x) => x !== name);
  }
} else {
  pkg.dependencies = pkg.dependencies || {};
  pkg.dependencies[name] = "link:../../plugins/" + name;
  pkg.dsh = pkg.dsh || {};
  pkg.dsh.profile = pkg.dsh.profile || {};
  const bundles = (pkg.dsh.profile.bundles = pkg.dsh.profile.bundles || []);
  if (!bundles.includes(name)) bundles.push(name);
}
fs.writeFileSync(file, JSON.stringify(pkg, null, 2) + "\n");
JS
trap 'rm -f "$EDITS"' EXIT

# =============================== 卸载 ======================================
if [ "$1" = "--uninstall" ] || [ "$1" = "-u" ] || [ "$1" = "uninstall" ]; then
  blue ""
  blue "  卡塞尔启动动画 · 卸载"
  blue "  ─────────────────────────────────"
  blue ""

  "$NODE_BIN" "$EDITS" "$PROFILE_DIR/package.json" "$PKG" remove
  ok "profile 配置已清理"

  rm -f "$NM/$PKG"
  ok "node_modules 链接已移除"

  if [ -d "$DSH_HOME/plugins/$PKG" ]; then
    TRASH="$DSH_HOME/plugins/.trash-$(date +%Y%m%d%H%M%S)"
    mkdir -p "$TRASH"
    mv "$DSH_HOME/plugins/$PKG" "$TRASH/$PKG"
    ok "插件文件已移到 .trash-$(basename "$TRASH" | sed 's/.*trash-//')（确认无误后可自行删除）"
  fi

  blue ""
  ok "卸载完成。完全退出并重新打开 DeepSeek Harness 即生效。"
  blue ""
  pause
  exit 0
fi

# =============================== 安装 ======================================
blue ""
blue "  卡塞尔启动动画 · DSH 插件安装器"
blue "  ─────────────────────────────────"
blue ""

STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"; rm -f "$EDITS"' EXIT

SRC="$1"
if [ -z "$SRC" ]; then
  SRC=$(ls "$SELF_DIR"/dsh-kassel-boot-*.tgz 2>/dev/null | head -1 || true)
fi
if [ -z "$SRC" ] && grep -qx '__KASSEL_PAYLOAD__' "$0" 2>/dev/null; then
  awk 'f{print} /^__KASSEL_PAYLOAD__$/{f=1}' "$0" > "$STAGE/payload.b64"
  if base64 -d < "$STAGE/payload.b64" > "$STAGE/pkg.tgz" 2>/dev/null; then :
  else base64 -D < "$STAGE/payload.b64" > "$STAGE/pkg.tgz"; fi
  SRC="$STAGE/pkg.tgz"
  ok "已从安装器自带的包里解出插件"
fi
# 通过 curl | bash 运行时没有自身文件，也没有同目录包 —— 从发布地址下载
if [ -z "$SRC" ] && [ -n "$PKG_URL" ]; then
  SRC="$PKG_URL"
fi
[ -n "$SRC" ] || die "找不到安装包（dsh-kassel-boot-*.tgz），请把它和本脚本放在一起。"

case "$SRC" in
  http://*|https://*)
    ok "下载安装包…"
    curl -fsSL "$SRC" -o "$STAGE/pkg.tgz" || die "下载失败，检查网络或链接。"
    SRC="$STAGE/pkg.tgz"
    ;;
  *)
    [ -f "$SRC" ] || die "文件不存在：$SRC"
    SRC=$(cd "$(dirname "$SRC")" && pwd)/$(basename "$SRC")
    ;;
esac
ok "安装包：$(basename "$SRC")"
ok "目标 profile：$PROFILE"

# 展开
tar -xzf "$SRC" -C "$STAGE" 2>/dev/null || die "安装包损坏。"
[ -f "$STAGE/package/package.json" ] || die "安装包结构不对，缺少 package/package.json。"

PLUGIN_DIR="$DSH_HOME/plugins/$PKG"
mkdir -p "$DSH_HOME/plugins"
if [ -d "$PLUGIN_DIR" ]; then
  mv "$PLUGIN_DIR" "$PLUGIN_DIR.bak-$(date +%Y%m%d%H%M%S)"
  warn "已存在旧版本，已备份（确认无误后可删除 .bak-* 目录）"
fi
cp -R "$STAGE/package" "$PLUGIN_DIR"
ok "插件文件已就位"

# 链接
mkdir -p "$NM"
rm -f "$NM/$PKG"
ln -s "../../plugins/$PKG" "$NM/$PKG"
ok "已链接到 profile/node_modules"

# 写配置
cp "$PROFILE_DIR/package.json" "$PROFILE_DIR/package.json.bak-$PKG"
"$NODE_BIN" "$EDITS" "$PROFILE_DIR/package.json" "$PKG" add || die "写入 profile 配置失败，原文件已备份。"
ok "profile 配置已更新"

# 冲突提示
for other in dsh-startup-screen dsh-boot-screen; do
  if [ -d "$NM/$other" ]; then
    warn "检测到同类启动插件 $other，两个会抢同一个浮层，建议关掉其中一个。"
  fi
done

blue ""
ok "安装完成。"
blue ""
printf "  下一步：\033[1m完全退出 DeepSeek Harness（⌘Q），再重新打开\033[0m\n"
printf "  启动后会出现六屏授权动画，点一下或按 Enter 进入下一屏。\n\n"
printf "  想卸载：拿这个文件运行 \033[1msh \"%s\" --uninstall\033[0m\n" "$(basename "$0")"
blue ""
pause
