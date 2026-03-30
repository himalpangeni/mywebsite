const fs = require('fs');
const path = require('path');

const baseDir = '/home/user/Documents/Web_Launch';
const excludeDirs = ['node_modules', '.git', '.gemini', 'python/ai-chat-web-app/venv'];

const issues = [];
const ok = [];

function walk(dir, fileList = []) {
  let entries;
  try { entries = fs.readdirSync(dir); } catch(e) { return fileList; }
  for (const file of entries) {
    const fullPath = path.join(dir, file);
    let stat;
    try { stat = fs.statSync(fullPath); } catch(e) { continue; }
    if (stat.isDirectory()) {
      if (!excludeDirs.some(ex => fullPath.includes(ex))) {
        walk(fullPath, fileList);
      }
    } else if (file === 'index.html') {
      fileList.push(fullPath);
    }
  }
  return fileList;
}

const allFiles = walk(baseDir);

// Read the main index.html to extract all href links
const mainHtml = fs.readFileSync(path.join(baseDir, 'index.html'), 'utf8');
const hrefRe = /href="([^"#]+\.html)"/g;
let match;
const linkedFiles = new Set();
while ((match = hrefRe.exec(mainHtml)) !== null) {
  const rel = match[1];
  if (!rel.startsWith('http')) {
    linkedFiles.add(path.resolve(baseDir, rel));
  }
}

console.log(`\n===== PORTFOLIO HEALTH CHECK =====`);
console.log(`Total HTML files found: ${allFiles.length}`);
console.log(`Links in index.html: ${linkedFiles.size}`);
console.log(`==================================\n`);

// Check 1: blank/empty files
for (const f of allFiles) {
  const size = fs.statSync(f).size;
  const rel = f.replace(baseDir + '/', '');
  if (size === 0) {
    issues.push(`❌ EMPTY FILE: ${rel}`);
  }
}

// Check 2: files still have old stub text
for (const f of allFiles) {
  if (f === path.join(baseDir, 'index.html')) continue;
  const content = fs.readFileSync(f, 'utf8');
  const rel = f.replace(baseDir + '/', '');
  const hasInteractivity = content.includes('Interactive App Mockup') || 
                           content.includes('onclick') || 
                           content.includes('<script') ||
                           content.includes('Return to Project Hub') ||
                           content.includes('Connect to App');
  if (content.includes('dedicated backend architecture stub') || 
      (content.includes('seamlessly separated') && !content.includes('onclick'))) {
    issues.push(`❌ STILL A STUB: ${rel}`);
  } else if (!hasInteractivity) {
    issues.push(`⚠️  NO INTERACTIVITY: ${rel}`);
  } else {
    ok.push(`✅ OK: ${rel}`);
  }
}

// Check 3: broken links from index.html
for (const linked of linkedFiles) {
  if (!fs.existsSync(linked)) {
    const rel = linked.replace(baseDir + '/', '');
    issues.push(`❌ BROKEN LINK: ${rel} (file not found)`);
  }
}

// Check 4: Files with wrong return paths (going too many levels up)
for (const f of allFiles) {
  if (f === path.join(baseDir, 'index.html')) continue;
  const content = fs.readFileSync(f, 'utf8');
  const depth = f.replace(baseDir, '').split('/').length - 2;
  const expectedReturn = '../'.repeat(depth) + 'index.html';
  // just check if ANY return link exists
  if (!content.includes('index.html') && !content.includes('127.0.0.1')) {
    const rel = f.replace(baseDir + '/', '');
    issues.push(`⚠️  NO RETURN LINK: ${rel}`);
  }
}

console.log(`Issues Found: ${issues.length}`);
if (issues.length > 0) {
  issues.forEach(i => console.log(i));
} else {
  console.log('No issues found!');
}
console.log(`\nFiles passing checks: ${ok.length}`);
