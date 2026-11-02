// 把 install.sh + 打好的 tgz 合并成一个自解压的 install.command
import fs from 'node:fs';
import path from 'node:path';

const dir = import.meta.dirname;
const install = fs.readFileSync(path.join(dir, 'install.sh'), 'utf8');
const tgzName = fs.readdirSync(dir).find((f) => /^dsh-kassel-boot-.*\.tgz$/.test(f));
if (!tgzName) {
  console.error('先打 tgz：npm pack，再运行本脚本');
  process.exit(1);
}

const b64 = fs.readFileSync(path.join(dir, tgzName)).toString('base64').match(/.{1,76}/g).join('\n');
const body = install.replace(/^#!\/bin\/bash\n/, '');
const out = '#!/bin/bash\n' + body + '\nexit 0\n__KASSEL_PAYLOAD__\n' + b64 + '\n';

const file = path.join(dir, 'install.command');
fs.writeFileSync(file, out, { mode: 0o755 });
fs.chmodSync(file, 0o755);
console.log('install.command  ' + (out.length / 1024).toFixed(0) + 'KB  (' + tgzName + ')');
