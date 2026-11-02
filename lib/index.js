/**
 * 卡塞尔启动动画 —— 宿主半（Node 侧）
 *
 * 本插件全部能力都在浏览器半（lib/client.js）里：往 shell.overlay 浮层挂一块
 * 全屏 iframe 播放六屏授权序列。宿主侧不需要注册服务、路由或工具，
 * 因此 apply 为空实现——但 Cordis 需要一个合法的插件入口。
 */
export const name = 'kassel-boot'

export const inject = []

export function apply() {}
