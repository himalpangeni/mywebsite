const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const baseDir = '/home/user/Documents/Web_Launch';
const key_files = [
  // C Projects
  'c/snake-game/index.html',
  'c/chat-app-sockets/index.html',
  'c/cli-text-editor/index.html',
  'c/encryption-tool/index.html',
  'c/mini-os-shell/index.html',
  'c/database-engine/index.html',
  'c/process-scheduler/index.html',
  'c/memory-allocator/index.html',
  'c/http-server/index.html',
  'c/file-compression/index.html',
  // Java
  'java/multiplayer-game-server/index.html',
  // .NET
  'dotnet/multiplayer-game-backend/index.html',
  // Python backend
  'python/ai-chat-web-app/index.html',
  // Main hub
  'index.html',
  // 3D Experience
  'NEW FOLDER/dist/index.html',
  // Ludo
  'ludo-game/client/index.html',
  'ludo-game/client/game.js',
];

const results = { pass: [], fail: [] };

for (const rel of key_files) {
  const full = path.join(baseDir, rel);
  if (!fs.existsSync(full)) {
    results.fail.push(`❌ NOT FOUND: ${rel}`);
    continue;
  }

  const stat = fs.statSync(full);
  if (stat.size < 100) {
    results.fail.push(`❌ TOO SMALL (${stat.size}b): ${rel}`);
    continue;
  }

  const content = fs.readFileSync(full, 'utf8');

  // For JS files: run node syntax check
  if (rel.endsWith('.js')) {
    try {
      execSync(`node --check "${full}"`, { stdio: 'pipe' });
      results.pass.push(`✅ JS SYNTAX OK (${Math.round(stat.size/1024)}KB): ${rel}`);
    } catch (e) {
      results.fail.push(`❌ JS SYNTAX ERROR: ${rel}\n   ${e.stderr?.toString().split('\n')[0]}`);
    }
    continue;
  }

  // For HTML: extract all <script> blocks and check syntax
  const scripts = [];
  const re = /<script[^>]*>([\s\S]*?)<\/script>/gi;
  let m;
  while ((m = re.exec(content)) !== null) {
    const src = m[1].trim();
    if (src && !src.includes('type="module"') && src.length > 10) {
      scripts.push(src);
    }
  }

  let hasSyntaxError = false;
  let errMsg = '';
  for (const script of scripts) {
    const tmp = `/tmp/check_${Date.now()}.js`;
    fs.writeFileSync(tmp, script);
    try {
      execSync(`node --check "${tmp}"`, { stdio: 'pipe' });
    } catch (e) {
      hasSyntaxError = true;
      errMsg = e.stderr?.toString().split('\n').slice(0,2).join(' ') || 'syntax error';
      break;
    } finally {
      try { fs.unlinkSync(tmp); } catch(e) {}
    }
  }

  // Also check for unclosed tags: simple heuristic
  const hasBody = content.includes('</body>');
  const hasHtml = content.includes('</html>');
  const hasReturnLink = content.includes('index.html') || rel === 'index.html';

  if (hasSyntaxError) {
    results.fail.push(`❌ SCRIPT SYNTAX ERROR: ${rel}\n   ${errMsg}`);
  } else if (!hasBody || !hasHtml) {
    results.fail.push(`⚠️  MALFORMED HTML (missing </body> or </html>): ${rel}`);
  } else {
    results.pass.push(`✅ OK (${Math.round(stat.size/1024)}KB, ${scripts.length} script block(s)): ${rel}`);
  }
}

console.log('\n======= RUNTIME SYNTAX VALIDATION =======');
console.log(`Checked: ${key_files.length} files`);
console.log(`Pass: ${results.pass.length} | Fail: ${results.fail.length}`);
console.log('\n--- PASSING ---');
results.pass.forEach(r => console.log(r));
if (results.fail.length) {
  console.log('\n--- ISSUES ---');
  results.fail.forEach(r => console.log(r));
} else {
  console.log('\n🎉 All checked files pass!');
}
