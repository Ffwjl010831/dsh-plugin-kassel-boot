#!/bin/bash
# ---------------------------------------------------------------------------
# 一键产出发给朋友的分享包
#   ./build-share.sh                    用当前用户名占位，生成 dist/
#   ./build-share.sh ouyangting         顺手把占位符换成你的 GitHub 用户名
# ---------------------------------------------------------------------------
set -e
DIR=$(cd "$(dirname "$0")" && pwd)
cd "$DIR"

USER_NAME="$1"
if [ -n "$USER_NAME" ]; then
  perl -pi -e "s|__GITHUB_USER__|$USER_NAME|g" install.sh README.md
  echo "已把发布地址里的用户名设为 $USER_NAME"
fi

# 1. 打 tgz
rm -f dsh-kassel-boot-*.tgz
npm pack --pack-destination . >/dev/null 2>&1
TGZ=$(ls dsh-kassel-boot-*.tgz | head -1)
echo "tgz     $TGZ"

# 2. 生成自解压 install.command
node build-share.js

# 3. 组装 dist
DIST="$DIR/dist"
rm -rf "$DIST"
mkdir -p "$DIST/卡塞尔启动动画"
cp "$TGZ" install.sh uninstall.sh 使用说明.txt "$DIST/卡塞尔启动动画/"
cp install.command "$DIST/卡塞尔启动动画/安装卡塞尔启动动画.command"
cp uninstall.sh "$DIST/卡塞尔启动动画/卸载卡塞尔启动动画.command"
chmod +x "$DIST/卡塞尔启动动画/"*.command "$DIST/卡塞尔启动动画/install.sh"
find "$DIST" -name ".DS_Store" -delete

ditto -c -k --norsrc --keepParent "$DIST/卡塞尔启动动画" "$DIR/卡塞尔启动动画-分享包.zip"
echo "zip     $DIR/卡塞尔启动动画-分享包.zip  $(du -h "$DIR/卡塞尔启动动画-分享包.zip" | cut -f1)"

echo ""
echo "可以直接发出去的三个东西："
echo "  · $DIR/卡塞尔启动动画-分享包.zip（推荐，解压双击）"
echo "  · $DIR/install.command（单个文件，双击即可）"
echo "  · $DIR/${TGZ}（标准 npm 包）"
