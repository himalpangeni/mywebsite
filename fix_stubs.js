const fs = require('fs');
const path = require('path');

const baseDir = '/home/user/Documents/Web_Launch';
const excludeDirs = ['node_modules', '.git', '.gemini', 'venv', 'NEW FOLDER', 'mywebsite', 'ludo-game', 'game'];

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
    } else if (file === 'index.html' && dir !== baseDir) {
      fileList.push(fullPath);
    }
  }
  return fileList;
}

const allFiles = walk(baseDir);
let fixedCount = 0;

for (const file of allFiles) {
  let content = fs.readFileSync(file, 'utf8');

  // Fix 1: Replace orphaned un-interpolated ${title} inside injected chat UI
  if (content.includes('Welcome to ${title}!')) {
    // Extract the h1 title to use instead
    const h1Match = content.match(/<h1[^>]*>(.*?)<\/h1>/i);
    const title = h1Match ? h1Match[1].replace(/<[^>]+>/g, '') : 'this App';
    content = content.replaceAll('Welcome to ${title}!', `Welcome to ${title}!`);
    fs.writeFileSync(file, content);
    fixedCount++;
    console.log(`Fixed \${title} in: ${file.replace(baseDir + '/', '')}`);
  }

  // Fix 2: Replace old stub description paragraph
  content = fs.readFileSync(file, 'utf8');
  if (content.includes('dedicated backend architecture stub') || content.includes('seamlessly separated')) {
    // Extract real description from title or desc sections
    const h1Match = content.match(/<h1[^>]*>(.*?)<\/h1>/i);
    const title = h1Match ? h1Match[1].replace(/<[^>]+>/g, '') : 'this App';

    // Replace old stub paragraph with a useful one
    content = content.replace(
      /<p style="margin-bottom:30px;">[^<]*dedicated backend architecture stub[^<]*<\/p>/,
      `<p style="margin-bottom:30px;">${title} — An interactive frontend showcase. Explore the simulated UI below.</p>`
    );
    content = content.replace(
      /<p style="margin-bottom:30px;">[^<]*seamlessly separated[^<]*<\/p>/,
      `<p style="margin-bottom:30px;">${title} — An interactive frontend showcase. Explore the simulated UI below.</p>`
    );
    fs.writeFileSync(file, content);
    fixedCount++;
    console.log(`Fixed stub desc in: ${file.replace(baseDir + '/', '')}`);
  }
}

console.log(`\nFixed ${fixedCount} files.`);
