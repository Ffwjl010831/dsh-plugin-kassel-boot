#!/bin/bash
# 卸载卡塞尔启动动画（等价于 install.sh --uninstall）
DIR=$(cd "$(dirname "$0")" && pwd)
exec sh "$DIR/install.sh" --uninstall
