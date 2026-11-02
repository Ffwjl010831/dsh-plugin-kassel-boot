/**
 * 把 lib/boot.html 重新内联进 lib/client.js。
 *
 * client.js 以 base64 常量携带整份动画页面，改完 boot.html 跑一次这个脚本即可：
 *   node build.js
 */
import { readFileSync, writeFileSync } from 'node:fs'

const html = readFileSync(new URL('./lib/boot.html', import.meta.url))
const b64 = html.toString('base64')

const clientPath = new URL('./lib/client.js', import.meta.url)
const src = readFileSync(clientPath, 'utf8')

const re = /const B64 = "[A-Za-z0-9+/=]*"/
if (!re.test(src)) {
  console.error('✗ 没在 client.js 里找到 B64 常量，内联失败')
  process.exit(1)
}

const out = src.replace(re, `const B64 = "${b64}"`)
writeFileSync(clientPath, out)

console.log(`✓ boot.html ${html.length} 字节 → base64 ${b64.length} 字符已写入 client.js（共 ${out.length} 字节）`)
